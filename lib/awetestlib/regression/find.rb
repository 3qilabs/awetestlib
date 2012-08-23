module Awetestlib
  module Regression
    module Find

      def get_select_list(browser, how, what, desc = '')
        list = browser.select_list(how, what)
        if validate(browser, @myName, __LINE__)
          passed_to_log("Select list #{how}='#{what}' found and returned.")
          return list
        end
      rescue
        failed_to_log("Unable to return select list #{how}='#{what}': '#{$!}' (#{__LINE__})")
      end

      def get_select_options(browser, how, what, dump = false)
        list = browser.select_list(how, what)
        dump_select_list_options(list) if dump
        list.options
      rescue
        failed_to_log("Unable to get select options for #{how}=>#{what}.  '#{$!}'")
      end

      def get_select_options_by_id(browser, strg, dump = false)
        get_select_options(browser, :id, strg, dump)
      end

      def get_select_options_by_name(browser, strg, dump = false)
        get_select_options(browser, :name, strg, dump)
      end

      def get_selected_options(browser, how, what)
        begin
          list = browser.select_list(how, what)
        rescue => e
          if not rescue_me(e, __method__, "browser.select_list(#{how}, '#{what}')", "#{browser.class}")
            raise e
          end
        end
        list.selected_options
      end

      def get_selected_options_by_id(browser, strg)
        get_selected_options(browser, :id, strg)
      end

      alias get_selected_option_by_id get_selected_options_by_id

      def get_selected_options_by_name(browser, strg)
        get_selected_options(browser, :name, strg)
      end

      alias get_selected_option_by_name get_selected_options_by_name

=begin rdoc
  :category: A_rdoc_test
Returns a reference to a division element.  Used to assign a div element to a variable
which can then be passed to methods that require a *browser* parameter.

_Parameters_::

*browser* - a reference to the browser window or container element to be tested

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  mainwindow = open_browser('www.myapp.com')  # open a browser to www.google.com
  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
  popup = attach_browser(mainwindow, :url, '[url of new window]') *or*
  popup = attach_browser(mainwindow, :title, '[title of new window]')

=end

      def get_div(browser, how, what, desc = '', dbg = false)
        msg = "Get division #{how}=>#{what}."
        msg << " #{desc}" if desc.length > 0
        Watir::Wait.until { browser.div(how, what).exists? }
        div = browser.div(how, what)
        debug_to_log(div.inspect) if dbg
        if validate(browser, @myName, __LINE__)
          if div
            passed_to_log(msg)
            return div
          else
            failed_to_log(msg)
          end
        end
      rescue
        failed_to_log("Unable to '#{msg}' '#{$!}'")
      end

      def get_div_by_id(browser, strg, desc = '', dbg = false)
        get_div(browser, :id, strg, desc, dbg)
      end

=begin rdoc
  :category: A_rdoc_test
Returns a reference to a division element identified by the value in its class attribute. Calls get_div()

_Parameters_::

*browser* - a reference to the browser window or container element to be tested

*strg* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  mainwindow = open_browser('www.myapp.com')  # open a browser to www.google.com
  click(mainwindow, :button, :id, 'an id string')  # click a button that opens another browser window
  popup = attach_browser(mainwindow, :url, '[url of new window]') *or*
  popup = attach_browser(mainwindow, :title, '[title of new window]')

