require 'regression/browser'
require 'regression/find'
require 'regression/user_input'
require 'regression/waits'
require 'regression/tables'
require 'regression/page_data'
require 'regression/drag_and_drop'
require 'regression/utilities'
require 'regression/logging'
require 'regression/validations'

#require 'rbconfig'
require 'ostruct'
require 'active_support'
require 'active_support/inflector'

module Awetestlib

  class Runner

  # order matters here
    include Logging
    include Browser
    include Find
    include UserInput
    include Waits
    include Tables
    include PageData
    include DragAndDrop
    include Utilities
    include Validations

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

    puts ENV["OS"]

    attr_accessor :browser, :browser_abbrev, :version, :env,
                  :library, :script_type, :script_file,
                  :log_properties, :log_queue, :log_class,
                  :notify_queue, :notify_class, :notify_id,
                  :screencap_path, :xls_path, :script_path, :user_token, :root_path,
                  :debug_on_fail,
                  :environment, :environment_name, :environment_url, :environment_nodename,
                  :cycle, :browser_sequence,
                  :output_to_log, :log_path_subdir, :report_all_test_refs,
                  :timeout

    #def self.build(options)
    #  #build_class = "Awetestlib::#{script_module_for options[:script_type]}::Runner".constantize
    #  build_class = "Awetestlib::Runner".constantize
    #  #options     = options.merge(:script_file => options[:script_file])
    #  #if build_class.respond_to?(:runner_class)
    #  #  build_class.runner_class(options)
    #  #else
    #    build_class.new(options)
    #  #end
    #end

    # TODO: Encapsulate in some kind of config
    ###################################
    def setup_global_test_vars(options)
      @my_failed_count = 0
      @my_passed_count = 0
      @my_error_references         = Hash.new
      @my_error_hits     = Hash.new

      @report_all_refs  = options[:report_all_test_refs]

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

      @targetBrowser  = browser_to_use(options[:browser], options[:version])
      @targetVersion  = @targetBrowser.version
      @browserAbbrev  = @targetBrowser.abbrev
      @myRoot         = USING_WINDOWS ? options[:root_path].gsub!('/', '\\') : options[:root_path]
      @myName         = File.basename(options[:script_file]).sub(/\.rb$/, '')

      if options[:output_to_log]
        log_path = "#{@myRoot}/"
        log_path << "#{options[:log_path_subdir]}/" if options[:log_path_subdir]
        log_spec = File.join log_path, "#{@myName}_#{Time.now.strftime("%Y%m%d%H%M%S")}.log"
        @myLog = init_logger(log_spec, @myName)
        #@start_timestamp   = Time.now
        #start_to_log(@start_timestamp)
      end

      if options[:xls_path]
        @xls_path = options[:xls_path]
      end

      #TODO need to find way to calculate these on the fly
      # window top border 30
      # IE toolbars 86
      @vertical_hack_ie   = 117
      # FF toolbars 114
      @vertical_hack_ff   = 144
      # window left border 4
      @horizontal_hack_ie = 5
      @horizontal_hack_ff = 4
      #
      # @x_tolerance = 12
      # @y_tolerance = 12
      require_gems
    end

    #def self.runner_class(options)
    #  script_file = options[:script_file]
    #  load script_file # force a load
    #
    #  runner_module = self.module_for script_file
    #  klass_name    = "#{runner_module.to_s}::Runner"
    #
    #  # Define a Runner class in the test script's module inheriting from AwetestLegacy::Runner
    #  runner_module.module_eval do
    #    eval <<-RUBY
    #  class #{klass_name} < Awetestlib::Runner
    #    def initialize(options)
    #      #super(options)
    #      setup_global_test_vars(options)
    #    end
    #  end
    #    RUBY
    #  end
    #
    #  runner = runner_module::Runner.new(options)
    #
    #  if options[:library]
    #    lib_file = options[:library]
    #    load lib_file
    #    lib_module = self.module_for lib_file
    #    runner.extend(lib_module)
    #  end
    #
    #  # Add in the methods defined in the script's module
    #  runner.extend(runner_module)
    #  runner
    #end

    def initialize(options)
      options.each_pair do |k, v|
        self.send("#{k}=", v)
      end
      setup_global_test_vars(options)

      # load and extend with library module if it exists
      if options[:library]
        lib_file = File.join @myRoot, options[:library]
        load lib_file # force a fresh load
        lib_module = module_for lib_file
        self.extend(lib_module)
      end

      # load and extend with script
      script_file = File.join @myRoot, options[:script_file]
      load script_file # force a fresh load
      runner_module = module_for script_file
      self.extend(runner_module)

    end

    def browser_to_use(browser, browser_version = nil)
      platform = ''
      platform = 'Windows' if !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM =~ /mswin|mingw/))
      platform = 'OSX' if RUBY_PLATFORM =~ /darwin/

      browser_abbrev =
          Awetestlib::BROWSER_ALTERNATES[platform][browser] ?
              Awetestlib::BROWSER_ALTERNATES[platform][browser] : browser
      if not browser_version
        case browser_abbrev
          when 'IE'
            browser_version = 8
          when 'FF'
            browser_version = 11
          when 'C', 'GC'
            browser_version = 10
          when 'S'
            browser_version = 10
        end
      end
      return OpenStruct.new(
            :name => (Awetestlib::BROWSER_MAP[browser_abbrev]),
            :abbrev => browser_abbrev,
            :version => browser_version
      )
    end

    def require_gems

      case @targetBrowser.abbrev

        when 'IE'
          if version.to_f >= 9.0
            require 'watir-webdriver'
          else
            require 'watir/ie'
            require 'watir'
            require 'watir/process'
            require 'watirloo'
            require 'patches/watir'
            Watir::IE.visible = true
          end
        when 'FF'
          if @targetBrowser.version.to_f < 4.0
            require 'firewatir'
            require 'patches/firewatir'
          else
            require 'watir-webdriver'
          end

        when 'S'
          require 'safariwatir'

        when 'C', 'GC'
          require 'watir-webdriver'

        # when 'CL'
        #   require 'celerity'
        #   require 'watir-webdriver'

      end

      if USING_WINDOWS
        require 'watir/win32ole'
        @ai = ::WIN32OLE.new('AutoItX3.Control')
        require 'pry'
      else
        # TODO: Need alternative for Mac?
        @ai = ''
      end

    end

    def module_for(script_file)
      File.read(script_file).match(/^module\s+(\w+)/)[1].constantize
    end

    def before_run
      start_run
    end

    def start
      before_run
      run
    rescue Exception => e
      failed_to_log(e.to_s)
    ensure
      after_run
    end

    def after_run
      finish_run
      @myLog.close if @myLog
    end

  end
end
