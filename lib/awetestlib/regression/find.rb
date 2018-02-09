module Awetestlib
  module Regression
    # Methods to fetch references to DOM elements for assigning to variables.  Includes collections of elements.
    # Primary use is to limit the scope of other commands to the element passed in their *browser* parameter.
    # (example here)
    module Find

      # @!group Core

      # Return a reference to a DOM element specified by its type *element*, attribute *how*, and the
      # contents of that attribute *what*.  Some elements may require use of the *:value* attribute in addition
      # to the designated one.  The target contents for *:value* are supplied in *value*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] element The kind of element to click. Must be one of the elements recognized by Watir.
      #   Some common values are :link, :button, :image, :div, :span.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute that uniquely identifies the element.
      # @param [String, Regexp] value A string or a regular expression to be found in the *:value* attribute that uniquely identifies the element.
      # @param [String] desc Contains a message or description intended to appear in the log and/or report output
      def get_element(container, element, how, what, value = nil, desc = '', options = {})
        value, desc, options = capture_value_desc(value, desc, options) # for backwards compatibility
        msg    = build_message("Return #{element} with :#{how}=>'#{what}'", value, desc)
        code   = build_webdriver_fetch(element, how, what, options)
        target = eval(code)
        if target and target.exists?
          passed_to_log(msg)
          target
        else
          failed_to_log(msg)
          nil
        end
      rescue => e
        unless rescue_me(e, __method__, rescue_me_command(target, how, what), "#{container.class}", target)
          raise e
        end
      end

      def get_attribute_value(browser, element, how, what, attribute, desc = '')
        #TODO: eliminate case statement by using eval with build_webdriver_fetch
        msg = build_message("Value of #{attribute} in #{element} #{how}=>#{what}.", desc)
        case element
          when :link
            value = browser.link(how => what).attribute_value attribute
          when :button
            value = browser.button(how => what).attribute_value attribute
          else
            if browser.element(how => what).responds_to?('attribute_value')
              value = browser.element(how => what).attribute_value attribute
            end
        end
        value
      rescue
        failed_to_log(" Unable to #{msg}: '#{$!}'")
      end

      def get_directory(path)
        if File.directory?(path)
          debug_to_log("Directory already exists, '#{path}'.")
        else
          Dir::mkdir(path)
          debug_to_log("Directory was created, '#{path}'.")
        end
        path
      end

      def get_ancestor(descendant, element, how, what, desc = '')
        found = false
        how = 'class_name' if how.to_s == 'class'
        tag = element.to_s.downcase
        debug_to_log("target: #{descendant.tag_name} :id=>#{descendant.id}")
        debug_to_log("goal:   #{element} :#{how}=>#{what}   #{desc}")
        ancestor = target.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}'")
        code = "ancestor.#{how}"
        what.is_a?(Regexp) ? code << " =~ /#{what.source}/" : code << " == '#{what}'"
        debug_to_log("#{code}")
        until found do
          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}'")
          if ancestor.tag_name == tag
            if eval(code)
              found = true
              break
            end
          end
          break unless ancestor
          ancestor = ancestor.parent
        end
        ancestor
      rescue
        failed_to_log(unable_to)
      end

      def capture_value_desc(value, desc, options = nil)
        opt = options.dup if options
        unless opt.kind_of?(Hash)
          opt = Hash.new
        end
        if value
          vlu = value.dup
          if opt[:value]
            vlu = nil
          else
            opt[:value] = vlu
          end
        end
        if desc
          dsc = desc.dup
          unless opt[:desc]
            opt[:desc] = dsc
          end
        end
        [vlu, dsc, opt]
      rescue
        failed_to_log(unable_to)
      end

      # Return an array containing the options available for selection in a select_list identifified by
      # its attribute *how*, and the contents of that attribute *what*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [Symbol] how The element attribute used to identify the specific element.
      #   Valid values depend on the kind of element.
      #   Common values: :text, :id, :title, :name, :class, :href (:link only)
      # @param [String, Regexp] what A string or a regular expression to be found in the *how* attribute
      # that uniquely identifies the element.
      # @param [Boolean] dump If set to true, a dump of the contents of the options will go to the log.
      # See Utilities#dump_select_list_options
      # @return [Array]
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
      # @return [Array]
      def get_selected_options(browser, how, what)
        begin
          list = browser.select_list(how, what)
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(:select_list, how, what), "#{browser.class}")
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
          unless rescue_me(e, __method__, rescue_me_command(:span, how, what, :exists?), "#{browser.class}")
            raise e
          end
        end
        begin
          span = browser.span(how, what)
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(:span, how, what, :exists?), "#{browser.class}")
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

      # Return the ole object for the specified element.
      # @note Usable only with classic Watir.
      # @todo Detect $watir_script variable and disable if not set to true
      # @param [Symbol] element A reference to the already identified element.
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

      # Return a hash of all links in *browser* with *:href* attribute containing the exact url in *href*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] href The exact url to be located.
      # @return [Hash] The hash is indexed by the order in which the links were located in *browser*.
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

      # Return a reference to the first link in *browser* with *:href* attribute containing the exact url in *href*.
      # @param [Watir::Browser] browser A reference to the browser window or container element to be tested.
      # @param [String] href The exact url to be located.
      # @return [Watir::Link]
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

      # @!endgroup Core

      # @!group Deprecated

      # Find the index of an element within *browser* which has attribute *how* containing *what*
      # @deprecated
      def find_index_for_element(browser, element, how, ord, what)
        element_sym = (element.to_s.pluralize).to_sym
        how_str = how.to_s
        ptrn    = /#{how}:\s+#{what}/i
        list    = get_element_collection(browser, element_sym, true)
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

      alias find_index_for_object find_index_for_element

      # @!endgroup Deprecated

    end
  end
end