=end

      def get_div_by_class(browser, strg, desc = '', dbg = false)
        get_div(browser, :class, strg, desc, dbg)
      end

      def get_div_by_text(browser, strg, desc = '', dbg = false)
        get_div(browser, :text, strg, desc, dbg)
      end

      def get_form(browser, how, strg)
        begin
          #       Watir::Wait.until( browser.form(how, strg).exists? )  # fails in wait_until
        rescue => e
          if not rescue_me(e, __method__, "browser.form(#{how}, '#{strg}').exists?", "#{browser.class}")
            raise e
          end
        end
        myForm = browser.form(how, strg)
        if validate(browser, @myName, __LINE__)
          passed_to_log("Form #{how}='#{strg}' found and returned.")
          return myForm
        end
      rescue
        failed_to_log("Unable to return form #{how}='#{strg}': '#{$!}' (#{__LINE__})")
      end

      def get_form_by_id(browser, strg)
        get_form(browser, :id, strg)
      end

      def get_frame(browser, how, strg, desc = '')
        #    begin
        #      Watir::Wait.until(browser.frame(how, strg).exists?) # fails in wait_until
        #    rescue => e
        #      if not rescue_me(e, __method__, "browser.frame(#{how}, '#{strg}').exists?", "#{browser.class}")
        #        raise e
        #      end
        #    end
        begin
          frame = browser.frame(how, strg)
        rescue => e
          if not rescue_me(e, __method__, "browser.frame(#{how}, '#{strg}').exists?", "#{browser.class}")
            raise e
          end
        end
        if validate(browser, @myName, __LINE__)
          passed_to_log("Frame #{how}='#{strg}' found and returned. #{desc}")
          return frame
        end
      rescue
        failed_to_log("Unable to return frame #{how}='#{strg}'. #{desc}: '#{$!}' (#{__LINE__})")
      end

      def get_frame_by_id(browser, strg, desc = '')
        get_frame(browser, :id, strg, desc)
      end

      def get_frame_by_index(browser, index, desc = '')
        get_frame(browser, :index, index, desc)
      end

      def get_frame_by_name(browser, strg, desc = '')
        get_frame(browser, :name, strg, desc)
      end

      def get_span(browser, how, strg, desc = '')
        begin
          #TODO: use LegacyExtensions#wait_until
          Watir::Wait.until { browser.span(how, strg).exists? }
        rescue => e
          if not rescue_me(e, __method__, "browser.span(#{how}, '#{strg}').exists?", "#{browser.class}")
            raise e
          end
        end
        begin
          span = browser.span(how, strg)
        rescue => e
          if not rescue_me(e, __method__, "browser.span(#{how}, '#{strg}').exists?", "#{browser.class}")
            raise e
          end
        end
        if validate(browser, @myName, __LINE__)
          passed_to_log("Span #{how}='#{strg}' found and returned. #{desc}")
          return span
        end
      rescue
        failed_to_log("Unable to return span #{how}='#{strg}'. #{desc}: '#{$!}' (#{__LINE__})")
      end

      def get_span_by_id(browser, strg, desc = '')
        get_span(browser, :id, strg, desc)
      end

=begin rdoc
  :category: A_rdoc_test
Returns a reference to a table element.  Used to assign a table element to a variable
which can then be used directly or passed to methods that require a *browser* or *table* parameter.

_Parameters_::

*browser* - a reference to the browser window or container element to be tested

*how* - the element attribute used to identify the specific element. Valid values depend on the kind of element.
Common values: :text, :id, :title, :name, :class, :href (:link only)

*what* - a string or a regular expression to be found in the *how* attribute that uniquely identifies the element.

*desc* - a string containing a message or description intended to appear in the log and/or report output

_Example_

  a_table = get_table(browser, :id, 'table1')
  a_table_cell = a_table[2][1]   # The cell in the first column of the second row of the table

