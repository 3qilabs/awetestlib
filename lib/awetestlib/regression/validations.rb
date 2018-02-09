module Awetestlib
  module Regression
    # Contains methods to verify content, accessibility, or appearance of page elements.
    module Validations

      # @!group Core

      # Verify that element style attribute contains expected value in style *type*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [String] type The name of the style type (sub-attribute) where *expected* is to be found.
      # @param [String] expected The value in *type* expected.
      # @return [Boolean] True if the style type contains the expected value
      #
      def validate_style_value(browser, element, how, what, type, expected, desc = '')
        #TODO: works only with watir-webdriver
        msg = build_message("Expected Style #{type} value '#{expected}' in #{element} with #{how} = #{what}", desc)
        case element
          when :link
            actual = browser.link(how, what).style type
          when :button
            actual = browser.button(how, what).style type
          when :image
            actual = browser.image(how, what).style type
          when :span
            actual = browser.span(how, what).style type
          when :div
            actual = browser.div(how, what).style type
          else
            if browser.element(how, what).responds_to?("style")
              actual = browser.element(how, what).style type
            else
              failed_to_log("#{msg}: Element #{element} does not repond to style command.")
            end
        end
        if expected == actual
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      def validate_style_greater_than_value(browser, element, how, what, type, value, desc = '')
        case element
          when :link
            actual_value = browser.link(how, what).style type
          when :button
            actual_value = browser.button(how, what).style type
          when :image
            actual_value = browser.image(how, what).style type
          when :span
            actual_value = browser.span(how, what).style type
          when :div
            actual_value = browser.div(how, what).style type
          else
            actual_value = browser.element(how, what).style type
        end
        msg = build_message("The CSS value for style #{type} in #{element} :#{how}=>#{what}: '#{actual_value}' is greater than #{value}.", desc)

        if actual_value.to_i > value.to_i
          passed_to_log(msg)
        elsif actual_value.to_i >~ value.to_i
          passed_to_log(msg)
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
        # sleep_for(1)
      end

      alias validate_style_greaterthan_value validate_style_greater_than_value

      def validate_style_less_than_value(browser, element, how, what, type, value, desc = '')
        case element
          when :link
            actual_value = browser.link(how, what).style type
          when :button
            actual_value = browser.button(how, what).style type
          when :image
            actual_value = browser.image(how, what).style type
          when :span
            actual_value = browser.span(how, what).style type
          when :div
            actual_value = browser.div(how, what).style type
          else
            actual_value = browser.element(how, what).style type
        end
        msg = build_message("The CSS value for style #{type} in #{element} :#{how}=>#{what}: '#{actual_value}' is greater than #{value}.", desc)

        if actual_value.to_i < value.to_i
          passed_to_log(msg)
        elsif actual_value.to_i <~ value.to_i
          passed_to_log(msg)
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
        # sleep_for(1)
      end

      alias validate_style_lessthan_value validate_style_less_than_value

      # @todo Clarify and rename
      def arrays_match?(exp, act, dir, col, org = nil, desc = '')
        if exp == act
          passed_to_log("Click on #{dir} column '#{col}' produces expected sorted list. #{desc}")
          true
        else
          failed_to_log("Click on #{dir} column '#{col}' fails to produce expected sorted list. #{desc}")
          debug_to_log("Original order ['#{org.join("', '")}']") if org
          debug_to_log("Expected order ['#{exp.join("', '")}']")
          debug_to_log("  Actual order ['#{act.join("', '")}']")
        end
      end

      alias arrays_match arrays_match?

      # Verify that a DOM element is enabled.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the element is enabled.
      #def enabled?(browser, element, how, what, desc = '')
      #  #TODO: Webdriver does not define this at element level, only for specific tags
      #  #TODO: handle identification of element with value as well as other attribute. see exists?
      #  msg = build_message("#{element.to_s.titlecase} by #{how}=>'#{what}' is enabled.}", desc)
      #  case element
      #    when :textfield, :textarea, :text_area, :text_field
      #      rtrn = browser.text_field(how, what).enabled? and not browser.text_field(how, what).readonly?
      #    when :select_list, :selectlist
      #      rtrn = browser.select_list(how, what).enabled?
      #    else
      #      rtrn = browser.element(how, what).enabled?
      #  end
      #  if rtrn
      #    passed_to_log("#{msg}")
      #    true
      #  else
      #    failed_to_log("#{msg}")
      #  end
      #  rtrn
      #rescue
      #  failed_to_log(unable_to(msg, false, true))
      #end

      #alias validate_enabled enabled?

      def expected_color?(container, element, how, what, style, expected_color, desc = '')
        #TODO: check that style is a color style
        msg          = build_message("Color of #{element} #{how}=>'#{what}' #{style} is #{expected_color}", desc)
        code         = build_webdriver_fetch(element, how, what)
        actual_color = eval("#{code}.style('#{style}')")
        if actual_color == expected_color
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      def disablement(container, should_be, element, how, what, desc = '')
        if should_be
          disabled?(container, element, how, what, desc)
        else
          enabled?(container, element, how, what, desc)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      # Verify that a DOM element is disabled.
      # @param (see #enabled?)
      # @return [Boolean] Returns true if the element is disabled.
      def disabled?(container, element, how, what, desc = '', value = nil)
        value, desc, options = capture_value_desc(value, desc) # for backwards compatibility
        msg2 = value ? "and value=>'#{value}' " : nil
        msg  = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'is disabled.', desc)
        code = build_webdriver_fetch(element, how, what, options)
        if eval("#{code}.disabled?")
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias validate_not_enabled disabled?
      alias validate_disabled disabled?

      def not_disabled?(container, element, how, what, desc = '', value = nil)
        value, desc, options = capture_value_desc(value, desc) # for backwards compatibility
        msg2 = value ? "and value=>'#{value}' " : nil
        msg  = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'is enabled.', desc)
        code = build_webdriver_fetch(element, how, what, options)
        if eval("#{code}.disabled?")
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias enabled? not_disabled?
      alias validate_enabled not_disabled?

      def element_disablement(target, disabled, desc = '')
        #TODO: Is this really necessary?
        is_disabled = target.disabled?
        disablement = false
        should_be   = disabled ? true : false
        msg         = build_message("#{method_to_title(__method__)}", "should be #{should_be}", "is #{is_disabled}", desc)
        if should_be == is_disabled
          passed_to_log(msg)
          disablement = true
        else
          failed_to_log(msg)
        end
        [is_disabled, disablement]
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      def presence(container, should_be, element, how, what, desc = '')
        if should_be
          is_present?(container, element, how, what, desc)
        else
          not_present?(container, element, how, what, desc)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def is_present?(container, element, how, what, value = nil, desc = '')
        value, desc, options = capture_value_desc(value, desc) # for backwards compatibility
        msg2 = value ? "and value=>'#{value}' " : nil
        msg  = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'is present.', desc)
        code = build_webdriver_fetch(element, how, what, options)
        if eval("#{code}.present?")
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      def not_present?(container, element, how, what, value = nil, desc = '')
        value, desc, options = capture_value_desc(value, desc) # for backwards compatibility
        msg2 = value ? "and value=>'#{value}' " : nil
        msg  = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'is not present.', desc)
        code = build_webdriver_fetch(element, how, what, options)
        if eval("#{code}.exists?")
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      def visibility(container, should_be, element, how, what, desc = '')
        msg = build_message(desc)
        if should_be
          visible?(container, element, how, what, desc)
        else
          not_visible?(container, element, how, what, desc)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      # Verify that a DOM element is visible.
      # @param (see #enabled?)
      # @return [Boolean] Returns true if the element is visible.
      def visible?(container, element, how, what, desc = '')
        msg  = build_message("#{__method__.to_s.titleize}: #{element.to_s.titleize} #{how}=>'#{what}'", desc)
        code = build_webdriver_fetch(element, how, what)
        if eval("#{code}.visible?")
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias validate_visible visible?

      # Verify that a DOM element is not visible.
      # @param (see #enabled?)
      # @return [Boolean] Returns true if the element is not visible.
      def not_visible?(container, element, how, what, desc = '')
        msg  = build_message("#{__method__.to_s.titleize}: #{element.to_s.titleize} #{how}=>'#{what}'", desc)
        code = build_webdriver_fetch(element, how, what)
        if eval("#{code}.visible?")
          failed_to_log("#{msg}")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias validate_not_visible not_visible?

      # Verify that a checkbox is checked.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the checkbox is checked.
      def checked?(browser, how, what, desc = '')
        #TODO: handle identification of element with value as well as other attribute.  see exists?
        msg = build_message("Checkbox #{how}=>#{what} is checked.", desc)
        if browser.checkbox(how, what).checked?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias checkbox_checked? checked?
      alias checkbox_set? checked?

      # Verify that a checkbox is not checked.
      # @param (see #checked?)
      # @return [Boolean] Returns true if the checkbox is not checked.
      def not_checked?(browser, how, what, desc = '')
        #TODO: handle identification of element with value as well as other attribute. see exists?
        msg = build_message("Checkbox #{how}=>#{what} is not checked.", desc)
        if not browser.checkbox(how, what).checked?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias checkbox_checked? checked?
      alias checkbox_set? checked?

      def existence(container, should_be, element, how, what, desc = '')
        if should_be
          exists?(container, element, how, what, desc)
        else
          does_not_exist?(container, element, how, what, desc)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      # Verify that a DOM element exists on the page.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the value attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] True if the element exists.
      def exists?(container, element, how, what, value = nil, desc = '')
        value, desc, options = capture_value_desc(value, desc) # for backwards compatibility
        msg2 = value ? "and value=>'#{value}' " : nil
        msg  = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'exists.', desc)
        code = build_webdriver_fetch(element, how, what, options)
        if eval("#{code}.exists?")
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      # Verify that a DOM element does not exist on the page.
      # @param (see #exists?)
      # @return [Boolean] True if the element does not exist.
      def does_not_exist?(container, element, how, what, value = nil, desc = '')
        value, desc, options = capture_value_desc(value, desc) # for backwards compatibility
        msg2 = value ? "and value=>'#{value}' " : nil
        msg  = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'does not exist.', desc)
        code = build_webdriver_fetch(element, how, what, options)
        if eval("#{code}.exists?")
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias not_exist? does_not_exist?

      # Verify that a radio button is set.
      # @param (see #checked?)
      # @return [Boolean] Returns true if the radio button is set.
      def set?(browser, how, what, desc = '', no_fail = false)
        #TODO: handle identification of element with value as well as other attribute. see radio_with_value_set?
        msg = build_message("Radio #{how}=>#{what} is set.", desc)
        if browser.radio(how, what).set?
          passed_to_log(msg)
          true
        else
          if no_fail
            passed_to_log("#{msg}.  (Fail suppressed)")
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias radio_set? set?
      alias radio_checked? set?
      alias radio_selected? set?

      # Verify that a radio button is not set.
      # @param (see #checked?)
      # @return [Boolean] Returns true if the radio button is not set.
      def not_set?(browser, how, what, desc = '', no_fail = false)
        #TODO: handle identification of element with value as well as other attribute. see radio_with_value_set?
        msg = build_message("Radio #{how}=>#{what} is not set.", desc)
        if not browser.radio(how, what).set?
          passed_to_log(msg)
          true
        else
          if no_fail
            passed_to_log("#{msg} (Fail suppressed")
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      alias radio_not_set? not_set?
      alias radio_not_checked? not_set?
      alias radio_not_selected? not_set?

      # Verify that a radio button, identified by both the value (*what*) in attribute *how*
      # and the *value* in its value attribute, is set.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the value attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the radio button is set.
      def radio_with_value_set?(browser, how, what, value, desc = '', no_fail = false)
        msg2 = 'not' if no_fail
        msg = build_message("Radio #{how}=>#{what} :value=>#{value} is", msg2, 'selected.', desc)
        if browser.radio(how, what, value).set?
          passed_to_log(msg)
          true
        else
          if no_fail
            passed_to_log(msg)
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to verify that #{msg}: '#{$!}'")
      end

      alias radio_set_with_value? radio_with_value_set?

      # Verify that a select list, identified by the value (*what*) in attribute *how*, contains an option with the
      # value in *option*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String, Regexp] option A string or a regular expression to be found in the value attribute of the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the option is found.
      def select_list_includes?(browser, how, what, option, desc = '')
        msg         = build_message("Select list #{how}=>#{what} includes option '#{option}'.", desc)
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if option
          if options.include?(option)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to verify #{msg}. '#{$!}'")
      end

      alias validate_select_list_contains select_list_includes?
      alias select_list_contains? select_list_includes?

      # Verify that a select list, identified by the value (*what*) in attribute *how*, contains an option with the
      # value in *option*.
      # @param (see #select_list_includes?)
      # @return [Boolean] Returns true if the option is not found.
      def select_list_does_not_include?(browser, how, what, option, desc = '')
        msg         = build_message("Select list #{how}=>#{what} does not include option '#{option}'.", desc)
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if option
          if not options.include?(option)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
            nil
          end
        end
      rescue
        failed_to_log("Unable to verify #{msg}. '#{$!}'")
      end

      # Compare strings for exact match and log results
      # @param [String] actual The actual value as found in the application.
      # @param [String] expected The value expected to be found.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if actual exactly matches expected.
      def string_equals?(actual, expected, desc = '')
        msg = build_message("Actual string '#{actual}' equals expected '#{expected}'.", desc)
        if actual == expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        failed_to_log("Unable to verify #{msg}. #{$!}")
      end

      alias validate_string_equal string_equals?
      alias validate_string_equals string_equals?
      alias text_equals string_equals?
      alias text_equals? string_equals?

      # Compare strings for no match and log results
      # @param (see #string_equals?)
      # @return [Boolean] Returns true if actual does not match expected.
      def string_does_not_equal?(actual, expected, desc = '')
        msg = build_message("Actual string '#{actual}' does not equal expected '#{expected}'.", desc)
        if actual == expected
          failed_to_log("#{msg} (#{__LINE__})")
          true
        else
          passed_to_log("#{msg} (#{__LINE__})")
        end
      end

      alias validate_string_not_equal string_does_not_equal?
      alias validate_string_does_not_equal string_does_not_equal?

      # Verify that date strings represent the same date, allowing for format differences.
      # Compare strings for no match and log results
      # @param (see #string_equals?)
      # @param [Boolean] fail_on_format If set to true method will fail if the formats differ
      # even though the dates/times match
      # @return [Boolean] Returns true if actual does not match expected.
      def date_string_equals?(actual, expected, desc = '', fail_on_format = true)
        rtrn = false
        if actual == expected
          rtrn = true
        elsif DateTime.parse(actual).to_s == DateTime.parse(expected).to_s
          msg2 = "with different formatting. "
          unless fail_on_format
            rtrn = true
          end
        end
        msg = build_message("Actual date '#{actual}' equals expected date '#{expected}'.", msg2, desc)
        if rtrn
          passed_to_log("#{msg}")
        else
          failed_to_log("#{msg}")
        end
        rtrn
      rescue
        failed_to_log("Unable to verify that #{msg}. #{$!}")
      end

      # Verify that a DOM element is in read-only state.
      # @param (see #enabled?)
      # @return [Boolean] Returns true if the element is in read-only state.
      def read_only?(browser, element, how, what, value = nil, desc = '')
        msg = "#{element.to_s.titlecase} with #{how}=>'#{what}' "
        msg << "and value=>'#{value}' " if value
        msg << "read only"
        e = get_element(browser, element, how, what, value)
        if e
          if e.readonly?
            passed_to_log("#{msg}? #{desc}")
            true
          else
            failed_to_log("#{msg}? #{desc} [#{get_callers(1)}]")
          end
        end
      rescue
        failed_to_log("Unable to determine if #{msg}. #{desc} '#{$!}' [#{get_callers(1)}]")
      end

      # Verify that a DOM element is not in read-only state.
      # @param (see #enabled?)
      # @return [Boolean] Returns true if the element is not in read-only state.
      def not_read_only?(browser, element, how, what, value = nil, desc = '')
        msg = "#{element.to_s.titlecase} with #{how}=>'#{what}' "
        msg << "and value=>'#{value}' " if value
        msg << "is not read only"
        e = get_element(browser, element, how, what, value)
        if e
          if e.readonly?
            failed_to_log("#{msg}? #{desc} [#{get_callers(1)}]")
          else
            passed_to_log("#{msg}? #{desc}")
            true
          end
        end
      rescue
        failed_to_log("Unable to determine if #{msg}. #{desc} '#{$!}' [#{get_callers(1)}]")
      end

      # Verify that a DOM element is ready, i.e., both exists and is enabled.
      # @param (see #exists?)
      # @return [Boolean] Returns true if the element is ready.
      #TODO: Watir-webdriver support
      def ready?(browser, element, how, what, value = '', desc = '')
        msg2 = "and value=>'#{value}' " if value
        msg = build_message("#{element.to_s.titlecase} with #{how}=>'#{what}' ", msg2, 'exists and is enabled.', desc)
        e   = get_element(browser, element, how, what, value)
        if e and e.enabled?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to determine if #{msg}. '#{$!}' [#{get_callers(1)}]")
      end

      # Verify that a text field (also text area), identified by *how* and *what*, contains only the exact string specified in *expected*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] expected A string which the value attribute of the text field must equal.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the *expected* and the value in the text field are identical.
      def textfield_equals?(browser, how, what, expected, desc = '')
        msg    = build_message("Expected value to equal '#{expected}' in textfield #{how}=>'#{what}'.", desc)
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
        failed_to_log(unable_to)
      end

      alias validate_textfield_value textfield_equals?
      alias text_field_equals? textfield_equals?

      # Verify that a text field (also text area), identified by *how* and *what*, contains the string specified in *expected*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String, Regexp] expected A string or regular expression which must be matched in the value of the text field
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the *expected* is matched in the value of the text field.
      def textfield_contains?(container, how, what, expected, desc = '')
        msg      = build_message("Text field #{how}=>#{what} contains '#{expected}'.", desc)
        contents = container.text_field(how, what).when_present.value
        if contents =~ /#{expected}/
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Contents: '#{contents}'")
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      # Verify that a text field (also text area), identified by *how* and *what*, is empty.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the text field is empty.
      def textfield_empty?(browser, how, what, desc = '')
        msg = "Text field #{how}=>#{what} is empty."
        msg << desc if desc.length > 0
        contents = browser.text_field(how, what).value
        if contents.to_s.length == 0
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Contents: '#{contents}'")
        end
      rescue
        failed_to_log(unable_to)
      end

      alias validate_textfield_empty textfield_empty?
      alias text_field_empty? textfield_empty?

      # Verify that a text field (also text area), identified by *how* and *what*, contains the string specified in *expected*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String] expected A string in dollar formatting
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the *expected* is matched in the value of the text field.
      def validate_textfield_dollar_value(browser, how, what, expected, with_cents = true, desc = '')
        target = expected.dup
        desc << " Dollar formatting"
        if with_cents
          target << '.00' if not expected =~ /\.00$/
          desc << " without cents. orig:(#{expected})"
        else
          target.gsub!(/\.00$/, '')
          desc << " with cents. orig:(#{expected})"
        end
        textfield_equals?(browser, how, what, target, desc)
      end

      # Verify that *browser* is set to a url that is matched by the string or rexexp in *url*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String, Regexp] url A string or a regular expression to match to the url of the browser..
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Boolean] Returns true if the *expected* is matched in the value of the text field.
      def validate_url(browser, url, desc = '')
        msg = build_message("Current URL matches #{url}.", desc)
        if browser.url.to_s.match(url)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Actual: #{browser.url}")
        end
      rescue
        failed_to_log(unable_to)
      end

      # @!endgroup Core

      # @!group AutoIT

      def window_exists?(title)
        title = translate_popup_title(title)
        if @ai.WinExists(title) == 1
          passed_to_log("Window title:'#{title}' exists")
          true
        else
          failed_to_log("Window title:'#{title}' does not exist")
        end
      end

      alias window_exists window_exists?

      def window_does_not_exist?(title)
        title = translate_popup_title(title)
        if @ai.WinExists(title) == 1
          failed_to_log("Window title:'#{title}' exists")
        else
          passed_to_log("Window title:'#{title}' does not exist")
          true
        end
      end

      alias window_no_exists window_does_not_exist?

      # @!endgroup AutoIT

      # @!group Core

      def popup_is_browser?(popup, desc = '')
        msg = build_message("Popup: #{popup.title} is a browser window.", desc)
        if is_browser?(popup)
          passed_to_log(msg)
          debug_to_log("\n"+popup.text+"\n")
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to)
      end

      alias popup_exist popup_is_browser?
      alias popup_exists popup_is_browser?
      alias popup_exist? popup_is_browser?
      alias popup_exists? popup_is_browser?
      alias iepopup_exist popup_is_browser?
      alias iepopup_exist? popup_is_browser?
      alias iepopup_exists popup_is_browser?
      alias iepopup_exists? popup_is_browser?

      # Verify that select list, identified by the value *what* in the attribute :id, contains text and select it if present.
      def validate_list_by_id(browser, what, option, desc = '', select_if_present = true)
        if select_list_includes?(browser, :id, what, option, desc)
          if select_if_present
            select_option(browser, :id, what, :text, option, desc, false)
          else
            passed_to_log(message)
            true
          end
        end
      end

      # Verify that select list contains text
      def validate_list_by_name(browser, what, option, desc = '', select_if_present = true)
        if select_list_includes?(browser, :name, what, option, desc)
          if select_if_present
            select_option(browser, :name, what, :text, option, desc, false)
          else
            passed_to_log(message)
            true
          end
        end
      end

      def validate_text(container, ptrn, desc = '', skip_fail = false, skip_sleep = false)
        cls = container.class.to_s
        cls.gsub!('Watir::', '')
        cls.gsub!('IE', 'Browser')
        msg = build_message("#{cls} text contains '#{ptrn}'.", desc)
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
          passed_to_log("#{msg}")
          true
        else
          if skip_fail
            debug_to_log("#{cls} text does not contain the text: '#{ptrn}'.  #{desc} (Fail suppressed)")
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      alias validate_link validate_text

      def text_in_element_equals?(browser, element, how, what, expected, desc = '')
        msg  = build_message("Expected exact text '#{expected}' in #{element} :#{how}=>#{what}.", desc)
        text = ''
        who  = browser.element(how, what)
        if who
          text = who.text
          if text == expected
            passed_to_log(msg)
            true
          else
            debug_to_log("exp: [#{expected.gsub(' ', '^')}]")
            debug_to_log("act: [#{text.gsub(' ', '^')}]")
            failed_to_log("#{msg} Found '#{text}'.")
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def element_contains_text?(browser, element, how, what, expected, desc = '')
        msg = build_message("Element #{element} :{how}=>#{what} contains text '#{expected}'.", desc)
        case how
          when :href
            who = browser.link(how, what)
          else
            who = browser.element(how, what)
        end
        if who
          text = who.text
          if expected and expected.length > 0
            rgx = Regexp.new(Regexp.escape(expected))
            if text =~ rgx
              passed_to_log(msg)
              true
            else
              debug_to_log("exp: [#{expected.gsub(' ', '^')}]")
              debug_to_log("act: [#{text.gsub(' ', '^')}]")
              failed_to_log("#{msg} Found '#{text}'. #{desc}")
            end
          else
            if text.length > 0
              debug_to_log("exp: [#{expected.gsub(' ', '^')}]")
              debug_to_log("act: [#{text.gsub(' ', '^')}]")
              failed_to_log("#{msg} Found '#{text}'. #{desc}")
            else
              passed_to_log(msg)
              true
            end
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def validate_select_list(browser, how, what, opt_type, list = nil, desc= '',  multiple = false, ignore = ['Select One'], limit = 5)
        mark_testlevel("(#{how}=>#{what})")
        msg  = "Select list #{how}=>#{what}"
        ok          = true
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if list
          if options == list
            passed_to_log(build_message(msg, ": options list equals expected list #{list}"))
          else
            debug_to_report("actual:\n#{nice_array(options, true)}")
            debug_to_report("expected:\n#{nice_array(list, true)}")
            failed_to_log(build_message(
                              msg,
                              ": options list #{nice_array(options, true)}",
                              "does not equal expected list #{nice_array(list, true)}")
                                       )
          end
        end

        #single selections
        cnt = 0
        options.each do |opt|
          if not ignore.include?(opt)
            cnt += 1
            ok  = select_option(select_list, opt_type, opt)
            break if not ok
            select_list.clear
            break if limit > 0 and cnt >= limit
          end
        end

        sleep_for(0.5)
        select_list.clear
        if ok and multiple
          if options.length > 2
            targets = list.slice(1, 2)
            select_option(select_list, opt_type, options[1])
            select_option(select_list, opt_type, options[2])
            selected = select_list.selected_options
            msg1 = "#{msg}: selected options equals expected #{nice_array(targets)}."
            if selected == targets
              passed_to_log(msg1)
            else
              failed_to_log("#{msg} Found #{nice_array(selected)}")
            end
          else
            debug_to_log("#{msg}: Too few options to test multiple selection (need 2 or more): '#{options}")
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def validate_select_list_contents(browser, how, what, list, desc = '')
        mark_testlevel("#{how}=>#{what}", 2)
        msg  = build_message("Select list #{how}=>#{what} options list equals", nice_array(list), desc)
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if list
          if options == list
            passed_to_log(msg)
            options
          else
            failed_to_log("#{msg}. Found #{nice_array(options)}")
            nil
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      def validate_selected_options(browser, how, what, list, desc = '', which = :text)
        selected_options = browser.select_list(how, what).selected_options.dup
        selected         = extract_selected(selected_options, which)
        sorted_list      = list.dup.sort
        if list.is_a?(Array)
          if selected == sorted_list
            passed_to_log("Expected options [#{list.sort}] are selected [#{selected}]. #{desc}")
          else
            failed_to_log("Selected options [#{selected}] do not match expected [#{sorted_list}]. #{desc}")
            true
          end
        else
          if selected.length == 1
            if selected[0] =~ /#{list}/
              passed_to_log("Expected option [#{list}] was selected. #{desc}")
              true
            else
              failed_to_log("Expected option [#{list}] was not selected. Found [#{selected}]. #{desc}")
            end
          else
            if selected.include?(list)
              failed_to_log("Expected option [#{list}] was found among multiple selections [#{selected}]. #{desc}")
            else
              failed_to_log("Expected option [#{list}] was not found among multiple selections [#{selected}]. #{desc}")
            end
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      alias validate_selections validate_selected_options
      alias validate_select_list_selections validate_selected_options

      def string_contains?(strg, target, desc = '')
        msg = build_message("String '#{strg}' contains '#{target}'.", desc)
        if strg.match(target)
          passed_to_log("#{msg} (#{__LINE__})")
          true
        else
          failed_to_log("#{msg} (#{__LINE__})")
        end
      end

      alias validate_string string_contains?
      alias validate_string_contains string_contains?

      def string_does_not_contain?(strg, target, desc = '')
        msg = build_message("String '#{strg}' does not contain '#{target}'.", desc)
        if strg.match(target)
          failed_to_log("#{msg} (#{__LINE__})")
          true
        else
          passed_to_log("#{msg} (#{__LINE__})")
        end
      end

      alias validate_string_not_contains string_does_not_contain?
      alias validate_string_not_contain string_does_not_contain?
      alias validate_string_does_not_contain string_does_not_contain?

      def validate_no_text(browser, ptrn, desc = '')
        cls = browser.class.to_s
        cls.gsub!('Watir::', '')
        cls.gsub!('IE', 'Browser')
        msg = "#{cls} does not contain text '#{ptrn}'."
        msg << " #{desc}" if desc.length > 0
        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end
        browser_text = browser.text
        if browser_text.match(target)
          failed_to_log("#{msg} [#{browser_text.match(target)[0]}]")
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to)
      end

      def textfield_does_not_equal?(browser, how, what, expected, desc = '')
        msg = build_message("Text field #{how}=>#{what} does not equal '#{expected}'", desc)
        if not browser.text_field(how, what).value == expected
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to)
      end

      alias validate_textfield_not_value textfield_does_not_equal?

      def verify_class(browser, element, how, what, strg, desc = '')
        msg = build_message("#{element} :#{how}=>#{what} :class contains '#{strg}'", desc)
        class_strg = browser.element(how, what).class_name
        if class_strg =~ /#{strg}/
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to)
      end

      def attribute_contains?(container, element, how, what, attr_name, expected, desc = '')
        msg = build_message("Element #{element} :#{how}=>#{what}", "attribute '#{attr_name}", "contains '#{expected}'.", desc)
        if container.element(how, what).attribute_value(attr_name).contains(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def attribute_does_not_contain?(container, element, how, what, attr_name, expected, desc = '')
        msg = build_message("Element #{element} :#{how}=>#{what}", "attribute '#{attr_name}", "does not contain '#{expected}'.", desc)
        if container.element(how, what).attribute_value(attr_name).contains(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def attribute_equals?(container, element, how, what, attr_name, expected, desc = '')
        msg = build_message("Element #{element} :#{how}=>#{what}", "attribute '#{attr_name}", "equals '#{expected}'.", desc)
        actual = container.element(how, what).attribute_value(attr_name)
        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Found '#{actual}'")
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def attribute_does_not_equal?(container, element, how, what, attr_name, expected, desc = '')
        msg = build_message("Element #{element} :#{how}=>#{what}", "attribute '#{attr_name}", "does not equal '#{expected}'.", desc)
        if container.element(how, what).attribute_value(attr_name) == expected
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def element_attribute_equals?(element, attr_name, expected, desc = '')
        msg = build_message("#{element.tag_name.capitalize}", "attribute '#{attr_name}'", "equals '#{expected}'.", desc)
        actual = element.attribute_value(attr_name)
        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Found '#{actual}'")
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def element_attribute_does_not_equal?(element, attr_name, expected, desc = '')
        msg = build_message("#{element.tag_name.capitalize}", "attribute '#{attr_name}'", "does not equal '#{expected}'.", desc)
        if element.attribute_value(attr_name) == expected
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def element_attribute_contains?(element, attribute, expected, desc = '')
        msg = build_message("#{element.tag_name.capitalize}", "attribute '#{attribute}'","contains '#{expected}'.", desc)
        if element.attribute_value(attribute).include?(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def element_attribute_does_not_contain?(element, attribute, expected, desc = '')
        msg = build_message("#{element.tag_name.capitalize}", "attribute '#{attribute}'","does not contain '#{expected}'.", desc)
        if element.attribute_value(attribute).include?(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log(unable_to('', false, true))
      end

      def contains_text?(container, element, how, what, expected, desc = '')
        msg  = build_message("Element #{element} :#{how}=>#{what} contains '#{expected}'.", desc)
        code = build_webdriver_fetch(element, how, what)
        target = eval(code)
        if target
          text = target.text
          if expected and expected.length > 0
            rgx = Regexp.new(Regexp.escape(expected))
            if text =~ rgx
              passed_to_log(msg)
              true
            else
              debug_to_log("exp: [#{expected.gsub(' ', '^')}]")
              debug_to_log("act: [#{text.gsub(' ', '^')}]")
              failed_to_log("#{msg} Found '#{text}'. #{desc}")
            end
          else
            if text.length > 0
              debug_to_log("exp: [#{expected.gsub(' ', '^')}]")
              debug_to_log("act: [#{text.gsub(' ', '^')}]")
              failed_to_log("#{msg} Found '#{text}'. #{desc}")
            else
              passed_to_log(msg)
              true
            end
          end
        end
      rescue
        failed_to_log(unable_to(msg, false, true))
      end

      def directory_exists?(directory)
        File.directory?(directory)
      end

      # @!endgroup Core

      # @!group Deprecated
      # @deprecated
      def self.included(mod)
        # puts "RegressionSupport::Validations extended by #{mod}"
      end

      # @deprecated Use #message_to_log
      def validate_message(browser, message)
        message_to_log(message)
      end

      # @!endgroup Deprecated

    end
  end
end

