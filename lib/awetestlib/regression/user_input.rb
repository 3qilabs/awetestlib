module Awetestlib
  module Regression
    module UserInput

=begin rdoc
  :category: A_rdoc_test
Click a specific DOM element by one of its attributes and that attribute's value.

_Parameters_::

*browser* - a reference to the browser window or container element to be tested

*element* - the kind of element to click. Must be one of the elements recognized by Watir.
Some common values are :link, :button, :image, :div, :span.

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  # html for a link element:
  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
  click(browser, :link, :text, 'Pickaxe')

=end

      def click(browser, element, how, what, desc = '')
        #debug_to_log("#{__method__}: #{element}, #{how}, #{what}")
        msg = "Click #{element} :#{how}=>'#{what}'"
        msg << ", '#{desc}'" if desc.length > 0
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
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to #{msg}. '#{$!}'")
      end

=begin rdoc
  :category: A_rdoc_test
Click a specific DOM element by one of its attributes and that attribute's value and
do not wait for the browser to finish reloading.  Used when a modal popup or alert is expected. Allows the script
to keep running so the popup can be handled.

_Parameters_::

*browser* - a reference to the browser window to be tested

*element* - the kind of element to click. Must be one of the elements recognized by Watir.
Some common values are :link, :button, :image, :div, :span.

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  # html for a link element:
  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
  click_no_wait(browser, :link, :text, 'Pickaxe')

=end

      def click_no_wait(browser, element, how, what, desc = '')
        debug_to_log("#{__method__}: #{element}, #{how}, #{what}")
        msg = "Click no wait #{element} :#{how}=>'#{what}'"
        msg << ", '#{desc}'" if desc.length > 0
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
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to #{msg}  '#{$!}'")
        sleep_for(1)
      end

    # :category: User Input
      def click_button_by_id(browser, strg, desc = '')
        click(browser, :button, :id, strg, desc)
      end

    # :category: User Input
      def click_link_by_index(browser, strg, desc = '')
        click(browser, :link, :index, strg, desc)
      end

    # :category: User Input
      def click_link_by_href(browser, strg, desc = '')
        click(browser, :link, :href, strg, desc)
      end

      alias click_href click_link_by_href
    # :category: User Input
      def click_link_no_wait_by_href(browser, strg, desc = '')
        click_no_wait(browser, :link, :href, strg, desc)
      end

      alias click_href_no_wait click_link_no_wait_by_href
    # :category: User Input
      def click_button_by_index(browser, index, desc = '')
        click(browser, :button, :index, index, desc)
      end

    # :category: User Input
      def click_button_by_name(browser, strg, desc = '')
        click(browser, :button, :name, strg, desc)
      end

    # :category: User Input
      def click_button_by_text(browser, strg, desc = '')
        click(browser, :button, :text, strg, desc)
      end

    # :category: User Input
      def click_button_by_class(browser, strg, desc = '')
        click(browser, :button, :class, strg, desc)
      end

    # :category: User Input
      def click_button_no_wait_by_id(browser, strg, desc = '')
        click_no_wait(browser, :button, :id, strg, desc)
      end

      alias click_button_by_id_no_wait click_button_no_wait_by_id
    # :category: User Input
      def click_button_no_wait_by_name(browser, strg, desc = '')
        click_no_wait(browser, :button, :name, strg, desc)
      end

    # :category: User Input
      def click_button_no_wait_by_class(browser, strg, desc = '')
        click_no_wait(browser, :button, :class, strg, desc)
      end

      alias click_button_by_class_no_wait click_button_no_wait_by_class
    # :category: User Input
      def click_button_by_value(browser, strg, desc = '')
        click(browser, :button, :value, strg, desc)
      end

    # :category: User Input
      def click_button_by_title(browser, strg, desc = '')
        click(browser, :button, :title, strg, desc)
      end

    # :category: User Input
      def click_button_by_xpath_and_id(browser, strg, desc = '')
        msg = "Click button by xpath and id '#{strg}' #{desc}"
        if browser.button(:xpath, "//a[@id = '#{strg}']").click
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to click button by xpath and id '#{strg}' #{desc} '#{$!}' (#{__LINE__})")
      end

      alias click_button_by_xpath click_button_by_xpath_and_id

