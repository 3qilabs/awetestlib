module Awetestlib
  module Regression
    module PageData

=begin rdoc
:category: Page Data
:tags: data, DOM, page

_Parameters_::

*browser* is any container element, usually the browser window or a div within it.  Best to use is the smallest that contains the desired data.

*types* is an array that defaults to all of: :text, :textarea, :select_list, :span, :hidden, :checkbox, and :radio.
Set types to an array of a subset of these if fewer elements are desired.

No positive validations are reported but failure is rescued and reported.
=end
      def capture_page_data(browser, types = [:text, :textarea, :select_list, :span, :hidden, :checkbox, :radio])
        start = Time.now
        debug_to_log("Begin #{__method__}")
        data         = Hash.new
        data[:id]    = Hash.new
        data[:name]  = Hash.new
        data[:index] = Hash.new
        types.each do |type|
          #debug_to_log("#{__method__}: #{type}. . .")
          data[:id][type], data[:name][type], data[:index][type] = parse_elements(browser, type)
        end
        data
      rescue
        failed_to_log("#{__method__}: '#{$!}'")
      ensure
        stop = Time.now
        passed_to_log("#{__method__.to_s.titleize} finished. (#{"%.5f" % (stop - start)} secs)")
        #debug_to_log("End #{__method__}")
      end

      def compare_page_data(before, after, how, desc = '')
        [:text, :textarea, :select_list, :span, :checkbox, :radio].each do |type|
          before[how][type].each_key do |what|
            msg = "#{desc} #{type} #{how}=#{what}: Expected '#{before[how][type][what]}'."
            if after[how][type][what] == before[how][type][what]
              passed_to_log(msg)
            else
              failed_to_log("#{msg} Found '#{after[how][type][what]}'")
            end
          end
        end
      rescue
        failed_to_log("Unable to compare before and after page data. '#{$!}'")
      end

=begin rdoc
:category: Page Data
:tags:data, DOM

*data* is the hash returned by capture_page_data().

*how* is one of :id, :name, :index

*what* is the target value for how. It can be a string or a regular expression

*type* is one of :text,:textarea,:select_list,:span,:hidden,:checkbox,:radio

*get_text* determines whether selected option's text or value is returned. Default is true, i.e., return the selected text.
This only applies when the *type* is :select_list.

=end
      def fetch_page_data(data, how, what, type, get_text = true)
        rslt = data[how][type][what]
        if type == :select_list
          value, text = rslt.split('::')
          if get_text
            rslt = text
          else
            rslt = value
          end
        end
        rslt
      end

=begin rdoc
:category: Page Data
:tags:data, DOM

*browser* is any container element.  best to use is the smallest that contains the desired data.

*type* is one of these symbols: :text,:textarea,:select_list,:span,:hidden,:checkbox,:radio

Returns three hashes: id[type][id] = value, name[type][id] = value, index[type][id] = value

A given element appears once in the set of hashes depending on how is is found: id first
then name, then index.

Select list value is in the form 'value::text'. parse with x.split('::')

No positive validations are reported but failure is rescued and reported.
=end
      def parse_elements(browser, type)
        id    = Hash.new
        name  = Hash.new
        index = Hash.new
        idx   = 0
        #debug_to_log("#{__method__}: #{type}")
        case type
          when :span
            collection = browser.spans
          when :select_list
            collection = browser.select_lists
          when :radio
            collection = browser.radios
          when :checkbox
            collection = browser.checkboxes
          else
            collection = browser.elements(:type, type.to_s)
        end
        #debug_to_log("#{__method__}: collection: #{collection.inspect}")
        collection.each do |e|
          case type
            when :span
              vlu = e.text
            when :select_list
              vlu = "#{e.value}::#{e.selected_options[0]}"
            when :radio
              vlu = e.set?
            when :checkbox
              vlu = e.set?
            else
              vlu = e.value
          end
          idx += 1
          if e.id.length > 0 and not e.id =~ /^__[A-Z]/
            id[e.id] = vlu
          elsif e.name.length > 0 and not e.name =~ /^__[A-Z]/
            name[e.name] = vlu
          else
            index[idx] = vlu if not type == :hidden
          end
        end
        [id, name, index]

      rescue
        failed_to_log("#{__method__}: '#{$!}'")
      end

      def get_textfield_value(browser, how, what, desc = '')
        msg = "Return value in textfield #{how}='#{what}'"
        msg << " #{desc}" if desc.length > 0
        tf = browser.text_field(how, what)
        if validate(browser, @myName, __LINE__)
          if tf
            debug_to_log("#{tf.inspect}")
            vlu = tf.value
            passed_to_log("#{msg} Value='#{vlu}'")
            vlu
          else
            failed_to_log("#{msg}")
          end
        end
      rescue
        failed_to_log("Unable to #{msg}: '#{$!}'")
      end

      def get_textfield_value_by_name(browser, strg, desc = '')
        get_textfield_value(browser, :name, strg, desc)
      end

      def get_textfield_value_by_id(browser, strg)
        get_textfield_value(browser, :id, strg)
      end

      def get_element_text(browser, element, how, what, desc = '')
        msg = "Return text in #{element} #{how}='#{what}'"
        msg << " #{desc}" if desc.length > 0
        text = browser.element(how, what).text
        if validate(browser, @myName, __LINE__)
          passed_to_log("#{msg} text='#{text}'")
          text
        end
      rescue
        failed_to_log("Unable to #{msg}: '#{$!}'")
      end




    end
  end
end

