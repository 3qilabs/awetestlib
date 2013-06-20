module Awetestlib
  module Regression
    # Methods for waiting until something has happened, or waiting while a condition exists, in the browser or DOM.
    # sleep_for() is the basic technique. Its disadvantage is that it needs to be set for the longest likely wait time.
    # The wait methods take advantage of the Watir and Watir Webdriver wait functionality to pause only as long as necessary for
    # the element in question to be in the state needed.
    module Waits

      # @!group Core

      # Sleep for *seconds* seconds before continuing execution of the script.
      # A message is logged (but not reported) which, by default, includes a trace showing where in the script the sleep was invoked.
      # @param [Fixnum] seconds The number of seconds to wait.
      # @param [Boolean] dbg If true, includes a trace in the message
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output.
      def sleep_for(seconds, dbg = true, desc = '')
        trace = "\n#{get_debug_list}" if dbg
        msg = build_message("Sleeping for #{seconds} seconds.", desc, trace)
        info_to_log(msg)
        sleep(seconds)
      end

      # Wait while an element identified by attribute *how* with value *what* 1) exists, disappears, and exists again.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] timeout
      # @return [Boolean] Returns true if disappears and reappears, each within the *timeout* limit
      def wait_for_element_to_reappear(browser, how, what, desc = '', timeout = 20)
        msg = "Element #{how}=#{what} exists. #{desc}"
        wait_while(browser, "While: #{msg}", timeout) { browser.element(how, what).exists? }
        wait_until(browser, "Until: #{msg}", timeout) { browser.element(how, what).exists? }
      end

      # Wait until element of type *element*, identified by attribute *how* with value *what* exists on the page.
      # Timeout is the default used by watir (60 seconds)
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if element exists within timeout limit
      def wait_until_exists(browser, element, how, what, desc = '')
        msg = build_message("Wait until (:#{element} :#{how}=>'#{what}') exists.", desc)
        start = Time.now.to_f
        # TODO: try Watir::Wait.until { browser.element(how, what).exists? } instead of this (cumbersome) case statement
        # TODO: above fails on frame
        # TODO: Webdriver compatibility?
        Watir::Wait.until { browser.exists? }
        begin
          case element
            when :link
              Watir::Wait.until { browser.link(how, what).exists? }
            when :button
              Watir::Wait.until { browser.button(how, what).exists? }
            when :radio
              Watir::Wait.until { browser.radio(how, what).exists? }
            when :checkbox
              Watir::Wait.until { browser.checkbox(how, what).exists? }
            when :div
              Watir::Wait.until { browser.div(how, what).exists? }
            when :select_list
              Watir::Wait.until { browser.select_list(how, what).exists? }
            when :text_field
              Watir::Wait.until { browser.text_field(how, what).exists? }
            when :frame
              Watir::Wait.until { browser.frame(how, what).exists? }
            when :form
              Watir::Wait.until { browser.form(how, what).exists? }
            when :cell
              Watir::Wait.until { browser.cell(how, what).exists? }
            when :image
              Watir::Wait.until { browser.image(how, what).exists? }
            else
              Watir::Wait.until { browser.element(how, what).exists? }
          end
        rescue => e
          if e.class.to_s =~ /TimeOutException/
            failed_to_log("#{msg}: '#{$!}'")
            return false
          elsif not rescue_me(e, __method__, rescue_me_command(element, how, what, :exists?), "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        msg += " (#{"%.5f" % (stop - start)} seconds)"
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      # Wait _while_ expression in *&block* returns true.
      # @example
      #   wait_while(browser, 'Textfield is enabled.', 10) { browser.text_field(:id, 'this text field').enabled?}
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] timeout Maximum time to wait, in seconds.
      # @param [Proc] &block A ruby expression that evaluates to true or false. The expression
      #  is usually a watir or watir-webdriver command like .exists?, enabled?, etc. on a
      #  specific DOM element. Note that *&block* is listed as the last parameter inside the signature
      #  parentheses, but is passed in curly braces outside the signature parentheses in the call.  This is
      #  the way Ruby works.
      # @return [Boolean] True if condition returns false within time limit.
      def wait_while(browser, desc, timeout = 45, &block)
        #TODO: Would like to be able to see the block code in the log message instead of the identification
        msg   = build_message("Wait while", desc)
        start = Time.now.to_f
        Watir::Wait.until { browser.exists? }
        begin
          #Watir::Wait.until(timeout) { block.call(nil) }
          if block.call(nil)
            Watir::Wait.while(timeout) { block.call(nil) }
          end
        rescue => e
          if e.class.to_s =~ /TimeOutException/ or e.message =~ /timed out/
            failed_to_log("#{msg}: '#{$!}' ")
            return false
          elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        msg += " (#{"%.5f" % (stop - start)} seconds)"
        passed_to_log(msg)
        true
      rescue
        failed_to_log("Unable to complete #{msg}. '#{$!}'")
      end

      alias wait_while_true wait_while

      # Wait _until_ expression in *&block* returns true.
      # @example
      #   wait_until(browser, 'Textfield is enabled.', 10) { browser.text_field(:id, 'this text field').exists?}
      #
      # @param (see #wait_while)
      # @return [Boolean] True if condition in *&block* returns true within time limit.
      def wait_until(browser, desc, timeout = 45, skip_pass = false, &block)
        #TODO: Would like to be able to see the block code in the log message instead of the identification
        msg   = build_message("Wait until", desc)
        start = Time.now.to_f
        Watir::Wait.until { browser.exists? }
        begin
          Watir::Wait.until(timeout) { block.call(nil) }
        rescue => e
          if e.class.to_s =~ /TimeOutException/ or e.message =~ /timed out/
            failed_to_log("#{msg} '#{$!}'")
            return false
          elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        msg += " (#{"%.5f" % (stop - start)} seconds)"
        passed_to_log(msg) unless skip_pass #  {#{block.to_s}}")
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      alias wait_until_true wait_until

      # Wait _until_ element, identified by attribute *how* and its value *what*, exists.
      # If it exists within *timeout* seconds then wait _until_ it is enabled.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] timeout Maximum time to wait, in seconds.
      # @param [Boolean] verbose When set to true, actual wait time is reported.
      # @param [Boolean] quiet When set to true, only fail messages are logged and reported.
      # @return [Boolean] True if element is ready within time limit.
      def wait_until_ready(browser, how, what, desc = '', timeout = 90, verbose = true, quiet = false)
        msg = build_message("Wait until element :#{how}=>'#{what}') is ready.", desc)
        ok  = false
        start = Time.now.to_f if verbose
        Watir::Wait.until(timeout) { browser.exists? }

        if $using_webdriver
          proc_present = Proc.new { browser.element(how, what).present? }
          if Watir::Wait.until(timeout) { proc_present.call(nil) }
            ok = true
          end
        else
          proc_exists  = Proc.new { browser.element(how, what).exists? }
          proc_enabled = Proc.new { browser.element(how, what).enabled? }
          if how == :href
            proc_exists  = Proc.new { browser.link(how, what).exists? }
            proc_enabled = Proc.new { browser.link(how, what).enabled? }
          end
          if Watir::Wait.until(timeout) { proc_exists.call(nil) }
            if Watir::Wait.until(timeout) { proc_enabled.call(nil) }
              ok = true
            end
          end
        end

        if verbose
          stop = Time.now.to_f
          msg += " (#{"%.5f" % (stop - start)} seconds)"
        end
        if ok
          unless quiet
            passed_to_log(msg)
          end
        else
          failed_to_log(msg)
        end
        ok
      rescue
        failed_to_log(unable_to(msg))
      end

      # Wait _until_ element, identified by attribute *how* and its value *what*, exists.
      # If it exists within *timeout* seconds then wait _until_ it is enabled. By default reports only failures.
      # @param (see #wait_until_ready)
      # @return [Boolean] True if  element is ready within time limit.
      def wait_until_ready_quiet(browser, how, what, desc = '', timeout = 90, quiet = true, verbose = false)
        wait_until_ready(browser, how, what, desc, timeout, verbose, quiet)
      end

      def wait_until_text(browser, strg, desc = '', timeout = 60)
        if not strg.class.to_s.match('String')
          raise "#{__method__} requires String for search target. #{strg.class} is not supported."
        end
        if $using_webdriver
          browser.wait(timeout)
        end
        wait_until(browser, "'#{strg}' #{desc}", timeout) { browser.text.include? strg }
      end

      alias wait_until_by_text wait_until_text

      def wait_until_enabled(browser, element, how, what, desc = '')
        wait_until_ready(browser, how, what, desc, timeout = 90, verbose = true, quiet = false)
      end

      def wait_until_visible(browser, element, how, what, desc = '', timeout = 60)
        msg = build_message("Wait until #{element} :#{how}=>'#{what}') is visible.", desc)
        start = Time.now.to_f
        Watir::Wait.until { browser.exists? }
        sleep_for(1)
        Watir::Wait.until(timeout) { browser.element(how, what).exists? }
        begin
          case element
            when :link
              Watir::Wait.until { browser.link(how, what).visible? }
            when :button
              Watir::Wait.until { browser.button(how, what).visible? }
            when :radio
              Watir::Wait.until { browser.radio(how, what).visible? }
            when :checkbox
              Watir::Wait.until { browser.checkbox(how, what).visible? }
            when :div
              Watir::Wait.until { browser.div(how, what).visible? }
            when :select_list
              Watir::Wait.until { browser.select_list(how, what).visible? }
            when :text_field
              Watir::Wait.until { browser.text_field(how, what).visible? }
            else
              Watir::Wait.until { browser.element(how, what).visible? }
            #          raise "#{__method__}: Element #{what} not supported."
          end
        rescue => e
          if e.class.to_s =~ /TimeOutException/
            failed_to_log("Wait until (#{what} :#{how}=>#{what}) visible. #{desc}: '#{$!}' #{desc}")
            return false
          elsif not rescue_me(e, __method__, rescue_me_command(element, how, what, :visible?), "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        msg += " (#{"%.5f" % (stop - start)} seconds)"
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      # @!endgroup Core

      # @!group  Altenatives

      # Wait for a specific text to appear in the *browser*.
      # @note This is a last resort method when other wait or wait until avenues have been exhausted.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] text A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] threshold The number of seconds after which a warning is added to the report message.
      # @param [Fixnum] interval The time between checks that the text exists.
      # @return [Boolean] Returns true if the text appears before *how_long* has expired.
      def hold_for_text(browser, how_long, text, desc = '', threshold = 20, interval = 0.25)
        countdown = how_long
        Watir::Wait.until { browser.exists? }
        sleep_for(1)
        while ((not browser.contains_text(text)) and countdown > 0)
          sleep(interval)
          countdown = countdown - interval
        end
        if countdown < how_long
          waittime = how_long - countdown
          passed_to_log("#{__method__}  '#{text}' found after #{waittime} second(s) #{desc}")
          if waittime > threshold
            failed_to_log("#{__method__}  '#{text}' took #{waittime} second(s). (threshold: #{threshold} seconds) #{desc}")
          end
          true
        else
          failed_to_log("#{__method__}  '#{text}' not found after #{how_long} second(s) #{desc}")
          false
        end
      rescue
        failed_to_log("Unable to #{__method__} '#{text}'. '#{$!}' #{desc}")
      end

      alias wait_for_text hold_for_text

      # Wait up to *how_long* seconds for DOM element *what_for* to exist in the page.
      # @note This is a last resort method when other wait or wait until avenues have been exhausted.
      # @param [Fixnum] how_long Timeout limit
      # @param [Watir::Element] what_for A reference to a Dom element to wait for.
      def wait_for_exists(how_long, what_for)
        wait_for(how_long, what_for)
      end

      # Wait up to *how_long* seconds for DOM element *what_for* to exist in the page.
      # @note This is a last resort method when other wait or wait until avenues have
      # been exhausted.
      # @param [Fixnum] how_long Timeout limit
      # @param [Watir::Element] what_for A reference to a Dom element to wait for.
      def wait_for(how_long, what_for, interval = 0.25)
        countdown = how_long
        while ((not what_for.exists?) and countdown > 0)
          sleep(interval)
          puts what_for.inspect+':'+countdown.to_s
          countdown = countdown - interval
        end
        if countdown
          puts 'found '+what_for.inspect
          passed_tolog("wait_for (#{how_long} found "+what_for.inspect)
        else
          puts 'Did not find '+what_for.inspect
          failed_tolog("wait_for (#{how_long} did not find "+what_for.inspect)
        end
        countdown
      end

      # Wait up to *how_long* seconds for DOM element identified by attribute *how* and its value
      # *what* to exist in the page.
      # @note This is a last resort method when other wait or wait until avenues have been exhausted.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [Fixnum] wait Timeout limit.
      # @param [Fixnum] interval How long to wait before checking again.
      # @return [Boolean] True if element exists within *wait* time
      def wait_the_hard_way(browser, how, what, wait = 6, interval = 0.25)
        count = (wait / interval).to_i + 1
        tally = 0
        ok    = (1 / interval).to_i + 1
        debug_to_log("#{__method__}: wait: #{wait} secs; interval: #{interval} secs; count; #{count}; thresh: #{ok}")
        Watir::Wait.until { browser.exists? }
        sleep_for(1)
        (1..count).each do |x|
          begin
            if browser.element(how, what).exists?
              tally += 1
              debug_to_log("#{x}: #{(x - 1) * interval}: #{what} exists.")
            else
              tally = 0
              debug_to_log("#{x}: #{(x - 1) * interval}: #{what} does not exist.")
            end
          rescue
            tally = 0
            debug_to_log("#{x}: #{(x - 1) * interval}: #{what} rescue: #{$!}")
          end
          if tally >= ok
            return true
          end
          sleep(interval)
        end
      end

      # @!endgroup Alternatives

    end
  end
end

