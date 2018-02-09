module Awetestlib
  # Awetest DSL for browser based testing.
  module Regression
    # Methods to manage browser windows: open, close, attach, verify health, and clean up.
    module Browser

      # @!group Browser

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

      alias goto_wd_url go_to_wd_url

      # Open a browser based on the command line parameters that identify the browser and
      # version to use for the test.
      # @note Safari currently supported only on Mac OS X
      # @example
      #  browser = open_browser('www.google.com')
      # @param [String, Regexp] url When provided, the browser will go to this url.
      # @return [Watir::Browser]
      def open_browser(url = nil)
        message_to_report("Opening browser: #{@targetBrowser.abbrev}")

        browser = nil

        if $mobile
          end_android_processes if $platform == :android
          clean_up_android_temp unless $device
          sleep_for(3)
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

      def browser_driver(browser)
        if @myBrowser.class.to_s =~ /IE/
          @actualBrowser.driver = 'Watir Classic'
          $using_webdriver      = false
        else
          #@actualBrowser.driver = "Watir-webdriver #{@myBrowser.driver.capabilities.browser_name.titleize}"
          $using_webdriver = true
        end
        #message_to_report("Running with #{@actualBrowser.driver}")
      end

      # Open IE (Internet Explorer) browser instance.
      # If global variable $watir_script is set to true in the first line of the script,
      # classic Watir will be used to drive the browser,
      # otherwise Watir Webdriver will be used.
      # @return [Watir::Browser]
      def open_ie
        #browser = Watir::Browser.new :ie
        caps = Selenium::WebDriver::Remote::Capabilities.internet_explorer(
            #:nativeEvents => false,
            #'nativeEvents' => false,
            :initialBrowserUrl                                   => 'about:blank',
            :enablePersistentHover                               => false,
            :ignoreProtectedModeSettings                         => true,
            :introduceInstabilityByIgnoringProtectedModeSettings => true,
            :unexpectedAlertBehaviour                            => 'ignore'
        )
        Watir::Browser.new(:ie, :desired_capabilities => caps)
      rescue
        failed_to_log(unable_to)
      end

      # Open Safari browser instance.
      # @note Safari currently supported only on Mac OS X
      # @return [Watir::Browser]
      def open_safari
        Watir::Browser.new(:remote, :desired_capabilities => :'safari')
      end

      # Open FF (Firefox) browser instance under FireWatir.
      # @return [Watir::Browser]
      def open_ff
        Watir::Browser.new :firefox
      end

      # Open GC (Google Chrome) browser instance.
      # @return [Watir::Browser] Browser is Google Chrome.
      def open_chrome
        client         = Selenium::WebDriver::Remote::Http::Default.new
        client.timeout = 180 # seconds – default is 60

        Watir::Browser.new(:chrome, :http_client => client)
      end

      # Instruct browser to navigate to a specific URL
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] url When provided, the browser will go to this url.
      # and the instance variable @myURL will be set to this value.
      # @return [Boolean] True when navigation to url succeeds.
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

      # Return a reference to a browser window.  Used to attach a browser window to a variable
      # which can then be passed to methods that require a *browser* parameter containing a Browser object.
      # @example
      #  mainwindow = open_browser('www.google.com')
      #  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
      #  popup = attach_browser(mainwindow, :url, '[url of new window]')   #*or*
      #  popup = attach_browser(mainwindow, :title, '[title of new window]')
      # @param [Watir::Browser] browser A reference to the current browser window.
      # @param [Symbol] how The element attribute used to identify the window: *:title* or :url.
      # @param [String|Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [String] refs List of reference identifiers to include in log/report message
      # @return [Watir::Browser]
      def attach(browser, how, what, desc = '', refs = '')
        msg = "Attaching browser window :#{how}='#{what}' #{desc} #{refs}"
        debug_to_report(with_caller(msg))
        uri_decoded_pattern = ::URI.encode(what.to_s.gsub('(?-mix:', '').gsub(')', ''))
        debug_to_log(with_caller(uri_decoded_pattern))
        browser.driver.switch_to.window(browser.driver.window_handles[0])
        browser.window(how, what).use
        browser
      rescue
        failed_to_log(unable_to(msg))
      end

      alias find_popup attach
      alias find_window attach
      alias attach_popup attach
      alias attach_window attach
      alias attach_browser attach
      alias use_window attach

      def re_attach(browser, window = 0)
        if $using_webdriver
          @myBrowser.driver.switch_to.window(browser.driver.window_handles[window])
          #@myBrowser.window.use
        else
          case window
            when 0
              @myBrowser
            else
              @myBrowser
          end
        end
      end

      alias re_attach_window re_attach

      # Locate and close instances of IE browsers
      def find_other_browsers
        cnt = 0
        if @targetBrowser.abbrev == 'IE'
          Watir::IE.each do |ie|
            debug_to_log("#{ie.inspect}")
            ie.close()
            cnt = cnt + 1
          end
        end
        debug_to_log("Found #{cnt} IE browser(s).")
        return cnt
      rescue
        error_to_log("#{$!}  (#{__LINE__})\n#{Kernel.caller.to_yaml}", __LINE__)
        return 0
      end

      # @!endgroup Browser

      # @!group Login

      # Simple login method
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] user Login ID for the user.
      # @param [String] password Password for the user.
      # @return [Boolean] True if login succeeds.
      def login(browser, user, password)
        #TODO: Needs to be more flexible about finding login id and password textfields
        #TODO: Parameterize url and remove references to environment
        myURL  = @myAppEnv.url
        runenv = @myAppEnv.nodename
        message_tolog("URL: #{myURL}") if @myAppEnv
        message_tolog("Beginning login: User: #{user} Environment: #{@myAppEnv.nodename}") if @myAppEnv
        if validate(browser, @myName, __LINE__)
          browser.goto(@myAppEnv.url)
          if validate(browser, @myName)
            set_textfield_by_name(browser, 'loginId', user)
            set_textfield_by_name(browser, 'password', password)
            click_button_by_value(browser, 'Login')
            if validate(browser, @myName)
              passed_to_log("Login successful.")
              true
            end
          else
            failed_to_log("Unable to login to application: '#{$!}'")
            #screen_capture( "#{@myRoot}/screens/#{myName}_#{@runid}_#{__LINE__.to_s}_#{Time.new.to_f.to_s}.jpg")
          end
        end
      rescue
        failed_to_log("Unable to login to application: '#{$!}'")
      end

      # Logon to webpage using Basic Authorization type of logon. Uses AutoIt
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] user Login ID for the user.
      # @param [String] password Password for the user.
      # @param [String] url The URL to log on to.
      # @param [Boolean] bypass_validate When set to true, the call to validate(),
      # which checks the health of the browser, is skipped..
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

      # Provide an authorization token or passcode in a specified text field element identified by its *:id* attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] role Usually a user role designation ('Administrator', 'User', etc.)
      # @param [String] token Authentification token required by logon process.
      # @param [String/Regexp] id Value of the *:id* attribute of the text field that will receive the *token*.
      def token_auth(browser, role, token, id = 'token_pass')
        set_textfield_by_id(browser, id, token)
        click_button_by_value(browser, 'Continue')
        if validate_text(browser, 'The requested page requires authentication\.\s*Please enter your Passcode below', nil, true)
          bail_out(browser, __LINE__, "Token authorization failed on '#{token}'")
        end
      end

      # @!endgroup Logon

      # @!group Error Handling

      # Exit more or less gracefully from script when errors are too severe to continue.
      # Normally _not_ called in a test script or project library.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Fixnum] lnbr Line number in calling script.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      #
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

      # Check for the presence of IE browser instances.
      # @return [Fixnum] The number of IE browser instances encountered.
      def check_for_other_browsers
        cnt1 = find_other_browsers
        cnt2 = Watir::Process.count 'iexplore.exe'
        debug_to_log("check_for_other_browsers: cnt1: #{cnt1} cnt2: #{cnt2}")
      rescue
        error_to_log("#{$!}  (#{__LINE__})\n#{Kernel.caller.to_yaml}")
      end

      # Check for the presence of IE browser instances and close all that are found.
      def check_for_and_clear_other_browsers
        if @targetBrowser.abbrev == 'IE'
          debug_to_log("#{__method__}:")
          cnt1 = find_other_browsers
          cnt2 = Watir::IE.process_count
          debug_to_log("#{__method__}: cnt1: #{cnt1} cnt2: #{cnt2}")
          begin
            Watir::IE.each do |ie|
              pid = Watir::IE::Process.process_id_from_hwnd(ie.hwnd)
              debug_to_log("#{__method__}: Killing browser process: hwnd #{ie.hwnd} pid #{pid} title '#{ie.title}' (#{__LINE__})")
              do_taskkill(INFO, pid)
              sleep_for(10)
            end
              #Watir::IE.close_all()
          rescue
            debug_to_log("#{__method__}: #{$!}  (#{__LINE__})")
          end
          sleep(3)
          cnt1 = find_other_browsers
          cnt2 = Watir::IE.process_count
          if cnt1 > 0 or cnt2 > 0
            debug_to_log("#{__method__}:cnt1: #{cnt1} cnt2: #{cnt2}")
            begin
              Watir::IE.each do |ie|
                pid = Watir::IE::Process.process_id_from_hwnd(ie.hwnd)
                debug_to_log("#{__method__}: Killing browser process: hwnd #{ie.hwnd} pid #{pid} title '#{ie.title}' (#{__LINE__})")
                do_taskkill(INFO, pid)
                sleep_for(10)
              end
                #Watir::IE.close_all()
            rescue
              debug_to_log("#{__method__}:#{$!}  (#{__LINE__})")
            end
          end
        end
      rescue
        error_to_log("#{__method__}: #{$!}  (#{__LINE__})\n#{Kernel.caller.to_yaml}")
      end

      # Force browser instance to close, one way or the other.
      # Instance is identified by *hwnd*, the Windows OS handle for the process.
      # @param [String] hwnd The value for the window handle for the browser process.
      # @param [Fixnum] lnbr Line number in calling script.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be closed.
      def kill_browser(hwnd, lnbr, browser = nil, doflag = false)
        # TODO Firefox
        logit = false
        if @browserAbbrev == 'FF'
          if is_browser?(browser) # and browser.url.length > 1
            logit = true
            here  = __LINE__
            url   = browser.url
            #capture_screen(browser, Time.new.to_f) if @screenCaptureOn
            browser.close if url.length > 0
            @status = 'killbrowser'
            fatal_to_log("Kill browser called from line #{lnbr}")
          end
        elsif hwnd
          pid = Watir::IE::Process.process_id_from_hwnd(hwnd)
          if pid and pid > 0 and pid < 538976288
            if browser.exists?
              here  = __LINE__
              logit = true
              url   = browser.url
              #capture_screen(browser, Time.new.to_f) if @screenCaptureOn
              browser.close
              sleep(2)
              if browser.exists?
                do_taskkill(FATAL, pid)
              end
              @status = 'killbrowser'
            end
          end
          if logit
            debug_to_log("#{@browserName} window hwnd #{hwnd} pid #{pid} #{url} (#{here})")
            fatal_to_log("Kill browser called from line #{lnbr}")
          end
        end
      end

      # @!endgroup Error Handling

      # @!group Browser

      # Use enabled_popup and winclicker to determine if there is an active modal popup.
      # Useful only when no wait action has been invoked.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] button The visible name of the button to be clicked to close the popup.
      # @return [String] containing the window handle of the closed modal popup.
      def modal_exists?(browser, button = nil)
        rtrn = nil
        if @browserAbbrev == 'IE'
          Timeout::timeout(2) do
            begin
              if browser.enabled_popup
                hwnd = browser.enabled_popup(5)
                debug_to_log("Modal popup with handle #{hwnd} found. (#{__LINE__})")
                wc = WinClicker.new
                wc.makeWindowActive(hwnd)
                rtrn = wc.getWindowTitle(hwnd)
                if button
                  wc.clickWindowsButton_hWnd(hwnd, button)
                end
                wc = nil
              end
            rescue Timeout::Error
              debug_to_log("No Modal popup found. (#{__LINE__})")
              return rtrn
            end
            return rtrn
          end
          rtrn
        else
          rtrn
        end
      end

      # Close a browser window identified by its title.
      # Uses AutoIt. Windows only.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [String] text (optional) The text of the window to be closed.  Matched from beginning of string.
      def close_window_by_title(browser, title, desc = '', text = '')
        msg = "Window '#{title}':"
        if @ai.WinWait(title, text, WAIT) > 0
          passed_to_log("#{msg} appeared. #{desc}")
          myHandle  = @ai.WinGetHandle(title, text)
          full_text = @ai.WinGetText(title)
          debug_to_log("#{msg} hwnd: #{myHandle.inspect}")
          debug_to_log("#{msg} title: '#{title}' text: '#{full_text}'")
          if @ai.WinClose(title, text) > 0
            passed_to_log("#{msg} closed successfully. #{desc}")
          else
            failed_to_log("#{msg} close failed. (#{__LINE__}) #{desc}")
          end
        else
          failed_to_log("#{msg} did not appear after #{WAIT} seconds. (#{__LINE__}) #{desc}")
        end
      rescue
        failed_to_log("#{msg}: Unable to close: '#{$!}'. (#{__LINE__}) #{desc}")
      end

      # Closes main browser session. Usually used at end of script to shut down browser.
      def close_browser(browser, where = @myName, lnbr = __LINE__)
        browser_name = BROWSER_MAP[@browserAbbrev]
        mark_test_level("#{browser_name} in #{where}")
        debug_to_log(with_caller("#{browser.inspect}"))

        url   = browser.url
        title = browser.title
        message_to_report(with_caller("#{browser_name}   url: #{browser.url}"))
        message_to_report(with_caller("#{browser_name} title: #{browser.title}"))

        report_browser_message(browser)

        if $mobile
          browser.close
          sleep(1)
          end_android_processes if $platform == :android
          clean_up_android_temp unless $device

        else
          browser.close
          # case @browserAbbrev
          #   when 'FF'
          #     if is_browser?(browser)
          #       debug_to_log("#{__method__}: Firefox browser url: [#{url}]")
          #       debug_to_log("#{__method__}: Firefox browser title: [#{title}]")
          #       debug_to_log("#{__method__}: Closing browser: #{where} (#{lnbr})")
          #       if url and url.length > 1
          #         browser.close
          #       else
          #         browser = FireWatir::Firefox.attach(:title, title)
          #         browser.close
          #       end
          #
          #     end
          #   when 'IE'
          #     if is_browser?(browser)
          #       debug_to_log("#{__method__}: Internet Explorer browser url: [#{url}]")
          #       debug_to_log("#{__method__}: Internet Explorer browser title: [#{title}]")
          #       debug_to_log("#{__method__}: Closing browser: #{where} (#{lnbr})")
          #       browser.close
          #     end
          #   when 'S'
          #     if is_browser?(browser)
          #       url   = browser.url
          #       title = browser.title
          #       debug_to_log("Safari browser url: [#{url}]")
          #       debug_to_log("Safari browser title: [#{title}]")
          #       debug_to_log("Closing browser: #{where} (#{lnbr})")
          #       # close_modal_s # to close any leftover modal dialogs
          #       browser.close
          #     end
          #   when 'C', 'GC'
          #     if is_browser?(browser)
          #       url   = browser.url
          #       title = browser.title
          #       debug_to_log("Chrome browser url: [#{url}]")
          #       debug_to_log("Chrome browser title: [#{title}]")
          #       debug_to_log("Closing browser: #{where} (#{lnbr})")
          #       if url and url.length > 1
          #         browser.close
          #       end
          #
          #     end
          #   else
          #     raise "Unsupported browser: '#{@browserAbbrev}'"
          # end
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

      # Close a browser window, usually a child window. Does not apply to modal popups/alerts.
      # @param [Watir::Browser] window Reference to the browser window to be closed
      def close_window(window)
        if is_browser?(window)
          url = window.url
          debug_to_log("Closing popup '#{url}' ")
          if $using_webdriver
            window.driver.switch_to.window(window.driver.window_handles[0])
            window.window(:url, url).close
          else
            window.close
          end
        end
      end

      alias close_new_window_popup close_window
      alias close_child_window close_window

      # Close an HTML panel or division by clicking a link within it identified by the *:text* value of the link.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Watir::Browser] panel Reference to the panel (usually a div element) to be closed
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      def close_panel(browser, panel, element, how, what, desc = '')
        msg = "Close panel with #{element} '#{how}'=>'#{what}' #{desc}"
        if validate(browser, @myName, __LINE__)
          if $using_webdriver
            begin
              panel.element(how, what).click
            rescue => e
              unless rescue_me(e, __method__, rescue_me_command(:link, how, what, :click), "#{panel.class}")
                raise e
              end
            end
          else
            panel.element(how, what).click!
          end
          sleep_for(1)
          passed_to_log(msg)
          true
        else
          failed_to_log(unable_to(msg))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      #def close_modal_ie(title, button = "OK", text = '', side = 'primary', wait = WAIT, desc = '', quiet = false)
      #  #TODO needs simplifying and debug code cleaned up
      #  title = translate_popup_title(title)
      #  msg   = "'#{title}'"
      #  msg << " with text '#{text}'" if text.length > 0
      #  msg << " (#{desc})" if desc.length > 0
      #  @ai.Opt("WinSearchChildren", 1) # Match any substring in the title
      #  if @ai.WinWait(title, text, wait) > 0
      #    myHandle  = @ai.WinGetHandle(title, text)
      #    full_text = @ai.WinGetText(title)
      #    #debug_to_report("Found popup handle:'#{myHandle}', title:'#{title}', text:'#{full_text}'")
      #    if myHandle.length > 0
      #      debug_to_log("hwnd: #{myHandle.inspect}")
      #      passed_to_log("#{msg} appeared.") unless quiet
      #      sleep_for(0.5)
      #      @ai.WinActivate(title, text)
      #      if @ai.WinActive(title, text) #  > 0   #Hack to prevent fail when windows session locked
      #        debug_to_log("#{msg} activated.")
      #        if @ai.ControlFocus(title, text, button) #  > 0
      #          controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
      #          if not controlHandle
      #            button        = "&#{button}"
      #            controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
      #          end
      #          debug_to_log("Handle for button '#{button}': [#{controlHandle}]")
      #          debug_to_log("#{msg} focus gained.")
      #          #              sleep_for(2)
      #          if @ai.ControlClick(title, text, button, side) # > 0
      #                                                         #            if @ai.ControlClick(title, text, "[Handle:#{controlHandle}]", side) > 0
      #                                                         #                debug_to_log("#{msg} #{side} click on 'Handle:#{controlHandle}'." )
      #            debug_to_log("#{msg} #{side} click on '#{button}' successful.")
      #            sleep_for(1)
      #            if @ai.WinExists(title, text) > 0
      #              debug_to_log("#{msg} close popup failed on click '#{button}'. Trying WinClose. (#{__LINE__})")
      #              @ai.WinClose(title, text)
      #              if @ai.WinExists(title, text) > 0
      #                debug_to_log("#{msg} close popup failed with WinClose('#{title}','#{text}'). (#{__LINE__})")
      #                @ai.WinKill(title, text)
      #                if @ai.WinExists(title, text) > 0
      #                  debug_to_log("#{msg} close popup failed with WinKill('#{title}','#{text}'). (#{__LINE__})")
      #                else
      #                  debug_to_log("#{msg} closed successfully with WinKill('#{title}','#{text}').")
      #                end
      #              else
      #                debug_to_log("#{msg} closed successfully with WinClose('#{title}','#{text}').")
      #              end
      #            else
      #              passed_to_log("#{msg} closed successfully.") unless quiet
      #            end
      #          else
      #            failed_to_log("#{msg} #{side} click on '#{button}' failed. (#{__LINE__})")
      #          end
      #        else
      #          failed_to_log("#{msg} Unable to gain focus on button (#{__LINE__})")
      #        end
      #      else
      #        failed_to_log("#{msg} Unable to activate (#{__LINE__})")
      #      end
      #    else
      #      failed_to_log("#{msg} did not appear after #{wait} seconds. (#{__LINE__})")
      #    end
      #  else
      #    failed_to_log("#{msg} did not appear after #{wait} seconds. (#{__LINE__})")
      #  end
      #rescue
      #  failed_to_log("Close popup title=#{title} failed: '#{$!}' (#{__LINE__})")
      #end

      # Close an browser window (popup) by clicking a link within it identified by the *:text* value of the link.
      # @param [Watir::Browser] popup A reference to the browser window or container element to be closed.
      # @param [String] what Uniquely identify the *:link* element within the popup by the value in its *:text* attribute.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      def close_popup_by_text(popup, what = 'Close', desc = '')
        count = 0
        url   = popup.url
        if validate(popup, @myName, __LINE__)
          count = string_count_in_string(popup.text, what)
          if count > 0
            begin
              popup.link(:text, what).click
            rescue => e
              unless rescue_me(e, __method__, rescue_me_command(:link, :text, what, :click), "#{popup.class}")
                raise e
              end
            end
            passed_to_log("Popup #{url} closed by clicking link with text '#{what}'. #{desc}")
            true
          else
            failed_to_log("Link :text=>'#{what}' for popup #{url} not found. #{desc}")
          end
        end
      rescue
        failed_to_log("Close popup #{url} with click link :text+>'#{what}' failed: '#{$!}' (#{__LINE__})")
        debug_to_log("#{strg} appears #{count} times in popup.text.")
        raise
      end

      # Close a modal dialog.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] button The display name of the button to be clicked.
      # @param [String] text The text of the window to be closed.  Matched from beginning of string in Windows
      # with Internet Explorer (regular expressions will fail). Use enough of beginning of the text string, in quotes,
      # to assure the correct modal is found. This will give best portability.
      # @param [String] side A string identifying which mouse button to click.
      # @param [Fixnum] wait Number of seconds to wait for the popup to be seen.
      def close_modal(browser, title="", button="OK", text='', side = 'primary', wait = WAIT)
        if $using_webdriver
          case button
            when /^OK$/i, /^Yes$/i
              browser.alert.ok
            else
              browser.alert.dismiss
          end
        else
          close_modal_ie(browser, title, button, text, side, wait)
        end
      rescue
        failed_to_log(unable_to)
      end

      alias close_alert close_modal

      # Close an IE modal popup by its title using AutoItX3. Windows only.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] button The display name of the button to be clicked.
      # @param [String] text The text of the window to be closed.  Matched from beginning of string.  Do not use regular expression
      # @param [String] side A string identifying which mouse button to click.
      # @param [Fixnum] wait Number of seconds to wait for the popup to be seen.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] quiet If true, fewer messages and pass/fail validations are logged.
      def close_modal_ie(browser, title="", button="OK", text='', side = 'primary', wait = WAIT, desc = '', quiet = false)
        #TODO needs simplifying, incorporating text verification, and debug code cleaned up
        title = translate_popup_title(title)
        msg   = "Modal window (popup) '#{title}'"
        if @ai.WinWait(title, text, wait) > 0
          myHandle = @ai.WinGetHandle(title, text)
          if myHandle.length > 0
            debug_to_log("hwnd: #{myHandle.inspect}")
            passed_to_log("#{msg} appeared.") unless quiet
            window_handle = "[HANDLE:#{myHandle}]"
            sleep_for(0.5)
            @ai.WinActivate(window_handle)
            if @ai.WinActive(window_handle) > 0
              debug_to_log("#{msg} activated.")
              controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
              if not controlHandle.length > 0
                button        = "&#{button}"
                controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
              end
              debug_to_log("Handle for button '#{button}': [#{controlHandle}]")
              debug_to_log("#{msg} focus gained.")
              if @ai.ControlClick(title, '', "[CLASS:Button; TEXT:#{button}]") > 0
                passed_to_log("#{msg} #{side} click on '[CLASS:Button; TEXT:#{button}]' successful.")
                sleep_for(0.5)
                if @ai.WinExists(window_handle) > 0
                  debug_to_log("#{msg} close popup failed on click '#{button}'. Trying WinClose. (#{__LINE__})")
                  @ai.WinClose(title, text)
                  if @ai.WinExists(window_handle) > 0
                    debug_to_log("#{msg} close popup failed with WinClose(#{window_handle}). (#{__LINE__})")
                    @ai.WinKill(window_handle)
                    if @ai.WinExists(window_handle) > 0
                      debug_to_log("#{msg} close popup failed with WinKill(#{window_handle}). (#{__LINE__})")
                    else
                      debug_to_log("#{msg} closed successfully with WinKill(#{window_handle}).")
                    end
                  else
                    debug_to_log("#{msg} closed successfully with WinClose(#{window_handle}).")
                  end
                else
                  passed_to_log("#{msg} closed successfully.")
                end
              else
                failed_to_log("#{msg} #{side} click on '[CLASS:Button; TEXT:#{button}]' failed. (#{window_handle}) (#{__LINE__})")
              end
            else
              failed_to_log("#{msg} Unable to activate (#{window_handle}) (#{__LINE__})")
            end
          else
            failed_to_log("#{msg} did not appear after #{wait} seconds. (#{window_handle}) (#{__LINE__})")
          end
        else
          failed_to_log("#{msg} did not appear after #{wait} seconds.(#{window_handle}) (#{__LINE__})")
        end
      rescue
        failed_to_log("Close popup title=#{title} failed: '#{$!}' (#{__LINE__})")
      end

      #alias close_popup_validate_text close_modal_ie
      #alias close_popup close_modal_ie

      #  private :close_modal_ie

      # Close an Internet Explorer modal popup by its title. Calls close_modal_ie. Windows only.
      # @deprecated Use close_modal.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] button The display name of the button to be clicked.
      # @param [String] text The text of the window to be closed.  Matched from beginning of string.
      # @param [String] side A string identifying which mouse button to click.
      # @param [Fixnum] wait Number of seconds to wait for the popup to be seen.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] quiet If true, fewer messages and pass/fail validations are logged.
      def close_popup(title = '', button = 'OK', text = '', side = 'primary',
                      wait = WAIT, desc = '', quiet = false)
        debug_to_log("#{__method__} begin")
        close_modal_ie(@myBrowser, title, button, text, side, wait, desc, quiet)
      end

      alias close_popup_validate_text close_popup

      # Close a Firefox modal popup by its title.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] button The display name of the button to be clicked.
      # @param [String] text The text of the window to be closed.  Matched from beginning of string.
      # @param [String] side A string identifying which mouse button to click.
      # @return [Boolean] True if the modal is successfully closed.
      def close_modal_ff(browser, title="", button=nil, text='', side='')
        title = translate_popup_title(title)
        msg   = "Modal dialog (popup): title=#{title} button='#{button}' text='#{text}' side='#{side}':"
        modal = browser.modal_dialog(:timeout => WAIT)
        if modal.exists?
          modal_text = modal.text
          if text.length > 0
            if modal_text =~ /#{text}/
              passed_to_log("#{msg} appeared with match on '#{text}'.")
            else
              failed_to_log("#{msg} appeared but did not match '#{text}' ('#{modal_text}).")
            end
          else
            passed_to_log("#{msg} appeared.")
          end
          if button
            modal.click_button(button)
          else
            modal.close
          end
          if modal.exists?
            failed_to_log("#{msg} close failed. (#{__LINE__})")
          else
            passed_to_log("#{msg} closed successfully.")
            true
          end
        else
          failed_to_log("#{msg} did not appear after #{WAIT} seconds. (#{__LINE__})")
        end
      rescue
        failed_to_log("#{msg} Unable to validate modal popup: '#{$!}'. (#{__LINE__})")
      end

      # Wait for a modal popup to appear and then close it.
      # Used when modal popup in response to browser action is intermittent or unpredictable.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] text The text of the window to be closed.  Matched from beginning of string.
      # @param [String] button The display name of the button to be clicked.
      # @param [String] side A string identifying which mouse button to click.
      # @param [Fixnum] wait Number of seconds to wait for the popup to be seen.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if the modal is successfully closed.
      def handle_popup(title, text = '', button= 'OK', side = 'primary', wait = WAIT, desc = '')
        title = translate_popup_title(title)
        msg   = "'#{title}'"
        if text.length > 0
          msg << " with text '#{text}'"
        end
        @ai.Opt("WinSearchChildren", 1) # match title from start, forcing default

        if button and button.length > 0
          if button =~ /ok|yes/i
            id = '1'
          else
            id = '2'
          end
        else
          id = ''
        end

        if @ai.WinWait(title, '', wait) > 0
          myHandle      = @ai.WinGetHandle(title, '')
          window_handle = "[HANDLE:#{myHandle}]"
          full_text     = @ai.WinGetText(window_handle)
          debug_to_log("Found popup handle:'#{myHandle}', title:'#{title}', text:'#{full_text}'")

          controlHandle = @ai.ControlGetHandle(window_handle, '', "[CLASS:Button; TEXT:#{button}]")
          if not controlHandle
            #        button        = "&#{button}"
            controlHandle = @ai.ControlGetHandle(window_handle, '', "[CLASS:Button; TEXT:&#{button}]")
          end

          if text.length > 0
            if full_text =~ /#{text}/
              passed_to_log("Found popup handle:'#{myHandle}', title:'#{title}', text includes '#{text}'. #{desc}")
            else
              failed_to_log("Found popup handle:'#{myHandle}', title:'#{title}', text does not include '#{text}'. Closing it. #{desc}")
            end
          end

          @ai.WinActivate(window_handle, '')
          @ai.ControlClick(window_handle, '', id, side)
          if @ai.WinExists(title, '') > 0
            debug_to_log("#{msg} @ai.ControlClick on '#{button}' (ID:#{id}) with handle '#{window_handle}' failed to close window. Trying title.")
            @ai.ControlClick(title, '', id, side)
            if @ai.WinExists(title, '') > 0
              debug_to_report("#{msg} @ai.ControlClick on '#{button}' (ID:#{id}) with title '#{title}' failed to close window.  Forcing closed.")
              @ai.WinClose(title, '')
              if @ai.WinExists(title, '') > 0
                debug_to_report("#{msg} @ai.WinClose on title '#{title}' failed to close window.  Killing window.")
                @ai.WinKill(title, '')
                if @ai.WinExists(title, '') > 0
                  failed_to_log("#{msg} @ai.WinKill on title '#{title}' failed to close window")
                else
                  passed_to_log("Killed: popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
                  true
                end
              else
                passed_to_log("Forced closed: popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
                true
              end
            else
              passed_to_log("Closed on '#{button}': popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
              true
            end
          else
            passed_to_log("Closed on '#{button}': popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
            true
          end

        else
          failed_to_log("#{msg} did not appear after #{wait} seconds. #{desc} (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to handle popup #{msg}: '#{$!}' #{desc} (#{__LINE__})")

      end

      # Confirm that the object passed in *browser* is actually a Browser object.
      # @param [Watir::Browser] browser A reference to the window or container element to be tested.
      def is_browser?(browser)
        browser.class.to_s =~ /Watir::Browser/i
      end

      # Translate window title supplied in *title* to a title appropriate for the targeted browser and version
      # actually being run.
      # Used primarily for handling of modal popups and dialogs.
      # This allows cross-browser compatibility for handling modal popups and other windows accessed by titlt.
      # @param [String] title The title of the window to be closed.
      def translate_popup_title(title)
        new_title = title
        case @browserAbbrev
          when 'IE'
            if @actualBrowser.version
              case @actualBrowser.version
                when '8.0'
                  case title
                    when "Microsoft Internet Explorer"
                      new_title = "Message from webpage"
                    when "The page at"
                      new_title = "Message from webpage"
                  end
                when '7.0'
                  case title
                    when "Message from webpage"
                      new_title = "Microsoft Internet Explorer"
                    when "The page at"
                      new_title = "Windows Internet Explorer"
                  end
                when '6.0'
                  case title
                    when "Message from webpage"
                      new_title = "Microsoft Internet Explorer"
                    when "The page at"
                      new_title = "Microsoft Internet Explorer"
                  end
                else
                  case title
                    when "Microsoft Internet Explorer"
                      new_title = "Message from webpage"
                    when "The page at"
                      new_title = "Message from webpage"
                  end
              end
            else
              case title
                when "Microsoft Internet Explorer"
                  new_title = "Message from webpage"
                when "The page at"
                  new_title = "Message from webpage"
              end
            end
          when 'FF'
            case title
              when 'File Download'
                new_title = 'Opening'
              when "Microsoft Internet Explorer"
                new_title = 'The page at'
              when "Message from webpage"
                new_title = 'The page at'
            end
          when 'C'
            case title
              when 'File Download'
                new_title = 'Save As'
              when "Microsoft Internet Explorer"
                new_title = 'The page at'
              when "Message from webpage"
                new_title = 'The page at'
            end
        end
        new_title
      end

      # Identify the exact version of the Browser currently being executed.
      # @todo Bring up to date with newer browser versions
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
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


      protected :get_browser_version

      def get_viewport_to_win_diff(browser)
        window_width = browser.window.size.width.to_f
        body_width   = browser.body.style("width")
        body_width   = body_width.to_f
        (window_width - body_width).to_i
      end

      def calc_window_size(browser, bpsize)
        diff = get_viewport_to_win_diff(browser)
        if @targetBrowser.abbrev == 'C'
          new_size = bpsize + diff -1
        elsif @targetBrowser.abbrev == 'FF'
          new_size = bpsize + diff -16
        end
      end

      # @!group Browser

      # Open and attach a browser popup window where the link to open it and its title contain the same string.
      # @deprecated
      def open_popup_through_link_title(browser, title, pattern, name)
        click_title(browser, title)
        #TODO need some kind of wait for process here
        sleep_for 2
        attach_popup_by_url(browser, pattern, name)
      rescue
        failed_to_log("Unable to open popup '#{name}': '#{$!}' (#{__LINE__})")
      end

      # @!group Error Handling

      # Verifies health of the browser. Looks for common http and system errors that are unrecoverable and
      # attempts to gracefully bail out of the script.
      # Calls rescue_me() when trying to capture the text to filter out known false errors
      # and handle container elements that don't respond to the .text method.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] file_name The file name of the executing script.
      # @param [Fixnum] lnbr Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] dbg If set to true additional debug messages are written to the log.
      #
      # @return [Boolean] True if no error conditions have been encountered.
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

      def verify_browser_options
        browser_name = Awetestlib::BROWSER_MAP[self.browser]
        browser_acro = self.browser
        ok           = true

        if $mobile

          # REDTAG: correction for Shamisen sending wrong browser acronym.
          if self.browser =~ /browser/i
            self.browser = 'AB'
            browser_name = Awetestlib::BROWSER_MAP[self.browser]
            browser_acro = self.browser
          end

          debug_to_log(with_caller(":#{__LINE__}\n#{self.options.to_yaml}"))

          parse_environment_node_for_mobile

          debug_to_log(with_caller(":#{__LINE__}\n#{self.options.to_yaml}"))

          case browser_acro
            when 'FF', 'IE', 'S', 'GC', 'C', 'ED', 'O'
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
            when 'ME', 'MI'
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

      # @!endgroup Error Handling

      # @!group Backward compatible usages

      # Returns a reference to a browser window using the window's *:url* attribute. Calls attach_browser().
      # @example
      #  mainwindow = open_browser('www.google.com')
      #  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
      #  popup = attach_browser_by_url(mainwindow, '[url of new window]')
      # @param [Watir::Browser] browser A reference to the current browser window.
      # @param [String, Regexp] what The value in the targeted attribute that uniquely identifies the new window
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::Browser]
      def attach_browser_by_url(browser, what, desc = '')
        attach(browser, :url, what, desc)
      end

      alias attach_browser_with_url attach_browser_by_url

      # Returns a reference to a new browser window identified by its *:title* attribute.  Used to attach a new browser window to a variable
      # which can then be passed to methods that require a *browser* parameter. Calls attach_browser().
      # @param (see #attach_browser_by_url)
      def attach_popup_by_title(browser, what, desc = '')
        attach(browser, :title, what, desc)
      end

      # Returns a reference to a new browser window identified by its *:url* attribute.  Used to attach a new browser window to a variable
      # which can then be passed to methods that require a *browser* parameter. Calls attach_browser().
      # @param (see #attach_browser_by_url)
      def attach_popup_by_url(browser, what, desc = '')
        attach(browser, :url, what, desc)
      end

      alias get_popup_with_url attach_popup_by_url
      alias attach_popup_with_url attach_popup_by_url
      alias attach_iepopup attach_popup_by_url

      # Close a popup browser window (non-modal) by clicking on a link with :title *what*.
      # This method does not check to make sure the popup is actually closed.
      # @param [Watir::Browser] browser A reference to the current popup browser window.
      # @param [String, Regexp] what The value in the targeted attribute that uniquely identifies the new window
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if the click is successful.
      def close_popup_by_button_title(browser, what, desc = '')
        click(browser, :link, :title, what, desc)
      end

      # Close an HTML panel or division by clicking a link within it identified by the *:text* value of the link.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Watir::Browser] panel Reference to the panel (usually a div element) to be closed
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      def close_panel_by_text(browser, panel, what = 'Close', desc = '')
        close_panel(browser, panel, :link, :text, what, desc)
      end

      # @!endgroup Backward


    end
  end
end

