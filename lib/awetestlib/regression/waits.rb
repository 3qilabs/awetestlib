module Awetestlib
  module Regression
    module Waits

      def sleep_for(seconds, dbg = true, desc = '')
        msg = "Sleeping for #{seconds} seconds."
        msg << " #{desc}" if desc.length > 0
        info_to_log(msg)
        sleep(seconds)
      end

      # howLong is integer, whatFor is a browser object
=begin rdoc
:tags:wait
howLong is the number of seconds, text is a string to be found, threshold is the number of seconds
after which a fail message is generated even though the text was detected within the howLong limit.
Use this in place of wait_until_by_text when the wait time needs to be longer than the test automation default.
=end
      def hold_for_text(browser, howLong, text, desc = '', threshold = 20, interval = 0.25)
        countdown = howLong
        while ((not browser.contains_text(text)) and countdown > 0)
          sleep(interval)
          countdown = countdown - interval
        end
        if countdown < howLong
          waittime = howLong - countdown
          passed_tolog("#{__method__}  '#{text}' found after #{waittime} second(s) #{desc}")
          if waittime > threshold
            failed_tolog("#{__method__}  '#{text}' took #{waittime} second(s). (threshold: #{threshold} seconds) #{desc}")
          end
          true
        else
          failed_tolog("#{__method__}  '#{text}' not found after #{howLong} second(s) #{desc}")
          false
        end
      rescue
        failed_tolog("Unable to #{__method__} '#{text}'. '#{$!}' #{desc}")
      end

      alias wait_for_text hold_for_text

      # howLong is integer, whatFor is a browser object
      def wait_for_text(browser, howLong, text)
        countdown = howLong
        while ((not browser.contains_text(text)) and countdown > 0)
          sleep(1)
          countdown = countdown - 1
        end
        if countdown
          passed_tolog("wait_for_text '#{text}' found after #{howLong} second(s)")
        else
          failed_tolog("wait_for_text '#{text}' not foundafter #{howLong} second(s)")
        end
        countdown
      end

      def wait_for_element_to_reappear(browser, how, what, desc = '', timeout = 20)
        msg = "Element #{how}=#{what} exists. #{desc}"
        wait_while(browser, "While: #{msg}", timeout) { browser.element(how, what).exists? }
        wait_until(browser, "Until: #{msg}", timeout) { browser.element(how, what).exists? }
      end

      # howLong is integer, whatFor is a browser object
      def wait_for_exists(howLong, whatFor)
        wait_for(howLong, whatFor)
      end

      def wait_for(howLong, whatFor)
        countdown = howLong
        while ((not whatFor.exists?) and countdown > 0)
          sleep(1)
          puts whatFor.inspect+':'+countdown.to_s
          countdown = countdown - 1
        end
        if countdown
          puts 'found '+whatFor.inspect
          passed_tolog("wait_for (#{howLong} found "+whatFor.inspect)
        else
          puts 'Did not find '+whatFor.inspect
          failed_tolog("wait_for (#{howLong} did not find "+whatFor.inspect)
        end
        countdown
      end

      def wait_the_hard_way(browser, how, what, wait = 6, intvl = 0.25)
        count = (wait / intvl).to_i + 1
        tally = 0
        ok    = (1 / intvl).to_i + 1
        debug_to_log("#{__method__}: wait: #{wait} secs; intvl: #{intvl} secs; count; #{count}; thresh: #{ok}")
        (1..count).each do |x|
          begin
            if browser.element(how, what).exists?
              tally += 1
              debug_to_log("#{x}: #{(x - 1) * intvl}: #{what} exists.")
            else
              tally = 0
              debug_to_log("#{x}: #{(x - 1) * intvl}: #{what} does not exist.")
            end
          rescue
            tally = 0
            debug_to_log("#{x}: #{(x - 1) * intvl}: #{what} rescue: #{$!}")
          end
          if tally >= ok
            return true
          end
          sleep(intvl)
        end
      end

      def wait_until_exists(browser, element, how, what, desc = '')
        msg = "Wait until (#{element} :#{how}=>#{what}) exists."
        msg << " #{desc}" if desc.length > 0
        start = Time.now.to_f
        # TODO: try Watir::Wait.until { browser.element(how, what).exists? } instead of this (cumbersome) case statement
        # TODO: above fails on frame
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
          elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        #debug_to_log("#{__method__}: start:#{start} stop:#{stop}")
        #    sleep 1
        passed_to_log("#{msg} (#{stop - start} seconds)")
        true
      rescue
        failed_to_log("Unable to complete #{msg}: '#{$!}'")
      end

      def wait_while(browser, desc, timeout = 45, &block)
        #TODO: Would like to be able to see the block code in the log message instead of the identification
        msg   = "Wait while #{desc}:"
        start = Time.now.to_f
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
        #debug_to_log("#{__method__}: start:#{start} stop:#{stop} block: #{block.to_s}")
                                                                     #    sleep 1
        passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)") #  {#{block.to_s}}")
        true
      rescue
        failed_to_log("Unable to complete #{msg}. '#{$!}'")
      end

      alias wait_while_true wait_while

      def wait_until(browser, desc, timeout = 45, skip_pass = false, &block)
        #TODO: Would like to be able to see the block code in the log message instead of the identification
        msg   = "Wait until #{desc}"
        start = Time.now.to_f
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
        #debug_to_log("#{__method__}: start:#{start} stop:#{stop} block: #{block.to_s}")
                                                                                      #    sleep 1
        passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)") unless skip_pass #  {#{block.to_s}}")
        true
      rescue
        failed_to_log("Unable to complete #{msg}  '#{$!}'")
      end

      alias wait_until_true wait_until

      def wait_until_by_radio_value(browser, strg, desc = '')
        wait_until_exists(browser, :radio, :value, strg, desc)
      end

      def wait_until_ready(browser, how, what, desc = '', timeout = 90, verbose = false)
        msg = "#{__method__.to_s.titleize}: element: #{how}='#{what}'"
        msg << " #{desc}" if desc.length > 0
        proc_exists  = Proc.new { browser.element(how, what).exists? }
        proc_enabled = Proc.new { browser.element(how, what).enabled? }
        case how
          when :href
            proc_exists  = Proc.new { browser.link(how, what).exists? }
            proc_enabled = Proc.new { browser.link(how, what).enabled? }
        end
        if verbose
          if wait_until(browser, "#{msg} Element exists.", timeout) { proc_exists.call(nil) }
            if wait_until(browser, "#{msg} Element enabled.", timeout) { proc_enabled.call(nil) }
              passed_to_log(msg)
              true
            else
              failed_to_log(msg)
            end
          else
            failed_to_log(msg)
          end
        else
          start = Time.now.to_f
          if Watir::Wait.until(timeout) { proc_exists.call(nil) }
            if Watir::Wait.until(timeout) { proc_enabled.call(nil) }
              stop = Time.now.to_f
              #debug_to_log("#{__method__}: start:#{"%.5f" % start} stop:#{"%.5f" % stop}")
              passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)")
              true
            else
              failed_to_log(msg)
            end
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to #{msg}. '#{$!}'")
      end

      def wait_until_ready_quiet(browser, how, what, desc = '', timeout = 45, quiet = true)
        msg = "#{__method__.to_s.titleize}: element: #{how}='#{what}'"
        msg << " #{desc}" if desc.length > 0
        proc_exists  = Proc.new { browser.element(how, what).exists? }
        proc_enabled = Proc.new { browser.element(how, what).enabled? }
        case how
          when :href
            proc_exists  = Proc.new { browser.link(how, what).exists? }
            proc_enabled = Proc.new { browser.link(how, what).enabled? }
        end
        start = Time.now.to_f
        if Watir::Wait.until(timeout) { proc_exists.call(nil) }
          if Watir::Wait.until(timeout) { proc_enabled.call(nil) }
            stop = Time.now.to_f
            #debug_to_log("#{msg}: start:#{"%.5f" % start} stop:#{"%.5f" % stop}")
            passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)") unless quiet
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to #{msg}. '#{$!}'")
      end

      def wait_until_text(browser, strg, desc = '', timeout = 60)
        if not strg.class.to_s.match('String')
          raise "#{__method__} requires String for search target. #{strg.class} is not supported."
        end
        wait_until(browser, "'#{strg}' #{desc}", timeout) { browser.text.include? strg }
      end

      alias wait_until_by_text wait_until_text

      def wait_until_by_link_text(browser, strg, desc = '')
        wait_until_exists(browser, :link, :text, strg, desc)
      end

      def wait_until_enabled(browser, what, how, value, desc = '')
        # TODO: This can be simplified
        start = Time.now.to_f
        begin
          case what
            when :link
              Watir::Wait.until { browser.link(how, value).enabled? }
            when :button
              Watir::Wait.until { browser.button(how, value).enabled? }
            when :radio
              Watir::Wait.until { browser.radio(how, value).enabled? }
            when :checkbox
              Watir::Wait.until { browser.checkbox(how, value).enabled? }
            when :div
              Watir::Wait.until { browser.div(how, value).enabled? }
            when :select_list
              Watir::Wait.until { browser.select_list(how, value).enabled? }
            when :text_field
              Watir::Wait.until { browser.text_field(how, value).enabled? }
            when :table
              Watir::Wait.until { browser.table(how, value).enabled? }
            else
              raise "#{__method__}: Element #{what} not supported."
          end
        rescue => e
          if e.class.to_s =~ /TimeOutException/
            failed_to_log("Wait until (#{what} :#{how}=>#{value}) enabled. #{desc}: '#{$!}' #{desc}")
            return false
          elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        #debug_to_log("#{__method__}: start:#{start} stop:#{stop}")
        #    sleep 1
        passed_to_log("Wait until (#{what} :#{how}=>#{value}) enabled. #{desc} (#{stop - start} seconds)")
        true
      rescue
        failed_to_log("Unable to complete wait until (#{what} :#{how}=>#{value}) enabled. #{desc}: '#{$!}'")
      end

      def wait_until_visible(browser, element, how, what, desc = '')
        start = Time.now.to_f
        Watir::Wait.until(20) { browser.element(how, what).exists? }
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
          elsif not rescue_me(e, __method__, '', "#{browser.class}")
            raise e
          end
        end
        stop = Time.now.to_f
        #debug_to_log("#{__method__}: start:#{start} stop:#{stop}")
        #    sleep 1
        passed_to_log("Wait until (#{element} :#{how}=>#{what}) visible. #{desc} (#{stop - start} seconds)")
        true
      rescue
        failed_to_log("Unable to complete wait until (#{element} :#{how}=>#{what}) visible. #{desc}: '#{$!}'")
      end

    end
  end
end

