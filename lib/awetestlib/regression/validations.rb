module Awetestlib
  module Regression
    # Contains methods to verify content, accessibility, or appearance of page elements.
    module Validations


      def validate_style_value(browser, element, how, what, type, expected, desc = '')
        #TODO: works only with watir-webdriver
        msg = "Expected CSS style #{type} value '#{expected}' in #{element} with #{how} = #{what}"
        msg << " #{desc}" if desc.length > 0
        case element
          when :link
            actual = browser.link(how => what).style type
          when :button
            actual = browser.button(how => what).style type
          when :image
            actual = browser.image(how => what).style type
          when :span
            actual = browser.span(how => what).style type
          when :div
            actual = browser.div(how => what).style type
        end
        if expected == actual
          passed_to_log(msg)
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log( "Unable to validate #{msg} '#{$!}'")
      end

      ##### begin core validation methods #####

      def arrays_match?(exp, act, dir, col, org = nil)
        if exp == act
          passed_to_log("Click on #{dir} column '#{col}' produces expected sorted list.")
          true
        else
          failed_to_log("Click on #{dir} column '#{col}' fails to produce expected sorted list.")
          debug_to_log("Original order ['#{org.join("', '")}']") if org
          debug_to_log("Expected order ['#{exp.join("', '")}']")
          debug_to_log("  Actual order ['#{act.join("', '")}']")
        end
      end

      alias arrays_match arrays_match?

      def enabled?(browser, element, how, what, desc = '')
        msg = "#{element.to_s.titlecase} by #{how}=>'#{what}' is enabled.}"
        msg << " #{desc}" if desc.length > 0
        case element
          when :textfield, :textarea, :text_area, :text_field
            rtrn = browser.text_field(how, what).enabled? and not browser.text_field(how, what).readonly?
          when :select_list, :selectlist
            rtrn = browser.select_list(how, what).enabled?
          else
            rtrn = browser.element(how, what).enabled?
        end
        if rtrn
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
        rtrn
      rescue
        failed_to_log("#Unable to verify that #{msg}': '#{$!}")
      end

      alias validate_enabled enabled?

      def date_string_equals?(actual, expected, desc = '', fail_on_format = true)
        rtrn = false
        msg  = "Assert actual date '#{actual}' equals expected date '#{expected}'. #{desc} "
        if actual == expected
          rtrn = true
        elsif DateTime.parse(actual).to_s == DateTime.parse(expected).to_s
          msg << " with different formatting. "
          if not fail_on_format
            rtrn = true
          end
        end
        msg << " #{desc}" if desc.length > 0
        if rtrn
          passed_to_log("#{msg}")
        else
          failed_to_log("#{msg}")
        end
        rtrn
      rescue
        failed_to_log("Unable to #{msg}. #{$!}")
      end

      def disabled?(browser, element, how, what, desc = '')
        msg = "#{element.to_s.titlecase} by #{how}=>'#{what}' is disabled. #{desc}"
        case element
          when :textfield, :textarea, :text_area, :text_field
            rtrn = browser.text_field(how, what).disabled? ||
                browser.text_field(how, what).readonly?
          when :select_list, :selectlist
            rtrn = browser.select_list(how, what).disabled?
          when :checkbox
            rtrn = browser.checkbox(how, what).disabled?
          when :radio
            rtrn = browser.radio(how, what).disabled?
          when :button
            rtrn = browser.button(how, value).disabled?
          else
            msg = "#{__method__} does not yet support '#{element}'. #{desc}"
            debug_to_log(msg)
            raise msg
        end
        if rtrn
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
        rtrn
      rescue
        failed_to_log("#Unable to verify that #{msg}: '#{$!}'")
      end

      alias validate_not_enabled disabled?
      alias validate_disabled disabled?

      def verify_text_in_table_with_text(table, text, value)
        #TODO This needs clarification, renaming
        msg   = "Table :id=>#{table.id} with text '#{text} contains '#{value}."
        index = get_index_of_row_with_text(table, text)
        if table[index].text =~ value
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      end

      def visible?(browser, element, how, what, desc = '')
        msg  = "#{element.to_s.titlecase} #{how}=>'#{what}' is visible. #{desc}"
        rtrn = false
        case how
          when :index
            target = get_element(browser, element, how, what)
            if target.visible?
              rtrn = true
            end
          else
            if browser.element(how, what).visible?
              rtrn = true
            end
        end
        if rtrn
          passed_to_log("#{msg}")
        else
          failed_to_log("#{msg}")
        end
        rtrn
      rescue
        failed_to_log("Unable to verify that #{msg}': '#{$!}'")
      end

      alias validate_visible visible?

      def not_visible?(browser, element, how, what, desc = '')
        msg  = "#{element.to_s.titlecase} #{how}=>'#{what}' is not visible. #{desc}"
        rtrn = false
        case how
          when :index
            target = get_element(browser, element, how, what)
            if not target.visible?
              rtrn = true
            end
          else
            if not browser.element(how, what).visible?
              rtrn = true
            end
        end
        if rtrn
          passed_to_log("#{msg}")
        else
          failed_to_log("#{msg}")
        end
        rtrn
      rescue
        failed_to_log("Unable to verify that #{msg}': '#{$!}' #{desc}")
      end

      alias validate_not_visible not_visible?

      def checked?(browser, how, what, desc = '')
        msg = "Checkbox #{how}=>#{what} is checked."
        msg << " #{desc}" if desc.length > 0
        if browser.checkbox(how, what).checked?
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}'")
      end

      alias checkbox_checked? checked?
      alias checkbox_set? checked?

      def not_checked?(browser, how, what, desc = '')
        msg = "Checkbox #{how}=>#{what} is not checked."
        msg << " #{desc}" if desc.length > 0
        if not browser.checkbox(how, what).checked?
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}'")
      end

      alias checkbox_checked? checked?
      alias checkbox_set? checked?

      def exists?(browser, element, how, what, value = nil, desc = '')
        msg = "#{element.to_s.titlecase} with #{how}=>'#{what}' "
        msg << "and value=>'#{value}' " if value
        msg << "exists"
        e = get_element(browser, element, how, what, value)
        if e
          passed_to_log("#{msg}? #{desc}")
          true
        else
          failed_to_log("#{msg}? #{desc} [#{get_callers(1)}]")
        end
      rescue
        failed_to_log("Unable to determine if #{msg}. #{desc} '#{$!}' [#{get_callers(1)}]")
      end

      def does_not_exist?(browser, element, how, what, value = nil, desc = '')
        msg = "#{element.to_s.titlecase} with #{how}=>'#{what}' "
        msg << "and value=>'#{value}' " if value
        msg << "does not exist."
        msg << " #{desc}" if desc.length > 0
        if browser.element(how, what).exists?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to verify that #{msg}': '#{$!}' #{desc}")
      end

      alias not_exist? does_not_exist?

      def set?(browser, how, what, desc = '', no_fail = false)
        #TODO Needs to handle radio value as well
        msg = "Radio #{how}=>#{what} is selected."
        msg << " #{desc}" if desc.length > 0
        if browser.radio(how, what).set?
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          if no_fail
            passed_to_log("Radio #{how}=>#{what} is not selected.")
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}'")
      end

      alias radio_set? set?
      alias radio_checked? set?
      alias radio_selected? set?

      def not_set?(browser, how, what, desc = '', no_fail = false)
        #TODO Needs to handle radio value as well
        msg = "Radio #{how}=>#{what} is not selectedd."
        msg << " #{desc}" if desc.length > 0
        if not browser.radio(how, what).set?
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          if no_fail
            passed_to_log("Radio #{how}=>#{what} is not selected.")
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}'")
      end

      alias radio_not_set? not_set?
      alias radio_not_checked? not_set?
      alias radio_not_selected? not_set?

      def radio_with_value_set?(browser, how, what, value, desc = '', no_fail = false)
        msg = "Radio #{how}=>#{what} :value=>#{value} is selected."
        msg << " #{desc}" if desc.length > 0
        if browser.radio(how, what, value).set?
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          if no_fail
            passed_to_log("Radio #{how}=>#{what} :value=>#{value} is not selected.")
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}'")
      end

      alias radio_set_with_value? radio_with_value_set?

      def select_list_includes?(browser, how, what, option, desc = '')
        msg = "Select list #{how}=>#{what} includes option '#{option}'."
        msg << " #{desc}" if desc.length > 0
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if option
          if options.include?(option)
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

      alias validate_select_list_contains select_list_includes?
      alias select_list_contains? select_list_includes?

      def select_list_does_not_include?(browser, how, what, option, desc = '')
        msg = "Select list #{how}=>#{what} does not include option '#{option}'."
        msg << " #{desc}" if desc.length > 0
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

      def string_equals?(actual, target, desc = '')
        msg = "Assert actual '#{actual}' equals expected '#{target}'. #{desc} "
        if actual == target
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        failed_to_log("Unable to #{msg}. #{$!}")
      end

      alias validate_string_equal string_equals?
      alias validate_string_equals string_equals?
      alias text_equals string_equals?
      alias text_equals? string_equals?

      def string_does_not_equal?(strg, target, desc = '')
        msg = "String '#{strg}' does not equal '#{target}'."
        msg << " '#{desc}' " if desc.length > 0
        if strg == target
          failed_to_log("#{msg} (#{__LINE__})")
          true
        else
          passed_to_log("#{msg} (#{__LINE__})")
        end
      end

      alias validate_string_not_equal string_does_not_equal?
      alias validate_string_does_not_equal string_does_not_equal?

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

      def ready?(browser, element, how, what, value = '', desc = '')
        msg = "#{element.to_s.titlecase} with #{how}=>'#{what}' "
        msg << "and value=>'#{value}' " if value
        e = get_element(browser, element, how, what, value)
        if e and e.enabled?
          passed_to_log("#{msg}? #{desc}")
          true
        else
          failed_to_log("#{msg}? #{desc} [#{get_callers(1)}]")
        end
      rescue
        failed_to_log("Unable to determine if #{msg}. #{desc} '#{$!}' [#{get_callers(1)}]")
      end

    ##### end core validation methods #####

    ##### begin methods using @ai #####

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

    ##### end methods using @ai #####

    ##### backward compatible methods #####

      def validate_link_exist(browser, link, logit = true, desc = '')
        exists?(browser, :link, :text, link, nil, desc)
      end

      def link_not_exist?(browser, link, desc = '')
        does_not_exist?(browser, :link, :text, link, nil, desc)
      end

      alias validate_link_not_exist link_not_exist?

      def validate_div_visible_by_id(browser, strg)
        visible?(browser, :div, :id, strg)
      end

      def validate_div_not_visible_by_id(browser, strg, desc = '')
        not_visible?(browser, :div, :id, strg, desc)
      end

    ##### end backward compatible methods #####


      def link_enabled?(browser, strg)
        #TODO Use enabled?()
        count = string_count_in_string(browser.text, strg)
        if count > 0
          if browser.link(:text, strg).enabled?
            if validate(browser, @myName, __LINE__)
              passed_to_log(strg + " is enabled. (#{__LINE__})")
              true
            end
          else
            failed_to_log(strg + " is not enabled.")
          end
        else
          failed_to_log("Link '#{strg.to_s}' (by :text) not found. Cannot validate if enabled. (#{__LINE__}) " + desc)
        end
      rescue
        failed_to_log("Unable to validate that link with :text '#{text}' is enabled: '#{$!}'. (#{__LINE__})")
        debug_to_log("#{strg} appears #{count} times in browser.text.")
      end

      alias validate_link_enabled link_enabled?

      def link_disabled?(browser, strg)
        #TODO use disabled?()
        count = string_count_in_string(browser.text, strg)
        if count > 0
          if browser.link(:text, strg).enabled?
            if validate(browser, @myName, __LINE__)
              failed_to_log(strg + " is enabled. (#{__LINE__})")
            end
          else
            passed_to_log(strg + " is not enabled.")
            true
          end
        else
          failed_to_log("Link '#{strg.to_s}' (by :text) not found. Cannot validate if disabled. (#{__LINE__}) " + desc)
        end
      rescue
        failed_to_log("Unable to validate that link with :text '#{text}' is enabled: '#{$!}'. (#{__LINE__})")
        debug_to_log("#{strg} appears #{count} times in browser.text.")
      end

      alias validate_link_not_enabled link_disabled?

      def popup_exists?(popup, message=nil)
        if not message
          message = "Popup: #{popup.title}"
        end
        if is_browser?(popup)
          passed_to_log("#{message}: found.")
          debug_to_log("\n"+popup.text+"\n")
          true
        else
          failed_to_log("#{message}: not found." + " (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to validate existence of popup: '#{$!}'. (#{__LINE__})")
      end

      alias popup_exist popup_exists?
      alias popup_exists popup_exists?
      alias popup_exist? popup_exists?
      alias iepopup_exist popup_exists?
      alias iepopup_exist? popup_exists?
      alias iepopup_exists popup_exists?
      alias iepopup_exists? popup_exists?

      def validate_drag_drop(err, tol, exp, act)
        ary = [false, "failed, expected: #{exp}, actual: #{act}, err: #{err}"]
        if err == 0
          ary = [true, 'succeeded ']
        elsif err.abs <= tol
          ary = [true, "within tolerance (+-#{tol}px) "]
        end
        ary
      end

      def validate_list(browser, listId, text, message)
        message_to_log("Method validate_list() is deprecated: use validate_list_by_xxx instead")
        validate_list_by_id(browser, listId, text, message)
      end

      #Validate select list contains text
      def validate_list_by_id(browser, strg, text, message, select_if_present=true)
        #TODO Use select_list_includes?() ?
        if browser.select_list(:id, strg).exists?
          select_list = browser.select_list(:id, strg)
          if select_list.include?(text)
            if select_if_present
              if select_option_by_id_and_option_text(browser, strg, text)
                if validate(browser, @myName, __LINE__)
                  passed_to_log(message)
                  true
                end
              else
                failed_to_log(message + " (#{__LINE__})")
              end
            else
              if validate(browser, @myName, __LINE__)
                passed_to_log(message)
                true
              end
            end
          else
            failed_to_log(message + "  Not found. (#{__LINE__})")
          end
        else
          failed_to_log("Select list with id='#{strg} not found. (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to validate selectlist with id='#{strg}: '#{$!}'. (#{__LINE__})")
      end

      #Validate select list contains text
      def validate_list_by_name(browser, strg, text, message, select_if_present=true)
        #TODO Use select_list_includes?() ?
        if browser.select_list(:name, strg).exists?
          select_list = browser.select_list(:name, strg)
          if select_list.include?(text)
            if select_if_present
              if select_option_by_name_and_option_text(browser, strg, text)
                if validate(browser, @myName, __LINE__)
                  passed_to_log(message)
                  true
                end
              else
                failed_to_log(message + " (#{__LINE__})")
              end
            else
              if validate(browser, @myName, __LINE__)
                passed_to_log(message)
                true
              end
            end
          else
            failed_to_log(message + "  Not found. (#{__LINE__})")
          end
        else
          failed_to_log("Select list with name='#{strg} not found. (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to validate that '#{text}' appeared in select list with name='#{strg}: '#{$!}'. (#{__LINE__})")
      end

      #Validate select list does not contain text
      def validate_no_list(browser, id, text, desc = '')
        select_list_does_not_include?(browser, :id, id, text, desc)
      end

      def validate_text(browser, ptrn, desc = '', skip_fail = false, skip_sleep = false)
        cls = browser.class.to_s
        cls.gsub!('Watir::', '')
        cls.gsub!('IE', 'Browser')
        msg = build_message("#{cls} text contains  '#{ptrn}'.", desc)
        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end
        sleep_for(2) unless skip_sleep
        myText = browser.text
        if not myText.match(target)
          sleep_for(2) unless skip_sleep #TODO try a wait_until here?
          myText = browser.text
        end
        if myText.match(target)
          #if myText.match(ptrn)
          if validate(browser, @myName, __LINE__)
            passed_to_log("#{msg}")
            true
          end
        else
          if skip_fail
            debug_to_log("#{cls}  text does not contain the text: '#{ptrn}'.  #{desc}")
          else
            failed_to_log("#{msg}")
          end
          #debug_to_log("\n#{myText}")
        end
      rescue
        failed_to_log("Unable to validate #{msg} '#{$!}'")
      end

      alias validate_link validate_text

      def text_in_element_equals?(browser, element, how, what, expected, desc = '')
        msg = "Expected exact text '#{expected}' in #{element} :#{how}=>#{what}."
        msg << " #{desc}" if desc.length > 0
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
        failed_to_log("Unable to verify #{msg} '#{$!}'")
      end

      def text_in_span_equals?(browser, how, what, expected, desc = '')
        text_in_element_equals?(browser, :span, how, what, expected, desc)
      end

      def element_contains_text?(browser, element, how, what, expected, desc = '')
        msg = "Element #{element} :{how}=>#{what} contains text '#{expected}'."
        msg << " #{desc}" if desc.length > 0
        who = browser.element(how, what)
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
        failed_to_log("Unable to verify #{msg} '#{$!}'")
      end

      def span_contains_text?(browser, how, what, expected, desc = '')
        element_contains_text?(browser, :span, how, what, expected, desc)
      end

      alias valid_text_in_span span_contains_text?

      def validate_text_in_span_by_id(browser, id, strg = '', desc = '')
        element_contains_text?(browser, :span, :id, id, strg, desc)
      end

      def validate_url(browser, url, message = '')
        if browser.url.to_s.match(url)
          if validate(browser, @myName, __LINE__)
            passed_to_log('Found "'+url.to_s+'" ' + message)
            true
          end
        else
          failed_to_log('Did not find "'+url.to_s+'" ' + message + " (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to validate that current url is '#{url}': '#{$!}'. (#{__LINE__})")
      end

      def validate_select_list(browser, how, what, opt_type, list = nil, multiple = false, ignore = ['Select One'], limit = 5)
        mark_testlevel("#{__method__.to_s.titleize} (#{how}=>#{what})", 2)
        ok          = true
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if list
          if options == list
            passed_to_log("Select list options list equals expected list #{list}")
          else
            debug_to_report("actual:\n#{nice_array(options, true)}")
            debug_to_report("expected:\n#{nice_array(list, true)}")
            failed_to_log("Select list options list #{nice_array(options, true)} "+
                              "does not equal expected list #{nice_array(list, true)}")
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
            if selected == targets
              passed_to_log("Select list selected options equals expected #{targets}")
            else
              failed_to_log("Select list selected options #{selected} does not equal expected list #{targets.to_a}")
            end
          else
            debug_to_log("Too few options to test multiple selection (need 2 or more): '#{options}", __LINE__)
          end
        end
      rescue
        failed_to_log("Unable to validate select_list: '#{$!}'", __LINE__)
      end

      def validate_select_list_contents(browser, how, what, list)
        mark_testlevel("#{__method__.to_s.titleize} (#{what})", 2)
        select_list = browser.select_list(how, what)
        options     = select_list.options
        if list
          if options == list
            passed_to_log("Select list options list equals expected list #{list}")
            options
          else
            failed_to_log("Select list options list #{options} does not equal expected list #{list}")
            nil
          end
        end
      rescue
        failed_to_log("Unable to validate select_list contents: '#{$!}'", __LINE__)
      end

      def validate_selected_options(browser, how, what, list, desc = '')
        select_list = browser.select_list(how, what)
        selected    = select_list.selected_options.sort
        if list.is_a?(Array)
          if selected == list.sort
            passed_to_log("Expected options [#{list.sort}] are selected [#{selected}]. #{desc}")
          else
            failed_to_log("Selected options [#{selected}] do not match expected [#{list.sort}]. #{desc}")
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
        failed_to_log("Unable to validate selected option(s): '#{$!}' #{desc}", __LINE__)
      end

      alias validate_selections validate_selected_options
      alias validate_select_list_selections validate_selected_options

      def string_contains?(strg, target, desc = '')
        msg = "String '#{strg}' contains '#{target}'."
        msg << " '#{desc}' " if desc.length > 0
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
        msg = "String '#{strg}' does not contain '#{target}'."
        msg << " '#{desc}' " if desc.length > 0
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
          if validate(browser, @myName, __LINE__)
            failed_to_log("#{msg} [#{browser_text.match(target)[0]}]")
          end
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}'")
      end

      def textfield_does_not_equal?(browser, how, what, expected, desc = '')
        msg = "Text field #{how}=>#{what} does not equal '#{expected}'"
        msg << " #{desc}" if desc.length > 0
        if not browser.text_field(how, what).value == expected
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to validate that #{msg}: '#{$!}'")
      end

      alias validate_textfield_not_value textfield_does_not_equal?

    ###################################
      def validate_textfield_not_value_by_name(browser, name, value, desc = '')
        textfield_does_not_equal?(browser, :name, name, value, desc)
      end

      alias validate_textfield_no_value_by_name validate_textfield_not_value_by_name

    ###################################
      def validate_textfield_not_value_by_id(browser, id, value, desc = '')
        textfield_does_not_equal?(browser, :id, id, value, desc)
      end

      alias validate_textfield_no_value_by_id validate_textfield_not_value_by_id

      def textfield_empty?(browser, how, what, desc = '')
        msg = "Text field #{how}=>#{what} is empty."
        msg << desc if desc.length > 0
        value = browser.text_field(how, what).value
        if value.to_s.length == 0
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} Contains '#{value}'")
        end
      rescue
        failed_to_log("Unable to validate #{msg}  '#{$!}'")
      end

      alias validate_textfield_empty textfield_empty?
      alias text_field_empty? textfield_empty?

      def validate_textfield_empty_by_name(browser, name, message = '')
        validate_textfield_empty(browser, :name, name, message)
      end

      def validate_textfield_empty_by_id(browser, id, message = '')
        validate_textfield_empty(browser, :id, id, message)
      end

      def validate_textfield_empty_by_title(browser, title, message = '')
        validate_textfield_empty(browser, :title, title, message)
      end

      def textfield_equals?(browser, how, what, expected, desc = '')
        msg    = "Expected '#{expected}' in textfield #{how}=>'#{what}'. #{desc}"
        actual = browser.text_field(how, what).value
        if actual.is_a?(Array)
          actual = actual[0].to_s
        end
        #debug_to_report("#{actual.inspect}")
        #debug_to_report("#{actual}")
        if actual == expected
          if validate(browser, @myName, __LINE__)
            passed_to_log("#{msg}")
            true
          end
        else
          act_s = actual.strip
          exp_s = expected.strip
          if act_s == exp_s
            if validate(browser, @myName, __LINE__)
              passed_to_log("#{msg} (stripped)")
              true
            end
          else
            debug_to_report(
                "#{__method__} (spaces underscored):\n "+
                    "expected:[#{expected.gsub(' ', '_')}] (#{expected.length})\n "+
                    "actual:[#{actual.gsub(' ', '_')}] (#{actual.length})"
            )
            failed_to_log("#{msg}. Found: '#{actual}'")
          end
        end
      rescue
        failed_to_log("Unable to validate #{msg}: '#{$!}")
      end

      alias validate_textfield_value textfield_equals?
      alias text_field_equals? textfield_equals?

      def validate_textfield_dollar_value(browser, how, what, expected, with_cents = true, desc = '')
        desc << " Dollar formatting"
        if with_cents
          expected << '.00' if not expected =~ /\.00$/
          desc << ' without cents.'
        else
          expected.gsub!(/\.00$/, '')
          desc << ' with cents.'
        end
        textfield_equals?(browser, how, what, expected, desc)
      end

      def validate_textfield_value_by_name(browser, name, expected, desc = '')
        textfield_equals?(browser, :name, name, expected, desc)
      end

      def validate_textfield_value_by_id(browser, id, expected, desc = '')
        textfield_equals?(browser, :id, id, expected, desc)
      end

      def validate_textfield_visible_by_name(browser, strg, desc = '')
        visible?(browser, :text_field, :name, strg, desc)
      end

      alias visible_textfield_by_name validate_textfield_visible_by_name

      def validate_textfield_disabled_by_name(browser, strg, desc = '')
        disabled?(browser, :text_field, :name, strg, desc)
      end

      alias disabled_textfield_by_name validate_textfield_disabled_by_name

      def validate_textfield_enabled_by_name(browser, strg, desc = '')
        enabled?(browser, :text_field, :name, strg, desc)
      end

      alias enabled_textfield_by_name validate_textfield_enabled_by_name

      def validate_textfield_not_visible_by_name(browser, strg, desc = '')
        not_visible?(browser, :text_field, :name, strg, desc)
      end

      alias visible_no_textfield_by_name validate_textfield_not_visible_by_name

      def validate_radio_not_set(browser, radio, message)
        if browser.radio(:id, radio).checked?
          if validate(browser, @myName, __LINE__)
            failed_to_log(message + " (#{__LINE__})")
          end
        else
          passed_to_log(message)
          true
        end
      rescue
        failed_to_log("Unable to validate that radio with id='#{radio} is clear': '#{$!}'. (#{__LINE__})")
      end

      alias validate_not_radioset validate_radio_not_set

      def radio_is_set?(browser, radio, message)
        if browser.radio(:id, radio).checked?
          if validate(browser, @myName, __LINE__)
            passed_to_log(message)
            true
          end
        else
          failed_to_log(message + " (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to validate that radio with id='#{radio} is clear': '#{$!}'. (#{__LINE__})")
      end

      alias validate_radioset radio_is_set?
      alias validate_radio_set radio_is_set?

      def validate_radioset_by_name(browser, radio, message)
        if browser.radio(:name, radio).checked?
          if validate(browser, @myName, __LINE__)
            passed_to_log(message)
            true
          end
        else
          failed_to_log(message + " (#{__LINE__})")
        end
      rescue
        failed_to_log("Unable to validate that radio with name='#{radio} is clear': '#{$!}'. (#{__LINE__})")
      end

      def checked_by_id?(browser, strg, desc = '')
        checked?(browser, :id, strg, desc)
      end

      alias validate_check checked_by_id?
      alias checkbox_is_checked? checked_by_id?

      def checkbox_is_enabled?(browser, strg, desc = '')
        enabled?(browser, :checkbox, :id, strg, desc)
      end

      alias validate_check_enabled checkbox_is_enabled?

      def checkbox_is_disabled?(browser, strg, desc = '')
        disabled?(browser, :checkbox, :id, strg, desc)
      end

      alias validate_check_disabled checkbox_is_disabled?

      def validate_check_by_class(browser, strg, desc)
        checked?(browser, :class, strg, desc)
      end

      def checkbox_not_checked?(browser, strg, desc)
        not_checked?(browser, :id, strg, desc)
      end

      alias validate_not_check checkbox_not_checked?

      def validate_image(browser, source, desc = '', nofail=false)
        if browser.image(:src, source).exists?
          if validate(browser, @myName, __LINE__)
            passed_to_log("Found '#{source}' image. #{desc}")
            true
          end
        else
          failed_to_log("Did not find '#{source}' image. #{desc} (#{__LINE__})") unless nofail
        end
      rescue
        failed_to_log("Unable to validate that '#{+source}' image appeared in page: '#{$!}'. (#{__LINE__})")
      end

      # @!group Deprecated
      # @deprecated
      def self.included(mod)
        # puts "RegressionSupport::Validations extended by #{mod}"
      end

      # @deprecated
      def validate_message(browser, message)
        if validate(browser, @myName, __LINE__)
          message_to_log(message)
        end
      end

      # @!endgroup Deprecated

    end
  end
end

