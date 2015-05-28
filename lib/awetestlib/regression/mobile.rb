module Awetestlib

  module Regression

    module Mobile

      def open_mobile_browser

        mark_test_level(": #{self.device_type.titleize}")

        debug_to_log(with_caller("$debug => #{$debug}, $DEBUG => #{$DEBUG}"))
        log_level = $debug ? 'debug:debug' : 'info:debug'

        debug_to_log("#{Dir.pwd.chomp}")
        log_file = File.join(Dir.pwd.chomp, 'log', "#{File.basename(__FILE__, '.rb')}_appium_lib_#{Time.now.strftime("%Y%m%d%H%M%S")}.log")
        command  = "start \"appium server\" appium --log-timestamp --log-level #{log_level} -g #{log_file} &"
        debug_to_log(command)
        appium      = IO.popen(command, :err => :out)
        @appium_pid = appium.pid
        debug_to_log("Appium PID: #{@appium_pid}")

        debug_to_log("nodejs version: #{`"C:\\Program Files (x86)\\Appium\\node" --version`.chomp}")
        sleep_for(10)

        client         = Selenium::WebDriver::Remote::Http::Default.new
        client.timeout = 300
        desired_caps = set_mobile_capabilities(self.device_id, self.device_type, self.sdk, self.emulator, client)

        debug_to_log(desired_caps.to_yaml)

        Appium::Driver.new(desired_caps)
        $driver.start_driver
        # who_is_there?(__LINE__)

        debug_to_log('Getting Watir Browser from driver...')
        browser = Watir::Browser.new($driver.driver)
        # who_is_there?(__LINE__, browser)

        # browser.goto('wf.com')

        browser
      rescue
        failed_to_log(unable_to)
      end

      def set_mobile_capabilities(device_id, device_type, sdk, emulator, http_client, server_url = "http://127.0.0.1:4723/wd/hub")
        mark_test_level

        case device_type

          when /android device/i
            desired_caps = {
                :caps       => {
                    :newCommandTimeout         => 600,
                    :androidDeviceReadyTimeout => 420,
                    :avdLaunchTimeout          => 240000,
                    :avdReadyTimeout           => 240000,
                    :deviceName                => "Android Device",
                    :automationName            => "Appium",
                    :platformName              => "Android",
                    :browserName               => "Chrome",
                    :platformVersion           => sdk,
                    'app'                      => "chrome",
                    # 'appPackage'                => "com.android.chrome",
                    :udid                      => device_id,
                    :http_client               => http_client,
                    :chromeOptions             => { "args" => ['--ignore-certificate-errors', '--verbose'] } #ignore-certificate-errors=true homepage=about:blank test_type=true' }
                },
                :appium_lib => {
                    :server_url => server_url
                }
            }

          when /android emulator/i

            # NOTE: avd cannot start from snapshot?.

            desired_caps = {
                :caps       => {
                    :newCommandTimeout         => 1200,
                    :androidDeviceReadyTimeout => 420,
                    :avdLaunchTimeout          => 240000,
                    :avdReadyTimeout           => 240000,
                    :debug                     => true,
                    :deviceName                => "Android Emulator",
                    :platformName              => "Android",
                    :avd                       => emulator,
                    :browserName               => "Browser",
                    :avdArgs                   => '-no-audio -http-proxy 151.151.15.250:8080 -dns-server 10.27.206.11:55,10.27.206.101:55,10.91.218.197:55',
                    :http_client               => http_client,
                    :chromeOptions             => { 'args' => ['--ignore-certificate-errors', '--verbose'] }
                },
                :appium_lib => {
                    :server_url => server_url
                }
            }

          when /ios device/i
            desired_caps = {
                'platformVersion' => sdk,
                'deviceName'      => "My_device",
                'platformName'    => "iOS",
                'browserName'     => 'Safari',
                'udid'            => device_id }

          when /ios simulator/i
            desired_caps = {
                'deviceName'      => device_type,
                'platformVersion' => sdk,
                'browserName'     => 'Safari',
                'platformName'    => "iOS" }
          else
            raise "Unrecognized mobile device type: '#{device_type}'"
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
