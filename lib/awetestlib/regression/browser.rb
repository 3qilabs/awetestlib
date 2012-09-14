module Awetestlib
  # Awetest DSL for browser based testing.
  module Regression
    # Methods to manage browser windows: open, close, attach, verify health, and clean up.
    module Browser

      #def run   #DO WE NEED? Use this method to tell user they need to create a run method?
      ## Not here in any case.
      #  setup
      #  set_script_variables
      #  run_test
      #rescue
      #  fatal_to_log("(#{__LINE__})  #{$!}")
      #  browser.close
      #  raise
      #end

      # @!group Browser

      # Open a browser based on the command line parameters that identify the browser and
      # version to use for the test.
      # @example
      #  browser = open_browser('www.google.com')
      # @param [String, Regexp] url When provided, the browser will go to this url.
      # @return [Watir::Browser]
      def open_browser(url = nil)
        debug_to_log("Opening browser: #{@targetBrowser.name}")
        case @targetBrowser.abbrev
          when 'IE'
            @myBrowser = open_ie
            if @myBrowser.class.to_s == "Watir::IE"
              @myHwnd = @myBrowser.hwnd
            end
          when 'FF'
            @myBrowser = open_ff_for_version
          when 'S'
            aBrowser = Watir::Safari.new
            @myBrowser = aBrowser
          when 'C', 'GC'
            @myBrowser = open_chrome
          else
            raise "Unsupported browser: #{@targetBrowser.name}"
        end
        if url
          go_to_url(@myBrowser, url)
        end
        @myBrowser
      end

      # Open IE (Internet Explorer) browser instance.
      # If global variable $watir_script is set to true in the first line of the script,
      # classic Watir will be used to drive the browser,
      # otherwise Watir Webdriver will be used.
      # @return [Watir::Browser]
      def open_ie
        if $watir_script
          browser = Watir::IE.new
        else
          browser = Watir::Browser.new :ie
        end
        browser
      end

      # Open FF (Firefox) browser instance.
      # @param [Fixnum] version A number designating the version of the browser to be opened.
      # @return [Watir::Browser, Firewatir::Browser]
      # Returns Firewatir::Browser if target browser is Firefox version less than 4.0
      def open_ff_for_version(version = @targetVersion)
        if version.to_f < 4.0
          browser = open_ff
        else
          browser = Watir::Browser.new(:firefox)
        end
        browser
      end

      # Open FF (Firefox) browser instance under FireWatir.
      # @return [Firewatir::Browser]
      def open_ff
        Watir::Browser.default = 'firefox'
        browser = Watir::Browser.new
      end

      # Open GC (Google Chrome) browser instance.
      # @return [Watir::Browser] Browser is Google Chrome.
      def open_chrome
        browser = Watir::Browser.new(:chrome)
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
        message_tolog("URL: #{@myURL}")
        browser.goto(@myURL)
        true
      rescue
        fatal_to_log("Unable to navigate to '#{@myURL}': '#{$!}'")
      end

      # Return a reference to a browser window.  Used to attach a browser window to a variable
      # which can then be passed to methods that require a *browser* parameter.
      # @example
      #  mainwindow = open_browser('www.google.com')
      #  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
      #  popup = attach_browser(mainwindow, :url, '[url of new window]')   #*or*
      #  popup = attach_browser(mainwindow, :title, '[title of new window]')
      # @todo Update to work with webdriver for IE.
      # @param [Watir::Browser] browser A reference to the current browser window.
      # @param [Symbol] how The element attribute used to identify the window: :title or :url.
      # @param [String|Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::Browser] Internet Explorer
      def attach_browser(browser, how, what, desc = '')
        debug_to_log("Attaching browser window :#{how}=>'#{what}' #{desc}")
        uri_decoded_pattern = URI.encode(what.to_s.gsub('(?-mix:', '').gsub(')', ''))
        case @browserAbbrev
          when 'IE'
            tmpbrowser      = Watir::IE.attach(how, what)
            browser.visible = true
            if tmpbrowser
              tmpbrowser.visible = true
              tmpbrowser.speed   = :fast
            else
              raise "Browser window :#{how}=>'#{what}' has at least one doc not in completed ready state."
            end
          when 'FF'
            #TODO: This may be dependent on Firefox version if webdriver doesn't support 3.6.17 and below
            browser.driver.switch_to.window(browser.driver.window_handles[0])
            browser.window(how, /#{uri_decoded_pattern}/).use
            tmpbrowser = browser
          when 'S'
            Watir::Safari.attach(how, what)
            tmpbrowser = browser
          when 'C'
            browser.window(how, /#{uri_decoded_pattern}/).use
            tmpbrowser = browser
        end
        debug_to_log("#{__method__}: tmpbrowser:#{tmpbrowser.inspect}")
        tmpbrowser
      end


      # Returns a reference to a new browser window.  Used to attach a new browser window to a variable
      # which can then be passed to methods that require a *browser* parameter. Calls attach_browser().
      # @example
      #  mainwindow = open_browser('www.google.com')
      #  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
      #  popup = attach_popup(mainwindow, :url, '[url of new window]') *or*
      #  popup = attach_popup(mainwindow, :title, '[title of new window]')
      # @param [Watir::Browser] browser A reference to the current browser window.
      # @param [Symbol] how The element attribute used to identify the window: :title or :url.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::Browser] The new browser window.
      def attach_popup(browser, how, what, desc = '')
        msg   = "Attach popup :#{how}=>'#{what}'. #{desc}"
        popup = attach_browser(browser, how, what, desc)
        sleep_for(1)
        debug_to_log("#{popup.inspect}")
        if is_browser?(popup)
          title = popup.title
          passed_to_log("#{msg} title='#{title}'")
          return popup
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to attach popup :#{how}=>'#{what}'. #{desc} '#{$!}' (#{__LINE__})")
      end

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
        mark_testlevel("Basic Authorization Login", 0)

        message_to_report ("Login:    #{user}")
        message_to_report ("URL:      #{url}")
        message_to_report ("Password: #{password}")

        @login_title = "Connect to"

        a = Thread.new {
          browser.goto(url)
        }

        sleep_for(2)
        message_to_log("#{@login_title}...")

        if (@ai.WinWait(@login_title, "", 90) > 0)
          win_title = @ai.WinGetTitle(@login_title)
          debug_to_log("Basic Auth Login window appeared: '#{win_title}'")
          @ai.WinActivate(@login_title)
          @ai.ControlSend(@login_title, '', "[CLASS:Edit; INSTANCE:2]", '!u')
          @ai.ControlSend(@login_title, '', "[CLASS:Edit; INSTANCE:2]", user, 1)
          @ai.ControlSend(@login_title, '', "[CLASS:Edit; INSTANCE:3]", password.gsub(/!/, '{!}'), 1)
          @ai.ControlClick(@login_title, "", '[CLASS:Button; INSTANCE:1]')
        else
          debug_to_log("Basic Auth Login window did not appear.")
        end
        a.join

        validate(browser, @myName) unless bypass_validate

        message_to_report("URL: [#{browser.url}] User: [#{user}]")

      end

      # Provide an authorization token or passcode in a specified text field element identified by its :id attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] role Usually a user role designation ('Administrator', 'User', etc.)
      # @param [String] token Authentification token required by logon process.
      # @param [String/Regexp] id Value of the :id attribute of the text field that will receive the +token+.
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
      # Normally not called in a test script or project library.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Fixnum] lnbr Line number in calling script.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      #
      def bail_out(browser, lnbr, desc)
        ts  = Time.new
        msg = "Bailing out at util line #{lnbr} #{ts} " + desc
        puts "#{msg}"
        fatal_to_log(msg, nil, 1, lnbr)
        debug_to_log(dump_caller(lnbr))
        if is_browser?(browser)
          if @browserAbbrev == 'IE'
            hwnd = browser.hwnd
            kill_browser(hwnd, lnbr, browser)
            raise(RuntimeError, msg, caller)
          elsif @browserAbbrev == 'FF'
            debug_to_log("#{browser.inspect}")
            debug_to_log("#{browser.to_s}")
            raise(RuntimeError, msg, caller)
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
      # Instance is identified by +hwnd+, the Windows OS handle for the process.
      # @param [String] hwnd The value for the window handle for the browser process.
      # @param [Fixnum] lnbr Line number in calling script.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be closed.
      def kill_browser(hwnd, lnbr, browser = nil)
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

      # Closes main browser session. Misnamed. Usually used at end of script to shut down browser.
      def logout(browser, where = @myName, lnbr = __LINE__)
        #TODO Firewatir 1.6.5 does not implement .exists for FireWatir::Firefox class
        debug_to_log("Logging out in #{where} at line #{lnbr}.", lnbr, true)
        debug_to_log("#{__method__}: browser: #{browser.inspect} (#{__LINE__})")

        if ['FF', 'S'].include?(@browserAbbrev) || browser.exists?
          case @browserAbbrev
            when 'FF'
              if is_browser?(browser)
                url   = browser.url
                title = browser.title
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
            when 'S'
              if is_browser?(browser)
                url   = browser.url
                title = browser.title
                debug_to_log("Safari browser url: [#{url}]")
                debug_to_log("Safari browser title: [#{title}]")
                debug_to_log("Closing browser: #{where} (#{lnbr})")
                close_modal_s # to close any leftover modal dialogs
                browser.close
              end
            when 'C'
              if is_browser?(browser)
                url   = browser.url
                title = browser.title
                debug_to_log("Chrome browser url: [#{url}]")
                debug_to_log("Chrome browser title: [#{title}]")
                debug_to_log("Closing browser: #{where} (#{lnbr})")
                if url and url.length > 1
                  browser.close
                  #else
                  #browser = FireWatir::Firefox.attach(:title, title)
                  #browser.close
                end

              end
            else
              raise "Unsupported browser: '#{@browserAbbrev}'"
          end
        end
        #  rescue => e
        #    if not e.is_a?(Vapir::WindowGoneException)
        #      raise e
        #    end
      end

      # Close a browser popup window. Does not apply to modal popups.
      # @param [Watir::Browser] popup Reference to the popup to be closed
      def close_new_window_popup(popup)
        if is_browser?(popup)
          url = popup.url
          debug_to_log("Closing popup '#{url}' ")
          popup.close

        end
      end

      # Close an HTML panel or division by clicking a link within it identified by the :text value of the link.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Watir::Browser] panel Reference to the panel (usually a div element) to be closed
      def close_panel_by_text(browser, panel, what = 'Close')
        if validate(browser, @myName, __LINE__)
          if @browserAbbrev == 'IE'
            panel.link(:text, what).click!
          elsif $USE_FIREWATIR
            begin
              panel.link(:text, what).click
            rescue => e
              if not rescue_me(e, __method__, "link(:text,'#{what}').click", "#{panel.class}")
                raise e
              end
            end
          else
            panel.link(:text, what).click(:wait => false)
          end
          sleep_for(1)
          if validate(browser, @myName, __LINE__)
            passed_to_log("Panel '#{what}' (by :text) closed.")
            true
          end
        else
          failed_to_log("Panel '#{strg}' (by :text) still open.")
        end
      rescue
        failed_to_log("Click on '#{strg}'(by :text) failed: '#{$!}' (#{__LINE__})")
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

      # Close an browser window (popup) by clicking a link within it identified by the :text value of the link.
      # @param [Watir::Browser] popup A reference to the browser window or container element to be closed.
      # @param [String] what Uniquely identify the :link element within the popup by the value in its :text attribute.
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
              if not rescue_me(e, __method__, "link(:text,'#{what}')", "#{popup.class}")
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
      # @param [String] text The text of the window to be closed.  Matched from beginning of string.
      # @param [String] side A string identifying which mouse button to click.
      # @param [Fixnum] wait Number of seconds to wait for the popup to be seen.
      def close_modal(browser, title="", button="OK", text='', side = 'primary', wait = WAIT)
        case @targetBrowser.abbrev
          when 'IE'
            close_modal_ie(browser, title, button, text, side, wait)
          when 'FF'
            close_modal_ff(browser, title, button, text, side)
          when 'S'
            close_modal_s
          when 'C', 'GC'
            close_modal_c(browser, title)
        end
      end

    # TODO: Logging
      # Close a Chrome modal popup by :url.
      def close_modal_c(browser, url)
        browser.window(:url, url).close
      end

    # TODO: Logging
      # Close a Safari modal popup by closing the frontmost Safari dialog.  MacOS only
      def close_modal_s
        # simply closes the frontmost Safari dialog
        Appscript.app("Safari").activate; Appscript.app("System Events").processes["Safari"].key_code(52)
      end

      # Close an IE modal popup by its title.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] title The title of the window to be closed.  Matched from beginning of string.
      # @param [String] button The display name of the button to be clicked.
      # @param [String] text The text of the window to be closed.  Matched from beginning of string.
      # @param [String] side A string identifying which mouse button to click.
      # @param [Fixnum] wait Number of seconds to wait for the popup to be seen.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] quiet If true, fewer messages and pass/fail validations are logged.
      def close_modal_ie(browser, title="", button="OK", text='', side = 'primary', wait = WAIT, desc = '', quiet = false)
        #TODO needs simplifying, incorporating text verification, and debug code cleaned up
        title = translate_popup_title(title)
        msg   = "Modal window (popup) '#{title}'"
        if @ai.WinWait(title, text, wait)
          myHandle = @ai.WinGetHandle(title, text)
          if myHandle.length > 0
            debug_to_log("hwnd: #{myHandle.inspect}")
            passed_to_log("#{msg} appeared.") unless quiet
            window_handle = "[HANDLE:#{myHandle}]"
            sleep_for(0.5)
            @ai.WinActivate(window_handle)
            if @ai.WinActive(window_handle)
              debug_to_log("#{msg} activated.")
              controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
              if not controlHandle.length > 0
                button        = "&#{button}"
                controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
              end
              debug_to_log("Handle for button '#{button}': [#{controlHandle}]")
              debug_to_log("#{msg} focus gained.")
              if @ai.ControlClick(title, '', "[CLASS:Button; TEXT:#{button}]")
                passed_to_log("#{msg} #{side} click on '[CLASS:Button; TEXT:#{button}]' successful.")
                sleep_for(0.5)
                if @ai.WinExists(window_handle)
                  debug_to_log("#{msg} close popup failed on click '#{button}'. Trying WinClose. (#{__LINE__})")
                  @ai.WinClose(title, text)
                  if @ai.WinExists(window_handle)
                    debug_to_log("#{msg} close popup failed with WinClose(#{window_handle}). (#{__LINE__})")
                    @ai.WinKill(window_handle)
                    if @ai.WinExists(window_handle)
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

      alias close_popup_validate_text close_modal_ie
      alias close_popup close_modal_ie

      #  private :close_modal_ie

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

      # Return a reference to an IE browser window based on one of its attributes.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the window: :url, :title, or :hwnd.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::IE] A reference to the popup.
      def find_popup(browser, how, what, desc = '')
        msg   = "Find popup :#{how}=>'#{what}'. #{desc}"
        popup = Watir::IE.find(how, what) # TODO: too browser specific
        sleep_for(1)
        debug_to_log("#{popup.inspect}")
        if is_browser?(popup)
    #      title = popup.title
          passed_to_log(msg)
          return popup
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to find popup :#{how}=>'#{what}'. #{desc} '#{$!}' (#{__LINE__})")
      end

      # Confirm that the object passed in +browser+ is actually a Browser object.
      # @param [Watir::Browser] browser A reference to the window or container element to be tested.
      def is_browser?(browser)
        myClass = browser.class.to_s
        case @targetBrowser.abbrev
          when 'IE'
            myClass =~ /Watir::IE|Watir::Browser/i
          when 'FF'
            myClass =~ /Watir::Browser/i
          when 'S'
            myClass =~ /Watir::Safari/i
          when 'C'
            myClass =~ /Watir::Browser/i
        end
      end

      alias is_browser is_browser?

      # Translate window title supplied in +title+ to a title appropriate for the targeted browser and version
      # actually being run.
      # Used primarily for handling of modal popups and dialogs.
      # This allows cross-browser compatibility for handling modal popups and other windows accessed by titlt.
      # @param [String] title The title of the window to be closed.
      def translate_popup_title(title)
        new_title = title
        case @browserAbbrev
          when 'IE'
            if @browserVersion
              case @browserVersion
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
      def get_browser_version(browser)
        debug_to_log("starting get_browser_version")
        case @targetBrowser.abbrev
          when 'IE'
            @browserAbbrev  = 'IE'
            @browserName    = 'Internet Explorer'
            @browserAppInfo = browser.document.invoke('parentWindow').navigator.appVersion
            @browserAppInfo =~ /MSIE\s(.*?);/
            @browserVersion = $1
          when 'FF'
            #@browserAbbrev = 'FF'
            #@browserName   = 'Firefox'
            #js_stuff       = <<-end_js_stuff
            #var info = Components.classes["@mozilla.org/xre/app-info;1"]
            #.getService(Components.interfaces.nsIXULAppInfo);
            #[info, info.name, info.version];
            #end_js_stuff
            #js_stuff.gsub!("\n", " ")
            #info = browser.execute_script(js_stuff)
            #info, aName, @browserVersion = info.split(',')
            #debug_to_log("FF info: [#{info}]")
            #debug_to_log("FF name: [#{aName}]")
            #debug_to_log("FF vrsn: [#{@browserVersion}]")
            @browserAbbrev  = 'FF'
            @browserName    = 'Firefox'
            @browserVersion = '6.01' #TODO: get actual version from browser
            debug_to_log("Firefox, in get_browser_version (#{@browserVersion})")
          when 'S'
            @browserAbbrev  = 'S'
            @browserName    = 'Safari'
            @browserVersion = '5.0.4' #TODO: get actual version from browser itself
            debug_to_log("Safari, in get_browser_version (#{@browserVersion})")
          when 'C'
            @browserAbbrev  = 'C'
            @browserName    = 'Chrome'
            @browserVersion = '11.0' #TODO: get actual version from browser
            debug_to_log("Chrome, in get_browser_version (#{@browserVersion})")
        end
          # if [notify_queue, notify_class, notify_id].all?
          #  Resque::Job.create(notify_queue, notify_class, :id => notify_id, :browser_used => "#{@browserName} #{@browserVersion}")
          #end
      rescue
        debug_to_log("Unable to determine #{@browserAbbrev} browser version: '#{$!}' (#{__LINE__})")

          # TODO: can we get rid of this?
          # js for getting firefox version information
          #      function getAppID() {
          #        var id;
          #        if("@mozilla.org/xre/app-info;1" in Components.classes) {
          #          // running under Mozilla 1.8 or later
          #          id = Components.classes["@mozilla.org/xre/app-info;1"]
          #                         .getService(Components.interfaces.nsIXULAppInfo).ID;
          #        } else {
          #          try {
          #            id = Components.classes["@mozilla.org/preferences-service;1"]
          #                           .getService(Components.interfaces.nsIPrefBranch)
          #                           .getCharPref("app.id");
          #          } catch(e) {
          #            // very old version
          #            dump(e);
          #          }
          #        }
          #        return id;
          #      }
          #      alert(getAppID());
          # another snippet that shows getting attributes from object
          #      var info = Components.classes["@mozilla.org/xre/app-info;1"]
          #                 .getService(Components.interfaces.nsIXULAppInfo);
          #      // Get the name of the application running us
          #      info.name; // Returns "Firefox" for Firefox
          #      info.version; // Returns "2.0.0.1" for Firefox version 2.0.0.1
      ensure
        message_to_log("Browser: [#{@browserAbbrev} #{@browserVersion}]")
      end

      protected :get_browser_version

      #def filter_bailout_from_rescue(err, msg)
      #  if msg =~ /bailing out/i
      #    raise err
      #  else
      #    error_to_log(msg)
      #  end
      #end

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
      # @param [String] fileName The file name of the executing script.
      # @param [Fixnum] lnbr Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] dbg If true additional debug messages are written to the log.
      # @return [Boolean] True if no error conditions have been encountered.
      def validate(browser, fileName = '', lnbr = __LINE__, dbg = false)
        debug_to_log("#{__method__} begin") if dbg
        msg  = ''
        myOK = true
        if not browser
          msg  = "#{fileName}----browser is nil object. (#{lnbr})"
          myOK = false
        elsif not is_browser?(browser)
          msg = "#{fileName}----not a browser. (#{lnbr})"
          debug_to_log(browser.inspect)
          myOK = false

        else
          if browser.respond_to?(:url)
            if not browser.url == @currentURL
              @currentURL = browser.url
              debug_to_log("Current URL: [#{@currentURL}]")
              #        mark_testlevel( "Current URL: [#{@currentURL}]", 1 )
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
            browser_text = browser.text.downcase
          rescue => e
            if not rescue_me(e, __method__, "browser.text.downcase", "#{browser.class}", browser)
              debug_to_log("browser.text.downcase in #{__method__} #{browser.class}")
              debug_to_log("#{get_callers}")
              raise e
            else
              return true
            end
          end

          if browser_text
            if browser_text.match(/unrecognized error condition has occurred/i)
              msg  = "#{fileName}----Unrecognized Exception occurred. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/cannot find server or dns error/i)
              msg  = "#{fileName}----Cannot find server error or DNS error. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/the rpc server is unavailable/i)
              msg  = "#{fileName}----RPC server unavailable. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/404 not found/i) or
                browser_text.match(/the page you were looking for does\s*n[o']t exist/i)
              msg  = "#{fileName}----RFC 2068 HTTP/1.1: 404 URI Not Found. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/we're sorry, but something went wrong/i) or
                browser_text.match(/http status 500/i)
              msg  = "#{fileName}----RFC 2068 HTTP/1.1: 500 Internal Server Error. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/internet explorer cannot display the webpage/i)
              msg  = "#{fileName}----Probably RFC 2068 HTTP/1.1: 500 Internal Server Error. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/503.*service unavailable/i)
              msg  = "#{fileName}----RFC 2068 HTTP/1.1: 503 Service Unavailable. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/java.lang.NullPointerException/i)
              msg  = "#{fileName}----java.lang.NullPointerException. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/due to unscheduled maintenance/i)
              msg  = "#{fileName}----Due to unscheduled maintenance. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/network\s+error\s*(.+)$/i)
              $1.chomp!
              msg  = "#{fileName}----Network Error #{$1}. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/warning: page has expired/i)
              msg  = "#{fileName}----Page using information from form has expired. Not automatically resubmitted. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/no backend server available/i)
              msg  = "#{fileName}----Cannot Reach Server (#{lnbr})"
              myOK = false

            elsif browser_text.match(/sign on\s+.+\s+unsuccessful/i)
              msg  = "#{fileName}----Invalid Id or Password (#{lnbr})"
              myOK = false

            elsif browser_text.match(/you are not authorized/i)
              msg  = "#{fileName}----Not authorized to view this page. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/too many incorrect login attempts have been made/i)
              msg  = "#{fileName}----Invalid Id or Password. Too many tries. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/system error\.\s+an error has occurred/i)
              msg  = "#{fileName}----System Error. An error has occurred. Please try again or call the Help Line for assistance. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/Internal Server failure,\s+NSAPI plugin/i)
              msg  = "#{fileName}----Internal Server failure, NSAPI plugin. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/Error Page/i)
              msg  = "#{fileName}----Error Page. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/The website cannot display the page/i)
              msg  = "#{fileName}----HTTP 500. (#{lnbr})"
              myOK = false

              #        elsif browser_text.match(/Insufficient Data/i)
              #          msg  = "#{fileName}----Insufficient Data. (#{lnbr})"
              #          myOK = false

            elsif browser_text.match(/The timeout period elapsed/i)
              msg  = "#{fileName}----Time out period elapsed or server not responding. (#{lnbr})"
              myOK = false

            elsif browser_text.match(/Unexpected\s+errors*\s+occur+ed\.\s+(?:-+)\s+(.+)/i)
              msg = "#{fileName}----Unexpected errors occurred. #{$2.slice(0, 120)} (#{lnbr})"
              if not browser_text.match(/close the window and try again/i)
                myOK = false
              else
                debug_to_log("#{msg}")
              end

            elsif browser_text.match(/Server Error in (.+) Application\.\s+(?:-+)\s+(.+)/i)
              msg  = "#{fileName}----Server Error in #{1} Application. #{$2.slice(0, 100)} (#{lnbr})"
              myOK = false

            elsif browser_text.match(/Server Error in (.+) Application\./i)
              msg  = "#{fileName}----Server Error in #{1} Application. '#{browser_text.slice(0, 250)}...' (#{lnbr})"
              myOK = false

            elsif browser_text.match(/An error has occur+ed\. Please contact support/i)
              msg  = "#{fileName}----An error has occurred. Please contact support (#{lnbr})"
              myOK = false

            end
          else
            debug_to_log("browser.text returned nil")
          end
        end

        if not myOK
          msg << " (#{browser.url})"
          puts msg
          debug_to_log(browser.inspect)
          debug_to_log(browser.text)
          fatal_to_log(msg, lnbr)
          raise(RuntimeError, msg, caller)
        else
          debug_to_log("#{__method__} returning OK") if dbg
          return myOK
        end

      rescue
        errmsg = $!
        if errmsg.match(msg)
          errmsg = ''
        end
        bail_out(browser, lnbr, "#{msg} #{errmsg}")
      end

      alias validate_browser validate

      # @!endgroup Error Handling

      # @!group Backward compatible usages

      # Returns a reference to a browser window using the window's :url attribute. Calls attach_browser().
      # @example
      #  mainwindow = open_browser('www.google.com')
      #  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
      #  popup = attach_browser_by_url(mainwindow, '[url of new window]')
      # @param [Watir::Browser] browser A reference to the current browser window.
      # @param [String, Regexp] what The value in the targeted attribute that uniquely identifies the new window
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::Browser]
      def attach_browser_by_url(browser, what, desc = '')
        attach_browser(browser, :url, what, desc)
      end

      alias attach_browser_with_url attach_browser_by_url

      # Returns a reference to a new browser window identified by its :title attribute.  Used to attach a new browser window to a variable
      # which can then be passed to methods that require a *browser* parameter. Calls attach_browser().
      # @param (see #attach_browser_by_url)
      def attach_popup_by_title(browser, what, desc = '')
        attach_popup(browser, :title, what, desc)
      end

      # Returns a reference to a new browser window identified by its :url attribute.  Used to attach a new browser window to a variable
      # which can then be passed to methods that require a *browser* parameter. Calls attach_browser().
      # @param (see #attach_browser_by_url)
      def attach_popup_by_url(browser, what, desc = '')
        attach_popup(browser, :url, what, desc)
      end

      alias get_popup_with_url attach_popup_by_url
      alias attach_popup_with_url attach_popup_by_url
      alias attach_iepopup attach_popup_by_url

      def close_popup_by_button_title(popup, strg, desc = '')
        click(popup, :link, :title, strg, desc)
      end

      # @!endgroup Backward


    end
  end
end

