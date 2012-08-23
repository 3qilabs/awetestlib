module Awetestlib
  module Regression
    module DragAndDrop

      def verify_element_inside(inner_element, outer_element, desc = '')
        mark_testlevel("#{__method__.to_s.titleize}", 3)
        msg = "#{inner_element.class.to_s} (:id=#{inner_element.id}) is fully enclosed by #{outer_element.class.to_s} (:id=#{outer_element.id})."
        msg << " #{desc}" if desc.length > 0
        if overlay?(inner_element, outer_element, :inside)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to verify that #{msg} '#{$!}'")
      end

      def verify_no_element_overlap(browser, above_element, above_how, above_what, below_element, below_how, below_what, side, desc = '')
        mark_testlevel("#{__method__.to_s.titleize}", 3)
        msg = "#{above_element.to_s.titleize} #{above_how}=>#{above_what} does not overlap "+
            "#{below_element.to_s.titleize} #{below_how}=>#{below_what} at the #{side}."
        msg << " #{desc}" if desc.length > 0
        above = browser.element(above_how, above_what)
        below = browser.element(below_how, below_what)
        if overlay?(above, below, side)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        failed_to_log("Unable to verify that #{msg} '#{$!}'")
      end

      def overlay?(inner, outer, side = :bottom)
        #mark_testlevel("#{__method__.to_s.titleize}", 3)
        inner_t, inner_b, inner_l, inner_r = inner.bounding_rectangle_offsets
        outer_t, outer_b, outer_l, outer_r = outer.bounding_rectangle_offsets
        #overlay = false
        case side
          when :bottom
            overlay = inner_b > outer_t
          when :top
            overlay = inner_t > outer_t
          when :left
            overlay = inner_l < outer_r
          when :right
            overlay = inner_r > outer_r
          when :inside
            overlay = !(inner_t > outer_t and
                inner_r < outer_r and
                inner_l > outer_l and
                inner_b < outer_b)
          else
            overlay = (inner_t > outer_b or
                inner_r > outer_l or
                inner_l < outer_r or
                inner_b < outer_t)
        end
        overlay
      rescue
        failed_to_log("Unable to determine overlay. '#{$!}'")
      end

      def hover(browser, element, wait = 2)
        w1, h1, x1, y1, xc1, yc1, xlr1, ylr1 = get_element_coordinates(browser, element, true)
        @ai.MoveMouse(xc1, yc1)
        sleep_for(1)
      end

      def move_element_with_handle(browser, element, handle_id, dx, dy)
        #    msg = "Move element "
        #    w1, h1, x1, y1, xc1, yc1, xlr1, ylr1 = get_element_coordinates(browser, element, true)
        #    newx   = w1 + dx
        #    newy   = h1 + dy
        #    msg << " by [#{dx}, #{dy}] to expected [[#{newx}, #{newy}] "
        #    handle = get_resize_handle(element, handle_id)
        #    hw, hh, hx, hy, hxc, hyc, hxlr, hylr  = get_element_coordinates(browser, handle, true)

        #    drag_and_drop(hxc, hyc, dx, dy)

        #    w2, h2, x2, y2, xc2, yc2, xlr2, ylr2 = get_element_coordinates(browser, element, true)

        #    xerr = x2 - newx
        #    yerr = y2 - newy
        #    xdsp = (x1 - x2).abs
        #    ydsp = (y1 - y2).abs

        #    if x2 == newx and y2 == newy
        #      msg << "succeeded."
        #      passed_to_log(msg)
        #    else
        #      msg << "failed. "
        #      failed_to_log(msg)
        #      debug_to_log("x: actual #{x2}, error #{xerr}, displace #{xdsp}. y: actual #{y2}, error #{yerr}, displace #{ydsp}.")
        #    end

      end

      def resize_element_with_handle(browser, element, target, dx, dy=nil)
        #TODO enhance to accept differing percentages in each direction
        msg                                  = "Resize element "
        w1, h1, x1, y1, xc1, yc1, xlr1, ylr1 = get_element_coordinates(browser, element, true)
        if dy
          deltax = dx
          deltay = dy
          neww   = w1 + dx
          newh   = h1 + dy
          msg << " by [#{dx}, #{dy}] " #"" to expected dimension [#{neww}, #{newh}] "
        else
          deltax, deltay, neww, newh = adjust_dimensions_by_percent(w1, h1, dx, true)
          msg << "by #{dx} percent " #"" to expected dimension [#{neww}, #{newh}] "
        end
        handle = get_resize_handle_by_class(element, target) #, true)
        sleep_for(0.5)
        hw, hh, hx, hy, hxc, hyc, hxlr, hylr = get_element_coordinates(browser, handle, true)
        hxlr_diff                            = 0
        hylr_diff                            = 0

        # TODO These adjustments are adhoc and empirical. Need to be derived more rigorously
        if @browserAbbrev == 'IE'
          hxlr_diff = (xlr1 - hxlr)
          hylr_diff = (ylr1 - hylr)
          x_start   = hxlr - 2
          y_start   = hylr - 2
        else
          hxlr_diff = (xlr1 - hxlr) / 2 unless (xlr1 - hxlr) == 0
          hylr_diff = (ylr1 - hylr) / 2 unless (ylr1 - hylr) == 0
          x_start = hxlr
          y_start = hylr
        end

        newxlr = xlr1 + deltax
        newylr = ylr1 + deltay
        #    msg << ", lower right [#{newxlr}, #{newylr}] - "
        sleep_for(0.5)

        drag_and_drop(x_start, y_start, deltax, deltay)

        sleep_for(1.5)
        w2, h2, x2, y2, xc2, yc2, xlr2, ylr2 = get_element_coordinates(browser, element, true)

        werr   = w2 - neww
        herr   = h2 - newh

        # TODO This adjustment is adhoc and empirical. Needs to be derived more rigorously
        xlrerr = xlr2 - newxlr + hxlr_diff
        ylrerr = ylr2 - newylr + hylr_diff

        xlrdsp = (xlr1 - xlr2).abs
        ylrdsp = (ylr1 - ylr2).abs

        debug_to_log("\n" +
                         "\t\t  hxlr_diff: #{hxlr_diff}\n" +
                         "\t\t  hylr_diff: #{hylr_diff}\n" +
                         "\t\t       werr: #{werr}\n" +
                         "\t\t       herr: #{herr}\n" +
                         "\t\t     xlrerr: #{xlrerr}\n" +
                         "\t\t     ylrerr: #{ylrerr}\n" +
                         "\t\t     xlrdsp: #{xlrdsp}\n" +
                         "\t\t     ylrdsp: #{ylrdsp}\n" +
                         "\t\t @min_width: #{@min_width}\n" +
                         "\t\t@min_height: #{@min_height}\n" +
                         "\t\t      x tol: #{@x_tolerance}\n" +
                         "\t\t      y tol: #{@y_tolerance}\n"
        )

        #TODO Add check that window _was_ resized.
        x_ok, x_msg = validate_move(w2, xlrerr, @x_tolerance, @min_width, xlr2)
        y_ok, y_msg = validate_move(h2, ylrerr, @y_tolerance, @min_height, ylr2)
        msg         = msg + "x: #{x_msg}, y: #{y_msg}"

        if x_ok and y_ok
          passed_to_log(msg)
        else
          failed_to_log(msg)
          debug_to_log("x - actual #{xlr2}, error #{xlrerr}, displace #{xlrdsp}, y - actual #{ylr2}, error #{ylrerr}, displace #{ylrdsp}.")
        end
        sleep_for(1)
      rescue
        failed_to_log("Unable to validate resize. #{$!} (#{__LINE__})")
        sleep_for(1)
      end

    # :category: GUI
      def get_resize_handle_by_id(element, id, dbg=nil)
        handle = get_div_by_id(element, id, dbg)
        sleep_for(1)
        handle.flash(5)
        return handle
      end

    # :category: GUI
      def get_resize_handle_by_class(element, strg, dbg=nil)
        handle = get_div_by_class(element, strg, dbg)
        sleep_for(0.5)
        handle.flash(5)
        return handle
      end

    # :category: GUI
      def get_element_coordinates(browser, element, dbg=nil)
        bx, by, bw, bh = get_browser_coord(browser, dbg)
        if @browserAbbrev == 'IE'
          x_hack = @horizontal_hack_ie
          y_hack = @vertical_hack_ie
        elsif @browserAbbrev == 'FF'
          x_hack = @horizontal_hack_ff
          y_hack = @vertical_hack_ff
        end
        sleep_for(1)
        w, h   = element.dimensions.to_a
        xc, yc = element.client_offset.to_a
        #    xcc, ycc = element.client_center.to_a
        xcc    = xc + w/2
        ycc    = yc + h/2
        # screen offset:
        xs     = bx + x_hack + xc - 1
        ys     = by + y_hack + yc - 1
        # screen center:
        xsc    = xs + w/2
        ysc    = ys + h/2
        xslr   = xs + w
        yslr   = ys + h
        if dbg
          debug_to_log(
              "\n\t\tElement: #{element.inspect}"+
                  "\n\t\tbrowser screen offset: x: #{bx} y: #{by}"+
                  "\n\t\t           dimensions: x: #{w} y: #{h}"+
                  "\n\t\t         client offset x: #{xc} y: #{yc}"+
                  "\n\t\t         screen offset x: #{xs} y: #{ys}"+
                  "\n\t\t         client center x: #{xcc} y: #{ycc}"+
                  "\n\t\t         screen center x: #{xsc} y: #{ysc}"+
                  "\n\t\t    screen lower right x: #{xslr} y: #{yslr}")
        end
        [w, h, xs, ys, xsc, ysc, xslr, yslr]
      end

      def adjust_dimensions_by_percent(w, h, p, returnnew=nil)
        p      += 100
        nw     = (w * (p/100.0)).to_i
        nh     = (h * (p/100.0)).to_i
        deltaw = nw - w
        deltah = nh - h
        if returnnew
          [deltaw, deltah, nw, nh]
        else
          [deltaw, deltah]
        end
      end

      def get_browser_coord(browser=nil, dbg=nil)
        browser = @myBrowser if not browser
        title = browser.title
        x     = @ai.WinGetPosX(title)
        y     = @ai.WinGetPosY(title)
        w     = @ai.WinGetPosWidth(title)
        h     = @ai.WinGetPosHeight(title)
        if dbg
          debug_to_log("\n\t\tBrowser #{browser.inspect}\n"+
                           "\t\tdimensions:   x: #{w} y: #{h}"+
                           "\t\tscreen offset x: #{x} y: #{y}")
        end
        [x, y, w, h]
      end

      def drag_and_drop(x1, y1, dx, dy, speed=nil)
        speed = 10 if not speed
        x2 = x1 + dx
        y2 = y1 + dy
        debug_to_log("drag_and_drop: start: [#{x1}, #{y1}] end: [#{x2}, #{y2}]")

        @ai.MouseMove(x1, y1, speed)
        @ai.MouseClick("primary", x1, y1)
        sleep_for(0.5)
        @ai.MouseClick("primary", x1, y1)
        sleep_for(0.5)
        @ai.MouseClickDrag("primary", x1, y1, x2, y2, speed)
      end

      def drag_and_drop_element(browser, element, dx, dy, speed = nil)
        speed = 10 if not speed
        w1, h1, x1, y1, xc1, yc1, xlr1, ylr1 = get_element_coordinates(browser, element, true)
        msg                                  = "Move #{element} by [#{dx}, #{dy}] from center[#{xc1}, #{yc1}] "
        newxc                                = xc1 + dx
        newyc                                = yc1 + dy
        msg << "to center[[#{newxc}, #{newyc}]"
        sleep_for(0.5)

        drag_and_drop(xc1, yc1, dx, dy)

        sleep_for(1)
        w2, h2, x2, y2, xc2, yc2, xlr2, ylr2 = get_element_coordinates(browser, element, true)

        # TODO This adjustment is adhoc and empirical. Needs to be derived more rigorously
        xcerr                                = xc2 - xc1
        ycerr                                = yc2 - yc1

        debug_to_log("\n" +
                         "\t\t   xc1: #{xc1}\n" +
                         "\t\t   yc1: #{yc1}\n" +
                         "\t\t   xc2: #{xc2}\n" +
                         "\t\t   yc2: #{yc2}\n" +
                         "\t\t xcerr: #{xlrerr}\n" +
                         "\t\t ycerr: #{ylrerr}\n" +
                         "\t\t x tol: #{@x_tolerance}\n" +
                         "\t\t y tol: #{@y_tolerance}\n"
        )

        #TODO Add check that window _was_ resized.
        x_ok, x_msg = validate_drag_drop(xcerr, @x_tolerance, newxc, xc2)
        y_ok, y_msg = validate_drag_drop(ycerr, @y_tolerance, newyc, yc2)
        msg         = msg + "x: #{x_msg}, y: #{y_msg}"

        if x_ok and y_ok
          passed_to_log(msg)
        else
          failed_to_log(msg)
        end
        sleep_for(1)
      rescue
        failed_to_log("Unable to validate drag and drop. #{$!} (#{__LINE__})")
        sleep_for(1)
      end

      def right_click(element)
        x = element.left_edge_absolute + 2
        y = element.top_edge_absolute + 2
        @ai.MouseClick("secondary", x, y)
      end

      def left_click(element)
        x = element.left_edge_absolute + 2
        y = element.top_edge_absolute + 2
        @ai.MouseClick("primary", x, y)
      end

      def screen_offset(element, browser=nil)
        bx, by, bw, bh = get_browser_coord(browser)
        ex             = element.left_edge
        ey             = element.top_edge
        [bx + ex, by + ey]
      end

      def screen_center(element, browser=nil)
        bx, by, bw, bh = get_browser_coord(browser)
        w, h           = element.dimensions.to_a
        cx             = bx + w/2
        cy             = by + h/2
        [cx, cy]
      end

      def screen_lower_right(element, browser=nil)
        bx, by, bw, bh = get_browser_coord(browser)
        w, h           = element.dimensions.to_a
        [bx + w, by + h]
      end

      def verify_resize(d, err, tol, min, act)
        ary = [false, "failed, actual #{act} err #{err}"]
        if err == 0
          ary = [true, 'succeeded ']
          #TODO need to find way to calculate this adjustment
        elsif d <= min + 4
          ary = [true, "reached minimum (#{min}) "]
        elsif err.abs <= tol
          ary = [true, "within tolerance (+-#{tol}px) "]
        end
        ary
      end

      alias validate_move verify_resize
      alias validate_resize verify_resize

    end
  end
end