=begin rdoc
  :category: A_rdoc_test
Click a link identified by the value in its id attribute.  Calls click()

_Parameters_::

*browser* - a reference to the browser window to be tested

*strg* - a string or a regular expression to be found in the id  attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output


_Example_

  # html for a link element:
  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
  click_link_by_text(browser, 'Pickaxe', 'Open the page for the Pickaxe book')

=end

      def click_link_by_id(browser, strg, desc = '')
        click(browser, :link, :id, strg, desc)
      end

    # :category: A_rdoc_test
      alias click_id click_link_by_id

    # :category: User Input
      def click_link_by_name(browser, strg, desc = '')
        click(browser, :link, :name, strg, desc)
      end

      alias click_name click_link_by_name
    # :category: User Input
      def click_link_by_xpath_and_id(browser, strg, desc = '')
        msg = "Click link by xpath and id '#{strg}' #{desc}"
        if browser.link(:xpath, "//a[@id = '#{strg}']").click
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable click on link by xpath and id '#{strg}' #{desc} '#{$!}' (#{__LINE__})")
      end

      alias click_link_by_xpath click_link_by_xpath_and_id

    # :category: User Input
      def click_link_no_wait_by_id(browser, strg, desc = '')
        click_no_wait(browser, :link, :id, strg, desc)
      end

      alias click_no_wait_id click_link_no_wait_by_id
      alias click_no_wait_by_id click_link_no_wait_by_id
      alias click_id_no_wait click_link_no_wait_by_id
      alias click_no_wait_link_by_id click_link_no_wait_by_id

    # :category: User Input
      def click_file_field_by_id(browser, strg, desc = '')
        click(browser, :file_field, :id, strg, desc)
      end

    # :category: User Input
      def click_img_by_alt(browser, strg, desc = '')
        click(browser, :image, :alt, strg, desc)
      end

    # :category: User Input
      def click_img_by_title(browser, strg, desc = '')
        click(browser, :image, :title, strg, desc)
      end

    # :category: User Input
      def click_img_by_xpath_and_name(browser, strg, desc = '')
        msg = "Click image by xpath where name='#{strg}' #{desc}"
        if browser.link(:xpath, "//input[@name = '#{strg}']").click
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to click image by xpath where name='#{strg}' #{desc} '#{$!}'")
      end

      alias click_img_by_xpath click_img_by_xpath_and_name
      alias click_image_by_xpath click_img_by_xpath_and_name
      alias click_image_by_xpath_and_name click_img_by_xpath_and_name

    # :category: User Input
      def click_img_no_wait_by_alt(browser, strg, desc = '')
        click_no_wait(browser, :image, :alt, strg, desc)
      end

      alias click_img_by_alt_no_wait click_img_no_wait_by_alt
    # :category: User Input
      def click_img_by_src(browser, strg, desc = '')
        click(browser, :image, :src, strg, desc)
      end

    # :category: User Input
      def click_img_by_src_and_index(browser, strg, index, desc = '')
        msg = "Click image by src='#{strg}' and index=#{index}"
        msg << " #{desc}" if desc.length > 0
        browser.image(:src => strg, :index => index).click
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

    # :category: User Input
      def click_link_by_value(browser, strg, desc = '')
        click(browser, :link, :value, strg, desc)
      end

=begin rdoc
  :category: A_rdoc_test
Click a link identified by the value in its text attribute.  Calls click()

_Parameters_::

*browser* - a reference to the browser window to be tested

*strg* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output


_Example_

  # html for a link element:
  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
  click_link_by_text(browser, 'Pickaxe', 'Open the page for the Pickaxe book')

