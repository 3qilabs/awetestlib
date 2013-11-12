module Awetestlib
  # Awetest DSL for browser based testing.
  module Regression
    # Methods covering user interactions with the browser.
    module UserInput

      # Click a specific DOM element identified by one of its attributes (*how*) and that attribute's value (*what*).
      #
      # @example
      #  # html for a link element:
      #  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
      #
      #  click(browser, :link, :text, 'Pickaxe')
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if the Watir or Watir-webdriver function does not throw an exception.
      #
      def click(container, element, how, what, desc = '', wait = 10)
        msg  = build_message("#{__method__.to_s.humanize} :#{element} :#{how}=>'#{what}'", desc, wait.to_s)
        code = build_webdriver_fetch(element, how, what)
        begin
          eval("#{code}.when_present(#{wait}).click")
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(element, how, what, __method__.to_s), "#{container.class}")
            raise e
          end
        end
        passed_to_log(msg)
        true
      rescue
        if desc =~ /second try/i
          passed_to_log(unable_to(msg))
        else
          failed_to_log(unable_to(msg))
        end
      end

      alias click_js click

      def click_as_needed(browser, target_container, target_elem, target_how, target_what, confirm_container, confirm_elem, confirm_how, confirm_what, desc = '', neg = false)
        rtrn = true
        nope = neg ? 'not ' : ''
        debug_to_log("#{__method__.to_s.titleize}: Target:  :#{target_elem} :#{target_how}=>'#{target_what}' in #{target_container}")
        debug_to_log("#{__method__.to_s.titleize}: Confirm: :#{confirm_elem} :#{confirm_how}=>'#{confirm_what}' in #{confirm_container}")
        windows_to_log(browser)
        click(target_container, target_elem, target_how, target_what, desc)

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
        limit = 30.0
        increment = 0.5
        seconds = 0.0
        until eval(code) do
          debug_to_log("#{__method__}: seconds=[#{seconds}] [#{code}]")
          sleep(increment)
          seconds += increment
          if seconds.modulo(3.0) == 0.0
            click(target_container, target_elem, target_how, target_what, "#{desc} (#{seconds} seconds)")
          end
          if seconds > limit
            rtrn = false
            break
          end
        end
        rtrn
      rescue
        failed_to_log(unable_to)
      end

      # Click a specific DOM element by one of its attributes (*how) and that attribute's value (*what) and
      # do not wait for the browser to finish reloading.  Used when a modal popup or alert is expected. Allows the script
      # to keep running so the popup can be handled.
      #
      # Call is passed to click() if using watir-webdriver as it does not recognize click_no_wait.
      #
      # @example
      #  # html for a link element:
      #  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
      #
      #  click_no_wait(browser, :link, :text, 'Pickaxe')
      #
      # @see #click
      #
      # @param (see #click)
      # @return (see #click)
      #
      def click_no_wait(browser, element, how, what, desc = '')
        if $using_webdriver
          click(browser, element, how, what, "#{desc} (called from click_no_wait)") # [#50300875]
        else
          msg = build_message("#{__method__.to_s.humanize} :#{element} :#{how}=>'#{what}'", desc)
          begin
            case element
              when :link
                browser.link(how, what).click_no_wait
              when :button
                browser.button(how, what).click_no_wait
              when :image
                browser.image(how, what).click_no_wait
              when :radio
                case how
                  when :index
                    set_radio_no_wait_by_index(browser, what, desc)
                  else
                    browser.radio(how, what).click_no_wait
                end
              when :span
                browser.span(how, what).click_no_wait
              when :div
                browser.div(how, what).click_no_wait
              when :checkbox
                browser.checkbox(how, what).click_no_wait
              when :cell
                browser.cell(how, what).click_no_wait
              else
                browser.element(how, what).click_no_wait
            end
          rescue => e
            unless rescue_me(e, __method__, rescue_me_command(element, how, what, :click_no_wait), "#{browser.class}")
              raise e
            end
          end
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to #{msg}  '#{$!}'")
        sleep_for(1)
      end

      # Click an image element identified by the value of its *:src* attribute and its index
      # within the array of image elements with src containing <b>*what*</b> and
      # within the container referred to by <b>*browser*</b>.
      # @param [Watir::Browser, Watir::Container] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Fixnum] index An integer that indicates the index of the element within the array of image elements with src containing <b>*what*</b>.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def click_img_by_src_and_index(browser, what, index, desc = '')
        msg = "Click image by src='#{what}' and index=#{index}"
        msg << " #{desc}" if desc.length > 0
        browser.image(:src => what, :index => index).click
        passed_to_log(msg)
        true
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      # Click the first row which contains a particular string in a table identified by attribute and value.
      # A specific column in the table can also be specified.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] text Full text string to be found in the table row.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] column Integer indicating the column to search for the text string.
      # If not supplied all columns will be checked.
      # @return (see #click)
      #
      def click_table_row_with_text(browser, how, what, text, desc = '', column = nil)
        msg   = build_message("Click row with text #{text} in table :#{how}=>'#{what}.", desc)
        table = get_table(browser, how, what, desc)
        if table
          index = get_index_of_row_with_text(table, text, column)
          if index
            table[index].click
            passed_to_log(msg)
            index
          else
            failed_to_log("#{msg} Row not found.")
          end
        else
          failed_to_log("#{msg} Table not found.")
        end
      rescue
        failed_to_log("Unable to #{msg}: '#{$!}'")
      end

      # Double click the first row which contains a particular string in a table identified by attribute and value.
      # A specific column in the table can also be specified.
      # Uses fire_event method in Watir to send 'onDblClick' event.
      # @param (see #click_table_row_with_text)
      # @return (see #click)
      #
      def double_click_table_row_with_text(browser, how, what, text, desc = '', column = nil)
        msg   = build_message("Double click row with text #{text} in table :#{how}=>'#{what}.", desc)
        table = get_table(browser, how, what, desc)
        if table
          index = get_index_of_row_with_text(table, text, column)
          if index
            table[index].fire_event('ondblclick')
            passed_to_log(msg)
            index
          else
            failed_to_log("#{msg} Row not found.")
          end
        else
          failed_to_log("#{msg} Table not found.")
        end
      rescue
        failed_to_log("Unable to #{msg}: '#{$!}'")
      end

      # Click a specifific button on a popup window.
      # (Windows only)
      # @param [String] title A string starting at the beginning of the title which uniquely identifies the popup window.
      # @param [String] button The value displayed for the button (e.g. OK, Yes, Cancel, etc)
      # @param [Fixnum] wait Integer indicating the number of seconds to wait for the popup window to appear.
      # @return (see #click)
      def click_popup_button(title, button, wait= 9, user_input=nil)
        #TODO: is winclicker still viable/available?
        wc = WinClicker.new
        if wc.clickWindowsButton(title, button, wait)
          passed_to_log("Window '#{title}' button '#{button}' found and clicked.")
          true
        else
          failed_to_log("Window '#{title}' button '#{button}' not found. (#{__LINE__})")
        end
        wc = nil
        # get a handle if one exists
        #    hwnd = $ie.enabled_popup(wait)
        #    if (hwnd)  # yes there is a popup
        #      w = WinClicker.new
        #      if ( user_input )
        #        w.setTextValueForFileNameField( hwnd, "#{user_input}" )
        #      end
        #      # I put this in to see the text being input it is not necessary to work
        #      sleep 3
        #      # "OK" or whatever the name on the button is
        #      w.clickWindowsButton_hwnd( hwnd, "#{button}" )
        #      #
        #      # this is just cleanup
        #      w=nil
        #    end
      end

      # Select option from select list (dropdown) already identified and passed to the method.  Selection can be by *:text* or *:value*.
      # @param [Watir::SelectList] list A reference to the specific select list object.
      # @param [Symbol] how Either :text or :value.
      # @param [String/Rexexp] what A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] nofail If true do not log a failed message if the option is not found in the select list.
      # @return (see #click)
      def select_option_from_list(list, how, what, desc = '', nofail = false)
        msg = build_message("Select :#{how}=>'#{what}'", desc)
        ok  = true
        if list
          case how
            when :text
              list.select(what) #TODO: regex?
            when :value
              list.select_value(what) #TODO: regex?
            when :index
              list.select(list.getAllContents[what.to_i])
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
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      # Select option from select list identified by *how* and *what*. Option is identified by *which* and *value*
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Symbol] which Either :text or :value.
      # @param [String/Rexexp] option A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] nofail If true do not log a failed message if the option is not found in the select list.
      # @return (see #click)
      def select_option(browser, how, what, which, option, desc = '', nofail = false)
        list = browser.select_list(how, what).when_present
        msg  = build_message("from list with :#{how}=>'#{what}", desc)
        select_option_from_list(list, which, option, msg, nofail)
      rescue
        failed_to_log(unable_to)
      end

      # Set radio button or checkbox to selected.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be either :radio or :checkbox.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the radio or checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set(browser, element, how, what, value = nil, desc = '')
        msg = "Set #{element} #{how}=>'#{what}' "
        msg << ", :value=>#{value} " if value
        msg << " '#{desc}' " if desc.length > 0
        case element
          when :radio
            browser.radio(how, what).set
          when :checkbox
            browser.checkbox(how, what).set
          else
            failed_to_log("#{__method__}: #{element} not supported")
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      # Set file field element, identified by *how* and *what*, to a specified file path and name.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] filespec The full path and name of the target file.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_file_field(browser, how, what, filespec, desc = '')
        msg = build_message("#{__method__.to_s.humanize} #{how}=>#{what} to '#{filespec}.", desc)
        ff  = browser.file_field(how, what)
        if ff
          ff.set filespec
          sleep_for(8)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} File field not found.")
        end
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      # Set radio button as selected using two element attributes.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how1 The first element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what1 A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Symbol] how2 The second element attribute used to identify the specific element.
      # @param [String, Regexp] what2 A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_radio_two_attributes(browser, how1, what1, how2, what2, desc = '')
        msg = build_message("Set radio #{how1}='#{what1}', #{how2}= #{what2}", desc)
        browser.radio(how1 => what1, how2 => what2).set
        passed_to_log(msg)
        true
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      #def set_radio_no_wait_by_index(browser, index, desc = '')
      #  #TODO: Not supported by Watir 1.8.x
      #  msg    = "Radio :index=#{index} "
      #  radios = browser.radios
      #  debug_to_log("\n#{radios}")
      #  radio = radios[index]
      #  debug_to_log("\n#{radio}")
      #  radio.click_no_wait
      #    msg << 'set ' + desc
      #    passed_to_log(msg)
      #    true
      #rescue
      #  msg << 'not found ' + desc
      #  failed_to_log("#{msg} (#{__LINE__})")
      #end

      # Clear (unset) radio, checkbox or text field as identified by the attribute specified in *how* with value *what*.
      # It's *:value* attribute can also be used when needed by specifying *value* (Ignored for text_field).
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to clear. Must be :radio, :checkbox or :text_field.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the element.
      # In the case of text_field this is the string to be entered in the field.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def clear(browser, element, how, what, value = nil, desc = '')
        msg = "Clear #{element} #{how}=>'#{what}' "
        msg << ", value=>#{value} " if value
        msg << " '#{desc}' " if desc.length > 0
        case element
          when :radio
            browser.radio(how, what).clear
          when :checkbox
            browser.checkbox(how, what).clear
          when :text_field
            browser.text_field(how, what).set('')
          else
            failed_to_log("#{__method__}: #{element} not supported")
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      # Set text field as identified by the attribute specified in *how* with value in *what* to the string specified in *value*.
      # This method differs from set() in that it validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting *skip_value_check* to true.
      # This is useful when the text_field performs formatting on the entered string. See set_text_field_and_validate()
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] value A string to enter into the text field.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] skip_value_check Forces verification of value in text field to pass.
      # @return (see #click)
      def set_text_field(browser, how, what, value, desc = '', skip_value_check = false)
        #TODO: fix this to handle Safari password field
        msg = build_message("#{__method__.to_s.humanize} #{how}='#{what}' to '#{value}'", desc)
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

      alias set_textfield set_text_field

      # Clear text field as identified by the attribute specified in *how* with value in *what* to the string specified in *value*.
      # This method differs from set() in that 1( it uses the Watir #clear method, 2( it validates that the text field has been
      # set to the specified value.
      # The value verification can be turned off by setting *skip_value_check* to true.
      # This is useful when the text_field performs formatting on the entered string. See set_text_field_and_validate()
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Boolean] skip_value_check Forces verification of value in text field to pass.
      # @return (see #click)
      def clear_textfield(browser, how, what, skip_value_check = false)
        msg1 = "Skip value check." if skip_value_check
        msg = build_message("#{__method__.to_s.humanize}  #{how}='#{what}'.", msg1)
        if browser.text_field(how, what).exists?
          tf = browser.text_field(how, what)
          tf.clear
          if tf.value == ''
            passed_to_log(msg)
            true
          elsif skip_value_check
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found:'#{tf.value}'.")
          end
        else
          failed_to_log("#{msg} Textfield not found.")
        end
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'.")
      end

      #Enter a string into a text field element identified by an attribute type and a value.
      #After the entry the value in the text field is validated against the *valid_value*. Use when the application reformats
      #or performs edits on the input value.

      # Set text field as identified by the attribute specified in *how* with value in *what* to the string specified in *value*.
      # and verify that the text field is set to the string in *valid_value*.
      #
      # @example
      #  set_text_field_and_validate(browser, :id, 'text field id', '99999', 'Dollar format', '$99,999.00')
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] value A string to enter into the text field.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output. Required in this method.
      # @param [String] valid_value The expected value of the text field, e.g., following reformatting.
      # @return (see #click)
      def set_text_field_and_validate(browser, how, what, value, valid_value = nil, desc ='')
        #NOTE: use when value and valid_value differ as with dollar reformatting
        if set_text_field(browser, how, what, value, desc, true)
          expected = valid_value ? valid_value : value
          validate_textfield_value(browser, how, what, expected, desc)
        end
      rescue
        failed_to_log("Unable to '#{msg}': '#{$!}'")
      end

      #def set_password_by_name(browser, name, value, desc = '', skip_value_check = false)
      #  set_text_field(browser, how, what, value, desc, skip_value_check)
      #  if browser.text_field(:name, name).exists?
      #    tf = browser.text_field(:name, name)
      #    # Workaround because browser.text_field doesn't work for password fields in Safari
      #  elsif @browserAbbrev.eql?("S")
      #    tf = browser.password(:name, name)
      #  end
      #  if tf.exists?
      #      tf.set(value)
      #        if tf.value == value
      #          passed_to_log("Set textfield name='#{name}' to '#{value}' #{desc}")
      #          true
      #        elsif skip_value_check
      #          passed_to_log("Set textfield name='#{name}' to '#{value}' #{desc} (skip value check)")
      #          true
      #        else
      #          failed_to_log("Set textfield name='#{name}' to '#{value}': Found:'#{tf.value}'.  #{desc} (#{__LINE__})")
      #        end
      #  else
      #    failed_to_log("Textfield name='#{name}' not found to set to '#{value}'.  #{desc} (#{__LINE__})")
      #  end
      #rescue
      #  failed_to_log("Textfield name='#{name}' could not be set to '#{value}': '#{$!}'. #{desc} (#{__LINE__})")
      #end

      # Fire an event on a specific DOM element identified by one of its attributes and that attribute's value.
      #
      # @example
      #  # html for a link element:
      #  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
      #
      #  fire_event(browser, :link, :text, 'Pickaxe', 'onMouseOver')
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] event A string identifying the event to be fired.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      #
      def fire_event(container, element, how, what, event, desc = '', wait = 10)
        msg  = build_message("#{element.to_s.titlecase}: #{how}=>'#{what}' event:'#{event}'", desc)
        code = build_webdriver_fetch(element, how, what)
        begin
          eval("#{code}.when_present(#{wait}).fire_event('#{event}')")
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(element, how, what, __method__.to_s, event), "#{container.class}")
            raise e
          end
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      def resize_browser_window(browser, width, height, move_to_origin = true)
        browser.driver.manage.window.resize_to(width, height)
        message_to_report("Browser window resized to (#{width}, #{height}).")
        sleep_for(0.5)
        if move_to_origin
          browser.driver.manage.window.move_to(0, 0)
          message_to_report('Browser window moved to origin (0, 0).')
        end
        scroll_to_top(browser)
      rescue
        failed_to_log(unable_to)
      end
      alias resize_window resize_browser_window

      #TODO: does this really scroll all the way to the bottom?
      def send_page_down(browser)
        browser.send_keys :page_down
        debug_to_log('Sent page down')
      end
      alias scroll_to_bottom send_page_down
      alias press_page_down send_page_down

      #TODO: does this really scroll all the way to the top?
      def sent_page_up(browser)
        browser.send_keys :page_up
        debug_to_log('Sent page up')
      end
      alias scroll_to_top sent_page_up
      alias press_page_up sent_page_up

      def send_spacebar(browser)
        browser.send_keys :space
        debug_to_log('Sent space')
      end
      alias press_spacebar send_spacebar

      def send_enter(browser)
        browser.send_keys :enter
        debug_to_log('Sent enter')
      end
      alias press_enter send_enter

      def send_tab(browser)
        browser.send_keys :tab
        debug_to_log('Sent tab')
      end
      alias press_tab send_tab

      def send_right_arrow(browser)
        browser.send_keys :arrow_right
        debug_to_log('Sent right arrow')
      end
      alias press_right_arrow send_right_arrow

      def send_left_arrow(browser)
        browser.send_keys :arrow_left
        debug_to_log('Sent left arrow')
      end
      alias press_left_arrow send_left_arrow

      def send_escape(browser)
        browser.send_keys :escape
        debug_to_log('Sent Esc key')
      end
      alias press_escape send_escape

    end
  end
end