=end

      def get_table(browser, how, what, desc = '')
        msg = "Return table :#{how}='#{what}'. #{desc}"
        tbl = browser.table(how, what)
        if validate(browser, @myName, __LINE__)
          passed_to_log(msg)
          tbl
        end
      rescue
        failed_to_log("#{msg}': '#{$!}'")
      end

      def get_table_by_id(browser, strg, desc = '')
        get_table(browser, :id, strg, desc)
      end

      def get_table_by_index(browser, idx)
        get_table(browser, :index, idx, desc)
      end

      def get_table_by_text(browser, strg)
        get_table(browser, :text, strg, desc)
      end

      def get_table_headers(table, header_index = 1)
        headers          = Hash.new
        headers['index'] = Hash.new
        headers['name']  = Hash.new
        count            = 1
        table[header_index].each do |cell|
          if cell.text.length > 0
            name                    = cell.text.gsub(/\s+/, ' ')
            headers['index'][count] = name
            headers['name'][name]   = count
          end
          count += 1
        end
        #debug_to_log("#{__method__}:****** headers:\n#{headers.to_yaml}")
        headers
      rescue
        failed_to_log("Unable to get content headers. '#{$!}'")
      end

      def get_element(browser, element, how, what, value = nil)
        target = nil
        what = Regexp.new(Regexp.escape(what)) unless how == :index or what.is_a?(Regexp)
        case element
          when :link
            target = browser.link(how, what)
          when :button
            target = browser.button(how, what)
          when :div
            target = browser.div(how, what)
          when :checkbox
            target = browser.checkbox(how, what, value)
          when :text_field, :textfield
            target = browser.text_field(how, what)
          when :image
            target = browser.image(how, what)
          when :file_field, :filefield
            target = browser.file_field(how, what)
          when :form
            target = browser.form(how, what)
          when :frame
            target = browser.frame(how, what)
          when :radio
            target = browser.radio(how, what, value)
          when :span
            target = browser.span(how, what)
          when :table
            target = browser.table(how, what)
          when :li
            target = browser.li(how, what)
          when :select_list, :selectlist
            target = browser.select_list(how, what)
          when :hidden
            target = browser.hidden(how, what)
          when :area
            target = browser.area(how, what)
        end
        if target.exists?
          target
        else
          nil
        end
      rescue => e
        if not rescue_me(e, __method__, "browser.#{element}(#{how}, '#{what}')", "#{browser.class}", target)
          raise e
        end
      end

      def get_objects(browser, which, dbg=false)
        cnt = 0
        case which
          when :links
            list = browser.links
            sleep(1)
          when :tables
            list = browser.tables
          when :divs
            list = browser.divs
          when :buttons
            list = browser.buttons
          when :checkboxes
            list = browser.checkboxes
          when :radios
            list = browser.radios
          when :selectlists
            list = browser.selectlists
          when :textfields
            list = browser.textfields
          when :lis
            list = browser.lis
          else
            debug_to_log("Unrecognized dom object '#{which}'")
        end
        if dbg
          list.each do |obj|
            cnt += 1
            debug_to_log("\n==========#{which}:\nindex:     #{cnt}\n#{obj}\n#{obj.to_yaml}")
          end
        end
        list
      end

      def get_ole(element)
        ole = element.ole_object
        if ole
          passed_to_log("Found ole_object for #{element}.")
          ole
        else
          failed_to_log("Did not find ole_object for #{element}.")
        end
      rescue
        failed_to_log("Unable to find ole_object for #{element}.  #{$!}")
      end

      def find_all_links_with_exact_href(browser, href)
        links = browser.links
        hash  = Hash.new
        idx   = 0
        links.each do |l|
          idx     += 1
          an_href = href
          my_href = l.href
          if my_href == an_href
            hash[idx] = l
            debug_to_log("#{__method__}:#{idx}\n********\n#{l.to_s}\n\n#{l.to_yaml}")
          end
        end
        hash
      end

      def find_link_with_exact_href(browser, href)
        links = browser.links
        link  = nil
        index = 0
        links.each do |l|
          index   += 1
          an_href = href
          my_href = l.href
          if my_href == an_href
            link = l
    #        debug_to_log("#{__method__}:#{__LINE__}\n********\n#{l.to_s}\n\n#{l.to_yaml}")
            break
          end
        end
        link
      end

      def find_index_for_object(browser, obj, how, ord, strg)
        obj_sym = (obj.to_s.pluralize).to_sym
        how_str = how.to_s
        ptrn    = /#{how}:\s+#{strg}/i
        list    = get_objects(browser, obj_sym, true)
        cnt     = 0
        idx     = 0
        list.each do |nty|
          s = nty.to_s
          #      a    = nty.to_a
          if s =~ ptrn
            cnt += 1
            if cnt == ord
              break
            end
          end
          idx += 1
        end
        idx
      end


    end
  end
end

