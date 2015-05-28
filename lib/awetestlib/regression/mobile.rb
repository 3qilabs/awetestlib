module Awetestlib

  module Regression

    module Mobile

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
        appium = IO.popen(command)
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


    end
  end
end
