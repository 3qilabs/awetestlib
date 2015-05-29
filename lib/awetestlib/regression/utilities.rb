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
        #    if $os.name =~ /Windows.+Server\s+2003/
        ##  'Microsoft(R) Windows(R) Server 2003, Enterprise Edition'
        #      @vertical_hack_ie   = 110
        #      @vertical_hack_ff   = 138
        #      @horizontal_hack_ie = 5
        #      @horizontal_hack_ff = 4
        #    elsif $os.name =~ /Windows XP Professional/
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

      def build_message(strg1, *strings)
        msg = "#{strg1}"
        strings.each do |strg|
          if strg.is_a?(Array)
            strg.each do |str|
              msg << " #{str}" if str and str.length > 0
            end
          else
            msg << " #{strg}" if strg and strg.length > 0
          end
        end if strings
        msg
      rescue
        failed_to_log(unable_to)
      end

      alias build_msg build_message
      alias bld_msg build_message

      def get_trace(lnbr)
        callertrace = "\nCaller trace: (#{lnbr})\n"
        Kernel.caller.each_index do |x|
          callertrace << '    >> ' + Kernel.caller[x].to_s + "\n"
        end
        callertrace
      end

      alias dump_caller get_trace

      def get_prefix(strg, offset)
        a_slice = strg.slice(0, offset)
        a_slice.downcase
      end

      def calc_index(index, every = 1)
        (index / every) + (every - 1)
      end

      def get_upload_file_control_indexes
        case $win_major
          when '5'
            case @browserAbbrev
              when 'IE'
                ['1', '1', '2', 'Choose File to Upload']
              when 'FF'
                ['1', '1', '2', 'File Upload']
              when 'GC', 'C'
                ['1', '1', '2', 'Open']
            end
          when '6'
            case @browserAbbrev
              when 'IE'
                ['1', '1', '2', 'Choose File to Upload']
              when 'FF'
                ['1', '1', '2', 'File Upload']
              when 'GC', 'C'
                ['1', '1', '2', 'Open']
            end
        end
      end

      def get_variables(file, key_type = :role, enabled_only = true, dbg = true)

        #TODO: support for xlsx files
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
            var_col              = col
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
        script_col   = 0
        role_col     = 0
        userid_col   = 0
        company_col  = 0
        password_col = 0
        url_col      = 0
        env_col      = 0
        name_col     = 0
        login_index  = find_sheet_with_name(workbook, 'Login')
        if login_index and login_index >= 0
          workbook.default_sheet = workbook.sheets[login_index]

          1.upto(workbook.last_column) do |col|
            a_cell = workbook.cell(1, col).downcase
            case a_cell
              when @myName.downcase
                script_col            = col
                script_found_in_login = true
                break
              when 'role'
                role_col = col
              when 'userid', 'user_id'
                userid_col = col
              when 'companyid', 'company_id'
                company_col = col
              when 'password'
                password_col = col
              when 'url'
                url_col = col
              when 'environment'
                env_col = col
              when 'name'
                name_col = col
            end
          end

          2.upto(workbook.last_row) do |line|
            role      = workbook.cell(line, role_col)
            userid    = workbook.cell(line, userid_col)
            password  = workbook.cell(line, password_col)
            url       = workbook.cell(line, url_col)
            env       = workbook.cell(line, env_col)
            username  = workbook.cell(line, name_col)
            companyid = workbook.cell(line, company_col)
            enabled   = workbook.cell(line, script_col).to_s

            case key_type
              when :id, :userid
                key = userid
              when :environment
                key = env
              when :role
                key = role
              else
                key = userid
            end

            if enabled_only and enabled.length == 0
              next
            end

            @login[key]              = Hash.new
            @login[key]['role']      = role
            @login[key]['userid']    = userid
            @login[key]['companyid'] = companyid
            @login[key]['password']  = password
            @login[key]['url']       = url
            @login[key]['name']      = username
            @login[key]['enabled']   = enabled

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
        failed_to_log(unable_to)
      end

      def translate_color_name(color)
        if color and color.length > 0
          HTML_COLORS[color.camelize.downcase].downcase
        else
          color
        end
      end

      def translate_tag_name(element)
        rtrn = ''
        tag  = ''
        typ  = ''
        if element.respond_to?(:tag_name)
          tag  = element.tag_name
          typ  = element.type if element.respond_to?(:type)
          rtrn = tag
          case tag
            when 'a'
              rtrn = 'link'
            when 'input'
              case typ
                when 'text'
                  rtrn = 'textfield'
                when 'textarea'
                  rtrn = 'textarea'
                when 'submit', 'button'
                  rtrn = 'button'
                else
                  rtrn = tag
              end
            else
              rtrn = tag
          end
        end
        rtrn
      rescue
        failed_to_log(unable_to(tag, typ))
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

      def get_awetestlib_metadata
        $metadata = YAML.load(`gem spec awetestlib metadata`.chomp)
      end

      def get_project_git(proj_dir = Dir.pwd)
        debug_to_log(with_caller(proj_dir))
        sha    = nil
        branch = nil
        date   = nil

        curr_dir = Dir.pwd

        if Dir.exists?(proj_dir)

          Dir.chdir(proj_dir) unless proj_dir == curr_dir

          if Dir.exists?('.git')
            require 'git'
            git    = Git.open(Dir.pwd)
            branch = git.current_branch
            commit = git.gblob(branch).log(5).first
            sha    = commit.sha
            date   = commit.date

            version_file = File.join(curr_dir, 'waft_version')
            file         = File.open(version_file, 'w')
            file.puts "#{branch}, #{date}, #{sha}"
            file.close

          end

          Dir.chdir(curr_dir) unless proj_dir == curr_dir

        end

        unless branch
          version_file = File.join(Dir.pwd, 'waft_version')
          if File.exists?(version_file)
            vers              = File.open(version_file).read
            branch, date, sha = parse_list(vers.chomp)
          end
        end

        [branch, date, sha]
      end

      def git_sha1(file)
        if File.exists?(file)
          size, sha1 = `ruby git_sha1.rb #{file}`.chomp.split(/\n/)
          debug_to_log("#{file} #{size} sha1 is #{sha1}")
        end
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

      def count_duplicates(arr)
        counts = {}
        dups   = {}
        arr.each do |id|
          counts[id] = counts[id] ? counts[id] + 1 : 1
          dups[id]   = counts[id] if counts[id] > 1
        end
        [dups, counts]
      end

      def debug_call_list(msg)
        call_array = get_call_array
        debug_to_log("#{msg}\n#{dump_array(call_array)}")
      end

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
        "['#{new_arr.join("', '")}']"
      end

      def nice_number(number, decimals = 0, dollars = false)
        number.to_s.gsub!(/[,\$]/, '')
        ptrn = "%0.#{decimals}f"
        ptrn = '$' + ptrn if dollars
        sprintf(ptrn, number).gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
      end

      def normalize_color_value(value, rgba = true)
        case value
          when /^#/
            html_to_rgb(value, rgba)
          when /^rgba/i
            value
          when /^rgb()/i
            rgb_to_rgba(value)
          when /^transparent/i, /^0$/i
            'rgba(0, 0, 0, 0)'
          when /white/
            'rgba(255, 255, 255, 1)'
          else
            html_to_rgb(translate_color_name(value), rgba)
        end
      end

      def number_to_word(nbr)
        map = { 1  => 'one', 2 => 'two', 3 => 'three', 4 => 'four', 5 => 'five',
                6  => 'six', 7 => 'seven', 8 => 'eight', 9 => 'nine', 10 => 'ten',
                11 => 'eleven', 12 => 'twelve', 13 => 'thirteen', 14 => 'fourteen', 15 => 'fifteen',
                16 => 'sixteen', 17 => 'seventeen', 18 => 'eighteen', 19 => 'nineteen', 20 => 'twenty'
        }
        if nbr > 20
          'more than twenty'
        else
          map[nbr]
        end
      end

      alias nbr2word number_to_word

      def string_array_numeric_sort(arr)
        #TODO: almost certainly a more 'rubyish' and less clunky way to do this
        trgt = arr.dup
        narr = []
        trgt.each do |n|
          narr << n.to_i
        end
        narr.sort!
        sarr = []
        narr.each do |n|
          sarr << n.to_s
        end
        sarr
      end

      alias strg_arr_numeric_sort string_array_numeric_sort

      def string_count_in_string(strg, substrg)
        count = strg.scan(substrg).length
        count
      end

      def string_to_hex(strg, format = 'U')
        strg.unpack(format*strg.length)
        # strg.split(//).collect do |x|
        #   x.match(/\d/) ? x : x.unpack('U')[0].to_s(16)
        # end
      end

      def strip_regex_mix(strg)
        rslt = strg.dup
        mtch = rslt.match(/(\(\?-mix:(.+)\))/)
        rslt.sub!(mtch[1], "/#{mtch[2]}/")
        rslt
      end

      def rescue_me(e, me = nil, what = nil, where = nil, who = nil)
        #TODO: these are rescues from exceptions raised in Watir or Watir-webdriver
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
        if msg =~ /undefined method\s+.join.\s+for/i # firewatir to_s implementation error
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
        elsif msg =~ /unable to locate element/i
          if located
            ok = true
          elsif where == 'Watir::Div'
            ok = true
          end
        elsif msg =~ /(The SafariDriver does not interact with modal dialogs)/i
          to_report = $1
          ok        = true
        elsif msg =~ /HRESULT error code:0x80070005/
          ok = true
          #elsif msg =~ /missing\s+\;\s+before statement/
          #  ok = true
        end
        call_list = get_call_list(6, true)
        if ok
          debug_to_log("#{__method__}: RESCUED: \n#{who.to_yaml}=> #{what} in #{me}()\n=> '#{$!}'")
          debug_to_log("#{__method__}: #{who.inspect}") if who
          debug_to_log("#{__method__}: #{where.inspect}")
          debug_to_log("#{__method__}: #{call_list}")
          failed_to_log("#{to_report}  #{call_list}")
        else
          debug_to_log("#{__method__}: NO RESCUE: #{e.message}")
          debug_to_log("#{__method__}: NO RESCUE: \n#{call_list}")
        end
        debug_to_log("#{__method__}: Exit")
        ok
      end

      def convert_color_value(value, rgba = false)
        if value =~ /^#/
          html_to_rgb(value, rgba)
        else
          rgb_to_html(value)
        end
      end

      def rgb_to_html(rgb)
        rgb =~ /rgba?\((.+)\)/
        if $1
          r, g, b, a = $1.split(/,\s*/)
          "#%02x%02x%02x" % [r, g, b]
        else
          rgb
        end
      end

      def rgb_to_rgba(rgb)
        if rgb =~ /^rgb\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\)/i
          r    = $1
          g    = $2
          b    = $3
          op   = rgb =~ /[1-9]/ ? '1' : '0'
          rtrn = "rgba(#{r}, #{g}, #{b}, #{op})" #waft-1148
        else
          rtrn = rgb
        end
        rtrn
      end

      def html_to_rgb(html, a = true)
        if html and html.length > 0
          html = html.gsub(%r{[#;]}, '')
          case html.size
            when 3
              colors = html.scan(%r{[0-9A-Fa-f]}).map { |el| (el * 2).to_i(16) }
            when 6
              colors = html.scan(%r<[0-9A-Fa-f]{2}>).map { |el| el.to_i(16) }
          end
          rgb = 'rgb'
          rgb << 'a' if a
          rgb << '('
          colors.each do |c|
            rgb << "#{c}, "
          end
          if a
            rgb << '1)'
          else
            rgb.strip!.chop!
            rgb << ')'
          end
          rgb
        else
          html
        end
      end

      def analyse_element_presence(container, element, how, what, max_seconds = 30, interval = 0.25)
        duration = 0
        code     = build_webdriver_fetch(element, how, what) + '.present?'
        debug_to_log("#{__method__}: code=>[#{code}")
        until duration > max_seconds do
          begin
            debug_to_log("#{eval(code)} #{duration}")
          rescue => e
            debug_to_log("#{__method__}: #{e.inspect}")
          end
          duration += interval
          sleep(interval)
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

      def dump_option_array(options, desc = '', to_report = false)
        msg = with_caller(desc, "\n")
        options.each do |option|
          msg << "text: '#{option.text}' value: '#{option.value}' selected: #{option.selected?}\n"
        end
        if to_report
          debug_to_report(msg)
        else
          debug_to_log(msg)
        end
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

      def parse_test_flag(string)
        test = false
        refs = nil
        if string
          if string == true or string == false
            test = string
          else
            if string.length > 0
              unless string =~ /^no$/i
                test = true
                unless string =~ /^yes$/i
                  refs = format_refs(string)
                end
              end
            end
          end
        end
        [test, refs]
      rescue
        failed_to_log(unable_to)
      end

      def build_webdriver_fetch(element, how, what, more = {})
        code = "container.#{element}(:#{how} => "
        what = escape_stuff(what) unless how == :index
        if what.is_a?(Regexp)
          code << "/#{what.source}/"
        elsif how == :index
          code << "#{what}"
        else
          code << "'#{what}'"
        end
        if more and not more.empty?
          more.each do |key, vlu|
            next if key == :desc or key == :flash or key == :exists_only
            code << ", :#{key} => "
            if vlu.is_a?(Regexp)
              code << "/#{vlu}/"
            elsif vlu.is_a?(String)
              code << "'#{vlu.gsub('/', '\/')}'"
            else
              code << "#{vlu}"
            end
          end
        end
        code << ')'
        #debug_to_log("code: '#{code}'")
        code
      rescue
        failed_to_log(unable_to)
      end

      def element_action_message(element, action, how = nil, what = nil, value = nil, desc = '', refs = '')
        name      = element.respond_to?(:tag_name) ? element.tag_name.upcase : element.to_s
        how, what = extract_locator(element, how)[1, 2] unless how and what
        build_message(desc, action, "#{name}",
                      (what ? "with #{how}=>'#{what}'" : nil),
                      (value ? "and value=>'#{value}'" : nil), refs)
      end

      def element_query_message(element, query, how = nil, what = nil, value = nil, desc = '', refs = '')
        if element.exists?
          name = element.respond_to?(:tag_name) ? element.tag_name.upcase : element.to_s
        else
          name = '(unknown)'
        end
        build_message(desc, "#{name}",
                      (what ? "with #{how}=>' #{what}'" : nil),
                      (value ? "and value=>'#{value}'" : nil),
                      query, refs)
      rescue
        failed_to_log(unable_to)
      end

      def end_processes(*names)
        pattern = ''
        names.each { |n| pattern << "#{n}|" }
        pattern.chop!
        # puts pattern
        targets = {}

        if USING_OSX
          p_io = IO.popen("ps axo comm,pid,sess,fname")
        else
          p_io = IO.popen("tasklist /nh")
        end

        p_io.readlines.each do |prc|
          # puts prc.chop
          if prc =~ /#{pattern}/
            name, pid    = prc.split(/\s+/)[0, 2]
            # puts "#{name} #{pid}"
            base         = File.basename(name)
            targets[pid] = base
          end
        end

        debug_to_log("End these processes:\n#{targets.to_yaml}")

        if USING_OSX
          kill_cmd = 'kill -9 @@@@@'
        else
          kill_cmd = 'taskkill /f /pid @@@@@'
        end

        targets.each do |pid, name|
          cmd = kill_cmd.sub('@@@@@', pid)
          debug_to_log("[#{cmd}]")
          kill_io = IO.popen(cmd, :err => :out)
          debug_to_log(kill_io.read.chomp)
        end

        if targets.length > 0
          sleep_for(10)
        end
      end

      def escape_stuff(strg)
        if strg.respond_to?(:dup)
          rslt = strg.dup
          unless rslt.is_a?(Regexp)
            if rslt.match(/[\/\(\)]/)
              rslt.gsub!('/', '\/')
              rslt.gsub!('(', '\(')
              rslt.gsub!(')', '\)')
              rslt = Regexp.new(rslt)
            end
          end
        else
          rslt = strg
        end
        rslt
      rescue
        failed_to_log(unable_to("#{rslt}"))
      end

      def extract_selected(selected_options, which = :text)
        arr = Array.new
        selected_options.each do |so|
          case which
            when :text
              arr << so.text
            else
              arr << so.value
          end
        end
        arr.sort
      rescue
        failed_to_log(unable_to)
      end

      def extract_locator(element, how = nil)
        # html_to_log(element)
        if element.respond_to?(:tag_name)
          tag = element.tag_name.to_sym
        else
          element = element.body.elements[0]
          tag     = element.tag_name.to_sym
        end
        what = nil
        case how
          when nil
            [:id, :name, :title, :class, :value].each do |attr|
              what = element.attribute_value(attr.to_s)
              if what and what.length > 0
                how = attr
                break
              end
            end
          else
            what = element.attribute_value(how.to_s)
        end
        # debug_to_log(with_caller("#{tag}:#{how}:#{what}"))
        [tag, how, what]
      rescue
        failed_to_log(unable_to(build_message(":#{tag}, :#{how}='#{what}'")))
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

      def flash(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        if @flash
          value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
          code                       = build_webdriver_fetch(element, how, what, options)
          target                     = eval(code)
          flash_element(target, desc, refs)
        end
      rescue
        failed_to_log(unable_to)
      end

      def flash_element(element, desc = '', refs = '')
        if @flash
          if element
            element.wd.location_once_scrolled_into_view
            # scroll_to(element.browser, element, desc, refs)
            if element.respond_to?(:flash)
              # sleep(0.1)
              element.flash
            end
          end
        end
      rescue
        failed_to_log(unable_to)
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

      def rotate_array(arr, stop = 0, index = 0, target = '')
        rotated = arr.dup
        length  = rotated.size
        (1..length).each do |itr|
          rotated.push(rotated.shift)
          if stop > 0
            break if itr == stop
          else
            break if rotated[index] == target
          end
        end
        rotated
      rescue
        failed_to_log(unable_to)
      end

      def running_thread_count
        running = Thread.list.select { |thread| thread.status == "run" }.count
        asleep  = Thread.list.select { |thread| thread.status == "sleep" }.count
        [running, asleep]
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
      def file_upload(filepath, title = 'Choose File', text = '', button = '&Open',
                      control = 'Edit1', side = 'primary')
        title = translate_popup_title(title)
        msg   = "Window title=#{title} button='#{button}' text='#{text}' side='#{side}':"
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

      def upload_file(browser, data_path, wait = 20)
        #mark_test_level(data_path)
        message_to_report(with_caller(data_path))
        data_path.gsub!('/', '\\') if USING_WINDOWS

        file, open, cancel, title = get_upload_file_control_indexes

        @ai.WinWait(title, "", wait)
        sleep_for(1)
        @ai.ControlSend(title, '', "[CLASS:Edit; INSTANCE:#{file}]", '!u')
        @ai.ControlSetText(title, '', "[CLASS:Edit; INSTANCE:#{file}]", data_path)
        sleep_for(0.5)
        @ai.ControlClick(title, "", "[CLASS:Button; INSTANCE:#{open}]", "primary")

      rescue
        failed_to_log(unable_to)
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

      def rescue_msg_for_validation(desc, refs = nil)
        failed_to_log(unable_to(build_message(desc, refs), NO_DOLLAR_BANG, VERIFY_MSG), 2)
      end

      def method_to_title(method, no_sub = false, subs = { /And/ => '&', /^Ac / => 'AC ' })
        title = method.to_s.titleize
        unless no_sub
          subs.each do |ptrn, rplc|
            title.gsub!(ptrn, rplc)
          end
        end
        title
      rescue
        debug_to_log(unable_to(": #{method}"))
      end

      def unable_to(message = '', no_dolbang = false, verify_that = false, caller_index = 1)
        call_arr = get_call_array
        puts call_arr
        call_script, call_line, call_meth = parse_caller(call_arr[caller_index])
        strg                              = "Unable to"
        strg << " verify" if verify_that
        strg << " #{call_meth.titleize}:"
        strg << '?' if call_meth =~ /\?/
        strg << ':'
        strg << " #{message}" if message.length > 0
        strg << " '#{$!}'" unless no_dolbang
        strg
      end

      def pad_id_end_count(id, delim = '_', pad = 6)
        mtch = id.match(/^(.*)#{delim}(\d+)$/)
        mtch[1] + delim + mtch[2].rjust(pad, '0')
      rescue
        failed_to_log(unable_to("id: '#{id}' delim: '#{delim}' pad: #{pad}"))
      end

      def parse_caller(caller)
        call_script, call_line, call_meth = caller.split(':')
        call_script.gsub!(/\.rb/, '')
        call_script = call_script.camelize
        call_meth =~ /in .([\w\d_]+)./
        call_meth = $1
        [call_script, call_line, call_meth]
      end

      def insert_id_pswd_in_url(userid, password, url)
        http = url.match(/^(http)(s?)(:\/\/)/)
        path = url.gsub(http[0], '')
        URI.encode("#{http[0]}#{userid}:#{password}@#{path}")
      end

      def get_basic_auth_control_indexes
        case $win_major
          when '5'
            case @browserAbbrev
              when 'IE'
                ['2', '3', '1', 'Connect to']
              when 'FF'
                ['2', '3', '1', 'Authentication Required']
              when 'GC', 'C'
                ['2', '1', '2', 'Authentication Required']
            end
          when '6'
            case @browserAbbrev
              when 'IE'
                ['1', '2', '2', 'Windows Security']
              when 'FF'
                ['2', '1', '2', 'Authentication Required']
              when 'GC', 'C'
                ['2', '1', '2', 'Authentication Required']
            end
        end
      end

      def windows_to_log(browser)
        msg = ("===== Current windows (#{where_am_i?(2)})")
        idx = 0
        browser.windows.each do |w|
          msg << "\n  #{idx}: #{w.title} current?=#{w.current?}" #" (#{w.url})"
          idx += 1
        end
        debug_to_log(msg)
      rescue => e
        debug_to_log(unable_to("#{where_am_i?(2)}: #{e.inspect}"))
      end

      # def where_am_i?(index = 1)
      #   get_call_list_new[index].to_s
      # end

      def get_windows_version
        ver          = `ver`.gsub("\n", '')
        mtch         = ver.match(/(.*)\s\[Version\s*(\d+)\.(\d+)\.(\d+)\]/)
        $win_name    = mtch[1]
        $win_major   = mtch[2]
        $win_minor   = mtch[3]
        $win_build   = mtch[4]
        $win_version = "#{$win_major}.#{$win_minor}.#{$win_build}"
      rescue
        failed_to_log(unable_to)
      end

      def set_env_name(xls = @xls_path, fix = :prefix, strg = 'toad')
        if fix == :prefix
          pattern = /#{strg}_([\w\d]+)\.xls$/
        else
          pattern = /([\w\d]+)_#{strg}\.xls$/
        end
        if awetestlib?
          if @runenv
            @env_name = @myAppEnv.name.downcase.underscore
          else
            @env_name = 'dev'
            #if xls
            #  xls =~ pattern
            #  @env_name = $1
            #else
            #  @env_name = 'sit'
            #end
          end
        else
          @env_name = @myAppEnv.name.downcase # .underscore #.gsub(/^toad./, '')
        end
        debug_to_report("#{__LINE__}: @env_name=#{@env_name}")
      rescue
        failed_to_log(unable_to)
      end

      def set_xls_spec(proj_acro = 'unknown', env = @env_name.downcase.underscore, fix = :prefix, xlsx = @xlsx)
        env = env.split(/:[\s_]*/)[1] if env =~ /:/
        case fix
          when :prefix
            xls_name = "#{proj_acro}_#{env}.xls"
          when :suffix
            xls_name = "#{env}_#{proj_acro}.xls"
          when :none
            xls_name = "#{env.gsub('-', '_')}.xls"
          else
            failed_to_log(with_caller("Unknown fix type: '#{fix}'.  Must be 'prefix', 'suffix', or 'none'."))
            return nil
        end
        spec = "#{@myRoot}/#{xls_name}"
        spec << 'x' if xlsx
        debug_to_log("#{where_am_i?}: #{spec}")
        spec
      rescue
        failed_to_log(unable_to)
      end

      def format_refs(list)
        refs = ''
        if list
          list.split(/,\s*/).each do |ref|
            refs << "*** #{ref} *** "
          end
        end
        refs
      end

      def force_regexp(target)
        if target.respond_to?(:dup)
          rslt = target.dup
          unless rslt.is_a?(Regexp)
            rslt = Regexp.new(Regexp.escape(target.to_s))
          end
        else
          rslt = target
        end
        rslt
      rescue
        failed_to_log(unable_to("'#{target}'"))
      end

      def force_string(target, slash_regexp = true)
        if target
          if target.respond_to?(:dup)
            rslt = target.dup
            if rslt.is_a?(Regexp)
              if slash_regexp
                rslt = "/#{rslt.source}/"
              else
                rslt = rslt.source
              end
            end
          else
            rslt = target.to_s
          end
        else
          rslt = ''
        end
        rslt
      rescue
        failed_to_log(unable_to("'#{target}'"))
      end

      def array_neighbors(arr, target)
        less_than    = []
        greater_than = []
        arr.each do |elmt|
          if elmt < target
            less_than << elmt
          elsif elmt > target
            greater_than << elmt
          end
        end
        [less_than.max, greater_than.min]
      end

      def array_to_list(arr, delim = ',')
        list = ''
        arr.each do |entry|
          if entry =~ /#{delim}/
            list << "\"#{entry}\""
          else
            list << entry
          end
          list << "#{delim} " unless entry == arr.last
        end
        list
      end

      alias arr2list array_to_list

      def awetestlib?
        defined? Awetestlib::Runner
      rescue
        return false
      end

      def get_os
        $os = OpenStruct.new(
            :name     => Sys::Uname.sysname,
            :version  => Sys::Uname.version,
            :release  => Sys::Uname.release,
            :nodename => Sys::Uname.nodename,
            :machine  => Sys::Uname.machine
        )
      end

    end
  end
end
