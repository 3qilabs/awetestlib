module Awetestlib
  module Regression
    # Miscellaneous helper methods.
    # Includes file save/upload as well as debug methods.
    # Rdoc work in progress.
    module Utilities


      # Group by associated DOM object or scripting function?


      # Place holder to prevent method not found error in scripts
      def set_script_variables
        # TODO: replace with method_missing?
      end

      def setup
        #    if @os_sysname =~ /Windows.+Server\s+2003/
        ##  'Microsoft(R) Windows(R) Server 2003, Enterprise Edition'
        #      @vertical_hack_ie   = 110
        #      @vertical_hack_ff   = 138
        #      @horizontal_hack_ie = 5
        #      @horizontal_hack_ff = 4
        #    elsif @os_sysname =~ /Windows XP Professional/
        #  'Microsoft Windows XP Professional'
        @vertical_hack_ie        = 118
        @vertical_hack_ff        = 144
        @horizontal_hack_ie      = 5
        @horizontal_hack_ff      = 4
        #end

        @settings_display_ids    = Hash[
            "Currency"       => "row-currencyName",
            "Description"    => "row-description",
            "Tx Date"        => "row-fmtDate",
            "Total"          => "row-amount",
            "[currencyCode]" => "row-currencyCode",
            "Date in Millis" => "row-dateInMilliseconds",
        ]
        @column_data_display_ids = Hash[
            "Currency"       => "yui-dt0-th-currencyName",
            "Description"    => "yui-dt0-th-description",
            "Tx Date"        => "yui-dt0-th-fmtDate",
            "Total"          => "yui-dt0-th-fmtDate",
            "[currencyCode]" => "yui-dt0-th-currencyCode",
            "Date in Millis" => "yui-dt0-th-dateInMilliseconds",
        ]
        @settings_panel_index    = 0
        @x_tolerance             = 4
        @y_tolerance             = 4
      end

      def build_message(strg1, desc = '', strg2 = '', strg3 = '', strg4 = '')
        msg = "#{strg1}"
        msg << " #{desc}" if desc and desc.length > 0
        msg << " #{strg2}" if strg2 and strg2.length > 0
        msg << " #{strg3}" if strg3 and strg3.length > 0
        msg << " #{strg4}" if strg4 and strg4.length > 0
        msg
      end

      def get_trace(lnbr)
        callertrace = "\nCaller trace: (#{lnbr})\n"
        Kernel.caller.each_index do |x|
          callertrace << '    >> ' + Kernel.caller[x].to_s + "\n"
        end
        callertrace
      end

      alias dump_caller get_trace

      def get_mdyy(t = Time.now)
        "#{t.month}/#{t.day}/#{t.year}"
      end

      def get_prefix(strg, offset)
        a_slice = strg.slice(0, offset)
        a_slice.downcase
      end

      def get_timestamp(format = 'long', offset = nil, offset_unit = :years)
        t = DateTime.now
        if offset
          t = t.advance(offset_unit => offset)
        end
        case format
          when 'dateonly'
            t.strftime("%m/%d/%Y")
          when 'condensed'
            t.strftime("%Y%m%d%H%M")
          when 'condensed_seconds'
            t.strftime("%Y%m%d%H%M%S")
          when 'long'
            t.strftime("%m/%d/%Y %I:%M %p")
          when 'mdyy'
            get_mdyy(t)
          when 'm/d/y'
            get_mdyy(t)
          else
            Time.now.strftime("%m/%d/%Y %H:%M:%S")
        end
      end

      def calc_index(index, every = 1)
        (index / every) + (every - 1)
      end

      def get_variables(file, key_type = :role, dbg = true)
        #TODO refactor this
        debug_to_log("#{__method__}: file = #{file}")
        debug_to_log("#{__method__}: key  = #{key_type}")

        script_found_in_login = false
        script_found_in_data  = false

        @var                   = Hash.new
        workbook               = Excel.new(file)
        data_index             = find_sheet_with_name(workbook, 'Data')
        workbook.default_sheet = workbook.sheets[data_index]
        var_col                = 0

        2.upto(workbook.last_column) do |col|
          scriptName = workbook.cell(1, col)
          if scriptName == @myName
            var_col = col
            script_found_in_data = true
            break
          end
        end

        2.upto(workbook.last_row) do |line|
          name       = workbook.cell(line, 'A')
          value      = workbook.cell(line, var_col).to_s.strip
          @var[name] = value
        end

        @var.keys.sort.each do |name|
          message_tolog("@var #{name}: '#{@var[name]}'")
        end if dbg

        @login       = Hash.new
        login_col    = 0
        role_col     = 0
        userid_col   = 0
        password_col = 0
        url_col      = 0
        name_col     = 0
        login_index   = find_sheet_with_name(workbook, 'Login')
        if login_index and login_index >= 0
          workbook.default_sheet = workbook.sheets[login_index]

          1.upto(workbook.last_column) do |col|
            a_cell = workbook.cell(1, col)
            case a_cell
              when @myName
                login_col = col
                script_found_in_login = true
                break
              when 'role'
                role_col = col
              when 'userid'
                userid_col = col
              when 'password'
                password_col = col
              when 'url'
                url_col = col
              when 'name'
                name_col = col
            end
          end

          2.upto(workbook.last_row) do |line|
            role     = workbook.cell(line, role_col)
            userid   = workbook.cell(line, userid_col)
            password = workbook.cell(line, password_col)
            url      = workbook.cell(line, url_col)
            username = workbook.cell(line, name_col)
            enabled  = workbook.cell(line, login_col).to_s

            case key_type
              when :id, :userid
                key = userid
              when :role
                key = role
              else
                key = userid
            end

            @login[key]             = Hash.new
            @login[key]['role']     = role
            @login[key]['userid']   = userid
            @login[key]['password'] = password
            @login[key]['url']      = url
            @login[key]['name']     = username
            @login[key]['enabled']  = enabled

          end

          @login.keys.sort.each do |key|
            message_tolog("@login (by #{key_type}): #{key}=>'#{@login[key].to_yaml}'")
          end if dbg
        end

        if script_found_in_login and script_found_in_data
          true
        else
          failed_to_log("Script found: in Login = #{script_found_in_login}; in Data = #{script_found_in_data}")
        end
      rescue
        failed_to_log("#{__method__}: '#{$!}'")
      end

      def translate_var_list(key)
        if @var[key] and @var[key].length > 0
          list = @var[key].dup
          unless list =~ /^\[.+\]$/
            list = "[#{list}]"
          end
          eval(list)
        end
      rescue
        failed_to_log("#{__method__}: '#{$!}'")
      end

      def grab_window_list(strg)
        @ai.AutoItSetOption("WinTitleMatchMode", 2)
        list    = @ai.WinList(strg)
        stuff   = ''
        names   = list[0]
        handles = list[1]
        max     = names.length - 1
        rng     = Range.new(0, max)
        rng.each do |idx|
          window_handle = "[HANDLE:#{handles[idx]}]"
          full_text     = @ai.WinGetText(window_handle)
          stuff << "[#{handles[idx]}]=>#{names[idx]}=>'#{full_text}'\n"
        end
        debug_to_log("\n#{stuff}")
        @ai.AutoItSetOption("WinTitleMatchMode", 1)
        stuff
      end

      def debug_call_list(msg)
        call_array = get_call_array
        debug_to_log("#{msg}\n#{dump_array(call_array)}")
      end

      def sec2hms(s)
        Time.at(s.to_i).gmtime.strftime('%H:%M:%S')
      end

      def close_log(scriptName, lnbr = '')
        cmplTS = Time.now.to_f.to_s
        puts ("#{scriptName} finished.  Closing log. #{lnbr.to_s}")
        passed_to_log("#{scriptName} run complete [#{cmplTS}]")
        @myLog.close()
        sleep(2)
      end

      protected :close_log

      def find_sheet_with_name(workbook, sheet_name)
        sheets = workbook.sheets
        idx    = 0
        found  = false
        sheets.each do |s|
          if s == sheet_name
            found = true
            break
          end
          idx += 1
        end
        if found
          idx
        else
          -1
        end
      end

      def nice_array(arr, space_to_underscore = false)
        new_arr = Array.new
        if space_to_underscore
          arr.each do |nty|
            new_arr << nty.gsub(/\s/, '_')
          end
        else
          new_arr = arr
        end
        "['#{new_arr.join("','")}']"
      end

      def string_count_in_string(strg, substrg)
        count = strg.scan(substrg).length
        count
      end

      def rescue_me(e, me = nil, what = nil, where = nil, who = nil)
        #TODO: these are rescues from exceptions raised in Watir/Firewatir
        debug_to_log("#{__method__}: Begin rescue")
        ok = false
        begin
          gaak    = who.inspect
          located = gaak =~ /located=true/i
        rescue
          debug_to_log("#{__method__}: gaak: '#{gaak}'")
        end
        msg = e.message
        debug_to_log("#{__method__}: msg = #{msg}")
        if  msg =~ /undefined method\s+.join.\s+for/i # firewatir to_s implementation error
          ok = true
        elsif msg =~ /undefined method\s+.match.\s+for.+WIN32OLERuntimeError/i # watir and firewatir
          ok = true
        elsif msg =~ /undefined method\s+.match.\s+for.+UnknownObjectException/i # watir
          ok = true
        elsif msg =~ /window\.getBrowser is not a function/i # firewatir
          ok = true
        elsif msg =~ /WIN32OLERuntimeError/i # watir
          ok = true
        elsif msg =~ /undefined method\s+.match.\s+for/i # watir
          ok = true
        elsif msg =~ /wrong number of arguments \(1 for 0\)/i
          ok = true
        elsif (msg =~ /unable to locate element/i)
          if located
            ok = true
          elsif where == 'Watir::Div'
            ok = true
          end
        elsif (msg =~ /HRESULT error code:0x80070005/)
          ok = true
                                                      #elsif msg =~ /missing\s+\;\s+before statement/
                                                      #  ok = true
        end
        if ok
          debug_to_log("#{__method__}: RESCUED: \n#{who.to_yaml}=> #{what} in #{me}()\n=> '#{$!}'")
          debug_to_log("#{__method__}: #{who.inspect}") if who
          debug_to_log("#{__method__}: #{where.inspect}")
          debug_to_log("#{__method__}: #{get_callers(6, true)}")
        else
          debug_to_log("#{__method__}: NO RESCUE: #{e.message}")
          debug_to_log("#{__method__}: NO RESCUE: \n#{get_callers(6, true)}")
        end
        debug_to_log("#{__method__}: Exit")
        ok
      end

      def get_caller_line
        last_caller = get_call_list[0]
        line        = last_caller.split(':', 3)[1]
        line
      end

      def get_call_list(depth = 9, dbg = false)
        myList    = []
        call_list = Kernel.caller
        puts call_list if dbg
        call_list.each_index do |x|
          myCaller = call_list[x].to_s
          myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          myList << "[#{$1.gsub(/eval/, @myName)}] "
          break if x > depth or myCaller =~ /:in .run.$/
        end
        myList
      end

      alias get_callers get_call_list

      def get_call_list_new(depth = 9, dbg = false)
        myList    = []
        call_list = Kernel.caller
        puts call_list if dbg
        call_list.each_index do |x|
          myCaller = call_list[x].to_s
          if myCaller.include? @myName
            myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
            myList << "[#{$1.gsub(/eval/, @myName)}] "
            break
          end
          break if x > depth or myCaller =~ /:in .run.$/
        end
        if @projName
          call_list.each_index do |x|
            myCaller = call_list[x].to_s
            if myCaller.include? @projName
              myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
              myList << "[#{$1.gsub(/eval/, @projName)}] "
              break
            end
          end
          break if x > depth or myCaller =~ /:in .run.$/
        end
        myList
      end

      def get_call_array(depth = 9)
        arr       = []
        call_list = Kernel.caller
        call_list.each_index do |x|
          myCaller = call_list[x].to_s
          myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          arr << $1.gsub(/eval/, @myName)
          break if x > depth or myCaller =~ /:in .run.$/
        end
        arr
      end

      def get_debug_list(dbg = false)
        calls = get_call_array(10)
        puts "#{calls.to_yaml}" if dbg
        arr = []
        calls.each_index do |ix|
          if ix > 1 # skip this method and the logging method
            arr << calls[ix]
          end
        end
        puts "#{arr.to_yaml}" if dbg
        if arr.length > 0
          list = 'TRACE:'
          arr.reverse.each { |l| list << "=>#{l}" }
          " [[#{list}]]"
        else
          nil
        end
      end

      def dump_array(arr, space_to_underscore = false)
        dump = "  #{arr.inspect}\n"
        arr.each_index do |x|
          value = arr[x].to_s
          value.gsub!(/\s/, '_') if space_to_underscore
          dump << " #{x.to_s.rjust(5)}>> '#{arr[x].to_s}'\n"
        end
        dump
      end

      def dump_ole_methods(ole)
        rtrn = ''
        ole.ole_methods.each do |m|
          prms = ''
          m.params.each do |p|
            prms << "#{p}, "
          end
          rtrn << "#{m.name}(#{prms.chop.chop})\n"
        end
        rtrn
      end

      def dump_ole_get_methods(ole)
        rtrn = ''
        ole.ole_get_methods.each do |m|
          prms = ''
          m.params.each do |p|
            prms << "#{p}, "
          end
          rtrn << "#{m.name}(#{prms.chop.chop})\n"
        end
        rtrn
      end

      def dump_ole_help(ole)
        rtrn = ''
        ole.ole_obj_help.each do |m|
          prms = ''
          m.params.each do |p|
            prms << "#{p}, "
          end
          rtrn << "#{m.name}(#{prms.chop.chop})\n"
        end
        rtrn
      end

      def dump_select_list_options(element, report = false)
        msg     = "#{element.inspect}"
        options = element.options
        cnt     = 1
        options.each do |o|
          msg << "\n\t#{cnt}:\t'#{o}"
          cnt += 1
        end
        if report
          debug_to_report(msg)
        else
          debug_to_log(msg)
        end
      end

      def dump_all_tables(browser, to_report = false)
        tables  = browser.tables
        msg     = ''
        tbl_cnt = 0
        tables.each do |tbl|
          tbl_cnt += 1
          row_cnt = 0
          msg <<"\n=================\ntable: #{tbl_cnt}\n=================\n#{tbl}\ntext:\n#{tbl.text}"
          tbl.rows.each do |row|
            row_cnt  += 1
            cell_cnt = 0
            msg <<"\n=================\ntable: #{tbl_cnt} row: #{row_cnt}\n#{row.inspect}\n#{row}\ntext:'#{row.text}'"
            row.each do |cell|
              cell_cnt += 1
              msg <<"\ncell: #{cell_cnt}\n#{cell.inspect}\n#{row}\ntext: '#{cell.text}'"
            end
          end
        end
        if to_report
          debug_to_report(msg)
        else
          debug_to_log(msg)
        end
      end

      def dump_table_and_rows(table, to_report = false)
        msg = "\n=================\ntable\n=================\nn#{table}\n#{table.to_yaml}\nrows:"
        cnt = 0
        table.rows.each do |r|
          cnt += 1
          msg << "\n#{cnt}: #{r.text}"
        end
        msg << "\n=================\n================="
        if to_report
          debug_to_report(msg)
        else
          debug_to_log(msg)
        end
      end

      def dump_table_rows_and_cells(tbl)
        msg     = ''
        row_cnt = 0
        msg <<"\n=================\ntable: #{tbl.inspect}\n=================\n#{tbl}\ntext:\n#{tbl.text}"
        tbl.rows.each do |row|
          row_cnt  += 1
          cell_cnt = 0
          msg <<"\n=================\nrow: #{row_cnt}\n#{row.inspect}\n#{row}\ntext:'#{row.text}'"
          row.each do |cell|
            cell_cnt += 1
            msg <<"\ncell: #{cell_cnt}\n#{cell.inspect}\n#{row}\ntext: '#{cell.text}'"
          end
        end
        debug_to_log(msg)
      end

      alias dump_table_rows dump_table_rows_and_cells

      def dump_row_cells(row)
        msg      = ''
        cell_cnt = 0
        msg <<"\n=================\nrow: #{row.inspect}\n#{row}\ntext:'#{row.text}'"
        row.each do |cell|
          cell_cnt += 1
          msg <<"\ncell: #{cell_cnt}\n#{cell.inspect}\n#{row}\ntext: '#{cell.text}'"
        end
        debug_to_log(msg)
      end

      def parse_cookies(browser)
        cookies = Hash.new
        strg    = browser.document.cookie
        ary     = strg.split(';')
        ary.each do |c|
          key, value          = c.split('=')
          cookies[key.lstrip] = value
        end
        cookies
      end

      def capture_screen(browser, ts)
        browser.maximize
        browser.bring_to_front
        caller = get_caller
        caller.match(/:(\d+):/)
        lnbr       = $1
        path       = "#{@myRoot}/screenshot/"
        screenfile = "#{@myName}_#{@myRun.id}_#{lnbr.to_s}_#{ts.to_f.to_s}.scrsht.jpg"
        info_to_log("path:#{path} screenfile:#{screenfile}")
        screenSpec = '"' + path + screenfile + '"'
        screenSpec.gsub!('/', '\\')
        screen_capture(screenSpec)
        screenfile
      end

      def pdf_to_text(file, noblank = true)
        spec = file.sub(/\.pdf$/, '')
        `pdftotext #{spec}.pdf`
        file = File.new("#{spec}.txt")
        text = []
        file.readlines.each do |l|
          l.chomp! if noblank
          if l.length > 0
            text << l
          end
        end
        file.close
        text
      end

      # @deprecated
      def flash_id(browser, strg, count)
        msg = "Flash link id='#{strg}' #{count} times."
        msg << " #{desc}" if desc.length > 0
        browser.link(:id, strg).flash(count)
        passed_to_log(msg)
        true
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      def flash(element, count = 4)
        element.flash(count)
        debug_to_log("'#{element.inspect}' flashed #{count} times.")
        true
      rescue
        debug_to_log("Flash '#{element.inspect}' failed: '#{$!}' (#{__LINE__})")
      end

      def get_save_file_path(root, filename)
        filespec = "#{root}/file/#{filename}"
        filespec.gsub!('/', '\\')
      end

      def save_file_orig(filepath, desc = '', wait = WAIT)
        #    title = translate_popup_title(title)
        @ai.WinWait("File Download", "", wait)
        @ai.ControlFocus("File Download", "", "&Save")
        sleep 1
        @ai.ControlClick("File Download", "", "&Save", "left")
        @ai.WinWait("Save As", "", wait)
        sleep 1
        @ai.ControlSend("Save As", "", "Edit1", filepath)
        @ai.ControlClick("Save As", "", "&Save", "left")
        sleep 1
        @ai.WinWait("Download complete", "", wait)
        @ai.ControlClick("Download complete", "", "Close")
      end

      #TODO This and save_file2 have to be combined somehow.
      def save_file1(filepath, title = "File Download", desc = '', wait = WAIT)
        title = translate_popup_title(title)
        @ai.WinWait(title, '', wait)
        @ai.WinActivate(title, '')
        sleep 1
        @ai.ControlFocus(title, "", "&Save")
        sleep 3
        @ai.ControlClick(title, "", "&Save", "primary")
        sleep 2
        @ai.ControlClick(title, "", "Save", "primary")

        @ai.WinWait("Save As", "", wait)
        sleep 1
        @ai.ControlSend("Save As", "", "Edit1", filepath)
        @ai.ControlFocus("Save As", "", "&Save")
        @ai.ControlClick("Save As", "", "&Save", "primary")
        @ai.ControlClick("Save As", "", "Save", "primary")

        @ai.WinWait("Download complete", "", wait)
        passed_to_log("Save file '#{filepath}' succeeded. #{desc}")
        @ai.ControlClick("Download complete", "", "Close")
      rescue
        failed_to_log("Save file failed: #{desc} '#{$!}'. (#{__LINE__})")
      end

      def save_file2(filepath, title = "File Download - Security Warning", desc = '', wait = WAIT)
        title = translate_popup_title(title)
        sleep(1)
        @ai.WinWait(title, '', wait)
        dl_hndl    = @ai.WinGetHandle(title, '')
        dl_sv_hndl = @ai.ControlGetHandle(title, '', "&Save")
        @ai.WinActivate(title, '')
        sleep 1
        @ai.ControlFocus(title, "", "&Save")
        sleep 1
        @ai.ControlFocus(title, "", "Save")
        sleep 1
        @ai.ControlClick(title, "", "&Save", "primary")
        sleep 1
        @ai.ControlClick(title, "", "Save", "primary")
        sleep 1
        w = WinClicker.new
        w.clickButtonWithHandle(dl_sv_hndl)
        sleep 1
        w.clickWindowsButton_hwnd(dl_hndl, "Save")
        sleep 1
        w.clickWindowsButton_hwnd(dl_hndl, "&Save")

        @ai.WinWait("Save As", "", wait)
        sleep 1
        @ai.ControlSend("Save As", "", "Edit1", filepath)
        @ai.ControlFocus("Save As", "", "&Save")
        @ai.ControlClick("Save As", "", "&Save", "primary")

        @ai.WinWait("Download complete", "", wait)
        passed_to_log("Save file '#{filepath}' succeeded. #{desc}")
        @ai.ControlClick("Download complete", "", "Close")
      rescue
        failed_to_log("Save file failed: #{desc} '#{$!}'. (#{__LINE__})")
      end

      #method for handling save dialog
      #use click_no_wait on the action that triggers the save dialog
      def save_file(filepath, download_title = "File Download - Security Warning")
        # TODO need version for Firefox
        # TODO need to handle first character underline, e.g. 'Cancel' and '&Cancel'
        download_title   = translate_popup_title(download_title)
        download_text    = ''
        download_control = "&Save"
        saveas_title     = 'Save As'
        saveas_text      = ''
        saveas_control   = "Edit1"
        dnld_cmplt_title = "Download Complete"
        dnld_cmplt_title = translate_popup_title(dnld_cmplt_title)
        dnld_cmplt_text  = ""
        #    save_title = ""
        side             = 'primary'
        msgdl            = "Window '#{download_title}':"
        msgsa            = "Window '#{saveas_title}':"
        msgdc            = "Window '#{dnld_cmplt_title}':"
        begin
          if @ai.WinWait(download_title, download_text, WAIT)
            @ai.WinActivate(download_title, download_text)
            if @ai.WinActive(download_title, download_text)
              dl_title = @ai.WinGetTitle(download_title, download_text)
              #          dl_hndl  = @ai.WinGetHandle(download_title, download_text)
              #          dl_text  = @ai.WinGetText(download_title, download_text)
              #          dl_sv_hndl = @ai.ControlGetHandle(dl_title, '', download_control)
              #          dl_op_hndl = @ai.ControlGetHandle(dl_title, '', '&Open')
              #          dl_cn_hndl = @ai.ControlGetHandle(dl_title, '', 'Cancel')
              debug_to_log("#{msgdl} activated. (#{__LINE__})")

              if @ai.ControlFocus(dl_title, download_text, download_control)
                debug_to_log("#{msgdl} focus gained. (#{__LINE__})")

                @ai.Send("S")
                #              @ai.ControlSend(dl_Stitle, download_text, download_control, "{ENTER}")
                sleep_for 1

                if @ai.ControlClick(dl_title, download_text, download_control, side)
                  debug_to_log("#{msgdl} click succeeded on '#{download_control}'. (#{__LINE__})")

                  if @ai.WinWait(saveas_title, saveas_text, WAIT)
                    debug_to_log("#{msgsa} appeared. (#{__LINE__})")
                    sleep_for 1
                    if @ai.ControlSend(saveas_title, saveas_text, saveas_control, filepath)
                      debug_to_log("#{msgsa} controlsend of '#{saveas_control}' succeeded. (#{__LINE__})")

                      @ai.Send("S")
                      @ai.ControlSend(saveas_title, saveas_text, saveas_control, "{ENTER}")
                      sleep_for 1

                      if @ai.ControlClick(saveas_title, saveas_text, saveas_control, side)
                        passed_to_log("#{msgsa} click succeeded on '#{saveas_control}'. (#{__LINE__})")
                        if @ai.WinWait(dnld_cmplt_title, dnld_cmplt_text, WAIT)
                          debug_to_log("#{msgdc} appeared. (#{__LINE__})")
                          sleep_for 1
                          if @ai.ControlClick(dnld_cmplt_title, dnld_cmplt_text, "Close", side)
                            passed_to_log("Save file for #{filepath} succeeded.")
                          else
                            failed_to_log("#{msgdc} click failed on 'Close'. (#{__LINE__})")
                          end
                        else
                          failed_to_log("#{msgdc} did not appear after #{WAIT} seconds. (#{__LINE__})")
                        end
                      else
                        failed_to_log("#{msgsa} click failed on '#{saveas_control}'. (#{__LINE__})")
                      end
                    else
                      failed_to_log("#{msgsa} controlsend of '#{saveas_control}' failed. (#{__LINE__})")
                    end
                  else
                    failed_to_log("#{msgsa} did not appear after #{WAIT} seconds. (#{__LINE__})")
                  end
                else
                  failed_to_log("#{msgdl} click failed on '#{download_control}'. (#{__LINE__})")
                end
              else
                failed_to_log("#{msgdl} Unable to gain focus on control '#{dl_title}'. (#{__LINE__})")
              end
            else
              failed_to_log("#{msgdl} Unable to activate. (#{__LINE__})")
            end
          else
            failed_to_log("#{msgdl} did not appear after #{WAIT} seconds. (#{__LINE__})")
          end
        rescue
          failed_to_log("Save file failed: '#{$!}'. (#{__LINE__})")
        end
      end

      #method for cancelling Print window
      # TODO need to handle 'Cancel' and '&Cancel' (first character underlined)
      def close_print(title = 'Print', text = '', button = '&Cancel', side = 'left')
        msg = "Popup: title=#{title} button='#{button}' text='#{text}' side='#{side}':"
        if @ai.WinWait(title, text, WAIT)
          passed_to_log("#{msg} found.")
          @ai.WinActivate(title)
          if @ai.WinActive(title, text)
            passed_to_log("#{msg} activated.")
            if @ai.ControlFocus(title, text, button)
              passed_to_log("#{msg} focus attained.")
              if @ai.ControlClick(title, text, button, side)
                passed_to_log("#{msg} closed successfully.")
              else
                failed_to_log("#{msg} click failed on button (#{__LINE__})")
              end
            else
              failed_to_log("#{msg} Unable to gain focus on button (#{__LINE__})")
            end
          else
            failed_to_log("#{msg} Unable to activate (#{__LINE__})")
          end
        else
          failed_to_log("#{msg} did not appear after #{WAIT} seconds. (#{__LINE__})")
        end
      rescue
        failed_to_log("Close #{msg}: '#{$!}'. (#{__LINE__})")
      end

      #method for handling file download dialog
      #use click_no_wait on the action that triggers the save dialog
      # TODO need version for Firefox
      # TODO need to handle 'Cancel' and '&Cancel' (first character underlined)
      # TODO replace call to close_modal_ie with actual file download
      def file_download(browser = nil)
        title  = 'File Download'
        title  = translate_popup_title(title)
        text   = ''
        button = 'Cancel'
        if @browserAbbrev == 'IE'
          close_popup(title, button, text)
        else

        end
      end

      #method for handling file upload dialog
      #use click_no_wait on the action that triggers the save dialog
      # TODO need version for Firefox
      def file_upload(filepath)
        title   = 'Choose File'
        title   = translate_popup_title(title)
        text    = ''
        button  = "&Open"
        control = "Edit1"
        side    = 'primary'
        msg     = "Window title=#{title} button='#{button}' text='#{text}' side='#{side}':"
        begin
          if @ai.WinWait(title, text, WAIT)
            passed_to_log("#{msg} found.")
            @ai.WinActivate(title, text)
            if @ai.WinActive(title, text)
              passed_to_log("#{msg} activated.")
              if @ai.ControlSend(title, text, control, filepath)
                passed_to_log("#{msg} #{control} command sent.")
                sleep_for 1
                if @ai.ControlClick(title, text, button, "primary")
                  passed_to_log("#{msg} Upload of #{filepath} succeeded.")
                else
                  failed_to_log("#{msg} Upload of #{filepath} failed. (#{__LINE__})")
                end
              else
                failed_to_log("#{msg} Unable to select #{filepath}. (#{__LINE__})")
              end
            else
              failed_to_log("#{msg} Unable to activate. (#{__LINE__})")
            end
          else
            failed_to_log("#{msg} did not appear after #{WAIT} seconds. (#{__LINE__})")
          end
        rescue
          failed_to_log("#{msg} Unable to upload: '#{$!}'. (#{__LINE__})")
        end

      end

      def upload_file(data_path)
        limit = 180 # .seconds
        Timeout::timeout(limit) {
          wait = 20
          @ai.WinWait("Choose File to Upload", "", wait)
          sleep 1
          @ai.ControlSend("Choose File to Upload", "", "Edit1", data_path)
          @ai.ControlClick("Choose File to Upload", "", "[CLASS:Button; INSTANCE:2]", "left")
          sleep 4
          #sleep 1
        }
        failed_to_log("Choose File to Upload not found after #{limit} '#{$!}'")
      rescue Timeout::Error
        failed_to_log("File Upload timeout after #{limit} '#{$!}'")
      end

      def focus_on_textfield_by_id(browser, strg, desc = '')
        msg = "Set focus on textfield name='#{strg}' "
        msg << " #{desc}" if desc.length > 0
        tf = browser.text_field(:id, strg)
        tf.focus
        passed_to_log(msg)
        true
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      # @deprecated
      def flash_text(browser, strg, count, desc = '')
        msg = "Flash link text='#{strg}' #{count} times."
        msg << " #{desc}" if desc.length > 0
        strgCnt = string_count_in_string(browser.text, strg)
        if strgCnt > 0
          browser.link(:text, strg).flash(count)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Link not found.")
        end
      rescue
        failed_to_log("Unable to #{msg} '#{$!}'")
      end

      def do_taskkill(severity, pid)
        if pid and pid > 0 and pid < 538976288
          info_to_log("Executing taskkill for pid #{pid}")
          log_message(severity, %x[taskkill /t /f /pid #{pid}])
        end
      rescue
        error_to_log("#{$!}  (#{__LINE__})")
      end

      def rescue_me_command(element, how, what, command = nil, param = nil, container = :browser)
        loc = "#{container}.#{element}(#{how}, #{what})"
        loc << ".#{command}" if command
        loc << "(#{param})" if param
        loc
      end

      def method_to_title(method, no_sub = false)
        title = method.to_s.titleize
        title.gsub!(/And/, '&') unless no_sub
        title
      rescue
        debug_to_log("#{__method__}: #{method} #{$!}")
      end

    end
  end
end
