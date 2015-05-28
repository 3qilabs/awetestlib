module Awetestlib

  require 'date'
  require 'active_support/all'
  require 'html_validation'
  require 'html_validation/page_validations'
  require 'html_validation/html_validation_result'
  require 'w3c_validators'
  require 'roo'
  require 'pry'
  require 'rbconfig'

  def using_windows?
    host_os.include?("mswin") || host_os.include?("mingw")
  end

  def using_osx?
    host_os.include?("darwin")
  end

  def host_os
    RbConfig::CONFIG['host_os']
  end

  def using_jruby?
    defined?(JRUBY_VERSION)
  end

  module Regression
    module Browser

      def test_override_method
        debug_to_log(with_caller('am in awetest_dsl.rb'))
      end

      def verify_browser_options
        browser_name = Awetestlib::BROWSER_MAP[self.browser]
        browser_acro = self.browser
        ok           = true

        if $mobile
          debug_to_log(with_caller(":#{__LINE__}\n#{self.options.to_yaml}"))

          parse_environment_node_for_mobile

          debug_to_log(with_caller(":#{__LINE__}\n#{self.options.to_yaml}"))

          case browser_acro
            when 'FF', 'IE', 'S', 'GC', 'C', 'SP'
              failed_to_log("#{browser_acro} (#{browser_name}) is not a valid mobile browser.")
              ok = false
            when 'IS', 'MS', 'IC', 'MC'
              if self.sdk
                self.device_type           = 'iOS Simulator'
                self.options[:device_type] = 'iOS Simulator'
              elsif self.device_id
                self.device_type           = 'iOS Device'
                self.options[:device_type] = 'iOS Device'
              else
                failed_to_log(with_caller("Must supply either sdk or device id for iOS."))
                ok = false
              end
            when 'AC', 'AB'
              if self.emulator
                self.device_type           = 'Android Emulator'
                self.options[:device_type] = 'Android Emulator'
              elsif self.device_id
                self.device_type           = 'Android Device'
                self.options[:device_type] = 'Android Device'
                if self.sdk
                  self.options[:sdk] = self.sdk
                else
                  failed_to_log(with_caller("Must supply sdk for Android device."))
                  ok = false
                end
              else
                failed_to_log(with_caller("Must supply either emulator or device id for Android."))
                ok = false
              end
            when 'ME', 'MP'
              failed_to_log(with_caller("#{browser_acro} (#{browser_name}) is not yet supported."))
              ok = false
            else
              failed_to_log(with_caller("'#{browser_acro}' is not a valid browser code."))
              ok = false
          end
        else
          ok = true
        end
        debug_to_log(with_caller(":#{__LINE__}\n#{self.options.to_yaml}"))

        ok
      rescue
        failed_to_log(unable_to)
      end

      def parse_environment_node_for_mobile

        if self.environment_nodename =~ /;/
          entries                            = {}
          self.environment['input_nodename'] = self.environment_nodename
          unless self.environment_nodename =~ /^W:/
            self.environment_nodename = "W:#{self.environment_nodename}"
          end
          parms = self.environment_nodename.split(';')
          parms.each do |p|
            key, vlu     = p.split(':')
            entries[key] = vlu
          end

          entries.each do |key, vlu|
            case key
              when 'W'
                self.environment_nodename           = vlu
                self.options[:environment_nodename] = vlu
                self.environment['nodename']        = vlu
              when 'I'
                self.device_id           = vlu
                self.options[:device_id] = vlu
              when 'K'
                self.sdk           = vlu
                self.options[:sdk] = vlu
              when 'T'
                self.device_type           = vlu
                self.options[:device_type] = vlu
              when 'E'
                self.emulator           = vlu
                self.options[:emulator] = vlu
            end
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def bail_out(browser, lnbr = __LINE__, desc = '')
        ts  = Time.new
        msg = "Bailing out at #{ts}. " + desc
        debug_to_log(msg)
        if is_browser?(browser)
          if @browserAbbrev == 'IE'
            hwnd = browser.hwnd
            kill_browser(hwnd, lnbr, browser)
          elsif @browserAbbrev == 'FF'
            debug_to_log("#{browser.inspect}")
            debug_to_log("#{browser.to_s}")
          end
        end
        @status = 'bailout'
        raise(RuntimeError, msg, caller)
      end

      def attach_browser(browser, how, what, desc = '', refs = '')
        debug_to_report("Attaching browser window :#{how}='#{what}' #{desc} #{refs}")
        uri_decoded_pattern = ::URI.encode(what.to_s.gsub('(?-mix:', '').gsub(')', ''))
        debug_to_log(with_caller(uri_decoded_pattern))

        if $watir_script
          tmpbrowser      = Watir::IE.attach(how, what)
          browser.visible = true
          if tmpbrowser
            tmpbrowser.visible = true
            tmpbrowser.speed   = :fast
          else
            raise "Browser window :#{how}='#{what}' has at least one doc not in completed ready state."
          end
        else
          browser.driver.switch_to.window(browser.driver.window_handles[0])
          browser.window(how, /#{uri_decoded_pattern}/).use
          tmpbrowser = browser
        end

        debug_to_log("#{__method__}: tmpbrowser:#{tmpbrowser.inspect}")
        tmpbrowser
      end

      def open_browser(url = nil)
        message_to_report("Opening browser: #{@targetBrowser.abbrev}")

        browser = nil

        if $mobile
          browser = open_mobile_browser
        else
          case @targetBrowser.abbrev
            when 'IE'
              browser = open_ie
              if browser.class.to_s == "Watir::IE"
                @myHwnd = browser.hwnd
              end
            when 'FF'
              browser = open_ff
            when 'S'
              if USING_OSX
                browser = open_safari
              else
                fail "Safari is not supported under this operating system #{RUBY_PLATFORM}"
              end
            when 'C', 'GC'
              browser = open_chrome
            else
              fail "Unsupported browser: #{@targetBrowser.name} (#{@targetBrowser.abbrev})"
          end
        end

        if browser and url
          go_to_url(browser, url)
        end

        get_browser_version(browser)
        message_to_report("Opened browser: #{@browserName} #{@browserVersion}")
        #message_to_log(@browserName)
        #message_to_log(@browserVersion)

        @myBrowser = browser

      rescue
        failed_to_log(unable_to)
      end

      def start_appium

        debug_to_log("#{Dir.pwd.chomp}")
        log_file = File.join(Dir.pwd.chomp, 'log', "#{@myName}_appium_#{@start_timestamp.strftime("%Y%m%d%H%M%S")}.log")
        command  = "appium --log #{log_file} "
        # command = "appium --log-no-colors --log-timestamp --local-timezone --log #{log_file}"
        # command = "appium --log-no-colors --log-timestamp --local-timezone --log #{log_file}"
        # command = "appium --log-no-colors --log-timestamp --local-timezone --log #{log_file}"
        debug_to_log(command)
        appium = IO.popen(command)
        debug_to_log("Appium PID: #{appium.pid}")
        3.times { debug_to_log(appium.readline.chomp) }
        appium

      rescue => e
        fatal_to_log(unable_to)
        raise(e)
      end

      # def stop_appium
      #   if USING_OSX
      #     system("ps aux | grep appium | grep 'device-name #{self.device_id}' | awk '{print $2}' | xargs kill -9")
      #     # system("kill -9 #{webkit_proxy_id}") if webkit_proxy_id
      #   else
      #     system("taskkill /F /t /pid #{@appium_pid}")
      #     # system("taskkill /F /t /pid #{webkit_proxy_id}") if webkit_proxy_id
      #   end
      # end

      # def stop_adb
      #   if USING_OSX
      #     system("ps aux | grep adb | awk '{print $2}' | xargs kill -9")
      #   else
      #     system("taskkill /IM adb.exe")
      #   end
      # end

      # def stop_android_emulator
      #   system("adb -s emulator-5554 emu help")
      #   #  system("adb -s emulator-5554 emu kill")
      #   begin
      #     telnet = Net::Telnet.new("Host" => "127.0.0.1", "Port" => 5554)
      #     telnet.cmd("kill")
      #   rescue
      #   end
      #
      # end

      def set_mobile_capabilities
        device_type = self.device_type
        device_id   = self.device_id
        ios_version = self.sdk ? self.sdk : '8.1'
        mark_test_level(": #{device_type.titleize}")

        case self.device_type

          when /android device/i
            desired_caps = {
                'deviceName'   => "My_device",
                'platformName' => "Android",
                'app'          => "Chrome",
                'appPackage'   => "com.android.chrome",
                'udid'         => device_id }

          when /android emulator/i

            # NOTE: appium cannot start avd from snapshot.

            desired_caps = {
                'newCommandTimeout'         => 600,
                'androidDeviceReadyTimeout' => 420,
                'avdLaunchTimeout'          => 240000,
                'avdReadyTimeout'           => 240000,
                'deviceName'                => "My_device",
                'platformName'              => "Android",
                'avd'                       => "poc-x86",
                'browserName'               => "Browser",
                'avdArgs'                   => '-no-audio -http-proxy 151.151.15.250:8080 -dns-server 10.27.206.11:55,10.27.206.101:55,10.91.218.197:55',
                # TODO: these lines trigger EPIPE write error because a pipe involving stdout is closed before the write completes
                # TODO: Need to check if epipebomb is included in most recent node release
                'chromeOptions'             => { 'args' => ['ignore-certificate-errors=true', 'homepage=about:blank', 'test_type=true'] }
            }

          when /ios device/i
            desired_caps = {
                'platformVersion' => ios_version,
                'deviceName'      => "My_device",
                'platformName'    => "iOS",
                'browserName'     => 'Safari',
                'udid'            => device_id }

          else #iOS simulator
            desired_caps = {
                'deviceName'      => device_type,
                'platformVersion' => ios_version,
                'browserName'     => 'Safari',
                'platformName'    => "iOS" }
        end

        debug_to_log(with_caller("\n#{desired_caps.to_yaml}"))

        desired_caps
      rescue
        failed_to_log(unable_to)
      end

      def open_mobile_browser

        mark_test_level(": #{self.device_type.titleize}")

        if self.device_type =~ /android emulator/i
          end_processes('adb.exe', 'node.exe', 'emulator-arm.exe', 'emulator-x86.exe', 'chromedriver.exe')

          # debug_to_log("Regular Boot sequence for Android Emulator")
          # emulator_command = 'emulator -avd poc -no-audio -http-proxy 151.151.15.250:8080 -dns-server 10.27.206.11,10.27.206.101,10.91.218.197 -no-boot-anim'
          # debug_to_log("[#{emulator_command}]")
          # system("#{emulator_command} &")
          # system("adb wait-for-device")
          # sleep 40
          # unlock_emulator

        end

        debug_to_log("#{Dir.pwd.chomp}")
        log_file = File.join(Dir.pwd.chomp, 'log', "#{@myName}_appium_#{@start_timestamp.strftime("%Y%m%d%H%M%S")}.log")
        command  = "appium --log-timestamp --local-timezone --log #{log_file} &"
        debug_to_log(command)
        appium   = IO.popen(command)
        debug_to_log("Appium PID: #{appium.pid}")
        5.times { debug_to_log(appium.readline.chomp) }

        capabilities = set_mobile_capabilities

        server_url     = "http://127.0.0.1:4723/wd/hub"
        client         = Selenium::WebDriver::Remote::Http::Default.new
        client.timeout = 360

        debug_to_log(with_caller("Calling Watir::Browser.new (through Appium)"))

        begin
          browser = Watir::Browser.new(:chrome, #:android, #:remote, #:chrome,    #:remote,
                                       :url                  => server_url,
                                       :desired_capabilities => capabilities,
                                       :http_client          => client)
          browser.goto('wf.com')
          sleep_for(5)
        rescue => e
          failed_to_log(with_caller(e))
        end

        begin
          debug_to_log(with_caller(browser.driver.capabilities.to_yaml))
        rescue
          puts 'oops browser.driver.capabilities.to_yaml'
        end

        browser
      rescue
        failed_to_log(unable_to)
      end

      def is_browser?(browser)
        my_class = browser.class.to_s
        case @targetBrowser.abbrev
          when 'IE'
            my_class =~ /Watir::IE|Watir::Browser/i
          # when 'FF'
          #   my_class =~ /Watir::Browser/i
          # when 'S'
          #   my_class =~ /Watir::Browser/i
          # when 'C', 'GC'
          else
            my_class =~ /Watir::Browser/i
        end
      end

      def open_ie
        if $watir_script
          browser = Watir::IE.new
        else
          #browser = Watir::Browser.new :ie
          caps    = Selenium::WebDriver::Remote::Capabilities.internet_explorer(
              #:nativeEvents => false,
              #'nativeEvents' => false,
              :enablePersistentHover                               => false,
              :ignoreProtectedModeSettings                         => true,
              :introduceInstabilityByIgnoringProtectedModeSettings => true,
              :unexpectedAlertBehaviour                            => 'ignore'
          )
          browser = Watir::Browser.new(:ie, :desired_capabilities => caps)
        end
        browser
      rescue
        failed_to_log(unable_to)
      end

      def open_chrome
        client         = Selenium::WebDriver::Remote::Http::Default.new
        client.timeout = 180 # seconds – default is 60

        browser = Watir::Browser.new(:chrome, :http_client => client)
      end

      def basic_auth(browser, user, password, url, bypass_validate = false)
        mark_test_level("Login")

        get_browser_version(browser)
        message_to_log(@browserName)
        message_to_log(@browserVersion)
        message_to_log("Login:    #{user}")
        message_to_log("URL:      #{url}")
        message_to_log("Password: #{password}")
        debug_to_report("@user: #{user}, @pass: #{password} (#{__LINE__})")

        case @browserAbbrev
          when 'IE', 'FF'

            user_name, pass_word, login_button, login_title = get_basic_auth_control_indexes

            a = Thread.new {
              begin
                #go_to_wd_url(browser, url)
                browser.goto(url)
                Watir::Wait.until(5) { browser.alert.exists? }
              rescue => e
                debug_to_log("#{__LINE__}: #{e.inspect}")
              rescue => e
                debug_to_log("#{__LINE__}: #{e.inspect}")
              end
            }

            sleep(1)
            message_to_log("#{login_title}...")
            if @ai.WinWait(login_title, "", 90) > 0
              win_title = @ai.WinGetTitle(login_title)
              debug_to_log("Basic Auth Login window appeared: '#{win_title}'")
              @ai.WinActivate(login_title)

              case @browserAbbrev
                when 'FF'
                  @ai.Send(user)
                  @ai.Send('{TAB}')
                  @ai.Send(password)
                  sleep(1)
                  @ai.Send('{ENTER}')
                when 'IE'
                  begin
                    @ai.ControlSend(login_title, '', "[CLASS:Edit; INSTANCE:#{user_name}]", '!u')
                    @ai.ControlSetText(login_title, '', "[CLASS:Edit; INSTANCE:#{user_name}]", user)
                    @ai.ControlSetText(login_title, '', "[CLASS:Edit; INSTANCE:#{pass_word}]", password.gsub(/!/, '{!}'))
                    sleep(1)
                    @ai.ControlClick(login_title, "", "[CLASS:Button; INSTANCE:#{login_button}]")
                  rescue => e
                    debug_to_log("#{__LINE__}: #{e.inspect}")
                  rescue => e
                    debug_to_log("#{__LINE__}: #{e.inspect}")
                  end
              end
            else
              debug_to_log("Basic Auth Login window '#{login_title}' did not appear.")
            end
            begin
              a.join
            rescue => e
              debug_to_log("#{__LINE__}: #{e.inspect}")
            rescue => e
              debug_to_log("#{__LINE__}: #{e.inspect}")
            end
            begin
              validate(browser, @myName) unless bypass_validate
            rescue => e
              debug_to_log("#{__LINE__}: #{e.inspect}")
            rescue => e
              debug_to_log("#{__LINE__}: #{e.inspect}")
            end

          when 'GC', 'C'
            browser.goto(url)
            sleep(2)
            browser.alert.use do
              browser.send_keys(user)
              browser.send_keys("{TAB}")
              browser.send_keys(password)
              browser.send_keys("~") # Enter
            end
            browser.windows[0].use
          #when 'FF'
          #  aug_url = insert_id_pswd_in_url(user, password, url)
          #  debug_to_log("urL: #{url}\naug: #{aug_url}")
          #  go_to_wd_url(browser, aug_url)
        end

        message_to_log("URL: [#{browser.url}]")

      rescue => e
        debug_to_log("#{__LINE__}: #{e.inspect}")
      rescue => e
        debug_to_log("#{__LINE__}: #{e.inspect}")
      end

      def go_to_url(browser, url = nil)
        if url
          @myURL = url
        end
        message_to_report(with_caller("URL: #{@myURL}"))
        browser.goto(@myURL)
        true
      rescue
        fatal_to_log("Unable to navigate to '#{@myURL}': '#{$!}'")
      end

      def go_to_wd_url(browser, url)

        Watir::Browser.class_eval do
          def goto(uri)
            uri = "http://#{uri}" unless uri =~ URI.regexp
            begin
              @driver.navigate.to uri
            rescue => e
              debug_to_log("#{e.inspect} '#{$!}'")
            end
            run_checkers
          end
        end
        browser.goto(url)
      rescue
        failed_to_log(unable_to)
      end

      def browser_version(browser)
        case @targetBrowser.abbrev
          when 'IE'
            @browserAbbrev = 'IE'
            @browserName   = 'Internet Explorer'
            if $watir_script
              @browserAppInfo = browser.document.invoke('parentWindow').navigator.appVersion
            else
              @browserAppInfo = browser.execute_script("return navigator.userAgent;")
            end
            @browserAppInfo =~ /MSIE\s(.*?);/
            @browserVersion = $1
          when 'FF'
            @browserAbbrev  = 'FF'
            @browserName    = 'Firefox'
            @browserAppInfo = browser.execute_script("return navigator.userAgent;")
            @browserAppInfo =~ /Firefox\/([\d\.]+)/
            @browserVersion = $1
          when 'S'
            @browserAbbrev  = 'S'
            @browserName    = 'Safari'
            @browserAppInfo = browser.execute_script("return navigator.userAgent;")
            @browserVersion = '6.0' #TODO: get actual version from browser itself
          when 'C', 'GC'
            @browserAbbrev  = 'GC'
            @browserName    = 'Chrome'
            @browserAppInfo = browser.execute_script("return navigator.userAgent;")
            @browserAppInfo =~ /Chrome\/([\d\.]+)/
            @browserVersion = $1
          else
            @browserAbbrev  = @targetBrowser.abbrev
            @browserAppInfo = browser.execute_script("return navigator.userAgent;")

        end
        debug_to_report("#{@browserName}, @browserAppInfo: (#{@browserAppInfo})")
        debug_to_log("#{browser.driver.capabilities.to_yaml}")

        @browserVersion # = browser.driver.capabilities.version
      rescue
        failed_to_log(unable_to)
      ensure
        message_to_report("Browser: [#{@browserName} (#{@browserAbbrev}) #{@browserVersion}]")
      end

      alias get_browser_version browser_version

      def close_browser(browser, where = @myName, lnbr = __LINE__)
        debug_to_log("Closing browser in #{where} at line #{lnbr}.")
        debug_to_log("#{__method__}: browser: #{browser.inspect} (#{__LINE__})")

        url   = browser.url
        title = browser.title

        report_browser_message(browser)

        if $mobile
          browser.close
          sleep(1)
          end_processes('adb.exe', 'node.exe', 'emulator-arm.exe')

        elsif ['FF', 'S'].include?(@browserAbbrev) || browser.exists?
          case @browserAbbrev
            when 'FF'
              if is_browser?(browser)
                debug_to_log("#{__method__}: Firefox browser url: [#{url}]")
                debug_to_log("#{__method__}: Firefox browser title: [#{title}]")
                debug_to_log("#{__method__}: Closing browser: #{where} (#{lnbr})")
                if url and url.length > 1
                  browser.close
                else
                  browser = FireWatir::Firefox.attach(:title, title)
                  browser.close
                end

              end
            when 'IE'
              debug_to_log("#{__method__}: Internet Explorer browser url: [#{url}]")
              debug_to_log("#{__method__}: Internet Explorer browser title: [#{title}]")
              debug_to_log("#{__method__}: Closing browser: #{where} (#{lnbr})")
              if $watir_script
                hwnd = browser.hwnd
                pid  = Watir::IE::Process.process_id_from_hwnd(hwnd)
                debug_to_log("#{__method__}: Closing browser: hwnd #{hwnd} pid #{pid} #{where} (#{lnbr}) (#{__LINE__})")
                browser.close
                if browser.exists? and pid > 0 and pid < 538976288 # value of uninitialized memory location
                  debug_to_log("Retry close browser: hwnd #{hwnd} pid #{pid} #{where} #{lnbr} (#{__LINE__})")
                  browser.close
                end
                if browser.exists? and pid > 0 and pid < 538976288 # value of uninitialized memory location
                  kill_browser(browser.hwnd, __LINE__, browser)
                end
              else
                browser.close
              end
            when 'S'
              if is_browser?(browser)
                url   = browser.url
                title = browser.title
                debug_to_log("Safari browser url: [#{url}]")
                debug_to_log("Safari browser title: [#{title}]")
                debug_to_log("Closing browser: #{where} (#{lnbr})")
                # close_modal_s # to close any leftover modal dialogs
                browser.close
              end
            when 'C', 'GC'
              if is_browser?(browser)
                url   = browser.url
                title = browser.title
                debug_to_log("Chrome browser url: [#{url}]")
                debug_to_log("Chrome browser title: [#{title}]")
                debug_to_log("Closing browser: #{where} (#{lnbr})")
                if url and url.length > 1
                  browser.close
                end

              end
            else
              raise "Unsupported browser: '#{@browserAbbrev}'"
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def report_browser_message(browser)
        if browser.title =~ /^\d+\s/
          failed_to_log(browser.title)
          message_to_report(browser.text)
        end
      end

      def validate(browser, file_name = @myName, lnbr = '', dbg = false)
        debug_to_log("#{__method__} begin") if dbg
        msg = ''
        ok  = true
        if not browser
          msg = "browser is nil object."
          ok  = false

        elsif not browser.class.to_s =~ /Watir/
          msg = "not a Watir object."
          debug_to_log(browser.inspect)
          ok = false

        else
          if browser.respond_to?(:url)
            if not browser.url == @currentURL
              @currentURL = browser.url
              debug_to_log(with_caller("Current URL: [#{@currentURL}]"))
            end
          end

          if @capture_js_errors
            if browser.respond_to?(:status)
              if browser.status.downcase =~ /errors? on page/ and
                  not browser.status.downcase.include?('Waiting for')
                capture_js_error(browser)
              end
            end
          end

          begin
            browser_text  = browser.text.downcase
            browser_title = browser.title
          rescue => e
            unless rescue_me(e, __method__, "browser.text.downcase", "#{browser.class}", browser)
              debug_to_log("browser.text.downcase in #{__method__} #{browser.class}")
              debug_to_log("#{get_callers}")
              raise e
            else
              return true
            end
          end

          if browser_text
            if browser_text.match(/unrecognized error condition has occurred/i)
              error = "Unrecognized Exception occurred."
              ok    = false

            elsif browser_text.match(/cannot find server or dns error/i)
              error = "Cannot find server error or DNS error."
              ok    = false

            elsif browser_text.match(/the rpc server is unavailable/i)
              error = "RPC server unavailable."
              ok    = false

            elsif browser_text.match(/404 not found/i) or
                browser_text.match(/the page you were looking for does\s*n[o']t exist/i)
              error = "RFC 2068 HTTP/1.1: 404 URI Not Found."
              ok    = false

            elsif browser_text.match(/we're sorry, but something went wrong/i) or
                browser_text.match(/http status 500/i)
              error = "RFC 2068 HTTP/1.1: 500 Internal Server Error."
              ok    = false

            elsif browser_text.match(/internet explorer cannot display the webpage/i)
              error = "Probably RFC 2068 HTTP/1.1: 500 Internal Server Error."
              ok    = false

            elsif browser_text.match(/503.*service unavailable/i)
              error = "RFC 2068 HTTP/1.1: 503 Service Unavailable."
              ok    = false

            elsif browser_text.match(/java.lang.NullPointerException/i)
              error = "java.lang.NullPointerException."
              ok    = false

            elsif browser_text.match(/due to unscheduled maintenance/i)
              error = "Due to unscheduled maintenance."
              ok    = false

            elsif browser_text.match(/network\s+error\s*(.+)$/i)
              $1.chomp!
              error = "Network Error #{$1}."
              ok    = false

            elsif browser_text.match(/warning: page has expired/i)
              error = "Page using information from form has expired. Not automatically resubmitted."
              ok    = false

            elsif browser_text.match(/no backend server available/i)
              error = "Cannot Reach Server"
              ok    = false

            elsif browser_text.match(/sign on\s+.+\s+unsuccessful/i)
              error = "Invalid Id or Password"
              ok    = false

            elsif browser_text.match(/you are not authorized/i)
              error = "Not authorized to view this page."
              ok    = false

            elsif browser_text.match(/too many incorrect login attempts have been made/i)
              error = "Invalid Id or Password. Too many tries."
              ok    = false

            elsif browser_text.match(/system error\.\s+an error has occurred/i)
              error = "System Error. An error has occurred. Please try again or call the Help Line for assistance."
              ok    = false

            elsif browser_text.match(/Internal Server failure,\s+NSAPI plugin/i)
              error = "Internal Server failure, NSAPI plugin."
              ok    = false

            elsif browser_text.match(/Error Page/i)
              error = "Error Page."
              ok    = false

            elsif browser_text.match(/The website cannot display the page/i)
              error = "HTTP 500."
              ok    = false

              #        elsif browser_text.match(/Insufficient Data/i)
              #           error = "Insufficient Data."
              #          ok = false

            elsif browser_text.match(/The timeout period elapsed/i)
              error = "Time out period elapsed or server not responding."
              ok    = false

            elsif browser_text.match(/Unexpected\s+errors*\s+occur+ed\.\s+(?:-+)\s+(.+)/i)
              error = "Unexpected errors occurred. #{$2.slice(0, 120)}"
              if not browser_text.match(/close the window and try again/i)
                ok = false
              else
                debug_to_log(with_caller(filename, '----', error, "(#{browser.url})"))
              end

            elsif browser_text.match(/Server Error in (.+) Application\.\s+(?:-+)\s+(.+)/i)
              error = "Server Error in #{1} Application. #{$2.slice(0, 100)}"
              ok    = false

            elsif browser_text.match(/Server Error in (.+) Application\./i)
              error = "Server Error in #{1} Application. '#{browser_text.slice(0, 250)}...'"
              ok    = false

            elsif browser_text.match(/An error has occur+ed\. Please contact support/i)
              error = "An error has occurred. Please contact support."
              ok    = false

            end
          else
            debug_to_log("browser.text returned nil")
          end
        end

        if browser_title
          if browser_title.match(/page not found/i)
            error = "#{browser_title} RFC 2068 HTTP/1.1: 404 URI Not Found."
            ok    = false
          end
        end

        if not ok
          msg = with_caller(file_name, '----', error, "(#{browser.url})")
          puts msg
          debug_to_log(browser.inspect)
          debug_to_log(browser.text)
          # fatal_to_log(msg)
          raise(RuntimeError, msg, caller)
        else
          debug_to_log("#{__method__} returning OK") if dbg
          return ok
        end

      rescue
        errmsg = $!
        if errmsg and errmsg.message.match(msg)
          errmsg = ''
        end
        bail_out(browser, __LINE__, build_message(msg, errmsg))
      end

      alias validate_browser validate

    end

    module Tables

      def get_table_headers(table, header_index = 0)
        headers          = Hash.new
        headers['index'] = Hash.new
        headers['name']  = Hash.new
        count            = 0
        table[header_index].cells.each do |cell|
          if cell.text.length > 0
            name                    = cell.text.strip.gsub(/\s+/, ' ')
            headers['index'][count] = name
            headers['name'][name]   = count
          end
          count += 1
        end
        #debug_to_log("#{__method__}: headers:\n#{headers.to_yaml}")
        headers
      rescue
        failed_to_log(unable_to)
      end

      def get_parent_row(container, element, how, what, limit = 5)
        msg    = "#{__method__}: #{element.to_s.upcase} :#{how}='#{what}'"
        target = nil
        parent = nil
        case element
          when :link
            target = container.link(how, what)
          when :select_list
            target = container.select_list(how, what)
          when :text_field
            target = container.text_field(how, what)
          when :checkbox
            target = container.checkbox(how, what)
          when :radio
            target = container.radio(how, what)
          else
            fail "#{element.to_s.upcase} not supported."
        end
        if target
          count  = 0
          parent = target.parent
          until parent.is_a?(Watir::TableRow) do
            parent = parent.parent
            count  += 1
            if count > limit
              failed_to_log("Parent row not within #{limit} ancestors.")
            end
          end
        else
          failed_to_log(msg)
        end
        if parent.is_a?(Watir::TableRow)
          passed_to_log(msg)
          parent
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to)
      end

    end

    module Utilities

      #def walk_tree(tree, depth = 0, &blk)
      #  # This allows the method to be used as an enumerable if it is used without a block
      #  # It is idiomatic in Ruby for all iterator methods to behave like this (since Ruby 1.8.7 anyway)
      #  return enum_for(:walk_tree, depth) unless blk
      #  yield tree, depth
      #  tree[:nodes].each do |node|
      #    walk_tree(node, depth + 1, &blk)
      #  end
      #end
      #
      #def iterate(h)
      #  h.each do |k,v|
      #    value = v || k
      #
      #    if value.is_a?(Hash) || value.is_a?(Array)
      #      puts "evaluating: #{value} recursively..."
      #      iterate(value)
      #    else
      #      puts v ? "key: #{k} value: #{v}" : "array value #{k}"
      #    end
      #  end
      #end
      #

      def dump_option_array(options, desc = '', to_report = false)
        msg = with_caller(desc, "\n")
        options.each do |option|
          msg << "text: '#{option.text}' value: '#{option.value}' selected: #{option.selected?}\n"
        end
        if to_report
          debug_to_report(msg)
        else
          debug_to_log(msg)
        end
      end

      def running_thread_count
        running = Thread.list.select { |thread| thread.status == "run" }.count
        asleep  = Thread.list.select { |thread| thread.status == "sleep" }.count
        [running, asleep]
      end

      def awetestlib?
        defined? Awetestlib::Runner
      end

      def html_to_log(element)
        debug_to_log("#{element}\n #{element.html}")
      end

      def git_sha1(file)
        if File.exists?(file)
          size, sha1 = `ruby git_sha1.rb #{file}`.chomp.split(/\n/)
          debug_to_log("#{file} #{size} sha1 is #{sha1}")
        end
      end

      def find_sheet_with_name(workbook, sheet_name)
        sheets = workbook.sheets
        idx    = 0
        found  = false
        sheets.each do |s|
          if s == sheet_name
            found = true
            break
          end
          idx += 1
        end
        if found
          idx
        else
          -1
        end
      end

      def translate_tag_name(element)
        rtrn = ''
        if element.respond_to?(:tag_name)
          tag  = element.tag_name
          typ  = element.type if element.respond_to?(:type)
          rtrn = tag
          case tag
            when 'a'
              rtrn = 'link'
            when 'input'
              case typ
                when 'text'
                  rtrn = 'textfield'
                when 'textarea'
                  rtrn = 'textarea'
                when 'submit', 'button'
                  rtrn = 'button'
                else
                  rtrn = tag
              end
            else
              rtrn = tag
          end
        end
        rtrn
      rescue
        failed_to_log(unable_to(tag, typ))
      end

      def flash_element(element, desc = '', refs = '')
        if @flash
          if element
            element.wd.location_once_scrolled_into_view
            # scroll_to(element.browser, element, desc, refs)
            if element.respond_to?(:flash)
              # sleep(0.1)
              element.flash
            end
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def flash(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        if @flash
          value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
          code                       = build_webdriver_fetch(element, how, what, options)
          target                     = eval(code)
          flash_element(target, desc, refs)
        end
      rescue
        failed_to_log(unable_to)
      end

      def strg_arr_numeric_sort(arr)
        #TODO: almost certainly a more 'rubyish' and less clunky way to do this
        trgt = arr.dup
        narr = []
        trgt.each do |n|
          narr << n.to_i
        end
        narr.sort!
        sarr = []
        narr.each do |n|
          sarr << n.to_s
        end
        sarr
      end

      def string_to_hex(strg, format = 'U')
        strg.unpack(format*strg.length)
        # strg.split(//).collect do |x|
        #   x.match(/\d/) ? x : x.unpack('U')[0].to_s(16)
        # end
      end

      def time_it(container, desc, timeout = 3, &block)
        start = Time.now.to_f
        begin
          Watir::Wait.until(timeout) { block.call(nil) }
        rescue => e
          if e.class.to_s =~ /TimeOutException/ or e.message =~ /timed out/
            debug_to_log("#{desc} '#{$!}'")
            return Time.now.to_f - start
          elsif not rescue_me(e, __method__, "#{block.to_s}", "#{container.class}")
            raise e
          end
        end
        duration = Time.now.to_f - start
        debug_to_report(with_caller(desc, duration.to_s))
        duration
      rescue
        failed_to_log(unable_to(desc))
      end

      def nbr2wd(nbr)
        map = { 1  => 'one', 2 => 'two', 3 => 'three', 4 => 'four', 5 => 'five',
                6  => 'six', 7 => 'seven', 8 => 'eight', 9 => 'nine', 10 => 'ten',
                11 => 'eleven', 12 => 'twelve', 13 => 'thirteen', 14 => 'fourteen', 15 => 'fifteen',
                16 => 'sixteen', 17 => 'seventeen', 18 => 'eighteen', 19 => 'nineteen', 20 => 'twenty'
        }
        if nbr > 20
          'more than twenty'
        else
          map[nbr]
        end
      end

      def array_neighbors(arr, target)
        less_than    = []
        greater_than = []
        arr.each do |elmt|
          if elmt < target
            less_than << elmt
          elsif elmt > target
            greater_than << elmt
          end
        end
        [less_than.max, greater_than.min]
      end

      def rotate_array(arr, stop = 0, index = 0, target = '')
        rotated = arr.dup
        length  = rotated.size
        (1..length).each do |itr|
          rotated.push(rotated.shift)
          if stop > 0
            break if itr == stop
          else
            break if rotated[index] == target
          end
        end
        rotated
      rescue
        failed_to_log(unable_to)
      end

      def strip_regex_mix(strg)
        rslt = strg.dup
        mtch = rslt.match(/(\(\?-mix:(.+)\))/)
        rslt.sub!(mtch[1], "/#{mtch[2]}/")
        rslt
      end

      def element_id(element)
        element.attribute_value('id')
      end

      def element_query_message(element, query, how = nil, what = nil, value = nil, desc = '', refs = '')
        if element.exists?
          name = element.respond_to?(:tag_name) ? element.tag_name.upcase : element.to_s
        else
          name = '(unknown)'
        end
        build_message(desc, "#{name}",
                      (what ? "with #{how}=>' #{what}'" : nil),
                      (value ? "and value=>'#{value}'" : nil),
                      query, refs)
      rescue
        failed_to_log(unable_to)
      end

      def extract_locator(element, how = nil)
        # html_to_log(element)
        if element.respond_to?(:tag_name)
          tag = element.tag_name.to_sym
        else
          element = element.body.elements[0]
          tag     = element.tag_name.to_sym
        end
        what = nil
        case how
          when nil
            [:id, :name, :title, :class, :value].each do |attr|
              what = element.attribute_value(attr.to_s)
              if what and what.length > 0
                how = attr
                break
              end
            end
          else
            what = element.attribute_value(how.to_s)
        end
        # debug_to_log(with_caller("#{tag}:#{how}:#{what}"))
        [tag, how, what]
      rescue
        failed_to_log(unable_to(build_message(":#{tag}, :#{how}='#{what}'")))
      end

      def element_action_message(element, action, how = nil, what = nil, value = nil, desc = '', refs = '')
        name      = element.respond_to?(:tag_name) ? element.tag_name.upcase : element.to_s
        how, what = extract_locator(element, how)[1, 2] unless how and what
        build_message(desc, action, "#{name}",
                      (what ? "with #{how}=>'#{what}'" : nil),
                      (value ? "and value=>'#{value}'" : nil), refs)
      end

      def normalize_color_value(value, rgba = true)
        case value
          when /^#/
            html_to_rgb(value, rgba)
          when /^rgba/i
            value
          when /^rgb()/i
            rgb_to_rgba(value)
          when /^transparent/i, /^0$/i
            'rgba(0, 0, 0, 0)'
          when /white/
            'rgba(255, 255, 255, 1)'
          else
            html_to_rgb(translate_color_name(value), rgba)
        end
      end

      def translate_color_name(color)
        if color and color.length > 0
          HTML_COLORS[color.camelize.downcase].downcase
        else
          color
        end
      end

      def convert_y_m_d_to_ymd(yrs, mos, dys, fmt_out = '%Y-%m-%d', alt_fmt = '%Y-%m')
        dys = [dys] unless dys.is_a?(Array)
        mos = [mos] unless mos.is_a?(Array)
        yrs = [yrs] unless yrs.is_a?(Array)
        arr = []
        if dys.size > 0
          dys.each do |dy|
            mo = mos[dys.index(dy)] ? mos[dys.index(dy)] : mos[0]
            yr = yrs[dys.index(dy)] ? yrs[dys.index(dy)] : yrs[0]
            arr << DateTime::parse("#{dy}/#{mo}/#{yr}").strftime(fmt_out).sub(/^0/, '')
          end
        else
          mos.each do |mo|
            yr = yrs[mos.index(mo)] ? yrs[mos.index(mo)] : yrs[0]
            arr << DateTime::parse("1/#{mo}/#{yr}").strftime(alt_fmt).sub(/^0/, '')
          end
        end
        arr
      rescue
        failed_to_log(unable_to("y:#{yrs}, m:#{mos}, d:#{dys}"))
      end

      def get_month_names(date = Date.today)
        this_month = date.month
        if this_month == 12
          next_month = 1
        else
          next_month = this_month + 1
        end
        if this_month == 1
          prev_month = 12
        else
          prev_month = this_month - 1
        end

        month_arr = Date::MONTHNAMES

        this_month_name = month_arr[this_month]
        next_month_name = month_arr[next_month]
        prev_month_name = month_arr[prev_month]

        arr = [date.year, date.day, this_month_name, next_month_name, prev_month_name]
        debug_to_log("#{__method__} #{nice_array(arr)}")
        arr

      end

      def convert_color_value(value, rgba = false)
        if value =~ /^#/
          html_to_rgb(value, rgba)
        else
          rgb_to_html(value)
        end
      end

      def rgb_to_html(rgb)
        rgb =~ /rgba?\((.+)\)/
        if $1
          r, g, b, a = $1.split(/,\s*/)
          "#%02x%02x%02x" % [r, g, b]
        else
          rgb
        end
      end

      def rgb_to_rgba(rgb)
        if rgb =~ /^rgb\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\)/i
          r    = $1
          g    = $2
          b    = $3
          op   = rgb =~ /[1-9]/ ? '1' : '0'
          rtrn = "rgba(#{r}, #{g}, #{b}, #{op})" #waft-1148
        else
          rtrn = rgb
        end
        rtrn
      end

      def html_to_rgb(html, a = true)
        if html and html.length > 0
          html = html.gsub(%r{[#;]}, '')
          case html.size
            when 3
              colors = html.scan(%r{[0-9A-Fa-f]}).map { |el| (el * 2).to_i(16) }
            when 6
              colors = html.scan(%r<[0-9A-Fa-f]{2}>).map { |el| el.to_i(16) }
          end
          rgb = 'rgb'
          rgb << 'a' if a
          rgb << '('
          colors.each do |c|
            rgb << "#{c}, "
          end
          if a
            rgb << '1)'
          else
            rgb.strip!.chop!
            rgb << ')'
          end
          rgb
        else
          html
        end
      end

      def method_to_title(method, no_sub = false, subs = { /And/ => '&', /^Ac / => 'AC ' })
        title = method.to_s.titleize
        unless no_sub
          subs.each do |ptrn, rplc|
            title.gsub!(ptrn, rplc)
          end
        end
        title
      rescue
        debug_to_log(unable_to(": #{method}"))
      end

      def report_results(errors, msg)
        call_script, call_line, call_meth = parse_caller(get_call_array[1])
        msg                               = ">> SUMMARY: #{build_msg("#{call_meth.titleize}:", msg)}"
        if errors > 0
          mark_test_level("#{msg}  ::FAIL::")
        else
          mark_test_level("#{msg}  ::Pass::")
          true
        end
      rescue
        failed_to_log(unable_to)
      end

      def rescue_msg_for_validation(desc, refs = nil)
        failed_to_log(unable_to(build_message(desc, refs), NO_DOLLAR_BANG, VERIFY_MSG, 2), 5)
      end

      def module_for(script_file)
        File.read(script_file).match(/^module\s+(\w+)/)[1].constantize
      end

      def get_debug_list(dbg = false, no_trace = false, last_only = false)
        debug_to_log(with_caller("awetest_dsl override")) if $debug
        calls = get_call_array(10)
        debug_to_log(with_caller("*** #{__LINE__}\n#{calls.to_yaml}\n***")) if dbg
        arr = []
        calls.each_index do |ix|
          if ix > 1 # skip this method and the logging method
            if filter_call(calls[ix])
              arr << calls[ix]
            end
          end
        end
        debug_to_log(with_caller("*** #{__LINE__}\n#{arr.to_yaml}\n***")) if dbg
        if arr.length > 0
          list = ''
          arr.reverse.each do |l|
            if last_only
              list = l
              break
            else
              list << "=>#{l}"
            end
          end
          if no_trace
            "#{list}"
          else
            " [TRACE:#{list}]"
          end
        else
          ''
        end
      rescue
        failed_to_log(unable_to)
      end

      def get_call_list(depth = 9, dbg = false)
        debug_to_log(with_caller("awetest_dsl override")) if $debug
        my_list   = []
        call_list = Kernel.caller
        debug_to_log(with_caller(call_list)) if dbg
        call_list.each_index do |x|
          my_caller = call_list[x].to_s
          my_caller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          my_list << "[#{$1.gsub(/eval/, @myName)}] "
          break if x > depth or my_caller =~ /:in .run.$/
        end
        my_list
      rescue
        failed_to_log(unable_to)
      end

      def get_call_array(depth = 9)
        debug_to_log(with_caller("awetest_dsl override")) if $debug
        arr       = []
        call_list = Kernel.caller
        call_list.each_index do |x|
          my_caller = call_list[x].to_s
          my_caller =~ /([\(\)\w_\_\-\.]+\:\d+\:.*?)$/
          # myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          arr << $1.gsub(/eval/, @myName)
          break if x > depth or my_caller =~ /:in .run.*$/
        end
        arr
      rescue
        failed_to_log(unable_to)
      end

      def tic(new = false)
        now = Time.now.utc
        if new
          @tic_tic = now
        else
          debug_to_log(with_caller("#{now.to_f - @tic_tic.to_f}", "#{get_call_array(2)[1]}"))
          @tic_tic = now
        end
      end

      def tic_m(msg = '')
        now = Time.now.utc
        debug_to_log(with_caller("#{now.to_f - @tic_tic.to_f}", "#{get_call_array(2)[1]}", msg))
        @tic_tic = now
      end

      def filter_call(call)
        modl = call.match(/^(browser|logging|find|runner|tables|user_input|utilities|validations|waits|page_data|legacy|drag_and_drop|awetest)/) || ''
        meth = call.match(/in .(run|each)/) || ''
        true unless "#{modl}#{meth}".length > 0
      end

      def arr2list(arr, delim = ',')
        list = ''
        arr.each do |entry|
          if entry =~ /#{delim}/
            list << "\"#{entry}\""
          else
            list << entry
          end
          list << "#{delim} " unless entry == arr.last
        end
        list
      end

      def analyse_element_presence(container, element, how, what, max_seconds = 30, interval = 0.25)
        duration = 0
        code     = build_webdriver_fetch(element, how, what) + '.present?'
        debug_to_log("#{__method__}: code=>[#{code}")
        until duration > max_seconds do
          begin
            debug_to_log("#{eval(code)} #{duration}")
          rescue => e
            debug_to_log("#{__method__}: #{e.inspect}")
          end
          duration += interval
          sleep(interval)
        end
      end

      def get_date_names(date = Date.today, language = 'English')
        this_month = date.month
        next_month = this_month == 12 ? 1 : this_month + 1
        prev_month = this_month == 1 ? 12 : this_month - 1

        month_arr = get_months(language)

        this_month_name = month_arr[this_month]
        next_month_name = month_arr[next_month]
        prev_month_name = month_arr[prev_month]

        arr = [date.year.to_s, date.day.to_s, this_month_name, next_month_name, prev_month_name]
        debug_to_log("#{__method__} #{nice_array(arr)}")
        arr
      end

      def next_day(yr, mo, dy, diff = 1)
        tdy = DateTime.new(yr.to_i, mo.to_i, dy.to_i, 0, 0, 0)
        tdy.advance(:days => diff).strftime("%Y-%m-%d")
      end

      def next_month(this)
        unless this.is_a?(Fixnum)
          this = this.to_i
        end
        nxt = this == 12 ? 1 : this + 1
        nxt.to_s.rjust(2, '0')
      end

      def next_month_name(this, language = 'English')
        unless this.is_a?(Fixnum)
          this = get_months(language).index(this)
        end
        nxt = this == 12 ? 1 : this + 1
        get_months(language)[nxt]
      end

      def prev_day(yr, mo, dy, diff = -1)
        diff = diff > 0 ? -diff : diff
        tdy  = DateTime.new(yr.to_i, mo.to_i, dy.to_i, 0, 0, 0)
        tdy.advance(:days => diff).strftime("%Y-%m-%d")
      end

      def prev_month(this)
        prev = this.to_i == 1 ? 12 : this.to_i - 1
        prev.to_s.rjust(2, '0')
      end

      def prev_month_name(this, language = 'English')
        unless this.is_a?(Fixnum)
          this = get_months(language).index(this)
        end
        prev = this == 1 ? 12 : this - 1
        get_months(language)[prev]
      end

      def get_month_name(this, language = 'English')
        unless this.is_a?(Fixnum)
          this = get_months(language).index(this)
        end
        get_months(language)[this]
      end

      def translate_month_name(name, to, from = 'English')
        get_months(from).index(name)
        get_months(to)[get_months(from).index(name)]
      end

      def get_days(language = 'English', abbrev = 0)
        case language
          when /english/i
            full_arr = Date::DAYNAMES

          # TODO: commented words with diacriticals until we can fix encoding confusion with mac/safari
          when /french/i, /francais/i #, /français/i
            full_arr = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]

          else
            failed_to_log(with_caller("Language #{language} not yet supported."))
            full_arr = nil
        end

        if abbrev > 0
          rtrn_arr = []
          full_arr.each do |m|
            rtrn_arr << m.slice(0, abbrev)
          end
        else
          rtrn_arr = full_arr
        end

        rtrn_arr
      rescue
        failed_to_log(unable_to)
      end

      def get_months(language = 'English', abbrev = 0)
        case language
          when /english/i
            full_arr = Date::MONTHNAMES

          # TODO: commented words with diacriticals until we can fix encoding confusion with mac/safari
          when /french/i, /francais/i #, /français/i
            full_arr = [nil, 'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
                        'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre']
          # full_arr = [nil, 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          #             'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre']
          else
            failed_to_log(with_caller("Language #{language} not yet supported."))
            full_arr = nil
        end

        if abbrev > 0
          rtrn_arr = []
          full_arr.each do |m|
            if m
              rtrn_arr << m.slice(0, abbrev)
            else
              rtrn_arr << nil
            end
          end
        else
          rtrn_arr = full_arr
        end

        rtrn_arr
      rescue
        failed_to_log(unable_to(language))
      end

      def load_variables(file, key_type = :role, enabled_only = true, dbg = true, scripts = nil)
        mark_test_level(build_message(file, "key:'#{key_type}'"))

        # ok = true

        debug_to_log("#{__method__}: file = #{file}")
        debug_to_log("#{__method__}: key  = #{key_type}")

        workbook = file =~ /\.xlsx$/ ? Roo::Excelx.new(file) : Roo::Excel.new(file)

        if @myName =~ /appium/i
          ok = script_found_in_data = script_found_in_login = true
        else
          script_found_in_data      = load_data_variables(workbook, dbg)
          ok, script_found_in_login = load_login_variables(workbook, enabled_only, file, key_type, scripts, dbg)
        end

        unless @env_name =~ /^gen/
          unless ok and script_found_in_login and script_found_in_data
            ok = false
            failed_to_log("Script found: in Login = #{script_found_in_login}; in Data = #{script_found_in_data}")
          end
        end

        ok
      rescue
        failed_to_log(unable_to)
      end

      alias get_variables load_variables

      def load_login_variables(workbook, enabled_only, file, key_type, scripts, dbg = nil)

        ok                    = true
        script_found_in_login = false
        @login                = Hash.new
        enabled_cnt           = 0
        script_col            = 0
        role_col              = 0
        userid_col            = 0
        company_col           = 0
        password_col          = 0
        url_col               = 0
        env_col               = 0
        name_col              = 0
        appid_col             = 0
        ref_col               = 0
        node_col              = 0
        login_index           = find_sheet_with_name(workbook, 'Login')
        if login_index and login_index >= 0
          workbook.default_sheet = workbook.sheets[login_index]

          1.upto(workbook.last_column) do |col|
            column_name = workbook.cell(1, col).downcase
            case column_name
              when @myName.downcase
                script_col            = col
                script_found_in_login = true
                if scripts.is_a?(Array)
                  scripts << column_name
                else
                  break
                end
              when 'role'
                role_col = col
              when 'userid', 'user_id'
                userid_col = col
              when 'companyid', 'company_id'
                company_col = col
              when 'password'
                password_col = col
              when 'url'
                url_col = col
              when 'environment'
                env_col = col
              when /reference/i
                ref_col = col
              when 'nodename'
                node_col = col
              when 'name'
                name_col = col
              when 'appid', 'app_id'
                appid_col = col
              else
                scripts << column_name if scripts.is_a?(Array)
            end
          end

          2.upto(workbook.last_row) do |line|
            role      = workbook.cell(line, role_col)
            userid    = workbook.cell(line, userid_col)
            password  = workbook.cell(line, password_col)
            url       = workbook.cell(line, url_col)
            env       = workbook.cell(line, env_col)
            username  = workbook.cell(line, name_col)
            nodename  = workbook.cell(line, node_col)
            companyid = workbook.cell(line, company_col)
            appid     = workbook.cell(line, appid_col)
            enabled   = workbook.cell(line, script_col).to_s
            refs      = workbook.cell(line, ref_col)

            case key_type
              when :id, :userid
                key = userid
              when :environment
                key = env
              when :role
                key = role
              else
                key = userid
            end

            if enabled_only and enabled.length == 0
              next
            end

            @login[key]                = Hash.new
            @login[key]['role']        = role
            @login[key]['userid']      = userid
            @login[key]['companyid']   = companyid
            @login[key]['password']    = password
            @login[key]['url']         = url
            @login[key]['name']        = username
            @login[key]['nodename']    = nodename
            @login[key]['enabled']     = enabled
            @login[key]['environment'] = env
            @login[key]['appid']       = appid
            @login[key]['references']  = refs

            if enabled =~ /^y$/i
              case key_type
                when :environment
                  case env
                    when /^gen/i
                      enabled_cnt += 1
                    else
                      enabled_cnt += 1 if @env_name =~ /#{env}/
                  end
                else
                  enabled_cnt += 1
              end
            end

          end

          @login.keys.sort.each do |key|
            message_to_log("@login (by #{key_type}): #{key}='#{@login[key].to_yaml}'")
          end if dbg

        else
          fail "'Login' worksheet not found in #{file}"
        end

        unless enabled_cnt > 0
          ok = false
          case key_type
            when :environment
              err_msg = "No enabled 'Login' entries for rows matching :#{key_type} => '#{@env_name}'"
            else
              err_msg = "No enabled 'Login' entries for rows matching :#{key_type}"
          end
          fail err_msg
        end

        return ok, script_found_in_login
      rescue
        failed_to_log(unable_to)
      end

      def load_data_variables(workbook, dbg = nil)

        script_found_in_data = false

        @var                   = Hash.new
        data_index             = find_sheet_with_name(workbook, 'Data')
        workbook.default_sheet = workbook.sheets[data_index]
        var_col                = 0
        default_col            = 2

        2.upto(workbook.last_column) do |col|
          script_name = workbook.cell(1, col)
          if script_name == 'default'
            default_col = col
          end
          if script_name == @myName
            var_col              = col
            script_found_in_data = true
            break
          end
        end

        defaults = {}
        2.upto(workbook.last_row) do |line|
          name           = workbook.cell(line, 'A')
          value          = workbook.cell(line, default_col).to_s.strip
          defaults[name] = value
        end

        2.upto(workbook.last_row) do |line|
          name  = workbook.cell(line, 'A')
          value = workbook.cell(line, var_col).to_s.strip
          if value and value.length > 0
            @var[name] = value
          else
            @var[name] = defaults[name]
          end
        end

        @var.keys.sort.each do |name|
          message_to_log("@var #{name}: '#{@var[name]}'")
        end if dbg

        script_found_in_data
      rescue
        failed_to_log(unable_to)
      end

      def choose_refs(arr, *indices)
        refs = ''
        indices.each do |idx|
          refs << "*** #{arr[idx]} *** "
        end
        refs
      rescue
        failed_to_log(unable_to)
      end

      def parse_test_flag(string)
        test    = false
        refs    = nil
        arr     = string.is_a?(Array) ? string : string.to_s.split(/,\s*/)
        ref_arr = []
        arr.each { |r| ref_arr << format_reference(r) }
        if string
          if string == true or string == false
            test = string
          else
            if string.length > 0
              unless string =~ /^no$|^false$/i
                test = true
                unless string =~ /^yes$|^true$/i
                  refs = format_refs(string)
                end
              end
            end
          end
        end
        [test, refs, ref_arr]
      rescue
        failed_to_log(unable_to)
      end

      def pad_id_end_count(id, delim = '_', pad = 6)
        mtch = id.match(/^(.*)#{delim}(\d+)$/)
        mtch[1] + delim + mtch[2].rjust(pad, '0')
      rescue
        failed_to_log(unable_to("id: '#{id}' delim: '#{delim}' pad: #{pad}"))
      end

      def parse_caller(caller)
        call_script, call_line, call_meth = caller.split(':')
        call_script.gsub!(/\.rb/, '')
        call_script = call_script.camelize
        call_meth =~ /in .([\w\d_ ]+)./
        call_meth = $1
        if call_meth.match(/((rescue|block|eval)\s*in\s*)/)
          delete = $1
          append = $2
          call_meth.sub!(delete, '')
          call_meth << " (#{append})"
        end
        [call_script, call_line, call_meth]
      rescue
        failed_to_log(unable_to)
      end

      def parse_mdy_to_datetime(mdy)
        if mdy and mdy.length > 0
          m, d1, d, d2, y = mdy.split(/([\/\.-])/)
          y               = "20#{y}" unless y.length == 4
          ymd             = "#{y}#{d1}#{m}#{d1}#{d}"
          DateTime.parse(ymd)
        end
      rescue
        failed_to_log(unable_to)
      end

      def count_duplicates(arr)
        counts = {}
        dups   = {}
        arr.each do |id|
          counts[id] = counts[id] ? counts[id] + 1 : 1
          dups[id]   = counts[id] if counts[id] > 1
        end
        [dups, counts]
      end

      def diff_datetimes_in_days(beg_dt, end_dt)
        (end_dt - beg_dt).to_i
      end

      def extract_selected(selected_options, which = :text)
        arr = Array.new
        selected_options.each do |so|
          case which
            when :text
              arr << so.text
            else
              arr << so.value
          end
        end
        arr.sort
      rescue
        failed_to_log(unable_to)
      end

      def build_webdriver_fetch_old(element, how, what, value = nil)
        code = "container.#{element}(:#{how} => "
        what = escape_stuff(what)
        if what.is_a?(Regexp)
          code << "/#{what.source}/"
        else
          code << "'#{what}'"
        end
        if value
          value = escape_stuff(value)
          code << ', :value => '
          if value.is_a?(Regexp)
            code << "/#{value}/"
          else
            value.gsub!('/', '\/')
            code << "'#{value}'"
          end
        end
        code << ')'
        debug_to_log("code: '#{code}'")
        code
      rescue
        failed_to_log(unable_to)
      end

      def build_webdriver_fetch(element, how, what, more = {})
        code = "container.#{element}(:#{how} => "
        what = escape_stuff(what) unless how == :index
        if what.is_a?(Regexp)
          code << "/#{what.source}/"
        elsif how == :index
          code << "#{what}"
        else
          code << "'#{what}'"
        end
        if more and not more.empty?
          more.each do |key, vlu|
            next if key == :desc or key == :flash or key == :exists_only
            code << ", :#{key} => "
            if vlu.is_a?(Regexp)
              code << "/#{vlu}/"
            elsif vlu.is_a?(String)
              code << "'#{vlu.gsub('/', '\/')}'"
            else
              code << "#{vlu}"
            end
          end
        end
        code << ')'
        #debug_to_log("code: '#{code}'")
        code
      rescue
        failed_to_log(unable_to)
      end

      def force_regexp(target)
        if target.respond_to?(:dup)
          rslt = target.dup
          unless rslt.is_a?(Regexp)
            rslt = Regexp.new(Regexp.escape(target.to_s))
          end
        else
          rslt = target
        end
        rslt
      rescue
        failed_to_log(unable_to("'#{target}'"))
      end

      def force_string(target, slash_regexp = true)
        if target
          if target.respond_to?(:dup)
            rslt = target.dup
            if rslt.is_a?(Regexp)
              if slash_regexp
                rslt = "/#{rslt.source}/"
              else
                rslt = rslt.source
              end
            end
          else
            rslt = target.to_s
          end
        else
          rslt = ''
        end
        rslt
      rescue
        failed_to_log(unable_to("'#{target}'"))
      end

      def end_processes(*names)
        pattern = ''
        names.each { |n| pattern << "#{n}|" }
        pattern.chop!
        # puts pattern
        targets = {}

        if USING_OSX
          p_io = IO.popen("ps axo comm,pid,sess,fname")
        else
          p_io = IO.popen("tasklist /nh")
        end

        p_io.readlines.each do |prc|
          # puts prc.chop
          if prc =~ /#{pattern}/
            name, pid    = prc.split(/\s+/)[0, 2]
            # puts "#{name} #{pid}"
            base         = File.basename(name)
            targets[pid] = base
          end
        end

        debug_to_log("End these processes:\n#{targets.to_yaml}")

        if USING_OSX
          kill_cmd = 'kill -9 @@@@@'
        else
          kill_cmd = 'taskkill /f /pid @@@@@'
        end

        targets.each do |pid, name|
            cmd   = kill_cmd.sub('@@@@@', pid)
            debug_to_log("[#{cmd}]")
            kill_io = IO.popen(cmd, :err => :out)
            debug_to_log(kill_io.read.chomp)
          end

        if targets.length > 0
          sleep_for(10)
        end
      end

      def escape_stuff(strg)
        if strg.respond_to?(:dup)
          rslt = strg.dup
          unless rslt.is_a?(Regexp)
            if rslt.match(/[\/\(\)]/)
              rslt.gsub!('/', '\/')
              rslt.gsub!('(', '\(')
              rslt.gsub!(')', '\)')
              rslt = Regexp.new(rslt)
            end
          end
        else
          rslt = strg
        end
        rslt
      rescue
        failed_to_log(unable_to("#{rslt}"))
      end

      def insert_id_pswd_in_url(userid, password, url)
        http = url.match(/^(http)(s?)(:\/\/)/)
        path = url.gsub(http[0], '')
        URI.encode("#{http[0]}#{userid}:#{password}@#{path}")
      end

      def get_test_level(meth = nil)
        arr       = []
        each_line = 0
        call_list = Kernel.caller
        #debug_to_log("#{call_list.to_yaml}")
        call_list.each_index do |x|
          myCaller = call_list[x].to_s
          myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          string = $1
          unless string =~ /logging\.rb|mark_test_level|mark_test_level|debug_to_report|debug_toreport/
            if string.length > 0
              if string =~ /each|each_key/
                each_line = string.match(/\:(\d+)\:/)[1]
              elsif string.match(/\:(\d+)\:/)[1] == each_line
                next
              else
                arr << string.gsub(/eval/, @myName)
              end
            end
          end
          break if meth and string.match(/#{meth}/)
          break if myCaller =~ /:in .run.$|runner\.rb/
        end
        #debug_to_log("#{arr.length} #{nice_array(arr)}")
        [arr.length, arr]
      end

      def get_basic_auth_control_indexes
        case $win_major
          when '5'
            case @browserAbbrev
              when 'IE'
                ['2', '3', '1', 'Connect to']
              when 'FF'
                ['2', '3', '1', 'Authentication Required']
              when 'GC', 'C'
                ['2', '1', '2', 'Authentication Required']
            end
          when '6'
            case @browserAbbrev
              when 'IE'
                ['1', '2', '2', 'Windows Security']
              when 'FF'
                ['2', '1', '2', 'Authentication Required']
              when 'GC', 'C'
                ['2', '1', '2', 'Authentication Required']
            end
        end
      end

      def get_upload_file_control_indexes
        case $win_major
          when '5'
            case @browserAbbrev
              when 'IE'
                ['1', '1', '2', 'Choose File to Upload']
              when 'FF'
                ['1', '1', '2', 'File Upload']
              when 'GC', 'C'
                ['1', '1', '2', 'Open']
            end
          when '6'
            case @browserAbbrev
              when 'IE'
                ['1', '1', '2', 'Choose File to Upload']
              when 'FF'
                ['1', '1', '2', 'File Upload']
              when 'GC', 'C'
                ['1', '1', '2', 'Open']
            end
        end
      end

      def upload_file(browser, data_path, wait = 20)
        #mark_test_level(data_path)
        message_to_report(with_caller(data_path))
        data_path.gsub!('/', '\\') if USING_WINDOWS

        file, open, cancel, title = get_upload_file_control_indexes

        @ai.WinWait(title, "", wait)
        sleep_for(1)
        @ai.ControlSend(title, '', "[CLASS:Edit; INSTANCE:#{file}]", '!u')
        @ai.ControlSetText(title, '', "[CLASS:Edit; INSTANCE:#{file}]", data_path)
        sleep_for(0.5)
        @ai.ControlClick(title, "", "[CLASS:Button; INSTANCE:#{open}]", "primary")

      rescue
        failed_to_log(unable_to)
      end

      def windows_to_log(browser)
        msg = ("===== Current windows (#{where_am_i?(2)})")
        idx = 0
        browser.windows.each do |w|
          msg << "\n  #{idx}: #{w.title} current?=#{w.current?}" #" (#{w.url})"
          idx += 1
        end
        debug_to_log(msg)
      rescue => e
        debug_to_log(unable_to("#{where_am_i?(2)}: #{e.inspect}"))
      end

      def get_windows_version
        ver          = `ver`.gsub("\n", '')
        mtch         = ver.match(/(.*)\s\[Version\s*(\d+)\.(\d+)\.(\d+)\]/)
        $win_name    = mtch[1]
        $win_major   = mtch[2]
        $win_minor   = mtch[3]
        $win_build   = mtch[4]
        $win_version = "#{$win_major}.#{$win_minor}.#{$win_build}"
      rescue
        failed_to_log(unable_to)
      end

      def set_env_name(xls = @xls_path, fix = :prefix, strg = 'toad')
        debug_to_log(with_caller("awetest_dsl override")) if $debug
        if fix == :prefix
          pattern = /#{strg}_([\w\d]+)\.xls$/
        else
          pattern = /([\w\d]+)_#{strg}\.xls$/
        end
        if awetestlib?
          if @runenv
            @env_name = @myAppEnv.name.downcase.underscore
          else
            @env_name = 'dev'
            #if xls
            #  xls =~ pattern
            #  @env_name = $1
            #else
            #  @env_name = 'sit'
            #end
          end
        else
          @env_name = @myAppEnv.name.downcase # .underscore #.gsub(/^toad./, '')
        end
        debug_to_report("#{__LINE__}: @env_name=#{@env_name}")
      rescue
        failed_to_log(unable_to)
      end

      def set_xls_spec(proj_acro = 'unknown', env = @env_name.downcase.underscore, fix = :prefix, xlsx = @xlsx)
        debug_to_log(with_caller("awetest_dsl override")) if $debug
        env = env.split(/:[\s_]*/)[1] if env =~ /:/
        case fix
          when :prefix
            xls_name = "#{proj_acro}_#{env}.xls"
          when :suffix
            xls_name = "#{env}_#{proj_acro}.xls"
          when :none
            xls_name = "#{env.gsub('-', '_')}.xls"
          else
            failed_to_log(with_caller("Unknown fix type: '#{fix}'.  Must be 'prefix', 'suffix', or 'none'."))
            return nil
        end
        spec = "#{@myRoot}/#{xls_name}"
        spec << 'x' if xlsx
        debug_to_log("#{where_am_i?}: #{spec}")
        spec
      rescue
        failed_to_log(unable_to)
      end

      def format_refs(list)
        refs = ''
        if list
          list.split(/,\s*/).each do |ref|
            refs << format_reference(ref)
          end
        end
        refs
      end

      def format_reference(ref)
        "*** #{ref} *** "
      end

      def collect_references(*strings)
        refs = ''
        strings.each do |strg|
          refs << " #{format_refs(strg)}" if strg and strg.length > 0
        end if strings
        refs
      end

      def build_message(strg1, *strings)
        msg = "#{strg1}"
        strings.each do |strg|
          if strg.is_a?(Array)
            strg.each do |str|
              msg << " #{str}" if str and str.length > 0
            end
          else
            msg << " #{strg}" if strg and strg.length > 0
          end
        end if strings
        msg
      rescue
        failed_to_log(unable_to)
      end

      alias build_msg build_message
      alias bld_msg build_message

      def load_html_validation_filters(file = @refs_spec)
        sheet         = 'HTML Validation Filters'
        workbook      = file =~ /\.xlsx$/ ? Roo::Excelx.new(file) : Roo::Excel.new(file)
        @html_filters = Hash.new

        sheet_index = find_sheet_with_name(workbook, "#{sheet}")
        if sheet_index > -1
          debug_to_log("Loading worksheet '#{sheet}'.")
          workbook.default_sheet = workbook.sheets[sheet_index]

          columns = Hash.new

          1.upto(workbook.last_column) do |col|
            columns[workbook.cell(1, col).to_sym] = col
          end

          2.upto(workbook.last_row) do |line|
            identifier               = workbook.cell(line, columns[:identifier])
            validator                = workbook.cell(line, columns[:validator])
            pattern                  = workbook.cell(line, columns[:pattern])
            action                   = workbook.cell(line, columns[:action])
            alt_pattern              = workbook.cell(line, columns[:alt_pattern])
            alt_action               = workbook.cell(line, columns[:alt_action])
            script                   = workbook.cell(line, columns[:script])
            head                     = workbook.cell(line, columns[:head])
            meta                     = workbook.cell(line, columns[:meta])
            body                     = workbook.cell(line, columns[:body])
            frame                    = workbook.cell(line, columns[:frame])
            fragment                 = workbook.cell(line, columns[:fragment])
            report_more              = workbook.cell(line, columns[:report_more])
            description              = workbook.cell(line, columns[:description])

            # pattern = pattern ? Regexp.escape(pattern) : nil
            # alt_pattern = alt_pattern ? Regexp.escape(alt_pattern) : nil

            @html_filters[validator] = Hash.new unless @html_filters[validator]

            @html_filters[validator][identifier] = {
                :validator   => validator,
                :pattern     => pattern,
                :action      => action,
                :alt_pattern => alt_pattern,
                :alt_action  => alt_action,
                :script      => script,
                :head        => head,
                :meta        => meta,
                :body        => body,
                :frame       => frame,
                :fragment    => fragment,
                :report_more => report_more,
                :description => description }
          end
        else
          failed_to_log("Worksheet '#{sheet}' not found #{file}")
        end

        @html_error_references = Hash.new

        sheet       = 'HTML Error References'
        sheet_index = find_sheet_with_name(workbook, "#{sheet}")
        if sheet_index > -1
          debug_to_log("Loading worksheet '#{sheet}'.")
          workbook.default_sheet = workbook.sheets[sheet_index]

          columns = Hash.new

          1.upto(workbook.last_column) do |col|
            columns[workbook.cell(1, col).to_sym] = col
          end

          2.upto(workbook.last_row) do |line|
            validator                       = workbook.cell(line, columns[:validator])
            pattern                         = workbook.cell(line, columns[:pattern])
            reference                       = workbook.cell(line, columns[:reference])
            component                       = workbook.cell(line, columns[:component])
            alm_df                          = workbook.cell(line, columns[:alm_df])
            jira_ref                        = workbook.cell(line, columns[:jira_ref])
            description                     = workbook.cell(line, columns[:description])

            # pattern                         = pattern ? Regexp.escape(pattern) : nil

            @html_error_references[pattern] = {
                :validator   => validator,
                :reference   => reference,
                :component   => component,
                :alm_df      => alm_df,
                :jira_ref    => jira_ref,
                :description => description }
          end
        else
          failed_to_log("Worksheet '#{sheet}' not found #{file}")
        end

        [@html_filters, @html_error_references]
      rescue
        failed_to_log(unable_to)
      end

      def unable_to(message = '', no_dolbang = false, verify_that = false, caller_index = 1)
        call_arr = get_call_array
        puts call_arr
        call_script, call_line, call_meth = parse_caller(call_arr[caller_index])
        strg                              = "Unable to"
        strg << " verify" if verify_that
        strg << " #{call_meth.titleize}:"
        strg << '?' if call_meth =~ /\?/
        strg << ':'
        strg << " #{message}" if message.length > 0
        strg << " '#{$!}'" unless no_dolbang
        strg
      end
    end

    module Find

      def get_attribute_value(container, element, how, what, attribute, desc = '', refs = '')
        msg   = build_message(desc, "'#{attribute}' in :#{element.to_s.upcase} :#{how}='#{what}'.")
        code  = build_webdriver_fetch(element, how, what)
        value = eval("#{code}.attribute_value('#{attribute}')")
        if value
          passed_to_log(with_caller(msg, desc, refs))
          value
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_element_colors(element, colors = [], desc = '', refs = '')
        msg    = build_message(desc, "Get colors for #{element.tag_name.upcase}.", refs)

        colors = [
            'color', 'background-color', 'border-bottom-color', 'border-left-color', 'border-right-color',
            'border-top-color'
        ] unless colors.size > 0

        hash = {}
        colors.each do |color|
          hash[color] = normalize_color_value(element.style(color))
        end

        hash
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_element_attribute(element, attribute, desc = '', refs = '', how = '', what = nil)
        msg   = build_message(desc, "Get '#{attribute}' for #{element.tag_name.upcase}", (":#{how}=>'#{what}'" if what), refs)
        value = element.attribute_value(attribute)
        if value
          passed_to_log(with_caller(msg))
        else
          failed_to_log(with_caller(msg))
        end
        value
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_selected_options(browser, how, what, desc = '', refs = '')
        msg      = with_caller(desc, with_caller(" in Select list #:#{how}=>#'#{what}'"), refs)
        selected = nil
        begin
          list = browser.select_list(how, what)
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(:select_list, how, what), "#{browser.class}")
            raise e
          end
        end
        if list
          selected = list.selected_options
          if selected and selected.length > 0
            passed_to_log(msg + " Found #{selected.length} selected options.")
            selected
          else
            failed_to_log(msg + " Found no selected options.")
          end
        else
          failed_to_log(with_caller(desc, "Select List #{how}=#{what} not found.", refs))
        end
        selected
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_style(container, element, how, what, style, desc = '', refs = '')
        msg   = build_message(desc, "Get '#{style}' in :#{element.to_s.upcase} :#{how}='#{what}'.")
        code  = build_webdriver_fetch(element, how, what)
        value = eval("#{code}.style('#{style}')")
        if value
          passed_to_log(with_caller(msg, "value=>'#{value}'", desc, refs))
          value
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      alias get_style_value get_style

      def get_directory(path)
        if File.directory?(path)
          debug_to_log("Directory already exists, '#{path}'.")
        else
          Dir::mkdir(path)
          debug_to_log("Directory was created, '#{path}'.")
        end
        path
      end

      def get_element(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        msg                        = build_message(desc, "Return #{element.to_s.upcase} with :#{how}='#{what}'", value, refs)
        timeout                    = options[:timeout] ? options[:timeout] : 30
        code                       = build_webdriver_fetch(element, how, what, options)
        code                       = "#{code}.when_present(#{timeout})" unless options[:exists_only] or container.to_s =~ /noko/i
        debug_to_log(with_caller("{#{code}")) if $mobile
        target = eval(code)
        if target and target.exists?
          if options[:flash] and target.respond_to?(:flash)
            target.wd.location_once_scrolled_into_view
            target.flash
          end
          if target.class =~ /element/i
            target = target.to_subtype
            msg.sub!(element.tag_name, target.tag_name)
          end
          passed_to_log(msg)
          target
        else
          failed_to_log(msg)
          nil
        end
      rescue => e
        unless rescue_me(e, __method__, rescue_me_command(target, how, what), "#{container.class}", target)
          failed_to_log(unable_to(msg))
          raise e
        end
      end

      def capture_value_desc(value, desc, refs, options = nil)
        opt = options.dup if options
        unless opt.kind_of?(Hash)
          opt = Hash.new
        end

        if value
          vlu = value.dup
        elsif opt[:value]
          vlu = opt[:value]
        end

        if desc
          dsc = desc.dup
        elsif opt[:desc]
          dsc = opt[:desc]
        end

        if refs
          rfs = refs.dup
        elsif opt[:refs]
          rfs = opt[:refs]
        end

        [vlu, dsc, rfs, opt]
      rescue
        failed_to_log(unable_to)
      end

      def ancestor_is_a?(descendant, tag_name, generation = 1, desc = '', refs = '')
        tag_name = 'a' if tag_name == 'link'
        msg      = build_message(desc, "#{descendant.tag_name.upcase} with id '#{descendant.attribute_value('id')}' has", "tag: '#{tag_name}'", "#{generation} level above")
        ancestor = descendant.dup
        count    = 0
        while count < generation
          ancestor = ancestor.parent
          count    += 1
        end
        if ancestor.respond_to?(:tag_name) and ancestor.tag_name.downcase == tag_name.downcase
          passed_to_log(with_caller(msg, desc, refs))
          true
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to, false, true)
      end

      def get_ancestor(descendant, element, how, what, desc = '', refs = '', dbg = $debug)
        found = false
        how   = 'class_name' if how.to_s == 'class'
        tag   = element.to_s.downcase
        debug_to_log("target: #{descendant.to_s.upcase} :id=>#{descendant.attribute_value('id')}") if dbg
        debug_to_log("goal:   #{tag.upcase} :#{how}='#{what}' #{desc}") if dbg
        ancestor = descendant.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' #{refs}") if dbg
        code = "ancestor.#{how}"
        what.is_a?(Regexp) ? code << " =~ /#{what.source}/" : code << " == '#{what}'"
        debug_to_log("#{code}") if dbg
        until found do
          break unless ancestor
          break if ancestor.tag_name =~ /html/i
          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{ancestor.attribute_value('id')}' #{refs}") if dbg
          if ancestor.tag_name == tag
            if eval(code)
              found = true
              break
            end
          end
          ancestor = ancestor.parent
        end
        msg = build_message(
            with_caller(desc),
            "- Descendant is #{descendant.tag_name.upcase} :id=>#{descendant.attribute_value('id')}.",
            "Find ancestor #{tag.upcase} :#{how}='#{what}'?"
        )
        if found
          passed_to_log(msg)
          ancestor
        else
          failed_to_log(msg)
          nil
        end

      rescue
        failed_to_log(unable_to)
      end

      def get_ancestor2(descendant, element, how, what, desc = '', dbg = $DEBUG)
        elements = Array.new
        if element.is_a?(Array)
          element.each do |e|
            elements << e.to_s.downcase
          end
        else
          elements[0] = element.tag_name.downcase
        end
        found = false
        how   = 'class_name' if how.to_s == 'class'
        debug_to_log("target: #{descendant.tag_name} :id=>'#{descendant.attribute_value('id')}'") if dbg
        debug_to_log("goal:   #{nice_array(elements)} :#{how}='#{what}'   #{desc}") if dbg
        ancestor = descendant.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}'") if dbg
        code = "ancestor.#{how}"
        what.is_a?(Regexp) ? code << " =~ /#{what.source}/" : code << " == '#{what}'"
        debug_to_log("#{code}") if dbg

        until found do
          break unless ancestor
          if ancestor.tag_name =~ /html/i
            ancestor = nil
            break
          end

          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{ancestor.attribute_value('id')}'") if dbg
          if elements.include?(ancestor.tag_name.downcase)
            if eval(code)
              found = true
              break
            end
          end

          ancestor = ancestor.parent
        end

        [ancestor, (ancestor.tag_name.downcase if ancestor)]
      rescue
        failed_to_log(unable_to)
      end

      def get_ancestor3(descendant, elements = [:any], hows = [], whats = [], desc = '', dbg = $DEBUG)
        fail 'Parameter \'elements\' must be an array.' unless elements.is_a?(Array)
        fail 'Parameter \'hows\' must be an array.' unless hows.is_a?(Array)
        fail 'Parameter \'whats\'  must be an array.' unless whats.is_a?(Array)
        fail 'Parameters \'hows\' and \'whats\'  must be the same length.' unless hows.length == whats.length

        found = false

        debug_to_log("target: #{descendant.tag_name} :id=>'#{descendant.attribute_value('id')}'") if dbg
        debug_to_log("goal:   #{element.tag_name.upcase} :#{how}='#{what}'   #{desc}") if dbg
        ancestor = descendant.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}'") if dbg
        code == ''
        (0..hows.length).each do |idx|
          hows[idx] = 'class_name' if hows[idx].to_s == 'class'
          code      = "ancestor.#{how}"
          whats[idx].is_a?(Regexp) ? code << " =~ /#{whats[idx].source}/" : code << " == '#{whats[idx]}'"
          code << ' and ' if idx < hows.length
          debug_to_log("#{code}") if dbg
        end
        until found do
          break unless ancestor
          break if ancestor.tag_name =~ /html/i
          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{descendant.attribute_value('id')}'") if dbg
          if elements.include?(ancestor.tag_name.downcase.to_sym)
            if eval(code)
              found = true
              break
            end
          end
          ancestor = ancestor.parent
        end
        [ancestor, ancestor.tag_name.downcase]
      rescue
        failed_to_log(unable_to)
      end

      def get_ancestor4(descendant, args = {})
        desc   = args[:desc] if args[:desc]
        errors = Array.new
        [:elements, :hows, :whats].each do |key|
          if args.keys.include?(key)
            unless args[key].is_a?(Array)
              args[key] = [args[key]]
            end
            eval("#{key.to_s} = args[#{key}]")
          else
            errors << "Parameter '#{key}' is required. "
          end
        end
        if hows and whats
          unless hows.length == whats.length
            errors << "Parameters 'hows' and 'whats' must be the same length. "
          end
        end
        if errors.length > 0
          failed_to_log("#{method_to_title(__method__)}: #{nice_array(errors)} #{desc}")
        else
          found    = false
          ancestor = descendant.parent
          code == ''
          (0..hows.length).each do |idx|
            hows[idx] = 'class_name' if hows[idx].to_s == 'class'
            code      = "ancestor.#{how}"
            whats[idx].is_a?(Regexp) ? code << " =~ /#{whats[idx].source}/" : code << " == '#{whats[idx]}'"
            code << ' and ' if idx < hows.length
            debug_to_log("#{code}") if dbg
          end
          until found do
            break unless ancestor
            debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{descendant.attribute_value('id')}'") if dbg
            if elements.include?(ancestor.tag_name.downcase.to_sym)
              if eval(code)
                found = true
                break
              end
            end
            ancestor = ancestor.parent
          end
          [ancestor, ancestor.tag_name.downcase]
        end
      rescue
        failed_to_log(unable_to)
      end

      # def find_element_with_focus(container)
      #   container.driver.browser.switch_to.active_element
      # end

      def get_active_element(container)
        container.execute_script("return document.activeElement")
      end

      alias find_element_with_focus get_active_element

      def identify_active_element(container, desc = '', parent = false)
        element = get_active_element(container)
        element = element.parent if parent
        tag     = element.respond_to?(:tag_name) ? element.tag_name : 'no tag name'
        id      = element.respond_to?(:id) ? element.id : 'no id'
        cls     = element.respond_to?(:class_name) ? element.class_name : 'no class'
        text    = element.respond_to?(:text) ? element.text : 'no text'
        debug_to_report(with_caller(desc, ":tag_name=>#{tag}", ":id=>#{id}", ":text=>'#{text}'", "is parent?=>#{parent}"))
        [element, tag.to_sym, :id, cls]
      rescue
        failed_to_log(unable_to)
      end

      def highlight_element(element)
        # not really different than .flash unless the two js scripts are separated by a sleep.
        # probably needs to make sure that original color and border can be restored.
        #public void highlightElement(WebDriver driver, WebElement element)
        # { for (int i = 0; i < 2; i++)
        # { JavascriptExecutor js = (JavascriptExecutor) driver;
        # js.executeScript("arguments[0].setAttribute('style', arguments[1]);", element, "color: yellow; border: 2px solid yellow;");
        # js.executeScript("arguments[0].setAttribute('style', arguments[1]);", element, "");
        # }
        # }
        # - See more at: http://selenium.polteq.com/en/highlight-elements-with-selenium-webdriver/#sthash.JShjPbsj.dpuf
      end

    end

    module Validations

      include W3CValidators

      def is_true?(actual, message, desc = '', refs = '')
        msg = build_message(desc, "Is '#{message}' true?", refs)
        if actual
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      end

      def is_false?(actual, message, desc = '', refs = '')
        msg = build_message(desc, "Is '#{message}' false?", refs)
        if actual
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      end

      def verify_months(list, language = 'English', abbrev = 0, desc = '', refs = '')
        msg         = build_message(desc, "List of xxxx months in #{language} is correct and in order?")
        list        = [nil].concat(list)
        month_names = get_months(language, abbrev)
        if abbrev > 0
          msg.gsub!('xxxx', "#{nbr2wd(abbrev)} character")
        else
          msg.gsub!('xxxx', 'fully spelled')
        end
        if list == month_names
          passed_to_log(with_caller(msg, desc, refs))
          true
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def verify_days(list, language = 'English', abbrev = 0, offset = 0, desc = '', refs = '')
        #TODO: Handle different starting day: rotate_array(arr, target, index = 0, stop = 0)
        msg       = build_message(desc, "List of xxxx weekdays in #{language} is correct and in order?")
        day_names = get_days(language, abbrev)
        day_names = rotate_array(day_names, offset) if offset > 0
        if abbrev > 0
          msg.gsub!('xxxx', "#{nbr2wd(abbrev)} character")
        else
          msg.gsub!('xxxx', 'fully spelled')
        end
        if list == day_names
          passed_to_log(with_caller(msg, desc, refs))
          true
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def greater_than?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Actual '#{actual}' greater than expected '#{expected}'?", refs)
        if actual > expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def greater_than_or_equal_to?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Actual '#{actual}' greater than or equal to expected '#{expected}'?", refs)
        if actual >= expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias greater_than_or_equal? greater_than_or_equal_to?
      alias greater_or_equal? greater_than_or_equal_to?
      alias count_greater_or_equal? greater_than_or_equal_to?

      def less_than?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Actual '#{actual}' less than expected '#{expected}'?", refs)
        if actual < expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def less_than_or_equal_to?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Actual '#{actual}' less than or equal to expected '#{expected}'?", refs)
        if actual <= expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias count_less_or_equal? less_than_or_equal_to?
      alias less_than_or_equal? less_than_or_equal_to?
      alias less_or_equal? less_than_or_equal_to?

      def number_equals?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Actual '#{actual}' equals expected '#{expected}'?", refs)
        if actual == expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias count_equals? number_equals?

      def number_does_not_equal?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Actual '#{actual}' does not equal expected '#{expected}'?", refs)
        if actual == expected
          failed_to_log("#{msg}")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias count_does_not_equal? number_does_not_equal?

      def within_range?(actual, target, min, max = nil)
        if max
          (min..max).include?(actual)
        else
          ((target - min)..(target + min)).include?(actual)
        end
      rescue
        failed_to_log(unable_to, false, true)
      end

      def within_tolerance?(actual, expected, tolerance, desc = '', refs = '')
        min = expected - tolerance
        max = expected + tolerance
        msg = build_message(desc, "#{actual} is between #{min} and #{max}?", refs)
        if within_range?(actual, expected, tolerance)
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias number_within_tolerance? within_tolerance?
      alias count_within_tolerance? within_tolerance?

      def dimensions_equal?(first_name, first_value, second_name, second_value, desc = '', refs = '')
        msg = build_message(desc, "#{first_name}: #{first_value} equals #{second_name}: #{second_value}?", refs)
        if first_value == second_value
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def dimensions_not_equal?(first_name, first_value, second_name, second_value, desc = '', refs = '')
        msg = build_message(desc, "#{first_name}: #{first_value} does not equal #{second_name}: #{second_value}?", refs)
        if first_value == second_value
          failed_to_log("#{msg}")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def dimension_within_tolerance?(name, actual, expected, tolerance, desc = '', refs = '')
        within_tolerance?(actual, expected, tolerance, with_caller("#{desc}, Dimension", name), refs = '')
      end

      # def centered?(container, element, desc = '', refs = '')
      #   name                      = element.respond_to?(:tag_name) ? element.tag_name.upcase : 'DOM'
      #   msg                       = build_message(desc, "is centered @@@?", refs)
      #
      #   element_x, element_y      = element.dimensions
      #   element_left, element_top = element.client_offset
      #
      #   horizontally = (((element_left * 2) + element_x.floor).to_i) == viewport_x
      #   h_msg        = msg.sub('@@@', 'horizontally')
      #   if horizontally
      #     passed_to_log(h_msg)
      #   else
      #     failed_to_log(h_msg)
      #   end
      #
      #   # At <= 600BP, should be full size of viewport
      #   vertically = true
      #   unless element_top <= 1 || element_x <= 601
      #     vertically = ((element_top * 2) + element_y) == viewport_y
      #     v_msg      = msg.sub('@@@', 'vertically')
      #
      #     if vertically
      #       passed_to_log(v_msg)
      #     else
      #       failed_to_log(v_msg)
      #     end
      #   end
      #
      #   if horizontally and vertically
      #     true
      #   else
      #     false
      #   end
      #
      # rescue
      #   failed_to_log(unable_to(msg.sub('@@@ ', ''), false, true))
      # end
      #
      def class_equals?(container, element, how, what, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_class_equals?(target, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      def element_class_equals?(container, element, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, ":class equals '#{expected}'?", how, what, nil, desc, refs)
        element_wait(element)
        if element.class_name == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}. Found '#{element.class_name}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def class_does_not_contain?(container, element, how, what, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_class_does_not_contain?(target, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      def element_class_does_not_contain?(element, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, ":class does not contain '#{expected}'?", how, what, nil, desc, refs)
        element_wait(element)
        if element.class_name.match(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def class_contains?(container, element, how, what, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_class_contains?(target, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      alias verify_class class_contains?

      def element_class_contains?(element, expected, desc = '', refs = '', how = nil, what = nil)
        msg        = element_query_message(element, ":class contains '#{expected}'?", how, what, nil, desc, refs)
        class_name = element.class_name
        if class_name.match(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}. Found '#{class_name}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias verify_class class_contains?

      def columns_match?(exp, act, dir, col, org = nil, desc = '', refs = '')
        msg = build_message(desc, "Click on #{dir} column '#{col}' produces expected sorted list?", refs)
        ok  = arrays_match?(exp, act, msg)
        unless ok
          debug_to_log("Original order ['#{org.join("', '")}']") if org
          debug_to_log("Expected order ['#{exp.join("', '")}']")
          debug_to_log("  Actual order ['#{act.join("', '")}']")
        end
        ok
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def hashes_match?(exp, act, desc = '', refs = '')
        msg = build_message(desc, 'Hashes match?', refs)
        if exp == act
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def array_includes?(array, expected, desc = '', refs = '')
        msg = build_message(desc, "Array includes '#{expected}'?", refs)
        if array.include?(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def array_does_not_include?(array, expected, desc = '', refs = '')
        msg = build_message(desc, "Array does not include '#{expected}'?", refs)
        if array.include?(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def arrays_match?(exp, act, desc = '', refs = '')
        msg = build_message(desc, 'Arrays match?', refs)
        exp = exp.is_a?(Array) ? exp.dup : [exp]
        act = act.is_a?(Array) ? act.dup : [act]
        if exp == act
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias arrays_match arrays_match?

      def attribute_contains?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", ";#{attribute}", "contains '#{expected}'?", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual.match(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_does_not_contain?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{attribute}", "does not contain '#{expected}'?", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual.match(expected)
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_equals?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{attribute}", "equals '#{expected}'?", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual == expected
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_does_not_equal?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{attribute}", "does not equal '#{expected}?", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual == expected
            failed_to_log(msg)
          else
            passed_to_log("#{msg} Found '#{actual}'")
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def checked?(container, element, how, what, value = nil, desc = '', refs = '')
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_checked?(target, desc, refs, how, what, value)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias checkbox_checked? checked?
      alias checkbox_set? checked?

      def element_checked?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, "is checked?", how, what, value, desc, refs)
        if element.checked?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_checked?(container, how, what, value = nil, desc = '', refs = '')
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_checked?(target, desc, refs, how, what, value)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias checkbox_not_checked? not_checked?
      alias checkbox_not_set? not_checked?

      def element_not_checked?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, "is not checked?", how, what, value, desc, refs)
        if element.checked?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def checkbox_has_checked?(checkbox, desc = '', refs = '')
        msg  = element_query_message(checkbox, "has 'checked' attribute", nil, nil, nil, desc, refs)
        html = checkbox.html
        if html =~ /checked/ and not html =~ /checked=""/
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def checkbox_does_not_have_checked?(checkbox, desc = '', refs = '')
        msg  = element_query_message(checkbox, "does not have 'checked' attribute", nil, nil, nil, desc, refs)
        html = checkbox.html
        if html =~ /checked=""/ or not html =~ /checked/
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_in_html?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_in_html?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_in_html?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' exists in html?", how, what, nil, desc, refs)
        # element_wait(element)
        ptrn = /#{attribute}(?:\s|>|=|$)/
        # debug_to_log(with_caller("[#{element.html}]::", "[#{ptrn}"))
        if element.html =~ ptrn
          attr_vlu = element.attribute_value(attribute)
          passed_to_log("#{msg} Value = '#{attr_vlu}'")
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_not_in_html?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_not_in_html?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_not_in_html?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' does not exist in html?", how, what, nil, desc, refs)
        ptrn = /#{attribute}(?:\s|>|=|$)/
        # debug_to_log(with_caller("[#{element.html}]::", "[#{ptrn}"))
        if element.html =~ ptrn
          attr_vlu = element.attribute_value(attribute)
          failed_to_log("#{msg} Value = '#{attr_vlu}'")
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_exists?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_exists?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_exists?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' exists?", how, what, nil, desc, refs)
        # element_wait(element)
        ptrn = /(?:<|\s)#{attribute}(?:\s|>|=|$)/
        if element.html =~ ptrn
          value = element.attribute_value(attribute)
          passed_to_log("#{msg} '#{attribute}' found with value '#{value}'.")
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_does_not_exist?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_does_not_exist?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_does_not_exist?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' does not exist?", how, what, nil, desc, refs)
        # element_wait(element)
        ptrn = /(?:<|\s)#{attribute}(?:\s|>|=|$)/
        if element.html =~ ptrn
          value = element.attribute_value(attribute)
          failed_to_log("#{msg} '#{attribute}' found with value '#{value}'.")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_inline_attribute_contains?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg          = element_query_message(element, "Inline attribute '#{attribute}' contains '#{force_string(expected)}'?", how, what, nil, desc, refs)
        element_html = element.html
        if element_html.include? attribute
          inline_attr = "#{attribute}" + '=' + '"' + "#{expected}" + '"'
          puts inline_attr
          if element_html.include? inline_attr
            pass_to_log(msg)
          else
            fail_to_log(msg)
          end
        end
      end

      # def element_inline_attribute_equals?(element, attribute, expected, desc = '', refs = '')
      #   element_html = element.html
      #   if element_html.include? attribute
      #     inline_attr = "#{attribute}" + '=' + '"' + "#{value}" + '"'
      #     puts inline_attr
      #     if element_html.include? inline_attr
      #       pass_to_log("#{attribute} has the expected value of #{value}")
      #     else
      #       fail_to_log("#{attribute} missing the expected value of #{value} ")
      #     end
      #   end
      # end

      def element_attribute_equals?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg    = element_query_message(element, "attribute '#{attribute}' equals '#{force_string(expected)}'?", how, what, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual == expected
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_does_not_equal?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg    = element_query_message(element, "attribute '#{attribute}' does not equal '#{force_string(expected)}'?", how, what, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual == expected
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias element_attribute_not_equal? element_attribute_does_not_equal?

      def element_attribute_contains?(element, attribute, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attribute}' contains '#{force_string(expected)}'?", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual.match(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def element_attribute_does_not_contain?(element, attribute, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attribute}' does not contain '#{force_string(expected)}'?", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual.match(expected)
            msg << " Found '#{actual.match(expected)[1]}'"
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def element_attribute_greater?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' greater than '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i > expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_less?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' less than '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i < expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_greater_or_equal?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' greater than or equal to '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i >= expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_less_or_equal?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' less than or equal to '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i <= expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_text_equals?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text equals '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual == expected
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_text_does_not_equal?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text does not '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual == expected
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_text_includes?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text includes '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual.include?(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias element_includes_text? element_text_includes?

      def element_text_does_not_include?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text does not include '#{expected}'?", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual.include?(expected)
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias element_does_not_include_text? element_text_does_not_include?

      def element_wait(element, sleep = 0.25)
        if element.respond_to?(:wait)
          element.wait
        elsif element.respond_to?(:wait_until_present)
          element.wait_until_present
        else
          sleep(sleep)
        end
      end

      def contains_text?(container, element, how, what, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}' contains '#{expected}'?", refs)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        if target
          element_wait(target)
          if target.text.match(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{text}'. #{desc}")
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def does_not_contain_text?(container, element, how, what, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}' does not contain '#{expected}'?", refs)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        if target
          element_wait(target)
          if target.text.match(expected)
            failed_to_log("#{msg} Found '#{text}'. #{desc}")
          else
            passed_to_log(msg)
            true
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def element_contains_text?(element, expected, desc = '', refs = '', how = '', what = '')
        msg = element_query_message(element, "text contains '#{expected}'?", how, what, nil, desc, refs)
        element_wait(element)
        if element.text.match(expected)
          passed_to_log(msg)
          true
        else
          if skip_fail
            debug_to_log(build_msg(msg, "(Fail suppressed)"))
          else
            failed_to_log("#{msg} Found '#{element.text}'")
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_text_contains? element_contains_text?

      def element_does_not_contain_text?(element, expected, desc = '', refs = '', how = '', what = '')
        msg = element_query_message(element, "text does not contain '#{expected}'?", how, what, nil, desc, refs)
        element_wait(element)
        if element.text.match(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_text_does_not_contain? element_does_not_contain_text?

      def directory_exists?(directory)
        File.directory?(directory)
      end

      def string_contains?(strg, target, desc = '', refs = '')
        msg = build_message(desc, "String '#{strg}' contains '#{target}'?", refs)
        if strg.match(target)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      end

      alias validate_string string_contains?
      alias validate_string_contains string_contains?

      def string_does_not_contain?(strg, target, desc = '', refs = '')
        msg = build_message(desc, "String '#{strg}' does not contain '#{target}'?", refs)
        if strg.match(target)
          failed_to_log(msg)
          true
        else
          passed_to_log(msg)
        end
      end

      def boolean_equals?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Boolean '#{actual}' equals expected '#{expected}'?", refs)
        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def string_equals?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "String '#{actual}' equals expected '#{expected}'?", refs)
        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def string_does_not_equal?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "String '#{actual}' does not equal expected '#{expected}'?", refs)
        if actual == expected
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias string_not_equal? string_does_not_equal?

      def text_equals?(container, ptrn, desc = '', refs = '', skip_fail = false, skip_sleep = false)
        name = container.respond_to?(:tag_name) ? container.tag_name.titleize : 'DOM'
        msg  = build_message(desc, "#{name} text contains '#{ptrn}'?", refs)
        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end
        # debug_to_log(with_caller(__LINE__))
        # if container.respond_to?(:wait)
        #   container.wait
        # elsif container.respond_to?(:wait_until_present)
        #   container.wait_until_present
        # else
        #   sleep(3)
        # end

        sleep_for(10)
        if container.text.match(target)
          passed_to_log("#{msg}")
          true
        else
          if skip_fail
            debug_to_log("#{name} text does not contain the text: '#{ptrn}'.  #{desc} (Fail suppressed)")
          else
            failed_to_log(msg)
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias validate_text text_equals?
      alias element_text_equals? text_equals?

      def validate_html(container, page, force_browser = false, filter = true)
        mark_testlevel(": #{page}")
        # require 'nokogiri-pretty'
        # require 'iconv'
        require 'diff/lcs'

        if force_browser
          html = container.browser.html
        else
          html = container.html
        end

        url = container.browser.url

        html_with_line_feeds = html.gsub("\n", '').gsub('>', ">\n")
        html_with_line_feeds = "<!DOCTYPE html>\n" + html_with_line_feeds unless html_with_line_feeds =~ /^\s*\<\!DOCTYPE/

        pretty_html, html_array = validate_encoding(html_with_line_feeds)

        html_context = html_line_context(html_array, container)

        file_name = page.gsub(' ', '_').gsub('-', '_').gsub('__', '_').gsub(':', '')
        file_name << "_#{get_timestamp('condensed_seconds')}_pretty.html"
        spec = File.join(@myRoot, 'log', file_name)
        file = File.new(spec, 'w')
        file.puts(pretty_html)
        file.close

        exceptions = Hash.new

        validate_with_nokogiri(pretty_html, exceptions)
        validate_with_tidy(url, pretty_html, exceptions)
        # validate_with_w3c_markup_file(spec, exceptions)
        validate_with_w3c_markup(pretty_html, exceptions)

        report_html_exceptions(container, exceptions, html_array, html_context, page, filter)

      rescue
        failed_to_log(unable_to, 2)
      end

      def validate_encoding(html, encoding = 'UTF-8')
        # ic      = Iconv.new("#{encoding}//IGNORE", encoding)
        encoded = ''

        html_array  = html.split(/\n/)
        line_number = 1

        html_array.each do |line|
          # valid_string = ic.iconv(line + ' ')[0..-2]
          valid_string = line.encode('UTF-16', :invalid => :replace, :replace => '').encode('UTF-8')
          unless line == valid_string
            diffs     = Diff::LCS.diff(valid_string, line)
            diffs_arr = diffs[0]
            debug_to_log("#{diffs_arr}")
            #TODO make message more meaningful by interpretting the nested array.
            debug_to_report("line #{line_number}: '#{diffs.to_s}' removed from '#{line}' to avoid W3C invalid UTF-8 characters error")
          end

          encoded << valid_string << "\n"

          line_number += 1
        end

        [encoded, html_array]

      rescue
        failed_to_log(unable_to)
      end

      def validate_with_nokogiri(html, exceptions)
        # mark_test_level
        nokogiri_levels = { '0' => 'None', '1' => 'Warning', '2' => 'Error', '3' => 'Fatal' }

        errors = Nokogiri::HTML(html).errors
        debug_to_log("Nokogiri: error count: #{errors.length}")

        instance = 1
        errors.each do |excp|
          debug_to_log("#{instance.to_s.ljust(4, ' ')}: #{excp}", 4)
          line                                                   = excp.line.to_i
          column                                                 = excp.column.to_i
          exceptions['nokogiri']                                 = Hash.new unless exceptions['nokogiri']
          exceptions['nokogiri'][:excps]                         = Hash.new unless exceptions['nokogiri'][:excps]
          exceptions['nokogiri'][:excps][line]                   = Hash.new unless exceptions['nokogiri'][:excps][line]
          exceptions['nokogiri'][:excps][line][column]           = Hash.new unless exceptions['nokogiri'][:excps][line][column]
          exceptions['nokogiri'][:excps][line][column][instance] = "line #{line} column #{column} - #{nokogiri_levels[excp.level.to_s]}: #{excp.message} (nokogiri)"
          instance                                               += 1
        end

      rescue
        failed_to_log(unable_to)
      end

      def validate_with_w3c_markup_file(html, exceptions)
        # mark_test_level
        @w3c_markup_validator = MarkupValidator.new(
            :validator_uri => 'http://wnl-svr017c.wellsfargo.com/w3c-validator/check'
        ) unless @w3c_markup_validator
        result                = @w3c_markup_validator.validate_file(html)
        parse_w3c_result(result, exceptions)
      end

      def validate_with_w3c_markup(html, exceptions)
        # mark_test_level
        @w3c_markup_validator = MarkupValidator.new(
            :validator_uri => 'http://wnl-svr017c.wellsfargo.com/w3c-validator/check'
        ) unless @w3c_markup_validator
        result                = @w3c_markup_validator.validate_text(html)
        parse_w3c_result(result, exceptions)
      end

      def parse_w3c_result(result, exceptions)

        debug_to_log("W3c Markup: #{result.debug_messages}")
        debug_to_log("W3c Markup: error count: #{result.errors.length}")

        instance = 1
        result.errors.each do |excp|
          begin
            debug_to_log("#{instance.to_s.ljust(4, ' ')}: #{excp}", 4)
            if excp =~ /not allowed on element/
              debug_to_log("[#{excp.explanation}]")
            end

            if excp.line
              line                                                     = excp.line.to_i
              column                                                   = excp.col.to_i
              exceptions['w3c_markup']                                 = Hash.new unless exceptions['w3c_markup']
              exceptions['w3c_markup'][:excps]                         = Hash.new unless exceptions['w3c_markup'][:excps]
              exceptions['w3c_markup'][:excps][line]                   = Hash.new unless exceptions['w3c_markup'][:excps][line]
              exceptions['w3c_markup'][:excps][line][column]           = Hash.new unless exceptions['w3c_markup'][:excps][line][column]
              exceptions['w3c_markup'][:excps][line][column][instance] = "line #{line} column #{column} - (#{excp.message_id}) #{excp.message} (w3c_markup)"
            end
            instance += 1
          rescue
            debug_to_log(unable_to("#{instance}"))
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      def validate_with_tidy(url, html, exceptions)
        # mark_test_level
        @html_validator = ::PageValidations::HTMLValidation.new(
            File.join(@myRoot, 'log'),
            [
                #'-access 2'
            ],
            {
                # :ignore_proprietary => true
                #:gnu_emacs          => true
            }
        ) unless @html_validator

        validation = @html_validator.validation(html, url)
        results    = validation.exceptions.split(/\n/)

        debug_to_log("HTML Tidy: error count: #{results.length}")

        instance = 1
        results.each do |excp|
          debug_to_log("#{instance.to_s.ljust(4, ' ')}: #{excp}", 4)
          begin
            mtch = excp.match(/line\s*(\d+)\s*column\s*(\d+)\s*-\s*(.+)$/)
            if mtch
              line   = mtch[1].to_i
              column = mtch[2].to_i
              excp.chomp!
              exceptions['tidy']                                 = Hash.new unless exceptions['tidy']
              exceptions['tidy'][:excps]                         = Hash.new unless exceptions['tidy'][:excps]
              exceptions['tidy'][:excps][line]                   = Hash.new unless exceptions['tidy'][:excps][line]
              exceptions['tidy'][:excps][line][column]           = Hash.new unless exceptions['tidy'][:excps][line][column]
              exceptions['tidy'][:excps][line][column][instance] = excp + ' (tidy)'
            end
            instance += 1
          rescue
            debug_to_log(unable_to("#{instance}"))
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      def report_html_exceptions(container, exceptions, html_array, html_location, page, filter = true, pre_length = 25, post_length = 50)
        mark_test_level(page)
        message_to_report(build_message('(Filtering disabled)')) unless filter

        exception_count = 0
        error_count     = 0
        log_count       = 0
        warn_count      = 0
        ignored_count   = 0
        unknown_count   = 0
        no_filtering    = 0


        exceptions.keys.sort.each do |validator|
          mark_test_level("Validator: #{validator.titleize}", 5)
          exceptions[validator][:tallies]           = Hash.new
          exceptions[validator][:tallies][:ignore]  = 0
          exceptions[validator][:tallies][:log]     = 0
          exceptions[validator][:tallies][:warn]    = 0
          exceptions[validator][:tallies][:fail]    = 0
          exceptions[validator][:tallies][:unknown] = 0

          # debug_to_log("[#{validator}]")
          exceptions[validator][:excps].keys.sort.each do |line|
            # debug_to_log("[#{line}]")
            next unless line.is_a?(Fixnum)
            exceptions[validator][:excps][line].keys.sort.each do |column|
              # debug_to_log("[#{column}]")
              exceptions[validator][:excps][line][column].keys.sort.each do |instance|

                excp            = exceptions[validator][:excps][line][column][instance]
                exception_count += 1

                mtch       = excp.match(/line\s*(\d+)\s*column\s*(\d+)\s*-\s*(.+)$/)
                arr_line   = (mtch[1].to_i - 1)
                int_column = (mtch[2].to_i - 1)
                desc       = mtch[3]

                tag     = "#{validator}/#{line}/#{column}/#{instance} "
                # debug_to_log(tag, 4)

                excerpt = format_html_excerpt(html_array[arr_line], int_column, pre_length, post_length, tag)
                out     = "#{desc}: line #{line} col #{column} #{excerpt}"

                annotate_html_message(out, html_location[arr_line], line, column)

                if filter

                  filter_id, action, alt_value = filter_html_exception?(desc, out, html_array[arr_line], validator, html_location[arr_line])
                  alt_value_msg                = alt_value ? "'#{alt_value}'" : nil

                  if filter_id
                    case action
                      when 'log'
                        log_count                             += 1
                        exceptions[validator][:tallies][:log] += 1
                        debug_to_log(build_message("LOGGED [#{filter_id}]: #{out}", alt_value_msg), 5)
                      when 'warn'
                        warn_count                             += 1
                        exceptions[validator][:tallies][:warn] += 1
                        message_to_report(build_message("WARN [#{filter_id}]: #{out}", alt_value_msg), 4)
                      when 'ignore'
                        ignored_count                            += 1
                        exceptions[validator][:tallies][:ignore] += 1
                        debug_to_log(build_message("IGNORED [#{filter_id}]: #{out}", alt_value_msg), 5)
                      else
                        unknown_count                             += 1
                        exceptions[validator][:tallies][:unknown] += 1
                        debug_to_log("unknown action '#{action}' [#{filter_id}]: #{out}", 4)
                    end
                  else
                    out.sub!(/Warning:|\(html5\)/i, 'ERROR:')
                    ref, desc, tag, id = fetch_html_err_ref(out)
                    ref                = ref.size > 0 ? format_reference(ref) : nil
                    if id
                      elem = container.element(:id, id)
                      debug_to_log(with_caller(build_message(elem.to_subtype, "class=#{elem.class_name}")), 5)
                    end
                    failed_to_log(build_message(out, desc, ref), 6)
                    error_count                            += 1
                    exceptions[validator][:tallies][:fail] += 1
                  end
                else
                  debug_to_report(out)
                  no_filtering += 1
                end

              end
            end
          end
        end

        if error_count > 0
          message_to_report(with_caller("#{error_count} HTML validation errors reported"))
        else
          message_to_report(with_caller('No HTML validation errors reported'))
        end
        message_to_report(with_caller("#{warn_count} HTML validation warnings reported")) if warn_count > 0
        debug_to_log(with_caller("total #{exception_count},", "filtering turned off? #{no_filtering},", " errors #{error_count},",
                                 " warn #{warn_count},", " log #{log_count},", " ignored #{ignored_count}",
                                 " unknown #{unknown_count}"))

        report_results(error_count, with_caller(page))

      rescue
        failed_to_log(unable_to)
      end

      def annotate_html_message(out, location, line, column)
        if location[:script]
          out << " (in script #{line}/#{column})"
        else
          if location[:head]
            out << " (in head)"
            if location[:meta]
              out << " (in meta)"
            end
          end
        end
        if location[:in_frame]
          out << " (in frame)"
        end
        # out << " (in meta)" if in_meta
        # out << " (in body)" if in_body
        if location[:fragment]
          out << " (in fragment)"
        end
      end

      def fetch_html_err_ref(strg)
        ref    = ''
        desc   = nil
        tag    = nil
        anchor = nil
        @html_error_references.each_key do |ptrn|
          begin
            mtch = strg.match(ptrn)
          rescue
            debug_to_report(with_caller("'#{$!}'"))
          end
          if mtch
            ref  = @html_error_references[ptrn][:reference]
            desc = @html_error_references[ptrn][:description]
            tag  = mtch[1] if mtch[1]
            case strg
              when /\s*anchor\s*/
                anchor = mtch[2] if mtch[2]
            end
            break
          end
        end
        [ref, desc, tag, anchor]
      rescue
        failed_to_log(unable_to)
      end

      def format_html_excerpt(line, column, pre_length, post_length, tag)
        # debug_to_log(with_caller(tag))
        if line
          column      = 0 if line.size < post_length
          pre_length  = column if column < pre_length
          pre_excerpt = line.slice(column - pre_length, pre_length)
          pre_excerpt.gsub!(/^\s+/, '')
          post_excerpt = line.slice(column, post_length)
          excerpt      = '['
          excerpt << '...' if (column - pre_length) > 1
          excerpt << pre_excerpt if pre_excerpt
          excerpt << '^'
          excerpt << post_excerpt if post_excerpt
          excerpt << '...' if line.size >= (pre_length + post_length)
          excerpt << ']'
          excerpt.ljust(excerpt.size + 1, ' ')
        else
          debug_to_log("Line for #{tag} is nil")
        end
      rescue
        failed_to_log(unable_to)
      end

      def filter_html_exception?(excp, out, line, validator, location)
        filter    = nil
        action    = nil
        alt_value = nil

        if @html_filters[validator]
          @html_filters[validator].each_key do |key|
            pattern = @html_filters[validator][key][:pattern]
            if excp.match(pattern)
              # msg = build_message('(filtered):', "[id:#{key}]", out, @html_filters[validator][key][:description])

              action = @html_filters[validator][key][:action]

              filter, action, alt_value = html_alt_filter(validator, key, action, line, location)

              case action
                when /ignore|log|warn/i
                  filter = key
                when /fail/i
                  filter = nil
                else
                  debug_to_log(with_caller("Unknown action '#{action}'"))
                  filter = nil
              end
              break
            end
          end
        end
        [filter, action, alt_value]
      rescue
        failed_to_log(unable_to)
      end

      def html_alt_filter(validator, key, action, line, location)
        filter     = key
        alt_action = action
        mtch_value = nil

        if @html_filters[validator][key][:alt_pattern]

          alt_pattern = @html_filters[validator][key][:alt_pattern]
          mtch        = line.match(alt_pattern)
          if mtch
            mtch_value = mtch[1] if mtch[1]
            alt_action = @html_filters[validator][key][:alt_action]
            case alt_action
              when ''
                filter = nil
              when /fail/i
                filter = nil
              when /ignore/i, /warn/i, /log/i
                filter = key
              else
                debug_to_log(with_caller("Unknown alt_action '#{alt_action}'"))
                alt_action = 'warn'
            end

          else
            alt_action = action
            filter     = nil if action =~ /fail/i
          end

        else
          # TODO This hierarchy is over simple.
          # NOTE: Current assumption is that first found wins
          # NOTE: and only one will be set with an action for a given filter
          [:script, :meta, :head, :body, :fragment, :frame].each do |loc|
            if location[loc] and @html_filters[validator][key][loc]
              alt_action = @html_filters[validator][key][loc]
              filter     = nil if alt_action =~ /fail/i
              break
            end
          end
        end

        [filter, alt_action, mtch_value]
      rescue
        failed_to_log(unable_to, 2)
      end

      def html_line_context(html, container)
        in_script   = false
        in_head     = false
        in_meta     = false
        in_body     = false
        in_frame    = false
        in_fragment = false

        line            = 0
        hash            = {}
        container_class = container.class.to_s
        debug_to_log("container class='#{container_class}'")

        case container_class
          when /frame/i
            in_frame = true
          when /browser/i
            in_frame = false
          else
            in_fragment = true
        end
        html.each do |l|
          target = l.dup.strip

          hash[line] = Hash.new

          hash[line][:frame]    = in_frame
          hash[line][:fragment] = in_fragment

          in_script             = true if target.match(/^\s*<script/)
          in_head               = true if target.match(/^\s*<head>/)
          in_meta               = true if target.match(/^\s*<meta/)
          in_body               = true if target.match(/^\s*<body/)

          hash[line][:script] = in_script
          hash[line][:head]   = in_head
          hash[line][:meta]   = in_meta
          hash[line][:body]   = in_body

          in_script           = false if target.match(/^\s*<script.*\/>$/)
          in_script           = false if target.match(/<\/script>$/)
          in_head             = false if target.match(/<\/head>/)
          in_meta             = false if target.match(/<\/meta.*\/>$/)
          in_script           = false if target.match(/<\/meta>$/)
          in_body             = false if target.match(/<\/body/)

          line += 1
        end

        hash
      end

      def text_does_not_equal?(container, ptrn, desc = '', refs = '')
        name = container.respond_to?(:tag_name) ? container.tag_name.titleize : 'DOM'
        msg  = build_message(desc, "#{name} text contains '#{ptrn}'?", refs)
        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end
        if container.respond_to?(:wait)
          container.wait
        elsif container.respond_to?(:wait_until_present)
          container.wait_until_present
        else
          sleep(3)
        end
        if container.text.match(target)
          failed_to_log(msg)
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        failed_to_log(unable_to)
      end

      alias validate_no_text text_does_not_equal?
      alias element_text_does_not_equal? text_does_not_equal?

      def textfield_equals?(browser, how, what, expected, desc = '', refs = '')
        msg    = build_message(desc, "Expected value to equal '#{expected}' in textfield #{how}='#{what}'?", refs)
        actual = browser.text_field(how, what).value
        if actual.is_a?(Array)
          actual = actual[0].to_s
        end
        if actual == expected
          passed_to_log(msg)
          true
        else
          act_s = actual.strip
          exp_s = expected.strip
          if act_s == exp_s
            passed_to_log("#{msg} (stripped)")
            true
          else
            debug_to_report(
                "#{__method__} (spaces underscored):\n "+
                    "expected:[#{expected.gsub(' ', '_')}] (#{expected.length})\n "+
                    "actual:[#{actual.gsub(' ', '_')}] (#{actual.length}) (spaces underscored)"
            )
            failed_to_log("#{msg}. Found: '#{actual}'")
          end
        end
      rescue
        failed_to_log(unable_to("#{how}='#{what}'", false, true))
      end

      alias validate_textfield_value textfield_equals?
      alias text_field_equals? textfield_equals?

      def textfield_contains?(container, how, what, expected, desc = '', refs = '')
        msg      = build_message(desc, "Does text field #{how}='#{what}' contains '#{expected}'?", refs)
        contents = container.text_field(how, what).when_present.value
        if contents =~ /#{expected}/
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Contents: '#{contents}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias text_field_contains? textfield_contains?

      def textfield_empty?(browser, how, what, desc = '', refs = '')
        msg      = build_message(desc, "Text field #{how}='#{what}' is empty?", refs)
        contents = browser.text_field(how, what).value
        if contents.to_s.length == 0
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Contents: '#{contents}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias validate_textfield_empty textfield_empty?
      alias text_field_empty? textfield_empty?

      def existence(container, should_be, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        if should_be
          element_exists?(target, desc, refs, how, what, value)
        else
          element_does_not_exist?(target, desc, refs, how, what, value)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def element_existence(element, should_be, desc = '', refs = '', how = '', what = '')
        should_be = force_boolean(should_be)
        if should_be
          element_exists?(element, desc, refs, how, what, nil)
        else
          element_does_not_exist?(element, desc, refs, how, what, nil)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def exists?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_exists?(target, desc, refs, how, what, value)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_exists?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'exists?', how, what, value, desc, refs)
        if element.exists?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def does_not_exist?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_does_not_exist?(target, value, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_does_not_exist?(element, value = nil, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, 'does not exist?', how, what, value, desc, refs)
        if element.exists?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def presence(container, should_be, element, how, what, value = nil, desc = '', refs = '')
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        if should_be
          element_is_present?(target, desc, refs, how, what, value)
        else
          element_not_present?(target, desc, refs, how, what, value)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def element_presence(element, should_be, desc = '', refs = '', how = '', what = '')
        should_be = force_boolean(should_be)
        if should_be
          element_is_present?(element, desc, refs, how, what, nil)
        else
          element_not_present?(element, desc, refs, how, what, nil)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def is_present?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_is_present?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      def element_is_present?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is_present?', how, what, value, desc, refs)
        if element.present?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_present? element_is_present?

      def not_present?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_present?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      def element_not_present?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is not present?', how, what, value, desc, refs)
        if element.present?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_is_not_present? element_not_present?

      def force_boolean(boolean)
        case boolean
          when true, false
            should_be = boolean
          when /yes/i, /true/i
            should_be = true
          else
            should_be = false
        end
        should_be
      end

      def expected_url?(container, expected, desc = '', refs = '')
        msg = build_message(desc, "Is browser at url #{expected}?", refs)
        if container.url == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Found #{container.url}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_focused?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_focused?(target, how, what, value, desc, refs)
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      alias is_not_focused? not_focused?

      def element_not_focused?(element, how, what, value = nil, desc = '', refs = '')
        msg = element_query_message(element, 'does not have focus?', how, what, value, desc, refs)
        current = element.browser.execute_script("return document.activeElement")
        if element == current
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_is_not_focused? element_not_focused?

      def is_focused?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_focused?(target, how, what, value, desc, refs)
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      def element_focused?(element, how, what, value = nil, desc = '', refs = '')
        msg     = element_query_message(element, 'has focus?', how, what, value, desc, refs)
        current = element.browser.execute_script("return document.activeElement")
        if element == current
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_is_focused? element_focused?

      def visibility(container, boolean, element, how, what, desc = '', refs = '')
        should_be = force_boolean(boolean)
        if should_be
          visible?(container, element, how, what, desc, refs)
        else
          not_visible?(container, element, how, what, desc, refs)
        end
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      def visible?(container, element, how, what, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_visible?(target, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      def element_visible?(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, 'is visible?', how, what, nil, desc, refs)
        if element.visible?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_visible?(container, element, how, what, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_not_visible?(target, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      def element_not_visible?(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, 'is not visible?', how, what, nil, desc, refs)
        if element.visible?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def disablement(container, boolean, element, how, what, desc = '', refs = '')
        should_be = force_boolean(boolean)
        if should_be
          disabled?(container, element, how, what, desc, nil, refs)
        else
          enabled?(container, element, how, what, desc, nil, refs)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def disabled?(container, element, how, what, desc = '', value = nil, refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_disabled?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      def element_disabled?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is disabled?', how, what, value, desc, refs)
        element_wait(element)
        if element.respond_to?(:disabled?)
          if element.disabled?
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log(build_message("#{element} does not respond to .disabled?"), msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_disabled?(container, element, how, what, desc = '', value = nil, refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_disabled?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      alias enabled? not_disabled?

      def element_not_disabled?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is enabled?', how, what, value, desc, refs)
        element_wait(element)
        if element.disabled?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_enabled? element_not_disabled?

      def element_disablement(target, disabled, desc = '', refs = '')
        #TODO: Is this really necessary?
        is_disabled = target.disabled?
        disablement = false
        should_be   = disabled ? true : false
        msg         = build_message(desc, "(in #{method_to_title(__method__)})", "should be #{should_be}", "is #{is_disabled}", refs)
        if should_be == is_disabled
          passed_to_log(msg)
          disablement = true
        else
          failed_to_log(msg)
        end
        [is_disabled, disablement]
      rescue
        rescue_msg_for_validation(msg)
      end

      def pixels_do_not_equal?(container, element, how, what, style, expected, desc = '', refs = '', rounding = 'up')
        code   = build_webdriver_fetch(element, how, what)
        actual = eval("#{code}.style('#{style}')")

        if actual =~ /px$/
          expected = expected.to_s + 'px'
        else
          case rounding
            when 'ceil', 'up'
              actual = actual.to_f.ceil
            when 'down', 'floor'
              actual = actual.to_f.floor
            else
              actual = actual.to_f.round
          end
        end

        msg = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "pixel size '#{style}",
                            "equals '#{expected}' (with rounding #{rounding})?", refs)

        if actual == expected
          failed_to_log("#{msg} Found '#{actual}'")
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias pixels_not_equal? pixels_do_not_equal?

      def pixels_equal?(container, element, how, what, style, expected, desc = '', refs = '', rounding = 'up')
        code   = build_webdriver_fetch(element, how, what)
        actual = eval("#{code}.style('#{style}')")

        if actual =~ /px$/
          expected = expected.to_s + 'px'
        else
          case rounding
            when 'ceil', 'up'
              actual = actual.to_f.ceil
            when 'down', 'floor'
              actual = actual.to_f.floor
            else
              actual = actual.to_f.round
          end
        end

        msg = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{style}",
                            "equals '#{expected}' (with rounding #{rounding})?", refs)

        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Found '#{actual}'")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def style_does_not_contain?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_style_does_not_contain?(target, style, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, style), false, true))
      end

      def element_style_does_not_contain?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, "style '#{style}' does not contain '#{expected}'?", how, what, nil, desc, refs)
        element_wait(element)
        if element.style(style).match(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def style_contains?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_style_contains?(target, style, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, style), false, true))
      end

      def element_style_contains?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, "style '#{style}' contains '#{expected}'?", how, what, nil, desc, refs)
        element_wait(element)
        if element.style(style).match(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}. Found '#{element.class_name}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def style_does_not_equal?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")

        element_style_does_not_equal?(target, style, expected, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias color_not_equal? style_does_not_equal?
      alias style_not_equal? style_does_not_equal?
      alias color_does_not_equal? style_does_not_equal?

      def element_style_does_not_equal?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg           = element_query_message(element, "style '#{style}' does not equal '#{expected}'?", how, what, nil, desc, refs)
        actual        = element.style(style)
        actual_norm   = style =~ /color/ ? normalize_color_value(actual) : actual
        expected_norm = style =~ /color/ ? normalize_color_value(expected) : expected

        if actual
          if actual_norm == expected_norm
            failed_to_log(msg)
          else
            found = style =~ /color/ ? "#{rgb_to_html(actual).upcase} (#{actual_norm})" : "#{actual}"
            passed_to_log("#{msg}. Found #{found}")
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_color_does_not_equal? element_style_does_not_equal?
      alias element_color_not_equal? element_style_does_not_equal?
      alias element_style_not_equal? element_style_does_not_equal?

      def style_equals?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_style_equals?(target, style, expected, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias color_equals? style_equals?

      def element_style_equals?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg           = element_query_message(element, "style '#{style}' equals '#{expected}'?", how, what, nil, desc, refs)
        actual        = element.style(style)
        actual        = element.attribute_value(style) unless actual and actual.length > 0
        actual_norm   = style =~ /color/ ? normalize_color_value(actual) : actual
        expected_norm = style =~ /color/ ? normalize_color_value(expected) : expected

        # if style =~ /color/
        #   debug_to_log(with_caller("'#{style}'", "actual:   raw: '" + actual + "'  normalized: '" + actual_norm + "'"))
        #   debug_to_log(with_caller("'#{style}'", "expected: raw: '" + expected + "'  normalized: '" + expected_norm + "'"))
        # end

        if actual and actual.length > 0
          if actual_norm == expected_norm
            passed_to_log(msg)
            true
          else
            found = style =~ /color/ ? "#{rgb_to_html(actual)} (#{actual_norm})" : "#{actual}"
            failed_to_log("#{msg}. Found #{found}")
          end
        else
          failed_to_log("#{msg} '#{style}' not found.")
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_color_equals? element_style_equals?

      def border_colors_equal?(container, element, how, what, desc, refs, *colors)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_border_colors_equal?(target, how, what, desc, refs, *colors)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_border_colors_equal?(element, how, what, desc, refs, *colors)
        msg    = element_query_message(element, "Border colors are '#{colors}'?", how, what, nil, desc, refs)
        errors = 0
        errs   = []

        sides = ['top', 'bottom', 'left', 'right']
        sides.each do |side|
          idx      = sides.index(side)
          color    = colors[idx] ? colors[idx] : colors[0]
          expected = normalize_color_value(color)
          actual   = normalize_color_value(element.style("border-#{side}-color"))
          unless actual == expected
            errors += 1
            errs << "#{side}:#{actual}"
          end
        end

        if errors == 0
          passed_to_log(with_caller(msg, desc, refs))
          true
        else
          failed_to_log(with_caller(msg, "Found #{nice_array(errs)}"))
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      def border_sizes_equal?(container, element, how, what, attribute, desc, refs, *pixels)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_border_sizes_equal?(target, how, what, attribute, desc, refs, *pixels)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_border_sizes_equal?(element, how, what, attribute, desc, refs, *pixels)
        attribute = attribute.downcase.gsub(/s$/, '')
        errors    = 0

        sides = ['top', 'bottom', 'left', 'right']

        sides.each do |side|
          msg      = element_query_message(element, "#{attribute}-#{side} equals '#{pixels}'?", how, what, nil, desc, refs)
          idx      = sides.index(side)
          value    = pixels[idx] ? pixels[idx] : pixels[0]
          expected = value =~ /px$/ ? value.to_s : "#{value}px"
          actual   = element.style("#{attribute}-#{side}")
          if actual == expected
            passed_to_log(msg)
          else
            failed_to_log(msg)
            errors += 1
          end
        end

        errors == 0

      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def margins_equal?(container, element, how, what, desc, refs, *pixels)
        border_sizes_equal?(container, element, how, what, 'margins', desc, refs, *pixels)
      end

      def borders_equal?(container, element, how, what, desc, refs, *pixels)
        border_sizes_equal?(container, element, how, what, 'borders', desc, refs, *pixels)
      end

      def padding_equal?(container, element, how, what, desc, refs, *pixels)
        border_sizes_equal?(container, element, how, what, 'padding', desc, refs, *pixels)
      end

      def select_list_includes?(browser, how, what, which, option, desc = '', refs = '')
        msg         = build_message(desc, "Select list #{how}='#{what}' includes option with #{which}='#{option}'?", refs)
        select_list = browser.select_list(how, what)
        options     = select_list.options
        case which
          when :text
            found = false
            options.each do |opt|
              if opt.text == option
                found = true
                break
              end
            end
            if found
              passed_to_log(msg)
              true
            else
              failed_to_log(msg)
            end
          else
            if options.include?(option)
              passed_to_log(msg)
              true
            else
              failed_to_log(msg)
            end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def select_list_does_not_include?(browser, how, what, which, option, desc = '', refs = '')
        msg         = build_message(desc, "Select list #{how}='#{what}' does not include option with #{which}='#{option}'?", refs)
        select_list = browser.select_list(how, what)
        options     = select_list.options
        case which
          when :text
            found = false
            options.each do |opt|
              if opt.text == option
                found = true
                break
              end
            end
            if found
              failed_to_log(msg)
            else
              passed_to_log(msg)
              true
            end
          else
            if options.include?(option)
              failed_to_log(msg)
            else
              passed_to_log(msg)
              true
            end
        end
      rescue
        failed_to_log("Unable to verify #{msg}. '#{$!}'")
      end

      def validate_selected_options(browser, how, what, list, desc = '', refs = '', which = :text)
        selected_options = browser.select_list(how, what).selected_options.dup
        selected         = extract_selected(selected_options, which)
        sorted_list      = list.dup.sort
        if list.is_a?(Array)
          msg = build_message(desc, "Expected options [#{list.sort}] are selected by #{which} [#{selected}]?", refs)
          if selected == sorted_list
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          if selected.length == 1
            msg      = build_message(desc, "Expected option [#{list}] was selected by #{which}?", refs)
            esc_list = Regexp.escape(list)
            if selected[0] =~ /#{esc_list}/
              passed_to_log(msg)
              true
            else
              failed_to_log("#{msg} Found [#{selected}]. #{desc}")
            end
          else
            msg = build_message(desc, "Expected option [#{list}] was found among multiple selections by #{which} [#{selected}]?", refs)
            if selected.include?(list)
              failed_to_log(msg)
            else
              failed_to_log(msg)
            end
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      def verify_attribute(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = element_query_message(element, "#{attribute} equals '#{expected}'?", how, what, nil, desc, refs)
        actual = get_attribute_value(container, element, how, what, attribute, desc)
        if actual == expected
          passed_to_log(msg)
        else
          failed_to_log("#{msg} Found '#{actual}'")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      alias validate_attribute_value verify_attribute
      alias verify_attribute_value verify_attribute

    end

    module UserInput

      def focus(container, element, how, what, desc = '', refs = '', wait = 10)
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}.when_present(#{wait})")
        focus_element(target, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(msg))
      end

      def focus_element(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, "Set focus on", how, what, nil, desc, refs)
        element.focus
        if element.focused?
          passed_to_log(with_caller(msg))
          true
        else
          failed_to_log(with_caller(msg))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def blur_element(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, "Trigger blur", how, what, nil, desc, refs)
        element.fire_event('onBlur')
        if element.focused?
          passed_to_log(with_caller(msg))
          true
        else
          failed_to_log(with_caller(msg))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def clear(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        msg                        = element_action_message(element, "Clear", how, what, value, desc, refs)
        code                       = build_webdriver_fetch(element, how, what, options)
        eval("#{code}.clear")
        cleared = false
        case element
          when :text_field, :textfield
            cleared = eval("#{code}.value == ''")
          when :text_area, :textarea
            cleared = eval("#{code}.value == ''")
          when :checkbox, :radio
            cleared != eval("#{code}.set?")
        end
        if cleared
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def click(container, element, how, what, desc = '', refs = '', wait = 10)
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}.when_present(#{wait})")
        click_element(target, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_message(desc, "#{element.to_s.upcase} :#{how}=>'#{what}'", refs)))
      end

      alias click_js click

      def click_element(element, desc = '', refs = '', how = '', what = '')
        msg = element_action_message(element, "Click", how, what, nil, desc, refs)
        begin
          element.click
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(element, how, what, __method__.to_s))
            raise e
          end
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      alias element_click click_element

      def click_as_needed(browser, target_container, target_elem, target_how, target_what,
                          confirm_container, confirm_elem, confirm_how, confirm_what,
                          desc = '', neg = false, alternate = false, limit = 6.0, increment = 0.5, interval = 2.0)
        rtrn = true
        nope = neg ? 'not ' : ''

        debug_to_log("#{__method__.to_s.titleize}: Target:  :#{target_elem} :#{target_how}='#{target_what}' in #{target_container}")
        debug_to_log("#{__method__.to_s.titleize}: Confirm: :#{confirm_elem} :#{confirm_how}='#{confirm_what}' in #{confirm_container}")
        windows_to_log(browser)
        click(target_container, target_elem, target_how, target_what, desc)
        last_action = 'click'

        if confirm_elem == :window
          query = 'current?'
        else
          query = 'present?'
        end

        if confirm_what.is_a?(Regexp)
          code = "#{nope}confirm_container.#{confirm_elem.to_s}(:#{confirm_how}, /#{confirm_what}/).#{query}"
        else
          code = "#{nope}confirm_container.#{confirm_elem.to_s}(:#{confirm_how}, '#{confirm_what}').#{query}"
        end
        debug_to_log("#{__method__}: code=[#{code}]")

        seconds = 0.0
        until eval(code) do
          debug_to_log("#{__method__}: seconds=[#{seconds}] [#{code}]")
          sleep(increment)
          seconds += increment
          if seconds > limit
            rtrn = false
            break
          end
          if seconds.modulo(interval) == 0.0
            if alternate
              if last_action == 'click'
                fire_event(target_container, target_elem, target_how, target_what, 'onclick', "#{desc} (#{seconds} seconds)")
                last_action = 'fire'
              else
                click(target_container, target_elem, target_how, target_what, "#{desc} (#{seconds} seconds)")
                last_action = 'click'
              end
            else
              click(target_container, target_elem, target_how, target_what, "#{desc} (#{seconds} seconds)")
            end
          end
        end
        unless rtrn
          focus(browser, target_elem, target_how, target_what)
          sleep(0.1)
          send_a_key(browser, :enter)
          sleep(interval)
          rtrn = eval(code)
        end
        rtrn
      rescue
        failed_to_log(unable_to)
      end

      def fire_event(container, element, how, what, event, desc = '', refs = '', wait = 10)
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}.when_present(#{wait})")
        element_fire_event(target, event, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, event)))
      end

      def element_fire_event(element, event, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, "Fire '#{event}' event on", how, what, nil, desc, refs)
        begin
          element.fire_event(event)
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(element, how, what, __method__.to_s, event))
            raise e
          end
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      def set(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval("#{code}")
        #TODO: Fix this!
        set_element(target, value, desc, refs, how, what)
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def set_element(element, value = nil, desc = '', refs = '', how = '', what = '')
        msg = element_action_message(element, "Set", how, what, nil, desc, refs)
        case element.class.to_s
          when /radio/i, /checkbox/i
            element.set
            passed_to_log(msg)
            true
          when /text_field|textfield|text_area|textarea/i
            element_set_text(element, value, desc, refs, how, what)
          else
            failed_to_log(with_caller(desc, "#{element} not supported", refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def element_set_text(element, value, desc = '', refs = '', how = '', what = '')
        msg = element_action_message(element, "Set to '#{value}':", how, what, nil, desc, refs)
        element.when_present.set(value)
        if element.value == value
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}: Found:'#{element.value}'.")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def set_text_field(browser, how, what, value, desc = '', refs = '', skip_value_check = false)
        #TODO: fix this to handle Safari password field
        msg = build_message(desc, with_caller("#{how}='#{what}' to '#{value}'"), refs)
        msg << ' (Skip value check)' if skip_value_check
        browser.text_field(how, what).when_present.set(value)
        if skip_value_check
          passed_to_log(msg)
          true
        else
          if browser.text_field(how, what).value == value
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg}: Found:'#{browser.text_field(how, what).value}'.")
          end
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def select_option(browser, how, what, which, option, desc = '', refs = '', nofail = false)
        list = browser.select_list(how, what).when_present
        msg  = build_message(desc, with_caller("from list with :#{how}='#{what}"))
        select_option_from_list(list, which, option, msg, refs, nofail)
      rescue
        failed_to_log(unable_to)
      end

      def select_next_option_from_list(list, desc = '', refs = '')
        msg            = build_message(desc, refs)
        options        = list.options
        #This doesnt seem to account for the last option already being selected. ex. calendar with dec selected
        selected_index = list.selected_options[0].index
        if selected_index == options.length - 1
          new_index = 0
        else
          new_index = options[selected_index + 1] ? selected_index + 1 : 0
        end

        select_option_from_list(list, :index, new_index, with_caller(desc), refs)
      rescue
        failed_to_log(unable_to(msg))
      end

      def select_option_from_list(list, how, what, desc = '', refs = '', nofail = false)
        msg = build_message(desc, "Select option :#{how}='#{what}'", refs)
        ok  = true
        if list
          case how
            when :text
              list.select(what) #TODO: regex?
            when :value
              list.select_value(what) #TODO: regex?
            when :index
              list.option(:index, what.to_i).select
            else
              failed_to_log("#{msg}  Select by #{how} not supported.")
              ok = false
          end
          if ok
            passed_to_log(msg)
            true
          else
            if nofail
              passed_to_log("#{msg} Option not found. No Fail specified.")
              true
            else
              failed_to_log("#{msg} Option not found.")
            end
          end
        else
          failed_to_log("#{msg} Select list not found.")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def option_selected?(container, how, what, which, option, desc = '', refs = '')
        list = container.select_list(how, what).when_present
        msg  = build_message(desc, with_caller("from list with :#{how}='#{what}"))
        option_selected_from_list?(list, which, option, desc, refs)
      rescue
        failed_to_log(unable_to(msg))
      end

      def option_selected_from_list?(list, which, what, desc = '', refs = '')
        msg = build_message(desc, "Option :#{which}='#{what}' is selected?", refs)
        if list.option(which, what).selected?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def resize_browser_window(browser, width, height, move_to_origin = true)
        msg = "#{__method__.to_s.humanize} to (#{width}, #{height})"
        #browser = browser.browser if browser.respond_to?(:tag_name)
        browser.browser.driver.manage.window.resize_to(width, height)
        sleep(0.5)
        if move_to_origin
          browser.browser.driver.manage.window.move_to(0, 0)
          msg << ' and move to origin (0, 0).'
        end
        #scroll_to_top(browser)
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      alias resize_window resize_browser_window

      def tab_until_focused(container, element, how, what, class_strg = nil, desc = '', refs = '', limit = 15)
        ok     = nil
        msg    = build_message('Tab to set focus on', "#{element.to_s.upcase}", "#{how}='#{what}'", refs)
        target = get_element(container, element, how, what, nil, with_caller(desc, "(#{limit})"), refs)
        count  = 0
        (0..limit).each do |cnt|
          #debug_to_log("tab #{cnt}")
          if class_strg
            if target.class_name.include?(class_strg)
              passed_to_log(with_caller(msg, "(#{cnt} tabs)"))
              ok = true
              break
            end
          else
            if target.focused?
              passed_to_log(with_caller(msg, "(#{cnt} tabs)"))
              ok = true
              break
            end
          end
          container.send_keys(:tab)
          count = cnt
          #send_tab(container)
        end
        failed_to_log(unable_to(msg, "(#{count} tabs)")) unless ok
        ok
      rescue
        failed_to_log(unable_to)
      end

      def type_in_text_field(element, strg, desc = '', refs = '')
        msg = build_message(desc, "Type (send_keys) '#{strg}' into text field :id=>'#{element.attribute_value('id')}'", refs)
        element.send_keys(strg)
        if element.value == strg
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def send_a_key(browser, key, modifier = nil, desc = '', refs = '')
        if modifier
          msg = build_message(desc, "Sent #{modifier}+#{key}", refs)
          browser.send_keys [modifier, key]
        else
          msg = build_message(desc, "Sent #{key}", refs)
          browser.send_keys key
        end
        message_to_report(msg)
      end

      def send_page_down(browser)
        send_a_key(browser, :page_down)
      end

      alias press_page_down send_page_down

      def sent_page_up(browser)
        send_a_key(browser, :page_up)
      end

      alias press_page_up sent_page_up

      def send_spacebar(browser)
        send_a_key(browser, :space)
      end

      alias press_spacebar send_spacebar
      alias press_space send_spacebar
      alias send_space send_spacebar

      def send_enter(browser)
        send_a_key(browser, :enter)
      end

      alias press_enter send_enter

      def send_tab(browser, modifier = nil)
        send_a_key(browser, :tab, modifier)
      end

      alias press_tab send_tab

      def send_up_arrow(browser)
        send_a_key(browser, :arrow_up)
      end

      alias press_up_arrow send_up_arrow

      def send_down_arrow(browser)
        send_a_key(browser, :arrow_down)
      end

      alias press_down_arrow send_down_arrow

      def send_right_arrow(browser)
        send_a_key(browser, :arrow_right)
      end

      alias press_right_arrow send_right_arrow

      def send_left_arrow(browser)
        send_a_key(browser, :arrow_left)
      end

      alias press_left_arrow send_left_arrow

      def send_escape(browser)
        send_a_key(browser, :escape)
      end

      alias press_escape send_escape

    end

    module DragAndDrop

      def remove_focus(container, element, desc = '', refs = '', tab_twice = false)
        msg = build_message(desc, refs)
        ok  = true
        if element.focused?
          debug_to_log('element has focus')
          element.fire_event('onblur')
          debug_to_log("Fired 'onblur' event")
          which = :blur
          if element.focused?
            container.send_keys(:tab)
            debug_to_log("Sent tab")
            which = :tab
            if tab_twice
              container.send_keys(:tab)
              debug_to_log("Sent second tab")
              which = :tab
            end
            if element.focused?
              container.send_keys(:enter)
              debug_to_log("Sent enter")
              which = :enter
            end
          end
          if element.focused?
            failed_to_log(unable_to(msg))
            which = :fail
            ok    = false
          else
            passed_to_log(with_caller("#{element.tag_name}", msg))
          end
        else
          debug_to_log('Element does not have focus to remove.')
          which = :already
        end
        begin
          if @focus_moves
            @focus_moves[:remove][which] += 1
            if which == :tab and tab_twice
              @focus_moves[:remove][which] += 1
            end
          end
        rescue
          debug_to_log(with_caller("'#{$!}'", msg))
        end
        ok
      rescue
        failed_to_log(unable_to(msg))
      end

      def return_focus(container, element, desc = '', refs = '')
        msg = build_message(desc, refs)
        ok  = true
        if element.focused?
          debug_to_log('Element already has focus.')
          which = :already
        else
          element.fire_event('onclick')
          debug_to_log("Fired 'onclick' event")
          which = :onclick
          unless element.focused?
            element.fire_event('onfocus')
            debug_to_log("Fired 'onfocus' event")
            which = :onfocus
            unless element.focused?
              element.focus
              debug_to_log("Called focus method")
              which = :focus
              unless element.focused?
                element.click
                debug_to_log("Called click method")
                which = :click
                unless element.focused?
                  container.send_keys([:shift, :tab])
                  debug_to_log("Sent shift tab")
                  which = :shift_tab
                end
              end
            end
          end
          if element.focused?
            passed_to_log(with_caller("#{element.tag_name}", msg))
          else
            failed_to_log(unable_to(msg))
            which = :fail
            ok    = false
          end
        end
        begin
          @focus_moves[:remove][which] += 1 if @focus_moves
        rescue
          debug_to_log(with_caller("'#{$!}'", msg))
        end
        ok
      rescue
        failed_to_log(unable_to(msg))
      end

      #TODO: needs work: should succeed if browser is other container or element
      def get_browser_coord(browser, dbg=nil)
        title = browser.title
        x, y  = browser.position
        w, h  = browser.size
        if dbg
          debug_to_log("\n\t\tBrowser #{browser.inspect}\n"+
                           "\t\tdimensions:   x: #{w} y: #{h}"+
                           "\t\tscreen offset x: #{x} y: #{y}")
        end
        [x, y, w, h]
      end

      def get_element_screen_coordinates(browser, element, dbg = nil)
        hash                            = Hash.new
        bx, by                          = browser.position
        ox, oy                          = window_viewport_offsets(browser)
        rect                            = element.bounding_client_rectangle
        w                               = rect['width']
        h                               = rect['height']
        hash['width']                   = w
        hash['height']                  = h
        xc                              = rect['left']
        yc                              = rect['top']
        xcc                             = xc + w/2
        ycc                             = yc + h/2
        # screen offset:
        xs                              = bx + ox + xc - 1
        ys                              = by + oy + yc - 1
        hash['left']                    = xs
        hash['top']                     = ys
        # screen center:
        xsc                             = xs + w/2
        ysc                             = ys + h/2
        hash['screen_center_left']      = xsc
        hash['screen_center_top']       = ysc
        xslr                            = xs + w
        yslr                            = ys + h
        hash['screen_lower_right_left'] = xslr
        hash['screen_lower_right_top']  = xs
        if dbg
          debug_to_log(
              "\n\t\tElement: #{element.inspect}"+
                  "\n\t\tbrowser screen offset: x: #{bx} y: #{by}"+
                  "\n\t\t           dimensions: x: #{w} y: #{h}"+
                  "\n\t\t         client offset x: #{xc} y: #{yc}"+
                  "\n\t\t         screen offset x: #{xs} y: #{ys}"+
                  "\n\t\t         client center x: #{xcc} y: #{ycc}"+
                  "\n\t\t         screen center x: #{xsc} y: #{ysc}"+
                  "\n\t\t    screen lower right x: #{xslr} y: #{yslr}")
        end
        hash
      end

      def viewport_size(browser, use_body = false)
        browser = browser.browser if browser.respond_to?(:tag_name)
        if @targetBrowser.abbrev == 'IE' and @browserVersion.to_i < 9
          x, y = insert_viewport_div(browser)
        else
          if use_body
            x = browser.body.attribute_value('clientWidth')
            y = browser.body.attribute_value('clientHeight')
          else
            x = browser.execute_script("return window.innerWidth")
            y = browser.execute_script("return window.innerHeight")
          end
        end

        [x, y]

      rescue => e
        unless rescue_me(e, __method__, "#{__method__}(browser, #{use_body})")
          raise e
        end
      end

      def screen_size(browser)
        [browser.execute_script('return screen.width'),
         browser.execute_script('return screen.height')]
      rescue => e
        unless rescue_me(e, __method__, "#{__method__}(browser)")
          raise e
        end
      end

      def screen_available_size(browser)
        [browser.execute_script('return screen.availWidth'),
         browser.execute_script('return screen.availHeight')]
      rescue => e
        unless rescue_me(e, __method__, "#{__method__}(browser)")
          raise e
        end
      end

      def insert_viewport_div(browser)
        browser.execute_script(
            'var test = document.createElement( "div" );' +
                'test.style.cssText = "position: fixed;top: 0;left: 0;bottom: 0;right: 0;"; ' +
                'test.id = "awetest-temp-viewport"; ' +
                'document.documentElement.insertBefore( test, document.documentElement.firstChild ); '
        )
        viewport = browser.div(:id, 'awetest-temp-viewport')
        x        = browser.execute_script("return arguments[0].offsetWidth", viewport)
        y        = browser.execute_script("return arguments[0].offsetHeight", viewport)
        browser.execute_script("document.documentElement.removeChild( arguments[0] )", viewport)
        [x, y]
      end

      def scroll_into_view(container, element, how, what, desc = '', refs = '', options = {})
        msg   = build_message(desc, "#{__method__.to_s.humanize} :#{element.to_s.upcase} :#{how}='#{what}'", refs)
        code  = build_webdriver_fetch(element, how, what, options)
        point = eval("#{code}.when_present.wd.location_once_scrolled_into_view")
        if point
          passed_to_log(msg)
          [point.x, point.y]
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def scroll_element_into_view(element, desc = '', refs = '')
        msg   = build_message(desc, "#{__method__.to_s.humanize}", refs)
        point = element.wd.location_once_scrolled_into_view
        if point
          passed_to_log(msg)
          [point.x, point.y]
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(desc))
      end

      def scroll_to(browser, param, desc = '', refs = '')
        ok = true
        case param
          when Array
            what = nice_array(param)
          when param.respond_to?(:tag_name)
            what = translate_tag_name(param)
          else
            what = "#{param}"
        end

        #Thanks to Alex Rodionov (p0deje)
        args = case param
                 when :top, :start
                   'window.scrollTo(0, 0);'
                 when :center
                   'window.scrollTo(document.body.scrollWidth / 2, document.body.scrollHeight / 2);'
                 when :bottom, :end
                   'window.scrollTo(0, document.body.scrollHeight);'
                 when Watir::Element, Watir::WhenPresentDecorator
                   ['arguments[0].scrollIntoView();', param]
                 when Array
                   ['window.scrollTo(arguments[0], arguments[1]);', Integer(param[0]), Integer(param[1])]
                 else
                   if param.respond_to?(:tag_name)
                     target = param.element
                     ['arguments[0].scrollIntoView();', target]
                   else
                     failed_to_log(build_message(with_caller(desc, what), refs, "Don't know how to scroll to: #{param.to_s}!"))
                     ok = false
                   end
               end

        if ok
          browser.execute_script(*args)
        end
        ok
      rescue
        failed_to_log(unable_to(build_message(desc, what, refs)))
      end

      def scroll_in_element(element, direction, amount)
        js     = 'return arguments[0].scroll@@@ = arguments[1];",EEEEE, PPPPP'
        ortho  = ''
        pixels = amount
        case direction
          when :up
            ortho = 'Top'
          when :down
            ortho  = 'Top'
            pixels = -amount
          when :left
            ortho = 'Left'
          when :right
            ortho  = 'Left'
            pixels = -amount
          else
            failed_to_log(with_caller("Invalid direction '#{direction}'"))
        end
        element.browser.execute_script("return arguments[0].scroll#{ortho} = arguments[1];\"", element, pixels)

          # Scroll inside web element vertically (e.g. 100 pixel)
          # js.executeScript("arguments[0].scrollTop = arguments[1];",driver.findElement(By.id("<div-id>")), 100);

          # eula = dr.find_element_by_id('eulaFrame')
          # dr.execute_script('arguments[0].scrollTop = arguments[0].scrollHeight', eula)

          # JavascriptExecutor jse = (JavascriptExecutor) localDriver;
          # //locate web element you need for scroll and its height
          #                               WebElement element = localDriver.findElement(By.id("DIV_element"));
          #                               String blockHeight = "return arguments[0].offsetHeight";
          #
          #                               String myscript = "arguments[0].scrollTop"+jse.executeScript(blockHeight,element);
          #
          #                               element.click();
          #                               pause(100);
          #                               jse.executeScript(myscript, element);

          # If you want to scroll inner div element, not window you can try this below code:
          #                                                                                //Get div element having scroll bar you want to do
          #   WebElement scrollArea = driver.findElement(By.xpath("//"));
          #   // Initialize Javascript executor
          #   JavascriptExecutor js = (JavascriptExecutor) driver;
          #   // Scroll inside web element vertically (e.g. 1000 pixel)
          #   js.executeScript("arguments[0].scrollTop = arguments[1];",scrollArea, 1000);
          #   Thread.sleep(1000);
          #   // do something (ex. choose an item in list ...)
          #   Good luck! hihi
      rescue
        failed_to_log(unable_to(ortho, pixels))
      end

      def window_viewport_offsets(browser)
        x = 0
        y = 0

        if $mobile
          debug_to_log(with_caller("Not supported for mobile browsers"))
        else
          browser = browser.browser if browser.respond_to?(:tag_name)
          wd_dim  = browser.window.size
          vp_dim  = viewport_size(browser)
          x       = (wd_dim.width - vp_dim[0])
          y       = (wd_dim.height - vp_dim[1])
          y       += 1 if @targetBrowser.abbrev == 'FF'
        end

        [x, y]
      rescue
        failed_to_log(unable_to)
      end

      def window_dimensions(browser)
        browser = browser.browser if browser.respond_to?(:tag_name)
        wd_dim  = browser.window.size
        wd_pos  = browser.window.position
        vp_dim  = viewport_size(browser)
        off_x   = (wd_dim.width - vp_dim[0])
        off_y   = (wd_dim.height - vp_dim[1])
        off_y   += 1 if @targetBrowser.abbrev == 'FF'

        just_inside_x = wd_pos.x + wd_dim.width - off_x - 3
        just_inside_y = wd_pos.y + off_x + 3

        debug_to_log(with_caller("\nposition: [#{wd_pos.x},#{wd_pos.y}]",
                                 "\nsize:     [#{wd_dim.width},#{wd_dim.height}] ",
                                 "\nviewport: [#{vp_dim[0]},#{vp_dim[1]}]",
                                 "\noffsets:  [#{off_x},#{off_y}]",
                                 "\njust_inside: [#{just_inside_x},#{just_inside_y}]"
                     ))
        [wd_pos.x, wd_pos.y,
         wd_dim.width, wd_dim.height,
         vp_dim[0], vp_dim[1],
         off_x, off_y,
         just_inside_x, just_inside_y]
      rescue
        failed_to_log(unable_to)
      end

      def mouse_to_browser_edge(container, offset_x = -3, offset_y = -3)
        x, y = window_dimensions(container)[4, 2]
        container.driver.mouse.move_to(container.driver[:tag_name => 'body'], x - offset_x, y - offset_y)
      end

      def set_viewport_size(browser, width, height, diff = nil, move_to_origin = true, use_body = false, desc = '', refs = '')
        if $mobile
          debug_to_log(with_caller("Not supported for mobile browsers"))
        else
          diff = window_viewport_offsets(browser.browser) unless diff
          resize_browser_window(browser.browser, width + diff[0], height + diff[1], move_to_origin)
          sleep(0.5)
          msg          = build_message(desc, "viewport (#{width}, #{height})",
                                       "(offsets (#{diff[0]}, #{diff[1]}))")
          act_x, act_y = viewport_size(browser.browser, use_body)
          if width == act_x.to_i and height == act_y.to_i
            if @targetBrowser.abbrev == 'FF'
              debug_to_log(with_caller(msg, refs))
            else
              passed_to_log(with_caller(msg, refs))
            end
            true
          else
            if @targetBrowser.abbrev == 'FF'
              debug_to_report(with_caller(msg, "Found (#{act_x}, #{act_y})", refs))
            else
              failed_to_log(with_caller(msg, "Found (#{act_x}, #{act_y})", refs))
            end
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      # @deprecated
      def get_viewport_to_win_diff(browser)
        window_viewport_offsets(browser)[0]
      end

      def overlay?(inner, outer, side = :bottom)
        i_dims = inner.bounding_client_rectangle
        o_dims = outer.bounding_client_rectangle
        case side
          when :bottom
            overlay = i_dims['bottom'] > o_dims['top']
          when :top
            overlay = i_dims['top'] > o_dims['top']
          when :left
            overlay = i_dims['left'] > o_dims['right']
          when :right
            overlay = i_dims['right'] > o_dims['right']
          when :inside
            overlay =
                !(i_dims['top'] > o_dims['top'] and
                    i_dims['right'] < o_dims['right'] and
                    i_dims['left'] > o_dims['left'] and
                    i_dims['bottom'] < o_dims['bottom']
                )
          else
            overlay =
                (i_dims['top'] > o_dims['bottom'] or
                    i_dims['right'] < o_dims['left'] or
                    i_dims['left'] > o_dims['right'] or
                    i_dims['bottom'] < o_dims['top']
                )
        end
        overlay
      rescue
        failed_to_log("Unable to determine overlay. '#{$!}'")
      end

      def get_element_dimensions(container, element, desc = '', refs = '')
        hash                = Hash.new
        #hash[:text]         = element.text
        #hash[:unit]         = element
        hash[:clientLeft]   = element.attribute_value('clientLeft')
        hash[:clientTop]    = element.attribute_value('clientTop')
        hash[:clientWidth]  = element.attribute_value('clientWidth')
        hash[:clientHeight] = element.attribute_value('clientHeight')
        #hash[:offsetParent] = element.attribute_value('offsetParent')
        hash[:offsetLeft]   = element.attribute_value('offsetLeft')
        hash[:offsetTop]    = element.attribute_value('offsetTop')
        hash[:offsetWidth]  = element.attribute_value('offsetWidth')
        hash[:offsetHeight] = element.attribute_value('offsetHeight')
        hash[:scrollLeft]   = element.attribute_value('scrollLeft')
        hash[:scrollTop]    = element.attribute_value('scrollTop')
        hash[:scrollWidth]  = element.attribute_value('scrollWidth')
        hash[:scrollHeight] = element.attribute_value('scrollHeight')
        if desc.length > 0
          debug_to_log("#{desc} #{refs}\n#{hash.to_yaml}")
        end
        hash
      rescue
        failed_to_log(unable_to)
      end

      def get_element_dimensions1(container, element, desc = '', refs = '')
        hash                = Hash.new
        #hash[:text]         = element.text
        #hash[:unit]         = element
        hash[:clientLeft]   = container.execute_script("return arguments[0].clientLeft", element)
        hash[:clientTop]    = container.execute_script("return arguments[0].clientTop", element)
        hash[:clientWidth]  = container.execute_script("return arguments[0].clientWidth", element)
        hash[:clientHeight] = container.execute_script("return arguments[0].clientHeight", element)
        #hash[:offsetParent] = container.execute_script("return arguments[0].offsetParent", element)
        hash[:offsetLeft]   = container.execute_script("return arguments[0].offsetLeft", element)
        hash[:offsetTop]    = container.execute_script("return arguments[0].offsetTop", element)
        hash[:offsetWidth]  = container.execute_script("return arguments[0].offsetWidth", element)
        hash[:offsetHeight] = container.execute_script("return arguments[0].offsetHeight", element)
        hash[:scrollLeft]   = container.execute_script("return arguments[0].scrollLeft", element)
        hash[:scrollTop]    = container.execute_script("return arguments[0].scrollTop", element)
        hash[:scrollWidth]  = container.execute_script("return arguments[0].scrollWidth", element)
        hash[:scrollHeight] = container.execute_script("return arguments[0].scrollHeight", element)
        if desc.length > 0
          debug_to_log("#{desc} #{refs}\n#{hash.to_yaml}")
        end
        hash
      rescue
        failed_to_log(unable_to)
      end

    end
  end
end

module Watir
  class Element

    def list_attributes
      # binding.pry
      # attributes = browser.execute_script(%Q[
      #           var s = {};
      #           var attrs = arguments[0].attributes;
      #           for (var l = 0; l < attrs.length; ++l) {
      #               var a = attrs[l]; s[a.name] = a.value);
      #           } ;
      #           return s;],
      #                                     self
      # )
      attributes = browser.execute_script(%Q[
                var s = [];
                var attrs = arguments[0].attributes;
                for (var l = 0; l < attrs.length; ++l) {
                    var a = attrs[l]; s.push(a.name + ': ' + a.value);
                } ;
                return s;],
                                          self
      )
    end

    def attribute_values
      hash = Hash.new
      ['id', 'offsetParent', 'style', 'currentstyle',
       'offsetHeight', 'offsetWidth', 'offsetLeft', 'offsetTop',
       'clientHeight', 'clientWidth', 'clientLeft', 'clientTop',
       'scrollHeight', 'scrollWidth', 'scrollLeft', 'scrollTop',
       'className', 'resizable',
       'visible', 'sourceIndex'].each do |attr|
        hash[attr] = attribute_value(attr)
      end
      hash
    end

    def dimensions
      hash = bounding_client_rectangle
      [hash['width'], hash['height']]
    end

    def bounding_client_rectangle
      assert_exists
      self.browser.execute_script("return arguments[0].getBoundingClientRect()", self)
    end

    ###################################
    def bottom_edge
      bounding_client_rectangle['bottom']
    end

    ###################################
    def top_edge
      bounding_client_rectangle['top']
    end

    ###################################
    def left_edge
      bounding_client_rectangle['left']
    end

    ###################################
    def right_edge
      bounding_client_rectangle['right']
    end

    ###################################
    def client_offset
      hash = bounding_client_rectangle
      [hash['left'], hash['top']]
    end


  end
end

class Hash
  def depth
    a = self.to_a
    d = 1
    while (a.flatten!(1).map! { |e| (e.is_a? Hash) ? e.to_a.flatten(1) : (e.is_a? Array) ? e : nil }.compact!.size > 0)
      d += 1
    end
    d
  end
end

class String

  def -(other)
    self.index(other) == 0 ? self[other.size..self.size] : nil
  end
end

class HTMLValidationResult

  def validate
    require 'fileutils'

    html_file = 'tidy_this.html'
    err_file  = 'tidy_err.txt'
    done_file = 'tidy_done.html'
    # FileUtils.touch(err_file) unless File.exists?(err_file)

    puts "#{__method__}: #{Dir.pwd}"
    html = File.new(html_file, 'w')
    html.puts(@html)
    html.close

    cmd = "tidy -quiet -f #{err_file} -o #{done_file} #{html_file}"

    out = `#{cmd}`
    puts out

    errs   = File.open(err_file)
    result = errs.read
    errs.close
    result

  end

end

