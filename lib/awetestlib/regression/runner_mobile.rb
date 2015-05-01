require 'awetestlib/regression/browser'
require 'awetestlib/regression/find'
require 'awetestlib/regression/user_input'
require 'awetestlib/regression/waits'
require 'awetestlib/regression/tables'
require 'awetestlib/regression/page_data'
require 'awetestlib/regression/drag_and_drop'
require 'awetestlib/regression/utilities'
require 'awetestlib/regression/legacy'
require 'awetestlib/logging'
require 'awetestlib/regression/validations'
require 'awetestlib/html_report'
#require 'rbconfig'
require 'ostruct'
require 'csv'
require 'etc'
require 'yaml'
require 'active_support'
require 'active_support/inflector'
# require 'sys/uname'

require 'watir-webdriver'

module Awetestlib
  module Regression
    # Collects all the components needed to run the script and executes it.
    class Runner < Awetestlib::Runner

      # order matters here
      #  include Sys  #; load_time('include Sys')
      include ActiveSupport::Inflector #; load_time('include ActiveSupport::Inflector')
      include Awetestlib::Logging #; load_time('include Awetestlib::Logging')
      include Awetestlib::Regression::Utilities #; load_time('include Awetestlib::Regression::Utilities')
      include Awetestlib::Regression::Browser #; load_time('include Awetestlib::Regression::Browser')
      include Awetestlib::Regression::Find #; load_time('include Awetestlib::Regression::Find')
      include Awetestlib::Regression::UserInput #; load_time('include Awetestlib::Regression::UserInput')
      include Awetestlib::Regression::Waits #; load_time('include Awetestlib::Regression::Waits')
      include Awetestlib::Regression::Tables #; load_time('include Awetestlib::Regression::Tables')
      include Awetestlib::Regression::PageData #; load_time('include Awetestlib::Regression::PageData')
      include Awetestlib::Regression::DragAndDrop #; load_time('include Awetestlib::Regression::DragAndDrop')
      include Awetestlib::Regression::Validations #; load_time('include Awetestlib::Regression::Validations')
      include Awetestlib::Regression::Legacy #; load_time('include Awetestlib::Regression::Legacy')
      # load_time('includes')

      ::DEBUG   = 0
      ::INFO    = 1
      ::WARN    = 2
      ::ERROR   = 3
      ::FATAL   = 4
      ::UNKNOWN = 5

      ::TOP_LEVEL    = 7
      ::SECOND_LEVEL = ::TOP_LEVEL - 1

      ::WAIT = 20
      ::PASS = '-PASS'
      ::FAIL = '-FAIL'

      attr_accessor :browser, :browser_abbrev, :version, :env,
                    :library, :script_type, :script_file, :script_name,
                    # :log_properties, :log_queue, :log_class,
                    # :notify_queue, :notify_class, :notify_id,
                    :screencap_path, :xls_path, :script_path, :user_token, :root_path,
                    :debug_on_fail,
                    :environment, :environment_name, :environment_url, :environment_nodename,
                    :cycle, :browser_sequence,
                    :output_to_log, :log_path_subdir, :report_all_test_refs,
                    :timeout, :classic_watir, :capture_load_times, :pry,
                    :emulator, :device_type, :device_id, :sdk, :options

      # TODO: Encapsulate in some kind of config
      ###################################
      def setup_global_test_vars(options)
        @my_failed_count     = 0
        @my_passed_count     = 0
        @my_error_references = Hash.new
        @my_error_hits       = Hash.new

        @report_all_refs = options[:report_all_test_refs]

        if options[:environment]
          @myAppEnv = OpenStruct.new(
              :name     => options[:environment]['name'],
              :url      => options[:environment]['url'],
              :nodename => options[:environment]['nodename']
          )
          @runenv   = options[:environment]['nodename'] || options[:environment]['name']
          @myURL    = options[:environment]['url']
        else
          @runenv = options[:environment_name]
        end

        # @targetBrowser, @actualBrowser = browser_to_use
        @targetBrowser, @actualBrowser = browser_to_use(options[:browser], options[:version])
        # @targetVersion                 = @targetBrowser.version
        @browserAbbrev                 = @targetBrowser.abbrev
        @myRoot                        = options[:root_path] || Dir.pwd # NOTE: bug fix pmn 05dec2012
        @myName                        = File.basename(options[:script_file]).sub(/\.rb$/, '')
        self.script_name               = File.basename(options[:script_file]).sub(/\.rb$/, '')

        if options[:output_to_log]
          log_name = "#{@myName}_#{Time.now.strftime("%Y%m%d%H%M%S")}.log"
          if options[:log_path_subdir]
            FileUtils.mkdir options[:log_path_subdir] unless File.directory? options[:log_path_subdir]
            log_path = options[:log_path_subdir]
            log_spec = File.join(log_path, log_name)
          else
            log_spec = log_name
          end
          @myLog = init_logger(log_spec, @myName)
        end

        if options[:xls_path]
          @xls_path = options[:xls_path]
        end

        #TODO need to find way to calculate these on the fly
        @vertical_hack_ie   = 117
        @vertical_hack_ff   = 144
        @horizontal_hack_ie = 5
        @horizontal_hack_ff = 4

      end

      def initialize(options)

        puts("#{__method__}:#{__LINE__}\n#{self.options.to_yaml}")
        self.options = options

        options.each_pair do |k, v|
          self.send("#{k}=", v)
        end

        if options[:pry]
          require 'pry'
        end

        $mobile, $emulator, $simulator = mobile_browser?(options)

        # if verify_browser_options

        # load script file to get overrides
        script_file                    = options[:script_file]
        load script_file; load_time('Load script file', Time.now)
        setup_global_test_vars(options)
        require_gems

        # load and extend with library module if it exists
        if options[:library]
          lib_file = options[:library]
          load lib_file; load_time('Load library file', Time.now) # force a fresh load
          lib_module = module_for lib_file
          self.extend(lib_module)
        end

        # load and extend with script to allow overrides in script.
        script_file = options[:script_file]
        load script_file; load_time('Reload script file', Time.now) # force a fresh load
        script_module = module_for script_file
        self.extend(script_module)
        # else
        #   raise 'Invalid mobile arguments'
        # end
      end

      def mobile_browser?(options)
        puts("#{__method__}:#{__LINE__}\n#{self.options.to_yaml}")
        mobile           = false
        android_emulator = false
        ios_simulator    = false

        if options[:emulator] or options[:sdk] or options[:device_id] or
            options[:device_type] or options[:environment_nodename] =~ /W:|E:|T:|K:|I:/
          require 'appium_lib'
          mobile = true
        end

        if options[:emulator]
          android_emulator = true
        elsif options[:sdk]
          ios_simulator = true
        end

        [mobile, android_emulator, ios_simulator]
      end

      def browser_to_use(browser, browser_version = nil)

        target = OpenStruct.new(
            :name    => (Awetestlib::BROWSER_MAP[self.browser]),
            :abbrev  => self.browser,
            :version => browser_version
        )

        actual = OpenStruct.new(
            :name    => (Awetestlib::BROWSER_MAP[self.browser]),
            :abbrev  => self.browser,
            :version => '',
            :driver  => ''
        )

        [target, actual]
      end

      # def browser_to_use(browser, browser_version = nil)
      #   # platform = ''
      #   # platform = 'Windows' if !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM =~ /mswin|mingw/))
      #   # platform = 'OSX' if RUBY_PLATFORM =~ /darwin/
      #   # platform = 'OSX' if defined?(JRUBY_VERSION)
      #
      #   # browser_abbrev =
      #   #     Awetestlib::BROWSER_ALTERNATES[platform][browser] ?
      #   #         Awetestlib::BROWSER_ALTERNATES[platform][browser] : browser
      #   # if not browser_version
      #   #   case browser_abbrev
      #   #     when 'IE'
      #   #       browser_version = 8
      #   #     when 'FF'
      #   #       browser_version = 11
      #   #     when 'C', 'GC'
      #   #       browser_version = 10
      #   #     when 'S'
      #   #       browser_version = 10
      #   #   end
      #   # end
      #
      #   target = OpenStruct.new(
      #         :name => (Awetestlib::BROWSER_MAP[browser_abbrev]),
      #         :abbrev => browser_abbrev,
      #         :version => browser_version
      #   )
      #   actual = OpenStruct.new(
      #         :name => (Awetestlib::BROWSER_MAP[browser_abbrev]),
      #         :abbrev => browser_abbrev,
      #         :version => '',
      #         :driver => ''
      #   )
      #   [target, actual]
      # end

      def require_gems

        case @browserAbbrev

          when 'IE'
            if $watir_script
              #require 'watir/ie'; load_time
              require 'watir' #; load_time
              require 'watir/process' #; load_time
              require 'watirloo' #; load_time
              require 'patches/watir' #; load_time
              Watir::IE.visible = true
            else
              require 'watir-webdriver' #; load_time
            end
          # when 'FF'
          #   require 'watir-webdriver'; load_time
          # when 'S'
          #   require 'watir-webdriver'; load_time
          #
          # when 'C', 'GC'
          #   require 'watir-webdriver'; load_time

          # when 'CL'
          #   require 'celerity'; load_time
          #   require 'watir-webdriver'; load_timerequi
          else
            require 'watir-webdriver' #; load_time

        end

        if USING_WINDOWS
          require 'win32ole' #; load_time
          @ai = ::WIN32OLE.new('AutoItX3.Control')
        else
          # TODO: Need alternative for Mac?
          @ai = ''
        end

        if @xls_path
          require 'roo' #; load_time
        end

      end

      def module_for(script_file)
        File.read(script_file).match(/^module\s+(\w+)/)[1].constantize
      end

      def before_run
        initiate_html_report
        load_time('Total load time', $begin_time)
        start_run
      end

      def start
        # get_os
        before_run
        run
      rescue Exception => e
        failed_to_log(e.to_s)
      ensure
        after_run
      end

      def after_run
        finish_run
        @report_class.finish_report(@html_report_file, @json_report_file)
        open_report_file
        @myLog.close if @myLog
      end

      def initiate_html_report
        @html_report_name = File.join(FileUtils.pwd, 'awetest_reports', @myName)
        @html_report_dir  = File.dirname(@html_report_name)
        FileUtils.mkdir @html_report_dir unless File.directory? @html_report_dir
        @report_class     = Awetestlib::HtmlReport.new(@myName)
        @html_report_file, @json_report_file = @report_class.create_report(@html_report_name)
      end

      def open_report_file
        full_report_file = File.expand_path(@html_report_file)
        if USING_WINDOWS
          system("start file:///#{full_report_file}")
        elsif USING_OSX
          system("open #{full_report_file}")
        else
          puts "Report can be found in #{full_report_file}"
        end

      end

    end
  end
end
