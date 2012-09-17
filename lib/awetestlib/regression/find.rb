module Awetestlib
  module Regression
    module Find

      # @!group Core

      # Return a reference to a DOM element specified by its type +element+, attribute *how*, and the
      # contents of that attribute *what*.  Some elements may require use of the :value attribute in addition
      # to the designated one.  The target contents for :value are supplied in +value+.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the :value attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      def get_element(browser, element, how, what, value = nil, desc = '')
        msg    = build_message("Return #{element} with :#{how}=#{what}", value, desc)
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
          else
            target = browser.element(how, what)
        end
        if target.exists?
          passed_to_log(msg)
          target
        else
          failed_to_log(msg)
          nil
        end
      rescue => e
        if not rescue_me(e, __method__, "browser.#{element}(#{how}, '#{what}')", "#{browser.class}", target)
          raise e
        end
      end

      # Return an array containing the options available for selection in a select_list identifified by
      # its attribute *how*, and the contents of that attribute *what*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute
      # that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] dump If set to true, a dump of the contents of the options will go to the log.
      # See Utilities#dump_select_list_options
      def get_select_options(browser, how, what, dump = false)
        list = browser.select_list(how, what)
        dump_select_list_options(list) if dump
        list.options
      rescue
        failed_to_log("Unable to get select options for #{how}=>#{what}.  '#{$!}'")
      end

      # Return an array containing the _selected_ options in a select_list identified by
      # its attribute *how*, and the contents of that attribute *what*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute
      # that uniquely identifies the element.
      def get_selected_options(browser, how, what)
        begin
          list = browser.select_list(how, what)
        rescue => e
          if not rescue_me(e, __method__, "browser.select_list(#{how}, '#{what}')", "#{browser.class}")
            raise e
          end
        end
        list.selected_options if list
      end

      # Return a reference to a div element identified by the contents *what* of its attribute *how*.
      # This differs from get_element in that it waits for the element to exist before trying to return it.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute
      # that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @param [Boolean] dbg If set to true additional debug logging is performed.
      # @return [Watir::Div]
      def get_div(browser, how, what, desc = '', dbg = false)
        msg = build_message("Get :div #{how}=>#{what}.", desc)
        Watir::Wait.until { browser.div(how, what).exists? }
        div = browser.div(how, what)
        debug_to_log(div.inspect) if dbg
        if div
          passed_to_log(msg)
          return div
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log("Unable to '#{msg}' '#{$!}'")
      end

      # Return a reference to a _span_ element identified by the contents *what* of its attribute *how*.
      # This differs from get_element in that it waits for the element to exist before trying to return it.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute
      # that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      # @return [Watir::Span]
      def get_span(browser, how, what, desc = '')
        begin
          Watir::Wait.until { browser.span(how, what).exists? }
        rescue => e
          if not rescue_me(e, __method__, "browser.span(#{how}, '#{what}').exists?", "#{browser.class}")
            raise e
          end
        end
        begin
          span = browser.span(how, what)
        rescue => e
          if not rescue_me(e, __method__, "browser.span(#{how}, '#{what}').exists?", "#{browser.class}")
            raise e
          end
        end
        passed_to_log("Span #{how}='#{what}' found and returned. #{desc}")
        return span
      rescue
        failed_to_log("Unable to return span #{how}='#{what}'. #{desc}: '#{$!}' (#{__LINE__})")
      end

      # Return a reference to a _form_ element identified by the contents *what* of its attribute *how*.
      # @param (see #get_span)
      # @return [Watir::Form]
      def get_form(browser, how, what, desc = '')
        get_element(browser, :form, how, what, desc)
      end

      # Return a reference to a _frame_ element identified by the contents *what* of its attribute *how*.
      # @param (see #get_span)
      # @return [Watir::Frame]
      def get_frame(browser, how, what, desc = '')
        get_element(browser, :frame, how, what, desc)
      end

      # Return a reference to a _select_list_ element identified by the contents *what* of its attribute *how*.
      # @param (see #get_span)
      # @return [Watir::SelectList]
      def get_select_list(browser, how, what, desc = '')
        get_element(browser, :select_list, how, what, desc)
      end

      # Return an array (collection) of all the elements of the type *which* contained in the browser or container
      # supplied in *browser*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Boolean] dbg If set to true additional debug logging is performed.
      # @return [Array]
      def get_element_collection(browser, element, dbg = false)
        cnt = 0
        case element
          when :links, :link
            list = browser.links
            sleep(1)
          when :tables, :table
            list = browser.tables
          when :divs, :div
            list = browser.divs
          when :buttons, :button
            list = browser.buttons
          when :checkboxes, :checkbox
            list = browser.checkboxes
          when :radios, :radio
            list = browser.radios
          when :selectlists, :select_lists, :selectlist, :select_list
            list = browser.selectlists
          when :textfields, :text_fields, :textareas, :text_fields, :textfield, :text_field, :textarea, :text_area
            list = browser.textfields
          when :lis, :li
            list = browser.lis
          when :uls, :ul
            list = browser.uls
          else
            debug_to_log("Unsupported DOM object '#{which}'")
        end
        if dbg
          list.each do |obj|
            cnt += 1
            debug_to_log("\n==========#{which}:\nindex:     #{cnt}\n#{obj}\n#{obj.to_yaml}")
          end
        end
        list
      end

      alias get_objects get_element_collection

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
        list    = get_elements(browser, obj_sym, true)
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

      # @!endgroup Core

      # @!group Legacy (Backward compatible usages)

      def get_select_options_by_id(browser, what, dump = false)
        get_select_options(browser, :id, what, dump)
      end

      def get_select_options_by_name(browser, what, dump = false)
        get_select_options(browser, :name, what, dump)
      end

      def get_selected_options_by_id(browser, what)
        get_selected_options(browser, :id, what)
      end

      alias get_selected_option_by_id get_selected_options_by_id

      def get_selected_options_by_name(browser, what)
        get_selected_options(browser, :name, what)
      end

      alias get_selected_option_by_name get_selected_options_by_name

      def get_div_by_id(browser, what, desc = '', dbg = false)
        get_div(browser, :id, what, desc, dbg)
      end

      def get_div_by_class(browser, what, desc = '', dbg = false)
        get_div(browser, :class, what, desc, dbg)
      end

      def get_div_by_text(browser, what, desc = '', dbg = false)
        get_div(browser, :text, what, desc, dbg)
      end

      def get_form_by_id(browser, what)
        get_form(browser, :id, what)
      end

      def get_frame_by_id(browser, what, desc = '')
        get_frame(browser, :id, what, desc)
      end

      def get_frame_by_index(browser, what, desc = '')
        get_frame(browser, :index, what, desc)
      end

      def get_frame_by_name(browser, what, desc = '')
        get_frame(browser, :name, what, desc)
      end

      def get_span_by_id(browser, what, desc = '')
        get_span(browser, :id, what, desc)
      end

      def get_table(browser, how, what, desc = '')
        get_element(browser, :table, how, what, nil, desc)
      end

      def get_table_by_id(browser, what, desc = '')
        get_element(browser, :table, :id, what, nil, desc)
      end

      def get_table_by_index(browser, what, desc = '')
        get_element(browser, :table, :index, what, nil, desc)
      end

      def get_table_by_text(browser, what)
        get_element(browser, :table, :text, what, nil, desc)
      end

      # @!endgroup Legacy

    end
  end
end

