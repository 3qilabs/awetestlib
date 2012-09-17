module Awetestlib
  # Awetest DSL for browser based testing.
  module Regression
    # Methods covering user interactions with the browser.
    #
    #
    # All of the methods in groups other than Core call Core methods.
    # The methods in the other groups, along with aliases, exist for backward compatibility with earlier versions
    # of the Awetest DSL.
    module UserInput

      # @!group Core

      # Click a specific DOM element identified by one of its attributes and that attribute's value.
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
      def click(browser, element, how, what, desc = '')
        #debug_to_log("#{__method__}: #{element}, #{how}, #{what}")
        msg = build_message("Click #{element} :#{how}=>'#{what}'", desc)
        msg1 = "#{element}(#{how}, '#{what}')"
        begin
          case element
            when :link
              browser.link(how, what).click
            when :button
              browser.button(how, what).click
            when :image
              browser.image(how, what).click
            when :radio
              case how
                when :index
                  set_radio_by_index(browser, what, desc)
                else
                  browser.radio(how, what).set
              end
            when :span
              browser.span(how, what).click
            when :div
              browser.div(how, what).click
            when :cell
              browser.cell(how, what).click
            else
              browser.element(how, what).click
          end
        end
          passed_to_log(msg)
          true
      rescue
        failed_to_log("Unable to #{msg}. '#{$!}'")
      end

      # @!endgroup Core

      # @!group Click

      # Click a button element identified by the value of its _id_ attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param [Watir::Browser, Watir::Container] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def click_button_by_id(browser, what, desc = '')
        click(browser, :button, :id, what, desc)
      end

      # Click a button element identified by the value of its index within the container referred to by <b>+browser+</b>.
      # @param [Watir::Browser, Watir::Container] browser A reference to the browser window or container element to be tested.
      # @param [Fixnum] what An integer that indicates the index of the element within the container.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def click_link_by_index(browser, what, desc = '')
        click(browser, :link, :index, what, desc)
      end

      # Click a link element identified by the value of its _href_ attribute. Take care to escape characters in the url that are reserved by Regexp.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_href(browser, what, desc = '')
        click(browser, :link, :href, what, desc)
      end

      alias click_href click_link_by_href

      # Click a link element identified by the value of its _href_ attribute and do not wait for the browser to reach ready state.
      # Take care to escape characters in the url that are reserved by Regexp.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_no_wait_by_href(browser, what, desc = '')
        click_no_wait(browser, :link, :href, what, desc)
      end

      # Click a button element identified by the value of its index within the container referred to by <b>+browser+</b>.
      # @param (see #click_link_by_index)
      # @return (see #click)
      def click_button_by_index(browser, what, desc = '')
        click(browser, :button, :index, what, desc)
      end

      # Click a button element identified by the value of its _name_ attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_by_name(browser, what, desc = '')
        click(browser, :button, :name, what, desc)
      end

      # Click a button element identified by the value of its _text_ attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_by_text(browser, what, desc = '')
        click(browser, :button, :text, what, desc)
      end

      # Click a button element identified by the value of its _class_ attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_by_class(browser, what, desc = '')
        click(browser, :button, :class, what, desc)
      end

      # Click a button element identified by the value of its _value_ attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_by_value(browser, what, desc = '')
        click(browser, :button, :value, what, desc)
      end

      # Click a button element identified by the value of its _title_ attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_by_title(browser, what, desc = '')
        click(browser, :button, :title, what, desc)
      end

      # Click a link element identified by the value of its _id_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_id(browser, what, desc = '')
        click(browser, :link, :id, what, desc)
      end

      alias click_id click_link_by_id

      # Click a link element identified by the value of its _name_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_name(browser, what, desc = '')
        click(browser, :link, :name, what, desc)
      end

      alias click_name click_link_by_name

      # Click a file_field element identified by the value of its _id_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_file_field_by_id(browser, what, desc = '')
        click(browser, :file_field, :id, what, desc)
      end

      # Click an image element identified by the value of its _id_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_img_by_alt(browser, what, desc = '')
        click(browser, :image, :alt, what, desc)
      end

      # Click an image element identified by the value of its _title_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_img_by_title(browser, what, desc = '')
        click(browser, :image, :title, what, desc)
      end

      # Click an image element identified by the value of its _src_ attribute.
      # Take care to escape characters in the source url that are reserved by Regexp.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_img_by_src(browser, what, desc = '')
        click(browser, :image, :src, what, desc)
      end

      # Click a link element identified by the value of its _value_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_value(browser, what, desc = '')
        click(browser, :link, :value, what, desc)
      end

      # Click a link element identified by the value in its text (innerHTML).
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_text(browser, what, desc = '')
        click(browser, :link, :text, what, desc)
      end

      alias click_link click_link_by_text
      alias click_text click_link_by_text
      alias click_js_button click_link_by_text

      # Click a link element identified by the value of its _class_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_class(browser, what, desc = '')
        click(browser, :link, :class, what, desc)
      end

      alias click_class click_link_by_class

      # Click a span element identified by the value in its text (innerHTML).
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_span_by_text(browser, what, desc = '')
        click(browser, :span, :text, what)
      end

      alias click_span_with_text click_span_by_text

      # Click a link element identified by the value of its _title_ attribute.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_title(browser, what, desc = '')
        click(browser, :link, :title, what, desc)
      end

      alias click_title click_link_by_title

      # @!endgroup Click

      # @!group Core

      # Click a specific DOM element by one of its attributes and that attribute's value and
      # do not wait for the browser to finish reloading.  Used when a modal popup or alert is expected. Allows the script
      # to keep running so the popup can be handled.
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
        debug_to_log("#{__method__}: #{element}, #{how}, #{what}")
        msg = build_message("Click no wait #{element} :#{how}=>'#{what}'", desc)
        msg1 = "#{element}(#{how}, '#{what}'"
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
          if not rescue_me(e, __method__, "browser(#{msg1}').click_no_wait", "#{browser.class}")
            raise e
          end
        end
          passed_to_log(msg)
          true
      rescue
        failed_to_log("Unable to #{msg}  '#{$!}'")
        sleep_for(1)
      end

      # @!endgroup Core

      alias click_href_no_wait click_link_no_wait_by_href

      # @!group Click No Wait

      # Click a button element identified by the value of its _id_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_no_wait_by_id(browser, what, desc = '')
        click_no_wait(browser, :button, :id, what, desc)
      end

      alias click_button_by_id_no_wait click_button_no_wait_by_id

      # Click a button element identified by the value of its _name_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_no_wait_by_name(browser, what, desc = '')
        click_no_wait(browser, :button, :name, what, desc)
      end

      # Click a button element identified by the value of its _class_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_no_wait_by_class(browser, what, desc = '')
        click_no_wait(browser, :button, :class, what, desc)
      end

      alias click_button_by_class_no_wait click_button_no_wait_by_class

      # Click a link element identified by the value of its _id_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_no_wait_by_id(browser, what, desc = '')
        click_no_wait(browser, :link, :id, what, desc)
      end

      alias click_no_wait_id click_link_no_wait_by_id
      alias click_no_wait_by_id click_link_no_wait_by_id
      alias click_id_no_wait click_link_no_wait_by_id
      alias click_no_wait_link_by_id click_link_no_wait_by_id

      # Click an image element identified by the value of its _alt_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_img_no_wait_by_alt(browser, what, desc = '')
        click_no_wait(browser, :image, :alt, what, desc)
      end

      alias click_img_by_alt_no_wait click_img_no_wait_by_alt

      # Click a button element identified by the value in its text (innerHTML)
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_no_wait_by_text(browser, what, desc = '')
        click_no_wait(browser, :button, :text, what, desc)
      end

      # Click a button element identified by the value of its _value_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_no_wait_by_value(browser, what, desc = '')
        click_no_wait(browser, :button, :value, what, desc)
      end

      # Click a button element identified by the value of its _name_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_name_no_wait(browser, what, desc = '')
        click_no_wait(browser, :link, :name, what, desc)
      end

      alias click_no_wait_name click_link_by_name_no_wait
      alias click_name_no_wait click_link_by_name_no_wait

      # Click a link element identified by the value in its text (innerHTML)
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_text_no_wait(browser, what, desc = '')
        click_no_wait(browser, :link, :text, what, desc)
      end

      alias click_no_wait_text click_link_by_text_no_wait
      alias click_text_no_wait click_link_by_text_no_wait

      # Click a link element identified by the value of its _title_ attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_title_no_wait(browser, what, desc = '')
        click_no_wait(browser, :link, :title, what, desc)
      end

      # @!endgroup Click No Wait

      # @!group Xpath

      # Click a button element identified by the value of its _id_ attribute using the xpath functionality in Watir.
      # A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @note Normally used only when the element is not located by other methods.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_button_by_xpath_and_id(browser, what, desc = '')
        click(browser, :button, :xpath, "//a[@id = '#{what}']", desc)
      end

      alias click_button_by_xpath click_button_by_xpath_and_id

      # Click a link element identified by the value of its _id_ attribute using the xpath functionality in Watir.
      # @note Normally used only when the element is not located by other methods.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_link_by_xpath_and_id(browser, what, desc = '')
        click(browser, :link, :xpath, "//a[@id = '#{what}']", desc)
      end

      alias click_link_by_xpath click_link_by_xpath_and_id

      # Click an image element identified by the value of its _name_ attribute using the xpath functionality in Watir.
      # @note Normally used only when the element is not located by other methods.
      # @param (see #click_button_by_id)
      # @return (see #click)
      def click_img_by_xpath_and_name(browser, what, desc = '')
        click(browser, :image, :xpath, "//a[@id = '#{what}']", desc)
      end

      alias click_img_by_xpath click_img_by_xpath_and_name
      alias click_image_by_xpath click_img_by_xpath_and_name
      alias click_image_by_xpath_and_name click_img_by_xpath_and_name

      # @!endgroup Xpath

      # @!group Core

      # Click an image element identified by the value of its _src_ attribute and its index
      # within the array of image elements with src containing <b>+what+</b> and
      # within the container referred to by <b>+browser+</b>.
      # @param [Watir::Browser, Watir::Container] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Fixnum] index An integer that indicates the index of the element within the array of image elements with src containing <b>+what+</b>.
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
        msg = build_message("Click row with text #{text} in table :#{how}=>'#{what}.", desc)
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
        msg = build_message("Double click row with text #{text} in table :#{how}=>'#{what}.", desc)
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

      # @!endgroup Core

      # @!group Tables

      # Click the first row which contains a particular string in a table identified by the value in its _id_ attribute.
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] text Full text string to be found in the table row.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] column Integer indicating the column to search for the text string.
      # If not supplied all columns will be checked.
      # @return (see #click)
      #
      def click_table_row_with_text_by_id(browser, what, text, desc = '', column = nil)
        click_table_row_with_text(browser, :id, what, text, desc, column)
      end

      # Click the first row which contains a particular string in a table identified by its index
      # in the array of tables contained in <b>+browser+</b>.
      # A specific column in the table can also be specified.
      #
      # @param (see #click_table_row_with_text_by_id)
      # @return (see #click)
      #
      def click_table_row_with_text_by_index(browser, what, text, desc = '', column = nil)
        click_table_row_with_text(browser, :id, what, text, desc, column)
      end

      # Double click the first row which contains a particular string in a table identified by the value in its _id_ attribute.
      # A specific column in the table can also be specified.
      #
      # @param (see #click_table_row_with_text_by_id)
      # @return (see #click)
      #
      def double_click_table_row_with_text_by_id(browser, what, text, desc = '', column = nil)
        double_click_table_row_with_text(browser, :id, what, text, desc, column)
      end

      # Double click the first row which contains a particular string in a table identified by its index
      # in the array of tables contained in <b>+browser+</b>.
      # A specific column in the table can also be specified.
      # @param (see #click_table_row_with_text_by_id)
      # @return (see #click)
      #
      def double_click_table_row_with_text_by_index(browser, idx, what, column = nil)
        double_click_table_row_with_text(browser, :index, what, text, desc, column)
      end

      # @!endgroup Tables

      # @!group Core

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

      # Select option from select list (dropdown) already identified and passed to the method.  Selection can be by :text or :value.
      # @param [Watir::SelectList] list A reference to the specific select list object.
      # @param [Symbol] how Either :text or :value.
      # @param [String/Rexexp] what A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] nofail If true do not log a failed message if the option is not found in the select list.
      # @return (see #click)
      def select_option_from_list(list, how, what, desc = '', nofail = false)
        msg = build_message("Select :#{how}=>'#{what}", desc)
        ok  = true
        if list
          case which
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

      # Select option from select list identified by +how+ and +what+. Option is identified by +which+ and +value+
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
        list = browser.select_list(how, what)
        msg = build_message(" from list with :#{how}=>'#{what}", desc)
        select_option_from_list(list, which, option, msg, nofail)
      end

      # @!endgroup Core

      # @!group Select

      # Select option from select list (dropdown) identified by the value in its :id attribute. Option is identified by +which+ and +value+
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String/Rexexp] option A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] nofail If true do not log a failed message if the option is not found in the select list.
      # @return (see #click)
      def select_option_by_id_and_option_text(browser, what, option, nofail = false, desc = '')
        select_option(browser, :id, what, :text, option, desc, nofail)
      end

      alias select_option_by_id select_option_by_id_and_option_text
      alias select_option_by_id_and_text select_option_by_id_and_option_text

      # Select option from select list (dropdown) identified by the value in its :name attribute. Option is selected by its :text attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String/Rexexp] option A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def select_option_by_name_and_option_text(browser, what, option, desc = '')
        select_option(browser, :name, what, :text, option, desc)
      end

      alias select_option_by_name select_option_by_name_and_option_text

      # Select option from select list (dropdown) identified by the value in its :name attribute. Option is selected by its :text attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click)
      def select_option_by_title_and_option_text(browser, what, option, desc = '')
        select_option(browser, :title, what, :text, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its :class attribute. Option is selected by its :text attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click)
      def select_option_by_class_and_option_text(browser, what, option, desc = '')
        select_option(browser, :class, what, :text, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its :name attribute. Option is selected by its :value attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click)
      def select_option_by_name_and_option_value(browser, what, option, desc = '')
        select_option(browser, :name, what, :value, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its :id attribute. Option is selected by its :value attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click)
      def select_option_by_id_and_option_value(browser, what, option, desc = '')
        select_option(browser, :id, what, :value, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its :id attribute.
      # Option is selected by its index withing the select list's array of options.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Fixnum] index An integer that indicates the index of the element within the array of options.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def select_option_by_id_and_index(browser, what, index, desc = '')
        select_option(browser, :id, what, :index, index, desc)
      end

      # Select option from select list (dropdown) identified by the value in its :name attribute. Option is selected by its :index attribute.
      # @param (see #select_option_by_id_and_index)
      # @return (see #click)
      def select_option_by_name_and_index(browser, what, option, desc = '')
        select_option(browser, :name, what, :index, option, desc)
      end

      # Select option from select list (dropdown) identified by the xpath command supplied in +what+. Option is selected by its :index attribute.
      # @param (see #select_option_by_id_and_index)
      # @return (see #click)
      def select_option_by_xpath_and_index(browser, what, option, desc = '')
        select_option(browser, :xpath, what, :index, option, desc)
      end

      # @!endgroup Select

      # @!group Core

      # Set radio button or checkbox to selected.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be either :radio or :checkbox.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the radio or checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set(browser, element, how, what, value = nil, desc = '')
        msg = "Set #{element} #{how}=>'#{what}' "
        msg << ", :value=>#{value} " if value
        msg << " '#{desc}' " if desc.length > 0
        case element
          when :radio
            browser.radio(how, what, value).set
          when :checkbox
            browser.checkbox(how, what, value).set
          else
            failed_to_log("#{__method__}: #{element} not supported")
        end
          passed_to_log(msg)
          true
      rescue
          failed_to_log("#{msg} '#{$!}'")
        end

      # Set file field element, identified by +how+ and +what, to a specified file path and name.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] filespec The full path and name of the target file.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_file_field(browser, how, what, filespec, desc = '')
        msg = build_message("Set file field #{how}=>#{what} to '#{filespec}.", desc)
        ff = browser.file_field(how, what)
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

      # @!endgroup Core

      # @!group Set

      # Set checkbox as checked. Checkbox is identified by the attribute specified in +how+ with value +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the checkbox.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_checkbox(browser, how, what, value = nil, desc = '')
        set(browser, :checkbox, how, what, value, desc)
      end

      # Set checkbox as checked identified by its :class attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the checkbox.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_checkbox_by_class(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :class, what, value, desc)
      end

      # Set checkbox as checked identified by its :class attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      # @return (see #click)
      def set_checkbox_by_id(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :id, what, value, desc)
      end

      # Set checkbox as checked identified by its :name attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      # @return (see #click)
      def set_checkbox_by_name(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :name, what, value, desc)
      end

      # Set checkbox as checked identified by its :title attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      # @return (see #click)
      def set_checkbox_by_title(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :title, what, value, desc)
      end

      # Set checkbox as checked identified by its :value attribute with the value in +what+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_checkbox_by_value(browser, what, desc = '')
        set(browser, :checkbox, :value, what, nil, desc)
      end

      # Set radio button as set. Radio is identified by the attribute specified in +how+ with value +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox)
      # @return (see #click)
      def set_radio(browser, how, what, value = nil, desc = '')
        set(browser, :radio, how, what, value, desc)
      end

      # Set radio button as set identified by its :class attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      def set_radio_by_class(browser, what, value = nil, desc = '')
        set(browser, :radio, :class, what, value, desc)
      end

      # Set radio button as set identified by its :id attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      # @return (see #click)
      def set_radio_by_id(browser, what, value = nil, desc = '')
        set(browser, :radio, :id, what, value, desc)
        end

      # Set radio button as set identified by its index within the array of radio buttons found in the container specified by +browser+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Fixnum] index An integer that indicates the index of the element within +browser+.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_radio_by_index(browser, index, desc = '')
        set(browser, :radio, :index, index, nil, desc)
      end

      # Set radio button as set identified by its :name attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      # @return (see #click)
      def set_radio_by_name(browser, what, value = nil, desc = '')
        set(browser, :radio, :name, what, value, desc)
      end

      # Set radio button as set identified by its :title attribute with the value in +what+. It's :value attribute can also be used
      # when needed by specifying +value+.
      # @param (see #set_checkbox_by_class)
      # @return (see #click)
      def set_radio_by_title(browser, what, value = nil, desc = '')
        set(browser, :radio, :title, what, value, desc)
      end

      # Set radio button as set identified by its :value attribute with the value in +what+.
      # @param (see #set_checkbox_by_value)
      # @return (see #click)
      def set_radio_by_value(browser, what, desc = '')
        set(browser, :radio, :value, what, nil, desc)
      end

      # Set radio button as set identified by its :name attribute with the value in +what+
      # and its index within the array of radio buttons with that :name
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the :name attribute that identifies the group of radio buttons.
      # @param [Fixnum] index An integer that indicates the index of the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_radio_by_name_and_index(browser, what, index, desc = '')
        set_radio_two_attributes(browser, :name, what, :index, index, desc)
      end

      # Set radio button as set identified by its :name attribute with the value in +what+
      # and its index within the array of radio buttons with that :name
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the :name attribute that identifies the group of radio buttons.
      # @param [String, Regexp] text A string or a regular expression to be found in the :text attribute that uniquely identifies the the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_radio_by_name_and_text(browser, what, text, desc = '')
        set_radio_two_attributes(browser, :name, what, :text, text, desc)
      end

      # Set radio button as set identified by its :value attribute with the value in +what+
      # and its index within the array of radio buttons with that :name
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute that identifies the group of radio buttons.
      # @param [Fixnum] index An integer that indicates the index of the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_radio_by_value_and_index(browser, value, index, desc = '')
        set_radio_two_attributes(browser, :value, value, :index, index, desc)
      end

      # Set radio button as set identified by its :name attribute with the value in +what+
      # and the :value attribute with the value in +value+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the :name attribute that identifies the group of radio buttons.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute that uniquely identifies the the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_radio_by_name_and_value(browser, what, value, desc = '')
        set_radio(browser, :name, what, value, desc)
      end

      # Set file field element, identified by its :name attribute with the value in +what+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] filespec The full path and name of the target file.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def set_file_field_by_name(browser, what, filespec, desc = '')
        set_file_field(browser, :name, what, filespec, desc)
      end

      # Set file field element, identified by its :id attribute with the value in +what+.
      # @param (see #set_file_field_by_name)
      # @return (see #click)
      def set_file_field_by_id(browser, what, filespec, desc = '')
        set_file_field(browser, :id, what, filespec, desc)
      end

      # @!endgroup Set

      # @!group Core

      # Clear (unset) radio, checkbox or text field as identified by the attribute specified in +how+ with value +what+.
      # It's :value attribute can also be used when needed by specifying +value+ (Ignored for text_field).
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to clear. Must be :radio, :checkbox or :text_field.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the element.
      # In the case of text_field this is the string to be entered in the field.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def clear(browser, element, how, what, value = nil, desc = '')
        msg = "Clear #{element} #{how}=>'#{what}' "
        msg << ", value=>#{value} " if value
        msg << " '#{desc}' " if desc.length > 0
        case element
          when :radio
            browser.radio(how, what, value).clear
          when :checkbox
            browser.checkbox(how, what, value).clear
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

      # @!endgroup Core

      # @!group Clear

      # Clear (uncheck) checkbox identified by the attribute specified in +how+ with value +what+.
      # It's :value attribute can also be used when needed by specifying +value+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def clear_checkbox(browser, how, what, value = nil, desc = '')
        clear(browser, :checkbox, how, what, value, desc)
      end

      # Clear (uncheck) checkbox identified by its :name attribute with value +what+.
      # It's :value attribute can also be used when needed by specifying +value+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def clear_checkbox_by_name(browser, what, value = nil, desc = '')
        clear(browser, :checkbox, :name, what, value, desc)
      end

      # Clear (uncheck) checkbox identified by its :id attribute with value +what+.
      # It's :value attribute can also be used when needed by specifying +value+.
      # @param (see #set_file_field_by_name)
      # @return (see #click)
      def clear_checkbox_by_name(browser, what, value = nil, desc = '')
        clear(browser, :checkbox, :id, what, value, desc)
      end

      # Clear (unset) radio button identified by the attribute specified in +how+ with value +what+.
      # It's :value attribute can also be used when needed by specifying +value+.
      # This clears the specified radio without setting any other radio buttons on.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      def clear_radio(browser, how, what, value = nil, desc = '')
        clear(browser, :radio, how, what, value, desc)
      end

      # @!endgroup Clear

      # @!group Core

      # Set text field as identified by the attribute specified in +how+ with value in +what+ to the string specified in +value+.
      # This method differs from set() in that it validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting +skip_value_check+ to true.
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
        msg = build_message("Set textfield #{how}='#{what}' to '#{value}'", desc)
        msg << " (Skip value check)" if skip_value_check
        if browser.text_field(how, what).exists?
          tf = browser.text_field(how, what)
          #debug_to_log("#{tf.inspect}")
            tf.set(value)
              if tf.value == value
                passed_to_log(msg)
                true
              elsif skip_value_check
                passed_to_log(msg)
                true
              else
                failed_to_log("#{msg}: Found:'#{tf.value}'.")
              end
        else
          failed_to_log("#{msg}: Textfield #{how}='#{what}' not found")
        end
      rescue
        failed_to_log("Unable to '#{msg}': '#{$!}'")
      end

      alias set_textfield set_text_field

      # Clear text field as identified by the attribute specified in +how+ with value in +what+ to the string specified in +value+.
      # This method differs from set() in that 1( it uses the Watir #clear method, 2( it validates that the text field has been
      # set to the specified value.
      # The value verification can be turned off by setting +skip_value_check+ to true.
      # This is useful when the text_field performs formatting on the entered string. See set_text_field_and_validate()
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Boolean] skip_value_check Forces verification of value in text field to pass.
      # @return (see #click)
      def clear_textfield(browser, how, what, skip_value_check = false)
        if browser.text_field(how, what).exists?
          tf = browser.text_field(how, what)
            tf.clear
              if tf.value == ''
                passed_to_log("Textfield #{how}='#{what}' cleared.")
                true
              elsif skip_value_check
                passed_to_log("Textfield  #{how}='#{what}' cleared. (skip value check)")
                true
              else
                failed_to_log("Textfield  #{how}='#{what}' not cleared: Found:'#{tf.value}'. (#{__LINE__})")
              end
        else
          failed_to_log("Textfield id='#{id}' to clear. (#{__LINE__})")
        end
      rescue
        failed_to_log("Textfield id='#{id}' could not be cleared: '#{$!}'. (#{__LINE__})")
      end

      #Enter a string into a text field element identified by an attribute type and a value.
      #After the entry the value in the text field is validated against the *valid_value*. Use when the application reformats
      #or performs edits on the input value.

      # Set text field as identified by the attribute specified in +how+ with value in +what+ to the string specified in +value+.
      # and verify that the text field is set to the string in +valid_value+.
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
      def set_text_field_and_validate(browser, how, what, value, desc, valid_value = nil)
        #NOTE: use when value and valid_value differ as with dollar reformatting
        if set_text_field(browser, how, what, value, desc, true)
          expected = valid_value ? valid_value : value
          validate_textfield_value(browser, how, what, expected)
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

      # @!endgroup Core

      # @!group Set

      # Set text field as identified by its :name attribute with value in +what+ to the string specified in +value+.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting +skip_value_check+ to true.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] value A string to enter into the text field.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output.
      # Required if +skip_value_check+ is set to true.
      # @param [Boolean] skip_value_check Forces verification of value in text field to pass.
      # @return (see #click)
      def set_textfield_by_name(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :name, what, value, desc, skip_value_check)
      end

      # Set text field as identified by its :id attribute with value in +what+ to the string specified in +value+.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting +skip_value_check+ to true.
      # @param (see #set_textfield_by_name)
      # @return (see #click)
      def set_textfield_by_id(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :id, what, value, desc, skip_value_check)
      end

      # Set text field as identified by its :class attribute with value in +what+ to the string specified in +value+.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting +skip_value_check+ to true.
      # @param (see #set_textfield_by_name)
      # @return (see #click)
      def set_textfield_by_title(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :title, what, value, desc, skip_value_check)
      end

      # Set text field as identified by its :class attribute with value in +what+ to the string specified in +value+.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting +skip_value_check+ to true.
      # @param (see #set_textfield_by_name)
      def set_textfield_by_class(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :class, what, value, desc, skip_value_check)
      end

      # @!endgroup Set
      # @!group Core

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
      def fire_event(browser, element, how, what, event, desc = '')
        msg  = "#{element.to_s.titlecase}: #{how}=>'#{what}' event:'#{event}'"
        msg1 = "#{element.to_s.titlecase}(#{how}, '#{what}')"
        begin
          case element
            when :link
              browser.link(how, what).fire_event(event)
            when :button
              browser.button(how, what).fire_event(event)
            when :image
              browser.image(how, what).fire_event(event)
            when :span
              browser.span(how, what).fire_event(event)
            when :div
              browser.div(how, what).fire_event(event)
            else
              browser.element(how, what).fire_event(event)
          end
        rescue => e
          if not rescue_me(e, __method__, "browser(#{msg1}).fire_event('#{event}')", "#{browser.class}")
            raise e
          end
        end
          passed_to_log("Fire event: #{msg}. #{desc}")
          true
      rescue
        failed_to_log("Unable to fire event: #{msg}. '#{$!}' #{desc}")
      end

      # @!endgroup Core
      
      # @!group Fire Event

      # Fire an event on a link element identified by the value in its text (innerHTML)
      #
      # @example
      #  # html for a link element:
      #  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
      #
      #  fire_event_on_link_by_text(browser, 'Pickaxe', 'onMouseOver')
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] event A string identifying the event to be fired.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click)
      #
      def fire_event_on_link_by_text(browser, what, event, desc = '')
        fire_event(browser, :link, :text, what, event, desc)
      end

      alias fire_event_text fire_event_on_link_by_text
      alias fire_event_by_text fire_event_on_link_by_text

      # Fire an event on a link element identified by the value in its _id_ attribute.
      #
      # @example
      #  # html for a link element:
      #  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
      #
      #  fire_event_on_link_by_id(browser, 'one', 'onMouseOver')
      #
      # @param (see #fire_event_on_link_by_text)
      # @return (see #click)
      #
      def fire_event_on_link_by_id(browser, what, event, desc = '')
        fire_event(browser, :link, :id, what, event, desc)
      end

      alias fire_event_id fire_event_on_link_by_id
      alias fire_event_by_id fire_event_on_link_by_id

      # Fire an event on a image element identified by the value in its _src_ attribute.
      # Take care to escape characters in the source url that are reserved by Regexp.
      # @param (see #fire_event_on_link_by_text)
      # @return (see #click)
      #
      def fire_event_on_image_by_src(browser, what, event, desc = '')
        fire_event(browser, :img, :src, what, event, desc)
      end

      alias fire_event_src fire_event_on_image_by_src
      alias fire_event_image_by_src fire_event_on_image_by_src

      # @!endgroup Fire Event

    end
  end
end

