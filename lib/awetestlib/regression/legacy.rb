module Awetestlib
  module Regression
    # Backward compatible methods and alias to support earlier versions of the Awetest DSL.
    # These are deprecated in favor of the methods actually called within them.
    # Work in Progress
    module Legacy

      # @!group Click (UserInput)

      # Click a button element identified by the value of its *:id* attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param [Watir::Browser, Watir::Container] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if the Watir or Watir-webdriver function does not throw an exception.
      def click_button_by_id(browser, what, desc = '')
        click(browser, :button, :id, what, desc)
      end

      # Click a button element identified by the value of its index within the container referred to by <b>*browser*</b>.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_index(browser, what, desc = '')
        click(browser, :link, :index, what, desc)
      end

      # Click a link element identified by the value of its *:href* attribute. Take care to escape characters in the url that are reserved by Regexp.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_href(browser, what, desc = '')
        click(browser, :link, :href, what, desc)
      end

      alias click_href click_link_by_href

      # Click a button element identified by the value of its index within the container referred to by <b>*browser*</b>.
      # @param (see #click_link_by_index)
      # @return (see #click_button_by_id)
      def click_button_by_index(browser, what, desc = '')
        click(browser, :button, :index, what, desc)
      end

      # Click a button element identified by the value of its *:name* attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_by_name(browser, what, desc = '')
        click(browser, :button, :name, what, desc)
      end

      # Click a button element identified by the value of its *:text* attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_by_text(browser, what, desc = '')
        click(browser, :button, :text, what, desc)
      end

      # Click a button element identified by the value of its *:class* attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_by_class(browser, what, desc = '')
        click(browser, :button, :class, what, desc)
      end

      # Click a button element identified by the value of its *:value* attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_by_value(browser, what, desc = '')
        click(browser, :button, :value, what, desc)
      end

      # Click a button element identified by the value of its *:title* attribute. A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_by_title(browser, what, desc = '')
        click(browser, :button, :title, what, desc)
      end

      # Click a link element identified by the value of its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_id(browser, what, desc = '')
        click(browser, :link, :id, what, desc)
      end

      alias click_id click_link_by_id

      # Click a link element identified by the value of its *:name* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_name(browser, what, desc = '')
        click(browser, :link, :name, what, desc)
      end

      alias click_name click_link_by_name

      # Click a file_field element identified by the value of its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_file_field_by_id(browser, what, desc = '')
        click(browser, :file_field, :id, what, desc)
      end

      # Click an image element identified by the value of its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_img_by_alt(browser, what, desc = '')
        click(browser, :image, :alt, what, desc)
      end

      # Click an image element identified by the value of its *:title* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_img_by_title(browser, what, desc = '')
        click(browser, :image, :title, what, desc)
      end

      # Click an image element identified by the value of its *:src* attribute.
      # Take care to escape characters in the source url that are reserved by Regexp.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_img_by_src(browser, what, desc = '')
        click(browser, :image, :src, what, desc)
      end

      def click_js(browser, element, how, what, desc = '')
        click(browser, element, how, what, desc)
      end

      # Click a link element identified by the value of its *:value* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_value(browser, what, desc = '')
        click(browser, :link, :value, what, desc)
      end

      # Click a link element identified by the value in its text (innerHTML).
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_text(browser, what, desc = '')
        click(browser, :link, :text, what, desc)
      end

      alias click_link click_link_by_text
      alias click_text click_link_by_text
      alias click_js_button click_link_by_text

      # Click a link element identified by the value of its *:class* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_class(browser, what, desc = '')
        click(browser, :link, :class, what, desc)
      end

      alias click_class click_link_by_class

      # Click a span element identified by the value in its text (innerHTML).
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_span_by_text(browser, what, desc = '')
        click(browser, :span, :text, what, desc)
      end

      alias click_span_with_text click_span_by_text

      # Click a link element identified by the value of its *:title* attribute.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_title(browser, what, desc = '')
        click(browser, :link, :title, what, desc)
      end

      alias click_title click_link_by_title

      # @!endgroup Click

      # @!group Click No Wait (UserInput)

      # Click a button element identified by the value of its *:id* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_no_wait_by_id(browser, what, desc = '')
        click_no_wait(browser, :button, :id, what, desc)
      end

      alias click_button_by_id_no_wait click_button_no_wait_by_id

      # Click a button element identified by the value of its *:name* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_no_wait_by_name(browser, what, desc = '')
        click_no_wait(browser, :button, :name, what, desc)
      end

      # Click a button element identified by the value of its *:class* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_no_wait_by_class(browser, what, desc = '')
        click_no_wait(browser, :button, :class, what, desc)
      end

      alias click_button_by_class_no_wait click_button_no_wait_by_class

      # Click a link element identified by the value of its *:id* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_no_wait_by_id(browser, what, desc = '')
        click_no_wait(browser, :link, :id, what, desc)
      end

      alias click_no_wait_id click_link_no_wait_by_id
      alias click_no_wait_by_id click_link_no_wait_by_id
      alias click_id_no_wait click_link_no_wait_by_id
      alias click_no_wait_link_by_id click_link_no_wait_by_id

      # Click an image element identified by the value of its *:alt* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_img_no_wait_by_alt(browser, what, desc = '')
        click_no_wait(browser, :image, :alt, what, desc)
      end

      alias click_img_by_alt_no_wait click_img_no_wait_by_alt

      # Click a button element identified by the value in its text (innerHTML)
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_no_wait_by_text(browser, what, desc = '')
        click_no_wait(browser, :button, :text, what, desc)
      end

      # Click a button element identified by the value of its *:value* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_no_wait_by_value(browser, what, desc = '')
        click_no_wait(browser, :button, :value, what, desc)
      end

      # Click a button element identified by the value of its *:name* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_name_no_wait(browser, what, desc = '')
        click_no_wait(browser, :link, :name, what, desc)
      end

      alias click_no_wait_name click_link_by_name_no_wait
      alias click_name_no_wait click_link_by_name_no_wait

      # Click a link element identified by the value in its text (innerHTML)
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_text_no_wait(browser, what, desc = '')
        click_no_wait(browser, :link, :text, what, desc)
      end

      alias click_no_wait_text click_link_by_text_no_wait
      alias click_text_no_wait click_link_by_text_no_wait

      # Click a link element identified by the value of its *:title* attribute
      # and do not wait for the browser to reach ready state.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_title_no_wait(browser, what, desc = '')
        click_no_wait(browser, :link, :title, what, desc)
      end

      # Click a link element identified by the value of its *:href* attribute and do not wait for the browser to reach ready state.
      # Take care to escape characters in the url that are reserved by Regexp.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_no_wait_by_href(browser, what, desc = '')
        click_no_wait(browser, :link, :href, what, desc)
      end

      alias click_href_no_wait click_link_no_wait_by_href

      # @!endgroup Click No Wait

      # @!group Xpath (UserInput)

      # Click a button element identified by the value of its *:id* attribute using the xpath functionality in Watir.
      # A button is an HTML element with tag 'input' and type 'submit' or 'button'.
      # @note Normally used only when the element is not located by other methods.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_button_by_xpath_and_id(browser, what, desc = '')
        click(browser, :button, :xpath, "//a[@id = '#{what}']", desc)
      end

      alias click_button_by_xpath click_button_by_xpath_and_id

      # Click a link element identified by the value of its *:id* attribute using the xpath functionality in Watir.
      # @note Normally used only when the element is not located by other methods.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_link_by_xpath_and_id(browser, what, desc = '')
        click(browser, :link, :xpath, "//a[@id = '#{what}']", desc)
      end

      alias click_link_by_xpath click_link_by_xpath_and_id

      # Click an image element identified by the value of its *:name* attribute using the xpath functionality in Watir.
      # @note Normally used only when the element is not located by other methods.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def click_img_by_xpath_and_name(browser, what, desc = '')
        click(browser, :image, :xpath, "//a[@name = '#{what}']", desc)
      end

      alias click_img_by_xpath click_img_by_xpath_and_name
      alias click_image_by_xpath click_img_by_xpath_and_name
      alias click_image_by_xpath_and_name click_img_by_xpath_and_name

      # @!endgroup Xpath

      # @!group Tables (UserInput)

      # Click the first row which contains a particular string in a table identified by the value in its *:id* attribute.
      #
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] text Full text string to be found in the table row.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Fixnum] column Integer indicating the column to search for the text string.
      # If not supplied all columns will be checked.
      # @return (see #click_button_by_id)
      #
      def click_table_row_with_text_by_id(browser, what, text, desc = '', column = nil)
        click_table_row_with_text(browser, :id, what, text, desc, column)
      end

      # Click the first row which contains a particular string in a table identified by its index
      # in the array of tables contained in <b>*browser*</b>.
      # A specific column in the table can also be specified.
      #
      # @param (see #click_table_row_with_text_by_id)
      # @return (see #click_button_by_id)
      #
      def click_table_row_with_text_by_index(browser, what, text, desc = '', column = nil)
        click_table_row_with_text(browser, :id, what, text, desc, column)
      end

      # Double click the first row which contains a particular string in a table identified by the value in its *:id* attribute.
      # A specific column in the table can also be specified.
      #
      # @param (see #click_table_row_with_text_by_id)
      # @return (see #click_button_by_id)
      #
      def double_click_table_row_with_text_by_id(browser, what, text, desc = '', column = nil)
        double_click_table_row_with_text(browser, :id, what, text, desc, column)
      end

      # Double click the first row which contains a particular string in a table identified by its index
      # in the array of tables contained in <b>*browser*</b>.
      # A specific column in the table can also be specified.
      # @param (see #click_table_row_with_text_by_id)
      # @return (see #click_button_by_id)
      #
      def double_click_table_row_with_text_by_index(browser, what, text, desc = '', column = nil)
        double_click_table_row_with_text(browser, :index, what, text, desc, column)
      end

      # @!endgroup Tables

      # @!group Select (UserInput)

      # Select option from select list (dropdown) identified by the value in its *:id* attribute. Option is identified by *which* and *value*
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String/Rexexp] option A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] nofail If true do not log a failed message if the option is not found in the select list.
      # @return (see #click_button_by_id)
      def select_option_by_id_and_option_text(browser, what, option, nofail = false, desc = '')
        select_option(browser, :id, what, :text, option, desc, nofail)
      end

      alias select_option_by_id select_option_by_id_and_option_text
      alias select_option_by_id_and_text select_option_by_id_and_option_text

      # Select option from select list (dropdown) identified by the value in its *:name* attribute. Option is selected by its *:text* attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String/Rexexp] option A string or regular expression that will uniquely identify the option to select.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def select_option_by_name_and_option_text(browser, what, option, desc = '')
        select_option(browser, :name, what, :text, option, desc)
      end

      alias select_option_by_name select_option_by_name_and_option_text

      # Select option from select list (dropdown) identified by the value in its *:name* attribute. Option is selected by its *:text* attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click_button_by_id)
      def select_option_by_title_and_option_text(browser, what, option, desc = '')
        select_option(browser, :title, what, :text, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its *:class* attribute. Option is selected by its *:text* attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click_button_by_id)
      def select_option_by_class_and_option_text(browser, what, option, desc = '')
        select_option(browser, :class, what, :text, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its *:name* attribute. Option is selected by its *:value* attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click_button_by_id)
      def select_option_by_name_and_option_value(browser, what, option, desc = '')
        select_option(browser, :name, what, :value, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its *:id* attribute. Option is selected by its *:value* attribute.
      # @param (see #select_option_by_name_and_option_text)
      # @return (see #click_button_by_id)
      def select_option_by_id_and_option_value(browser, what, option, desc = '')
        select_option(browser, :id, what, :value, option, desc)
      end

      # Select option from select list (dropdown) identified by the value in its *:id* attribute.
      # Option is selected by its index withing the select list's array of options.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [Fixnum] index An integer that indicates the index of the element within the array of options.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def select_option_by_id_and_index(browser, what, index, desc = '')
        select_option(browser, :id, what, :index, index, desc)
      end

      # Select option from select list (dropdown) identified by the value in its *:name* attribute. Option is selected by its *:index* attribute.
      # @param (see #select_option_by_id_and_index)
      # @return (see #click_button_by_id)
      def select_option_by_name_and_index(browser, what, option, desc = '')
        select_option(browser, :name, what, :index, option, desc)
      end

      # Select option from select list (dropdown) identified by the xpath command supplied in *what*. Option is selected by its *:index* attribute.
      # @param (see #select_option_by_id_and_index)
      # @return (see #click_button_by_id)
      def select_option_by_xpath_and_index(browser, what, option, desc = '')
        select_option(browser, :xpath, what, :index, option, desc)
      end

      # @!endgroup Select

       # @!group Set (UserInput)

      # Set checkbox as checked. Checkbox is identified by the attribute specified in *how* with value *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the checkbox.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_checkbox(browser, how, what, value = nil, desc = '')
        set(browser, :checkbox, how, what, value, desc)
      end

      # Set checkbox as checked identified by its *:class* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the checkbox.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_checkbox_by_class(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :class, what, value, desc)
      end

      # Set checkbox as checked identified by its *:class* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      # @return (see #click_button_by_id)
      def set_checkbox_by_id(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :id, what, value, desc)
      end

      # Set checkbox as checked identified by its *:name* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      # @return (see #click_button_by_id)
      def set_checkbox_by_name(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :name, what, value, desc)
      end

      # Set checkbox as checked identified by its *:title* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      # @return (see #click_button_by_id)
      def set_checkbox_by_title(browser, what, value = nil, desc = '')
        set(browser, :checkbox, :title, what, value, desc)
      end

      # Set checkbox as checked identified by its *:value* attribute with the value in *what*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the checkbox.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_checkbox_by_value(browser, what, desc = '')
        set(browser, :checkbox, :value, what, nil, desc)
      end

      # Set radio button as set. Radio is identified by the attribute specified in *how* with value *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox)
      # @return (see #click_button_by_id)
      def set_radio(browser, how, what, value = nil, desc = '')
        set(browser, :radio, how, what, value, desc)
      end

      # Set radio button as set identified by its *:class* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      def set_radio_by_class(browser, what, value = nil, desc = '')
        set(browser, :radio, :class, what, value, desc)
      end

      # Set radio button as set identified by its *:id* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      # @return (see #click_button_by_id)
      def set_radio_by_id(browser, what, value = nil, desc = '')
        set(browser, :radio, :id, what, value, desc)
        end

      # Set radio button as set identified by its index within the array of radio buttons found in the container specified by *browser*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Fixnum] index An integer that indicates the index of the element within *browser*.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_radio_by_index(browser, index, desc = '')
        set(browser, :radio, :index, index, nil, desc)
      end

      # Set radio button as set identified by its *:name* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      # @return (see #click_button_by_id)
      def set_radio_by_name(browser, what, value = nil, desc = '')
        set(browser, :radio, :name, what, value, desc)
      end

      # Set radio button as set identified by its *:title* attribute with the value in *what*. It's *:value* attribute can also be used
      # when needed by specifying *value*.
      # @param (see #set_checkbox_by_class)
      # @return (see #click_button_by_id)
      def set_radio_by_title(browser, what, value = nil, desc = '')
        set(browser, :radio, :title, what, value, desc)
      end

      # Set radio button as set identified by its *:value* attribute with the value in *what*.
      # @param (see #click_button_by_id)
      # @return (see #click_button_by_id)
      def set_radio_by_value(browser, what, desc = '')
        set(browser, :radio, :value, what, nil, desc)
      end

      # Set radio button as set identified by its *:name* attribute with the value in *what*
      # and its index within the array of radio buttons with that :name
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *:name* attribute that identifies the group of radio buttons.
      # @param [Fixnum] index An integer that indicates the index of the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_radio_by_name_and_index(browser, what, index, desc = '')
        set_radio_two_attributes(browser, :name, what, :index, index, desc)
      end

      # Set radio button as set identified by its *:name* attribute with the value in *what*
      # and its index within the array of radio buttons with that :name
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *:name* attribute that identifies the group of radio buttons.
      # @param [String, Regexp] text A string or a regular expression to be found in the *:text* attribute that uniquely identifies the the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_radio_by_name_and_text(browser, what, text, desc = '')
        set_radio_two_attributes(browser, :name, what, :text, text, desc)
      end

      # Set radio button as set identified by its *:value* attribute with the value in *what*
      # and its index within the array of radio buttons with that :name
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute that identifies the group of radio buttons.
      # @param [Fixnum] index An integer that indicates the index of the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_radio_by_value_and_index(browser, value, index, desc = '')
        set_radio_two_attributes(browser, :value, value, :index, index, desc)
      end

      # Set radio button as set identified by its *:name* attribute with the value in *what*
      # and the *:value* attribute with the value in *value*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *:name* attribute that identifies the group of radio buttons.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute that uniquely identifies the the radio button to be set.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_radio_by_name_and_value(browser, what, value, desc = '')
        set_radio(browser, :name, what, value, desc)
      end

      # Set file field element, identified by its *:name* attribute with the value in *what*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] filespec The full path and name of the target file.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def set_file_field_by_name(browser, what, filespec, desc = '')
        set_file_field(browser, :name, what, filespec, desc)
      end

      # Set file field element, identified by its *:id* attribute with the value in *what*.
      # @param (see #set_file_field_by_name)
      # @return (see #click_button_by_id)
      def set_file_field_by_id(browser, what, filespec, desc = '')
        set_file_field(browser, :id, what, filespec, desc)
      end

      # Set text field as identified by its *:name* attribute with value in *what* to the string specified in *value*.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting *skip_value_check* to true.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String] value A string to enter into the text field.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output.
      # Required if *skip_value_check* is set to true.
      # @param [Boolean] skip_value_check Forces verification of value in text field to pass.
      # @return (see #click_button_by_id)
      def set_textfield_by_name(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :name, what, value, desc, skip_value_check)
      end

      # Set text field as identified by its *:id* attribute with value in *what* to the string specified in *value*.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting *skip_value_check* to true.
      # @param (see #set_textfield_by_name)
      # @return (see #click_button_by_id)
      def set_textfield_by_id(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :id, what, value, desc, skip_value_check)
      end

      # Set text field as identified by its *:class* attribute with value in *what* to the string specified in *value*.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting *skip_value_check* to true.
      # @param (see #set_textfield_by_name)
      # @return (see #click_button_by_id)
      def set_textfield_by_title(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :title, what, value, desc, skip_value_check)
      end

      # Set text field as identified by its *:class* attribute with value in *what* to the string specified in *value*.
      # This method validates that the text field has been set to the specified value.
      # The value verification can be turned off by setting *skip_value_check* to true.
      # @param (see #set_textfield_by_name)
      def set_textfield_by_class(browser, what, value, desc = '', skip_value_check = false)
        set_text_field(browser, :class, what, value, desc, skip_value_check)
      end

      # @!endgroup Set

       # @!group Clear (UserInput)

      # Clear (uncheck) checkbox identified by the attribute specified in *how* with value *what*.
      # It's *:value* attribute can also be used when needed by specifying *value*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def clear_checkbox(browser, how, what, value = nil, desc = '')
        clear(browser, :checkbox, how, what, value, desc)
      end

      # Clear (uncheck) checkbox identified by its *:name* attribute with value *what*.
      # It's *:value* attribute can also be used when needed by specifying *value*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def clear_checkbox_by_name(browser, what, value = nil, desc = '')
        clear(browser, :checkbox, :name, what, value, desc)
      end

      # Clear (uncheck) checkbox identified by its *:id* attribute with value *what*.
      # It's *:value* attribute can also be used when needed by specifying *value*.
      # @param (see #set_file_field_by_name)
      # @return (see #click_button_by_id)
      def clear_checkbox_by_id(browser, strg, value = nil, desc = '')
        clear_checkbox(browser, :id, strg, desc)
      end

      # Clear (unset) radio button identified by the attribute specified in *how* with value *what*.
      # It's *:value* attribute can also be used when needed by specifying *value*.
      # This clears the specified radio without setting any other radio buttons on.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific checkbox.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #click_button_by_id)
      def clear_radio(browser, how, what, value = nil, desc = '')
        clear(browser, :radio, how, what, value, desc)
      end

      # @!endgroup Clear

      # @!group Fire Event (UserInput)

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
      # @return (see #click_button_by_id)
      #
      def fire_event_on_link_by_text(browser, what, event, desc = '')
        fire_event(browser, :link, :text, what, event, desc)
      end

      alias fire_event_text fire_event_on_link_by_text
      alias fire_event_by_text fire_event_on_link_by_text

      # Fire an event on a link element identified by the value in its *:id* attribute.
      #
      # @example
      #  # html for a link element:
      #  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
      #
      #  fire_event_on_link_by_id(browser, 'one', 'onMouseOver')
      #
      # @param (see #fire_event_on_link_by_text)
      # @return (see #click_button_by_id)
      #
      def fire_event_on_link_by_id(browser, what, event, desc = '')
        fire_event(browser, :link, :id, what, event, desc)
      end

      alias fire_event_id fire_event_on_link_by_id
      alias fire_event_by_id fire_event_on_link_by_id

      # Fire an event on a image element identified by the value in its *:src* attribute.
      # Take care to escape characters in the source url that are reserved by Regexp.
      # @param (see #fire_event_on_link_by_text)
      # @return (see #click_button_by_id)
      #
      def fire_event_on_image_by_src(browser, what, event, desc = '')
        fire_event(browser, :img, :src, what, event, desc)
      end

      alias fire_event_src fire_event_on_image_by_src
      alias fire_event_image_by_src fire_event_on_image_by_src

      # @!endgroup Fire Event

      # @!group Validations

      # @param (see #clear_checkbox_by_name)
      # @return [Boolean] True if the answer to the assertion expressed in the called method name is yes.
      def validate_textfield_not_value_by_name(browser, what, value, desc = '')
        textfield_does_not_equal?(browser, :name, what, value, desc)
      end

      alias validate_textfield_no_value_by_name validate_textfield_not_value_by_name

      # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_not_value_by_id(browser, what, value, desc = '')
        textfield_does_not_equal?(browser, :id, what, value, desc)
      end

      alias validate_textfield_no_value_by_id validate_textfield_not_value_by_id

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_empty_by_name(browser, what, desc = '')
        textfield_empty?(browser, :name, what, desc)
      end

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_empty_by_id(browser, what, desc = '')
        textfield_empty?(browser, :id, what, desc)
      end

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_empty_by_title(browser, what, desc = '')
        textfield_empty?(browser, :title, what, desc)
      end

      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the specified attribute that uniquely identifies the element.
      # @param [String, Regexp] expected A string or a regular expression to be found in the *:value* attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_value_by_name(browser, what, expected, desc = '')
        textfield_equals?(browser, :name, what, expected, desc)
      end

      # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_value_by_id(browser, what, expected, desc = '')
        textfield_equals?(browser, :id, what, expected, desc)
      end

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_visible_by_name(browser, what, desc = '')
        visible?(browser, :text_field, :name, what, desc)
      end

      alias visible_textfield_by_name validate_textfield_visible_by_name

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_disabled_by_name(browser, what, desc = '')
        disabled?(browser, :text_field, :name, what, desc)
      end

      alias disabled_textfield_by_name validate_textfield_disabled_by_name

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_enabled_by_name(browser, what, desc = '')
        enabled?(browser, :text_field, :name, what, desc)
      end

      alias enabled_textfield_by_name validate_textfield_enabled_by_name

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_textfield_not_visible_by_name(browser, what, desc = '')
        not_visible?(browser, :text_field, :name, what, desc)
      end

      alias visible_no_textfield_by_name validate_textfield_not_visible_by_name

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_radio_not_set(browser, what, desc = '')
        not_set?(browser, :id, what, desc)
      end

      alias validate_not_radioset validate_radio_not_set

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def radio_is_set?(browser, what, desc = '')
        set?(browser, :id, what, desc)
      end

      alias validate_radioset radio_is_set?
      alias validate_radio_set radio_is_set?

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_radioset_by_name(browser, what, desc = '')
        set?(browser, :name, what, desc)
      end

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def checked_by_id?(browser, what, desc = '')
        checked?(browser, :id, what, desc)
      end

      alias validate_check checked_by_id?
      alias checkbox_is_checked? checked_by_id?

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def checkbox_is_enabled?(browser, what, desc = '')
        enabled?(browser, :checkbox, :id, what, desc)
      end

      alias validate_check_enabled checkbox_is_enabled?

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def checkbox_is_disabled?(browser, what, desc = '')
        disabled?(browser, :checkbox, :id, what, desc)
      end

      alias validate_check_disabled checkbox_is_disabled?

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_check_by_class(browser, what, desc)
        checked?(browser, :class, what, desc)
      end

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def checkbox_not_checked?(browser, what, desc)
        not_checked?(browser, :id, what, desc)
      end

      alias validate_not_check checkbox_not_checked?

      # @param (see #click_button_by_id)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_image(browser, what, desc = '', nofail = false)
        exists?(browser, :image, :src, what, desc)
      end

      # Verify that link identified by *:text* exists.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if the element exists.
      def validate_link_exist(browser, what, desc = '')
        exists?(browser, :link, :text, what, nil, desc)
      end

      # Verify that link identified by *:text* does not exist.
      # @param (see #click_button_by_id)
      # @return [Boolean] True if the element is does not exist.
      def link_not_exist?(browser, what, desc = '')
        does_not_exist?(browser, :link, :text, what, nil, desc)
      end

      alias validate_link_not_exist link_not_exist?

      # Verify that div identified by *:id* is visible.
      # @param (see #click_button_by_id)
      # @return [Boolean] True if the element is visible.
      def validate_div_visible_by_id(browser, what, desc = '')
        visible?(browser, :div, :id, what, desc)
      end

      # Verify that div identified by *:id* is not visible.
      # @param (see #click_button_by_id)
      # @return [Boolean] True if the element is not visible.
      def validate_div_not_visible_by_id(browser, what, desc = '')
        not_visible?(browser, :div, :id, what, desc)
      end

      # Verify that div click_button_by_id by *:text* is enabled.
      # @param (see #click_button_by_id)
      # @return [Boolean] True if the element is enabled.
      def link_enabled?(browser, what, desc = '')
        enabled?(browser, :link, :text, what, desc)
      end

      alias validate_link_enabled link_enabled?
      alias check_link_enabled link_enabled?

      # Verify that div identified by *:text* is disabled.
      # @param (see #click_button_by_id)
      # @return [Boolean] True if the element is disabled.
      def link_disabled?(browser, what, desc = '')
        disabled?(browser, :link, :text, what, desc)
      end

      alias validate_link_not_enabled link_disabled?

      def check_element_is_disabled(browser, element, how, what, desc = '')
        disabled?(browser, element, how, what, desc)
      end

      # Verify that select list, identified by :id and *what* contains *text* and select it if present
      # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_list(browser, what, expected, desc = '')
        validate_list_by_id(browser, what, expected, desc)
      end

      # Verify select list, identified by *:id*, does not contain *text*
      # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_no_list(browser, what, expected, desc = '')
        select_list_does_not_include?(browser, :id, what, expected, desc)
      end

      # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def text_in_span_equals?(browser, how, what, expected, desc = '')
        text_in_element_equals?(browser, :span, how, what, expected, desc)
      end

      # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def span_contains_text?(browser, how, what, expected, desc = '')
        element_contains_text?(browser, :span, how, what, expected, desc)
      end

      alias valid_text_in_span span_contains_text?

     # @param (see #clear_checkbox_by_name)
      # @return (see #validate_textfield_not_value_by_name)
      def validate_text_in_span_by_id(browser, what, expected, desc = '')
        element_contains_text?(browser, :span, :id, what, expected, desc)
      end

      # @!endgroup Validations

      # @!group Find

      # Return the list of options in a select list identified by its *:id* attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the designated attribute that uniquely identifies the element.
      # @param [Boolean] dbg Triggers additional debug logging when set to true.
      # @return [Array]
      def get_select_options_by_id(browser, what, dbg = false)
        get_select_options(browser, :id, what, dbg)
      end

      # Return the list of options in a select list identified by its *:name* attribute.
      # @param (see #get_select_options_by_id)
      # @return [Array]
      def get_select_options_by_name(browser, what, dbg = false)
        get_select_options(browser, :name, what, dbg)
      end

      # Return the list of _selected_ options in a select list identified by its *:id* attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the designated attribute that uniquely identifies the element.
      # @return [Array]
      def get_selected_options_by_id(browser, what)
        get_selected_options(browser, :id, what)
      end

      alias get_selected_option_by_id get_selected_options_by_id

      # Return the list of _selected_ options in a select list identified by its *:name* attribute.
      # @param (see #get_select_options_by_id)
      # @return [Array]
      def get_selected_options_by_name(browser, what)
        get_selected_options(browser, :name, what)
      end

      alias get_selected_option_by_name get_selected_options_by_name

      # Return a reference to a div element identified by its *:id* attribute.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the designated attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] dbg Triggers additional debug logging when set to true.
      # @return [Water::Div]
      def get_div_by_id(browser, what, desc = '', dbg = false)
        get_div(browser, :id, what, desc, dbg)
      end

      # Return a reference to a div element identified by its *:class* attribute.
      # @param (see #get_div_by_id)
      # @return [Water::Div]
      def get_div_by_class(browser, what, desc = '', dbg = false)
        get_div(browser, :class, what, desc, dbg)
      end

      # Return a reference to a div element identified by its *:text* attribute.
      # @param (see #get_div_by_id)
      # @return [Water::Div]
      def get_div_by_text(browser, what, desc = '', dbg = false)
        get_div(browser, :text, what, desc, dbg)
      end

      # Return a reference to a form element identified by its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return [Water::Form]
      def get_form_by_id(browser, what, desc = '')
        get_form(browser, :id, what, desc)
      end

      # Return a reference to a frame element identified by its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return [Water::Frame]
      def get_frame_by_id(browser, what, desc = '')
        get_frame(browser, :id, what, desc)
      end

      # Return a reference to a frame element identified by its *:index* within *browser*.
      # @param (see #click_button_by_id)
      # @return [Water::Frame]
      def get_frame_by_index(browser, what, desc = '')
        get_frame(browser, :index, what, desc)
      end

      # Return a reference to a frame element identified by its *:name* attribute.
      # @param (see #click_button_by_id)
      # @return [Water::Frame]
      def get_frame_by_name(browser, what, desc = '')
        get_frame(browser, :name, what, desc)
      end

      # Return a reference to a span element identified by its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return [Water::Span]
      def get_span_by_id(browser, what, desc = '')
        get_span(browser, :id, what, desc)
      end

      # Return a reference to a table element identified by its attribute *how* containing *what*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::Table]
      def get_table(browser, how, what, desc = '')
        get_element(browser, :table, how, what, nil, desc)
      end

      # Return a reference to a table element identified by its *:id* attribute.
      # @param (see #click_button_by_id)
      # @return [Watir::Table]
      def get_table_by_id(browser, what, desc = '')
        get_element(browser, :table, :id, what, nil, desc)
      end

      # Return a reference to a table element identified by its *:index* within *browser*.
      # @param (see #click_button_by_id)
      # @return [Watir::Table]
      def get_table_by_index(browser, what, desc = '')
        get_element(browser, :table, :index, what, nil, desc)
      end

      # Return a reference to a table element identified by its *:text* attribute.
      # @param (see #get_table)
      # @return [Watir::Table]
      def get_table_by_text(browser, what)
        get_element(browser, :table, :text, what, nil, desc)
      end

      # @!endgroup Find

      # @!group Wait

      # Wait until radio button, identified by attribute :value with value *what* exists on the page.
      # Timeout is the default used by watir (60 seconds)
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if radio exists within timeout limit
      def wait_until_by_radio_value(browser, what, desc = '')
        wait_until_exists(browser, :radio, :value, what, desc)
      end

      # Wait up to *how_long* seconds for DOM element *what_for* to exist in the page.
      # @note This is a last resort method when other wait or wait until avenues have
      # been exhausted.
      # @param [Fixnum] how_long Timeout limit
      # @param [Watir::Element] what_for A reference to a Dom element to wait for.
      def wait_for_exists(how_long, what_for)
        wait_for(how_long, what_for)
      end

      # Wait until link, identified by attribute :text with value *what* exists on the page.
      # Timeout is the default used by watir (60 seconds)
      # @param (see #wait_until_by_radio_value)
      # @return [Boolean] True if link exists within timeout limit
      def wait_until_by_link_text(browser, what, desc = '')
        wait_until_exists(browser, :link, :text, what, desc)
      end

      # @!endgroup Wait

    end
  end
end