=end

      def click_link_by_text(browser, strg, desc = '')
        click(browser, :link, :text, strg, desc)
      end

      alias click_link click_link_by_text
    # :category: A_rdoc_test
      alias click_text click_link_by_text
      alias click_js_button click_link_by_text

    # :category: User Input
      def click_link_by_class(browser, strg, desc = '')
        click(browser, :link, :class, strg, desc)
      end

      alias click_class click_link_by_class

    # :category: User Input
      def click_button_no_wait_by_text(browser, strg, desc = '')
        click_no_wait(browser, :button, :text, strg, desc)
      end

    # :category: User Input
      def click_button_no_wait_by_value(browser, strg, desc = '')
        click_no_wait(browser, :button, :value, strg, desc)
      end

    # :category: User Input
      def click_link_by_name_no_wait(browser, strg, desc = '')
        click_no_wait(browser, :link, :name, strg, desc)
      end

      alias click_no_wait_name click_link_by_name_no_wait
      alias click_name_no_wait click_link_by_name_no_wait

    # :category: User Input
      def click_link_by_text_no_wait(browser, strg, desc = '')
        click_no_wait(browser, :link, :text, strg, desc)
      end

      alias click_no_wait_text click_link_by_text_no_wait
      alias click_text_no_wait click_link_by_text_no_wait

    # :category: User Input
      def click_span_by_text(browser, strg, desc = '')
        if not desc and not strg.match(/Save|Open|Close|Submit|Cancel/)
          desc = 'to navigate to selection'
        end
        msg = "Click span containing text '#{strg}'."
        msg << " #{desc}" if desc.length > 0
        if validate(browser, @myName, __LINE__)
          passed_to_log("#{msg}")
        end
      rescue
        failed_to_log("Unable to #{msg}: '#{$!}'")
      end

    # TODO no logging yet.  slow.# :category: User Input
      def click_span_with_text(browser, trgt, desc = '')
        msg = "Find and click span containing text '#{trgt}'."
        msg << " #{desc}" if desc.length > 0
        spans = browser.spans
        x     = 0
        spans.each do |span|
          x += 1
          debug_to_log("Span #{x}: #{span.text}")
          aText = span.text
          if aText and aText.size > 0
            if aText =~ /#{trgt}/
              break
            end
          end
        end
        spans[x].click
      end

    # :category: User Input
      def click_link_by_title(browser, strg, desc = '')
        click(browser, :link, :title, strg, desc)
      end

      alias click_title click_link_by_title
    # :category: User Input
      def click_title_no_wait(browser, strg, desc = '')
        click_no_wait(browser, :link, :title, strg, desc)
      end

    # :category: User Input
      def click_table_row_with_text_by_id(browser, ptrn, strg, column = nil)
        msg   = "id=#{ptrn} row with text='#{strg}"
        table = get_table_by_id(browser, /#{ptrn}/)
        if table
          index = get_index_of_row_with_text(table, strg, column)
          if index
            table[index].click
            if validate(browser, @myName, __LINE__)
              passed_to_log("Click #{msg} row index=#{index}.")
              index
            end
          else
            failed_to_log("Table #{msg} not found to click.")
          end
        else
          failed_to_log("Table id=#{ptrn} not found.")
        end
      rescue
        failed_to_log("Unable to click table #{msg}: '#{$!}' (#{__LINE__}) ")
      end

    # :category: User Input
      def click_table_row_with_text_by_index(browser, idx, strg, column = nil)
        msg   = "index=#{idx} row with text='#{strg}"
        table = get_table_by_index(browser, idx)
        if table
          index = get_index_of_row_with_text(table, strg, column)
          if index
            table[index].click
            if validate(browser, @myName, __LINE__)
              passed_to_log("Click #{msg} row index=#{index}.")
              index
            end
          else
            failed_to_log("Table #{msg} not found to click.")
          end
        else
          failed_to_log("Table id=#{ptrn} not found.")
        end
      rescue
        failed_to_log("Unable to click table #{msg}: '#{$!}' (#{__LINE__}) ")
      end

      def double_click_table_row_with_text_by_id(browser, ptrn, strg, column = nil)
        msg   = "id=#{ptrn} row with text='#{strg}"
        table = get_table_by_id(browser, /#{ptrn}/)
        if table
          index = get_index_of_row_with_text(table, strg, column)
          if index
            table[index].fire_event('ondblclick')
            if validate(browser, @myName, __LINE__)
              passed_to_log("Double click #{msg} row index=#{index}.")
              index
            end
          else
            failed_to_log("Table #{msg} not found to double click.")
          end
        else
          failed_to_log("Table id=#{ptrn} not found.")
        end
      rescue
        failed_to_log("Unable to double click table #{msg}: '#{$!}' (#{__LINE__}) ")
      end

      def double_click_table_row_with_text_by_index(browser, idx, strg, column = nil)
        msg   = "index=#{idx} row with text='#{strg}"
        table = get_table_by_index(browser, idx)
        if table
          index = get_index_of_row_with_text(table, strg, column)
          if index
            row = table[index]
            table[index].fire_event('ondblclick')
            row.fire_event('ondblclick')
            if validate(browser, @myName, __LINE__)
              passed_to_log("Double click #{msg} row index=#{index}.")
              index
            end
          else
            failed_to_log("Table #{msg} not found to double click.")
          end
        else
          failed_to_log("Table id=#{ptrn} not found.")
        end
      rescue
        failed_to_log("Unable to double click table #{msg}: '#{$!}' (#{__LINE__}) ")
      end

      def click_popup_button(title, button, waitTime= 9, user_input=nil)
        #TODO: is winclicker still viable/available?
        wc = WinClicker.new
        if wc.clickWindowsButton(title, button, waitTime)
          passed_to_log("Window '#{title}' button '#{button}' found and clicked.")
          true
        else
          failed_to_log("Window '#{title}' button '#{button}' not found. (#{__LINE__})")
        end
        wc = nil
        # get a handle if one exists
        #    hwnd = $ie.enabled_popup(waitTime)
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

      def select_option(browser, how, what, which, value, desc = '')
        msg  = "Select option #{which}='#{value}' from list #{how}=#{what}. #{desc}"
        list = browser.select_list(how, what)
        case which
          when :text
            list.select(value)
          when :value
            list.select_value(value)
          when :index
            all = list.getAllContents
            txt = all[value]
            list.select(txt)
          else
            na = "#{__method__} cannot support select by '#{which}'. (#{msg})"
            debug_to_log(na, __LINE__, true)
            raise na
        end
        passed_to_log(msg)
      rescue
        failed_to_log("#Unable to #{msg}': '#{$!}'")
      end

      def select_option_from_list(list, what, what_strg, desc = '')
        ok  = true
        msg = "#{__method__.to_s.titleize} "
        if list
          msg << "list id=#{list.id}: "
          case what
            when :text
              list.select(what_strg) #TODO: regex?
            when :value
              list.select_value(what_strg) #TODO: regex?
            when :index
              list.select(list.getAllContents[what_strg.to_i])
            else
              msg << "select by #{what} not supported. #{desc} (#{__LINE__})"
              failed_to_log(msg)
              ok = false
          end
          if ok
            msg << "#{what}='#{what_strg}' selected. #{desc}"
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{__method__.to_s.titleize} list not found. #{desc} (#{__LINE__})")
        end
      rescue
        failed_to_log("#{__method__.to_s.titleize}: #{what}='#{what_strg}' could not be selected: '#{$!}'. #{desc} (#{__LINE__})")
      end

=begin rdoc
  :category: A_rdoc_test
Select an option from a specific drop down list.  The drop down (select list) is id

_Parameters_::

*browser* - a reference to the browser window to be tested

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  # html for a link element:
  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
  click_no_wait(browser, :link, :text, 'Pickaxe')

=end

      def select_option_by_id_and_option_text(browser, strg, option, nofail=false, desc = '')
        msg = "Select list id=#{strg} option text='#{option}' selected."
        msg << " #{desc}" if desc.length > 0
        list = browser.select_list(:id, strg)
        list.select(option)
        #      browser.select_list(:id, strg).select(option)   #(browser.select_list(:id, strg).getAllContents[option])
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        if !nofail
          failed_to_log("#{msg} '#{$!}'")
        end
      end

      alias select_option_by_id select_option_by_id_and_option_text
      alias select_option_by_id_and_text select_option_by_id_and_option_text

      def select_option_by_name_and_option_text(browser, strg, option, desc = '')
        msg = "Select list name=#{strg} option text='#{option}' selected."
        msg << " #{desc}" if desc.length > 0
        begin
          list = browser.select_list(:name, strg)
        rescue => e
          if not rescue_me(e, __method__, "#{__LINE__}: select_list(:name,'#{strg}')", "#{browser.class}")
            raise e
          end
        end
        begin
          list.select(option)
        rescue => e
          if not rescue_me(e, __method__, "#{__LINE__}: select_list#select('#{option}')", "#{browser.class}")
            raise e
          end
        end
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      alias select_option_by_name select_option_by_name_and_option_text

      def select_option_by_title_and_option_text(browser, strg, option, desc = '')
        msg = "Select list name=#{strg} option text='#{option}' selected."
        msg << " #{desc}" if desc.length > 0
        browser.select_list(:title, strg).select(option)
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def select_option_by_class_and_option_text(browser, strg, option, desc = '')
        msg = "Select list class=#{strg} option text='#{option}' selected."
        msg << " #{desc}" if desc.length > 0
        browser.select_list(:class, strg).select(option)
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def select_option_by_name_and_option_value(browser, strg, option, desc = '')
        msg = "Select list name=#{strg} option value='#{option}' selected."
        msg << " #{desc}" if desc.length > 0
        begin
          list = browser.select_list(:name, strg)
        rescue => e
          if not rescue_me(e, __method__, "#{__LINE__}: select_list(:name,'#{strg}')", "#{browser.class}")
            raise e
          end
        end
        begin
          list.select_value(option)
        rescue => e
          if not rescue_me(e, __method__, "#{__LINE__}: select_list#select_value('#{option}')", "#{browser.class}")
            raise e
          end
        end
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def select_option_by_id_and_option_value(browser, strg, option, desc = '')
        msg = "Select list name=#{strg} option value='#{option}' selected."
        msg << " #{desc}" if desc.length > 0
        begin
          list = browser.select_list(:id, strg)
        rescue => e
          if not rescue_me(e, __method__, "#{__LINE__}: select_list(:text,'#{strg}')", "#{browser.class}")
            raise e
          end
        end
        sleep(0.5) unless @targetBrowser.abbrev == 'IE'
        begin
          list.select_value(option)
        rescue => e
          if not rescue_me(e, __method__, "#{__LINE__}: select_list#select_value('#{option}')", "#{browser.class}")
            raise e
          end
        end
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def select_option_by_id_and_index(browser, strg, idx, desc = '')
        msg = "Select list id=#{strg} index='#{idx}' selected."
        msg << " #{desc}" if desc.length > 0
        list = browser.select_list(:id, strg)
        all  = list.getAllContents
        txt  = all[idx]
        browser.select_list(:id, strg).set(browser.select_list(:id, strg).getAllContents[idx])
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def select_option_by_name_and_index(browser, strg, idx)
      # TODO add check that both list and option exist
        msg = "Select list name=#{strg} index='#{idx}' selected."
        msg << " #{desc}" if desc.length > 0
        browser.select_list(:name, strg).set(browser.select_list(:name, strg).getAllContents[idx])
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def select_option_by_xpath_and_index(browser, strg, idx)
        msg = "Select list xpath=#{strg} index='#{idx}' selected."
        msg << " #{desc}" if desc.length > 0
        browser.select_list(:xpath, strg).set(browser.select_list(:xpath, strg).getAllContents[idx])
        if validate(browser, nil, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

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
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def set_checkbox(browser, how, what, value, desc = '')
        set(browser, :checkbox, how, what, value, desc)
      end

      def set_checkbox_by_class(browser, strg, value = nil, desc = '')
        set(browser, :checkbox, :class, strg, value, desc)
      end

      def set_checkbox_by_id(browser, strg, value = nil, desc = '')
        set(browser, :checkbox, :id, strg, value, desc)
      end

      def set_checkbox_by_name(browser, strg, value = nil, desc = '')
        set(browser, :checkbox, :name, strg, value, desc)
      end

      def set_checkbox_by_title(browser, strg, value = nil, desc = '')
        set(browser, :checkbox, :title, strg, value, desc)
      end

      def set_checkbox_by_value(browser, strg, desc = '')
        set(browser, :checkbox, :value, strg, nil, desc)
      end

      def set_radio(browser, how, what, value = nil, desc = '')
        set(browser, :radio, how, what, value, desc)
      end

      def set_radio_two_attributes(browser, how1, what1, how2, what2, desc = '')
        msg = "Set radio #{how1}='#{what1}', #{how2}= #{what2}"
        msg << " '#{desc}' " if desc.length > 0
        browser.radio(how1 => what1, how2 => what2).set
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def set_radio_by_class(browser, strg, value = nil, desc = '')
        set(browser, :radio, :class, strg, value, desc)
      end

      def set_radio_by_id(browser, strg, value = nil, desc = '')
        set(browser, :radio, :id, strg, value, desc)
      end

      def set_radio_by_index(browser, index, desc = '')
        set(browser, :radio, :index, index, value, desc)
      end

      def set_radio_by_name(browser, strg, value = nil, desc = '')
        set(browser, :radio, :name, strg, value, desc)
      end

      def set_radio_by_title(browser, strg, value = nil, desc = '')
        set(browser, :radio, :title, strg, value, desc)
      end

      def set_radio_by_value(browser, strg, desc = '')
        set(browser, :radio, :value, strg, nil, desc)
      end

      def set_radio_no_wait_by_index(browser, index, desc = '')
        #TODO: Not supported by Watir 1.8.x
        msg    = "Radio :index=#{index} "
        radios = browser.radios
        debug_to_log("\n#{radios}")
        radio = radios[index]
        debug_to_log("\n#{radio}")
        radio.click_no_wait
        if validate(browser)
          msg << 'set ' + desc
          passed_to_log(msg)
          true
        end
      rescue
        msg << 'not found ' + desc
        failed_to_log("#{msg} (#{__LINE__})")
      end

      def set_radio_by_name_and_index(browser, name, index, desc = '')
        set_radio_two_attributes(browser, :name, name, :index, index, desc)
      end

      def set_radio_by_name_and_text(browser, name, text, desc = '')
        set_radio_two_attributes(browser, :name, name, :text, text, desc)
      end

      def set_radio_by_value_and_index(browser, value, index, desc = '')
        set_radio_two_attributes(browser, :value, value, :index, index, desc)
      end

      def set_radio_by_name_and_value(browser, strg, value, desc = '')
        set_radio(browser, :name, strg, value, desc)
      end

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
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def clear_checkbox(browser, how, what, value = nil, desc = '')
        clear(browser, :checkbox, how, what, value, desc)
      end

      def clear_checkbox_by_name(browser, strg, value = nil, desc = '')
        clear(browser, :checkbox, :name, strg, value, desc)
      end

      def clear_checkbox_by_id(browser, strg, value = nil, desc = '')
        clear(browser, :checkbox, :id, strg, value, desc)
      end

      def clear_radio(browser, how, what, value = nil, desc = '')
        clear(browser, :radio, how, what, value, desc)
      end

    # Set skip_value_check = true when string is altered by application and/or
    # this method will be followed by validate_text
      def clear_textfield(browser, how, which, skip_value_check = false)
        if browser.text_field(how, which).exists?
          tf = browser.text_field(how, which)
          if validate(browser, @myName, __LINE__)
            tf.clear
            if validate(browser, @myName, __LINE__)
              if tf.value == ''
                passed_to_log("Textfield #{how}='#{which}' cleared.")
                true
              elsif skip_value_check
                passed_to_log("Textfield  #{how}='#{which}' cleared. (skip value check)")
                true
              else
                failed_to_log("Textfield  #{how}='#{which}' not cleared: Found:'#{tf.value}'. (#{__LINE__})")
              end
            end
          end
        else
          failed_to_log("Textfield id='#{id}' to clear. (#{__LINE__})")
        end
      rescue
        failed_to_log("Textfield id='#{id}' could not be cleared: '#{$!}'. (#{__LINE__})")
      end

      def set_file_field(browser, how, what, filespec, desc = '')
        msg = "Set file field #{how}=>#{what} to '#{filespec}."
        msg << " #{desc}" if desc.length > 0
        ff = browser.file_field(how, what)
        if ff
          ff.set filespec
          sleep_for(8)
          if validate(browser, @myName, __LINE__)
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} File field not found.")
        end
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      def set_file_field_by_name(browser, strg, path, desc = '')
        set_file_field(browser, :name, strg, path, desc)
      end

      def set_file_field_by_id(browser, strg, path, desc = '')
        set_file_field(browser, :id, strg, path, desc)
      end

=begin rdoc
  :category: A_rdoc_test
Enter a string into a text field element identified by an attribute type and a value.
After the entry the value in the text field is validated against the input value unless the *skip_value_check*
parameter is set to true

_Parameters_::

*browser* - a reference to the browser window to be tested

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*value* - a string to be entered in the text field

*desc* - a string containing a message or description intended to appear in the log and/or report output

*skip_value_check* (Optional, default is false). Set to true to prevent the built-in verification
that the text field actually contains the value entered.  Useful when application reformats
or otherwise edits the input string.

_Example_

  set_text_field(browser, :name, /thisTextfield/, 'The text to enter')

=end

      def set_text_field(browser, how, what, value, desc = '', skip_value_check = false)
        #TODO: fix this to handle Safari password field
        msg = "Set textfield #{how}='#{what}' to '#{value}'"
        msg << " #{desc}" if desc.length > 0
        msg << " (Skip value check)" if skip_value_check
        if browser.text_field(how, what).exists?
          tf = browser.text_field(how, what)
          debug_to_log("#{tf.inspect}")
          if validate(browser, @myName, __LINE__)
            tf.set(value)
            if validate(browser, @myName, __LINE__)
              if tf.value == value
                passed_to_log(msg)
                true
              elsif skip_value_check
                passed_to_log(msg)
                true
              else
                failed_to_log("#{msg}: Found:'#{tf.value}'.")
              end
            end
          end
        else
          failed_to_log("Textfield #{how}='#{what}' not found to set to '#{value}''")
        end
      rescue
        failed_to_log("Unable to '#{msg}': '#{$!}'")
      end

      alias set_textfield set_text_field

      def set_textfield_by_name(browser, name, value, desc = '', skip_value_check = false)
        if browser.text_field(:name, name).exists?
          tf = browser.text_field(:name, name)
          # Workaround because browser.text_field doesn't work for password fields in Safari
        elsif @browserAbbrev.eql?("S")
          tf = browser.password(:name, name)
        end
        if tf.exists?
          if validate(browser, @myName, __LINE__)
            tf.set(value)
            if validate(browser, @myName, __LINE__)
              if tf.value == value
                passed_to_log("Set textfield name='#{name}' to '#{value}' #{desc}")
                true
              elsif skip_value_check
                passed_to_log("Set textfield name='#{name}' to '#{value}' #{desc} (skip value check)")
                true
              else
                failed_to_log("Set textfield name='#{name}' to '#{value}': Found:'#{tf.value}'.  #{desc} (#{__LINE__})")
              end
            end
          end
        else
          failed_to_log("Textfield name='#{name}' not found to set to '#{value}'.  #{desc} (#{__LINE__})")
        end
      rescue
        failed_to_log("Textfield name='#{name}' could not be set to '#{value}': '#{$!}'. #{desc} (#{__LINE__})")
      end

=begin rdoc
  :category: A_rdoc_test
Enter a string into a text field element identified by the value in its id attribute.

_Parameters_::

*browser* - a reference to the browser window to be tested

*id* - a string or a regular expression to be found in the id attribute that uniquely identifies the element.

*value* - a string to be entered in the text field

*desc* - a string containing a message or description intended to appear in the log and/or report output

*skip_value_check* (Optional, default is false). Set to true to prevent the built-in verification
that the text field actually contains the value entered.  Useful when application reformats
or otherwise edits the input string.

_Example_

  set_text_field_by_id(browser, /thisTextfield/, 'The text to enter')

=end

      def set_textfield_by_id(browser, id, value, desc = '', skip_value_check = false)
        set_text_field(browser, :id, id, value, desc, skip_value_check)
      end

      def set_textfield_by_title(browser, title, value, desc = '', skip_value_check = false)
        set_text_field(browser, :title, title, value, desc, skip_value_check)
      end

      def set_textfield_by_class(browser, strg, value, desc = '', skip_value_check = false)
        set_text_field(browser, :class, strg, value, desc, skip_value_check)
      end

=begin rdoc
  :category: A_rdoc_test
Enter a string into a text field element identified by an attribute type and a value.
After the entry the value in the text field is validated against the *valid_value*. Use when the application reformats
or performs edits on the input value.

_Parameters_::

*browser* - a reference to the browser window to be tested

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*value* - a string to be entered in the text field

*desc* - a string containing a message or description intended to appear in the log and/or report output

*valid_value* (Optional, default is nil). Set to the expected value

_Example_

  set_text_field_and_validate(browser, :id, /AmountTendered/, '7500', 'Dollar formatting', '$7,500.00')

=end

      def set_text_field_and_validate(browser, how, what, value, desc = '', valid_value = nil)
        #NOTE: use when value and valid_value differ as with dollar reformatting
        if set_text_field(browser, how, what, value, desc, true)
          expected = valid_value ? valid_value : value
          validate_textfield_value(browser, how, what, expected)
        end
      rescue
        failed_to_log("Unable to '#{msg}': '#{$!}'")
      end

=begin rdoc
  :category: A_rdoc_test
Allows a generic way to fire browser or javascript events on page elements.
Raises UnknownObjectException if the object is not found or ObjectDisabledException if the object is currently disabled.
_Parameters_::

*browser* - a reference to the browser window to be tested

*element* - the kind of element to click. Must be one of the elements recognized by Watir.
Some common values are :link, :button, :image, :div, :span.

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*event* - a string indicating the event to be triggered, e.g., 'onMouseOver', 'onClick', and etc.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  # html for a link element:
  # <a href="http://pragmaticprogrammer.com/titles/ruby/" id="one" name="book">Pickaxe</a>
  fire_event(browser, :link, :text, 'Pickaxe', 'onMouseOver')

=end

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
        if validate(browser, @myName, __LINE__)
          passed_to_log("Fire event: #{msg}. #{desc}")
          true
        end
      rescue
        failed_to_log("Unable to fire event: #{msg}. '#{$!}' #{desc}")
      end

      def fire_event_on_link_by_text(browser, strg, event = 'onclick', desc = '')
        fire_event(browser, :link, :text, strg, event, desc)
      end

      alias fire_event_text fire_event_on_link_by_text
      alias fire_event_by_text fire_event_on_link_by_text

      def fire_event_on_link_by_id(browser, strg, event = 'onclick', desc = '')
        fire_event(browser, :link, :id, strg, event, desc)
      end

      alias fire_event_id fire_event_on_link_by_id
      alias fire_event_by_id fire_event_on_link_by_id

      def fire_event_on_image_by_src(browser, strg, event = 'onclick', desc = '')
        fire_event(browser, :img, :src, strg, event, desc)
      end

      alias fire_event_src fire_event_on_image_by_src
      alias fire_event_image_by_src fire_event_on_image_by_src


    end
  end
end

