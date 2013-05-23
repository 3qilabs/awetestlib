module Watir

  class IE

    ###################################
    def browser_screen_offset(browser)
      parent = page_container.document.parentWindow
      [parent.screenLeft.to_i,
       parent.screenTop.to_i]
    end

  end

  class Element
    # for watir element returns array of arrays where each element is a [name, value] as long as value is other than null or blank
    def get_attributes
      attrs = []
      self.document.attributes.each do |atr|
        k= []
        next if (atr.value == 'null') || (atr.value == '')
        k << atr.name << atr.value
        attrs << k
      end
      attrs.sort
    end

    ###################################
    def attribute_values
      hash = Hash.new
      ['id', #   'offsetParent', 'style', 'currentstyle',
       'offsetHeight', 'offsetWidth', 'offsetLeft', 'offsetTop',
       'clientHeight', 'clientWidth', 'clientLeft', 'clientTop',
       'scrollHeight', 'scrollWidth', 'scrollLeft', 'scrollTop',
       'className', 'resizable',
       'visible', 'sourceIndex'].each do |attr|
        value   = attribute_value(attr)
        myClass = value.class
        if myClass =~ /WIN32OLE/i or value.is_a?(WIN32OLE)
          meths = Hash.new
          value.ole_methods.each do |m|
            meths[m.name] = m.helpstring
          end
          hash[attr] = meths.sort
        else
          hash[attr] = value
        end
      end
      hash
    end

    ###################################
    def fetch_attributes
      assert_exists
      assert_enabled
      obj     = ole_object
      hash    = Hash.new
      methods = obj.ole_methods
      methods.each do |m|
        hash[m.name] = "visible: #{m.visible?}: #{m.helpstring}: #{m.invoke_kind}: #{m.params}: #{m.return_type}: #{m.return_type_detail}"
      end
      hash.sort.to_yaml
    end

    def list_attributes
      attributes = browser.execute_script(%Q[
                var s = [];
                var attrs = arguments[0].attributes;
                for (var l = 0; l < attrs.length; ++l) {
                    var a = attrs[l]; s.push(a.name + ': ' + a.value);
                } ;
                return s;],
                                          self)
    end

    ###################################
    def bottom_edge
      assert_exists
      assert_enabled
      ole_object.getBoundingClientRect.bottom.to_i
    end

    ###################################
    def top_edge
      assert_exists
      assert_enabled
      ole_object.getBoundingClientRect.top.to_i
    end

    ###################################
    def top_edge_absolute
      top_edge + page_container.document.parentWindow.screenTop.to_i
    end

    ###################################
    def left_edge
      assert_exists
      assert_enabled
      ole_object.getBoundingClientRect.left.to_i
    end

    ###################################
    def right_edge
      assert_exists
      assert_enabled
      ole_object.getBoundingClientRect.right.to_i
    end

    ###################################
    def left_edge_absolute
      left_edge + page_container.document.parentWindow.screenLeft.to_i
    end

    ###################################
    def dimensions
      assert_exists
      assert_enabled
      x = ole_object.getBoundingClientRect.right.to_i - left_edge
      y = ole_object.getBoundingClientRect.bottom.to_i - top_edge
      [x, y]
    end

    ###################################
    def screen_offset
      [left_edge_absolute, top_edge_absolute]
    end

    ###################################
    def client_offset
      [left_edge, top_edge]
    end

    ###################################
    def client_center
      client_offset + dimensions.map { |dim| dim/2 }
#      x, y = client_offset
#      w, h = dimensions
#      cx = x + ( w / 2 ).to_i
#      cy = y + ( h / 2 ).to_i
#      [cx, cy]
    end

    ###################################
    def screen_center
      x, y = screen_offset
      w, h = dimensions
      cx   = x + (w / 2).to_i
      cy   = y + (h / 2).to_i
      [cx, cy]
    end

    ###################################
    def client_lower_right
      x, y = client_offset
      w, h = dimensions
      lrx  = x + w
      lry  = y + h
      [lrx, lry]
    end

    ###################################
    def screen_lower_right
      x, y = screen_offset
      w, h = dimensions
      lrx  = x + w
      lry  = y + h
      [lrx, lry]
    end

    ###################################
    def bounding_rectangle_offsets
      l, t = client_offset
      r    = ole_object.getBoundingClientRect.right.to_i
      b    = ole_object.getBoundingClientRect.bottom.to_i
      [t, b, l, r]
    end


  end

  #class NonControlElement
  #  class Ol < NonControlElement
  #    TAG = 'OL'
  #  end
  #end

end
