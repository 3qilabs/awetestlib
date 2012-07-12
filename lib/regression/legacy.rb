module Legacy

  def run
    setup
    set_script_variables
    run_test
  rescue
    fatal_to_log("(#{__LINE__})  #{$!}")
    browser.close
    raise
  end

  #TODO replace with method_missing?
  #    place holder to prevent method not found error in scripts
  def set_script_variables
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

  def sleep_for(seconds, dbg = true, desc = '')
    msg = "Sleeping for #{seconds} seconds."
    msg << " #{desc}" if desc.length > 0
    msg << "\n#{get_debug_list}" if dbg
    info_to_log(msg)
    sleep(seconds)
  end

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

  def token_auth(browser, role, token, id = 'token_pass')
    set_textfield_by_id(browser, id, token)
    click_button_by_value(browser, 'Continue')
    if validate_text(browser, 'The requested page requires authentication\.\s*Please enter your Passcode below', nil, true)
      bail_out(browser, __LINE__, "Token authorization failed on '#{token}'")
    end
  end

  def calc_index(index, every = 1)
    (index / every) + (every - 1)
  end

=begin rdoc
tags: data, DOM, page
browser is any container element.  Best to use is the smallest that contains the desired data.
types defaults to all of: :text, :textarea, :select_list, :span, :hidden, :checkbox, and :radio
Set types to array of subset if fewer elements are desired.
returns a single hash:
---
:name:
  :span: {}
  :textarea: {}
  :radio: {}
  :checkbox: {}
  :hidden: {}
  :select_list: {}
  :text: {}
:index:
  :span: {}
  :textarea: {}
  :radio: {}
  :checkbox: {}
  :hidden: {}
  :select_list: {}
  :text: {}
:id:
  :span: {}
  :textarea: {}
  :radio: {}
  :checkbox: {}
  :hidden: {}
  :select_list: {}
  :text: {}

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
tags: data, DOM
data is output of capture_page_data().
how is one of :id, :name, :index
what is the target value for how
type is one of :text,:textarea,:select_list,:span,:hidden,:checkbox,:radio
get_text is used for select_list to choose selected option value or text (default)
note that multiple selections will be captured as arrays so value and text.
Not tested with multiple selections (02aug2011)
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

  def bail_out(browser, lnbr, msg)
    ts  = Time.new
    msg = "Bailing out at util line #{lnbr} #{ts} " + msg
    puts "#{msg}"
    fatal_to_log(msg, nil, 1, lnbr)
    debug_to_log(dump_caller(lnbr))
    if is_browser?(browser)
      if @browserAbbrev == 'IE'
        hwnd = browser.hwnd
        kill_browser(hwnd, lnbr, browser)
        raise(RuntimeError, msg, caller)
      elsif @browserAbbrev == 'FF'
        debug_to_log("#{browser.inspect}")
        debug_to_log("#{browser.to_s}")
        raise(RuntimeError, msg, caller)
      end
    end
    @status = 'bailout'
    raise(RuntimeError, msg, caller)
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

=begin rdoc
tags: data, DOM
browser is any container element.  best to use is the smallest that contains the desired data.
type is one of these symbols: :text,:textarea,:select_list,:span,:hidden,:checkbox,:radio
returns three hashes: id[type][id] = value, name[type][id] = value, index[type][id] = value
a given element appears once in the set of hashes depending on how is is found:  id first
then name, then index.
select list value is in the form 'value::text'. parse with x.split('::')
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

  def kill_browser(hwnd, lnbr, browser = nil, doflag = false)
    # TODO Firefox
    logit = false
    if @browserAbbrev == 'FF'
      if is_browser?(browser) # and browser.url.length > 1
        logit = true
        here  = __LINE__
        url   = browser.url
        capture_screen(browser, Time.new.to_f) if @screenCaptureOn
        browser.close if url.length > 0
        @status = 'killbrowser'
        fatal_to_log("Kill browser called from line #{lnbr}")
      end
    elsif hwnd
      pid = Watir::IE::Process.process_id_from_hwnd(hwnd)
      if pid and pid > 0 and pid < 538976288
        if browser.exists?
          here  = __LINE__
          logit = true
          url   = browser.url
          capture_screen(browser, Time.new.to_f) if @screenCaptureOn
          browser.close
          sleep(2)
          if browser.exists?
            do_taskkill(FATAL, pid)
          end
          @status = 'killbrowser'
        end
      end
      if logit
        debug_to_log("#{@browserName} window hwnd #{hwnd} pid #{pid} #{url} (#{here})")
        fatal_to_log("Kill browser called from line #{lnbr}")
      end
    end
  end

  def do_taskkill(severity, pid)
    if pid and pid > 0 and pid < 538976288
      info_to_log("Executing taskkill for pid #{pid}")
      log_message(severity, %x[taskkill /t /f /pid #{pid}])
    end
  rescue
    error_to_log("#{$!}  (#{__LINE__})")
  end

  def check_for_other_browsers
    cnt1 = find_other_browsers
    cnt2 = Watir::Process.count 'iexplore.exe'
    debug_to_log("check_for_other_browsers: cnt1: #{cnt1} cnt2: #{cnt2}")
  rescue
    error_to_log("#{$!}  (#{__LINE__})\n#{Kernel.caller.to_yaml}")
  end

  def check_for_and_clear_other_browsers
    if @targetBrowser.abbrev == 'IE'
      debug_to_log("#{__method__}:")
      cnt1 = find_other_browsers
      cnt2 = Watir::IE.process_count
      debug_to_log("#{__method__}: cnt1: #{cnt1} cnt2: #{cnt2}")
      begin
        Watir::IE.each do |ie|
          pid = Watir::IE::Process.process_id_from_hwnd(ie.hwnd)
          debug_to_log("#{__method__}: Killing browser process: hwnd #{ie.hwnd} pid #{pid} title '#{ie.title}' (#{__LINE__})")
          do_taskkill(INFO, pid)
          sleep_for(10)
        end
        #Watir::IE.close_all()
      rescue
        debug_to_log("#{__method__}: #{$!}  (#{__LINE__})")
      end
      sleep(3)
      cnt1 = find_other_browsers
      cnt2 = Watir::IE.process_count
      if cnt1 > 0 or cnt2 > 0
        debug_to_log("#{__method__}:cnt1: #{cnt1} cnt2: #{cnt2}")
        begin
          Watir::IE.each do |ie|
            pid = Watir::IE::Process.process_id_from_hwnd(ie.hwnd)
            debug_to_log("#{__method__}: Killing browser process: hwnd #{ie.hwnd} pid #{pid} title '#{ie.title}' (#{__LINE__})")
            do_taskkill(INFO, pid)
            sleep_for(10)
          end
          #Watir::IE.close_all()
        rescue
          debug_to_log("#{__method__}:#{$!}  (#{__LINE__})")
        end
      end
    end
  rescue
    error_to_log("#{__method__}: #{$!}  (#{__LINE__})\n#{Kernel.caller.to_yaml}")
  end

  #def attach_browser(browser, how, what)
  #  debug_to_log("Attaching browser window :#{how}=>'#{what}' ")
  #  uri_decoded_pattern = URI.encode(what.to_s.gsub('(?-mix:', '').gsub(')', ''))
  #  case @browserAbbrev
  #  when 'IE'
  #    tmpbrowser         = Watir::IE.attach(how, what)
  #    browser.visible    = true
  #    tmpbrowser.visible = true
  #    tmpbrowser.speed   = :fast
  #    tmpbrowser
  #  when 'FF'
  #    tmpbrowser = FireWatir::Firefox.attach(how, /#{uri_decoded_pattern}/)
  #  when 'S'
  #    Watir::Safari.attach(how, what)
  #    tmpbrowser = browser
  #  when 'C'
  #    browser.window(how, /#{uri_decoded_pattern}/).use
  #    tmpbrowser = browser
  #  end
  #  debug_to_log("#{__method__}: tmpbrowser:#{tmpbrowser.inspect}")
  #  tmpbrowser
  #end
  #
  def attach_browser(browser, how, what, desc = '')
    debug_to_log("Attaching browser window :#{how}=>'#{what}' #{desc}")
    uri_decoded_pattern = URI.encode(what.to_s.gsub('(?-mix:', '').gsub(')', ''))
    case @browserAbbrev
      when 'IE'
        tmpbrowser      = Watir::IE.attach(how, what)
        browser.visible = true
        if tmpbrowser
          tmpbrowser.visible = true
          tmpbrowser.speed   = :fast
        else
          raise "Browser window :#{how}=>'#{what}' has at least one doc not in completed ready state."
        end
      when 'FF'
        #TODO: This may be dependent on Firefox version if webdriver doesn't support 3.6.17 and below
        browser.driver.switch_to.window(browser.driver.window_handles[0])
        browser.window(how, /#{uri_decoded_pattern}/).use
        tmpbrowser = browser
      when 'S'
        Watir::Safari.attach(how, what)
        tmpbrowser = browser
      when 'C'
        browser.window(how, /#{uri_decoded_pattern}/).use
        tmpbrowser = browser
    end
    debug_to_log("#{__method__}: tmpbrowser:#{tmpbrowser.inspect}")
    tmpbrowser
  end

  def attach_browser_by_url(browser, pattern, desc = '')
    attach_browser(browser, :url, pattern, desc)
  end

  alias attach_browser_with_url attach_browser_by_url

  def attach_popup(browser, how, what, desc = '')
    msg   = "Attach popup :#{how}=>'#{what}'. #{desc}"
    popup = attach_browser(browser, how, what, desc)
    sleep_for(1)
    debug_to_log("#{popup.inspect}")
    if is_browser?(popup)
      title = popup.title
      passed_to_log("#{msg} title='#{title}'")
      return popup
    else
      failed_to_log(msg)
    end
  rescue
    failed_to_log("Unable to attach popup :#{how}=>'#{what}'. #{desc} '#{$!}' (#{__LINE__})")
  end

  def attach_popup_by_title(browser, strg, desc = '')
    attach_popup(browser, :title, strg, desc)
  end

  def attach_popup_by_url(browser, pattern, desc = '')
    attach_popup(browser, :url, pattern, desc)
  end

  alias get_popup_with_url attach_popup_by_url
  alias attach_popup_with_url attach_popup_by_url
  alias attach_iepopup attach_popup_by_url

  def clear_checkbox(browser, how, what, value = nil, desc = '')
    msg = "Clear checkbox #{how}=>'#{what}'"
    msg << " ('#{value}')" if value
    msg << " #{desc}'" if desc.length > 0
    browser.checkbox(how, what).clear
    if validate(browser, @myName, __LINE__)
      passed_to_log(msg)
      true
    end
  rescue
    failed_to_log("Unable to #{msg} '#{$!}'")
  end

  def clear_checkbox_by_name(browser, strg, value = nil, desc = '')
    clear_checkbox(browser, :name, strg, value, desc)
  end

  def clear_checkbox_by_id(browser, strg, value = nil, desc = '')
    clear_checkbox(browser, :id, strg, value, desc)
  end

  def find_other_browsers
    cnt = 0
    if @targetBrowser.abbrev == 'IE'
      Watir::IE.each do |ie|
        debug_to_log("#{ie.inspect}")
        ie.close()
        cnt = cnt + 1
      end
    end
    debug_to_log("Found #{cnt} IE browser(s).")
    return cnt
  rescue
    error_to_log("#{$!}  (#{__LINE__})\n#{Kernel.caller.to_yaml}", __LINE__)
    return 0
  end

  def get_trace(lnbr)
    callertrace = "\nCaller trace: (#{lnbr})\n"
    Kernel.caller.each_index do |x|
      callertrace << '    >> ' + Kernel.caller[x].to_s + "\n"
    end
    callertrace
  end

  alias dump_caller get_trace

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

  def get_variables(file, login = :role, dbg = true)
    debug_to_log("#{__method__}: file = #{file}")
    debug_to_log("#{__method__}: role = #{login}")

    @var                   = Hash.new
    workbook               = Excel.new(file)
    data_index             = find_sheet_with_name(workbook, 'Data')
    workbook.default_sheet = workbook.sheets[data_index]
    var_col                = 0

    2.upto(workbook.last_column) do |col|
      scriptName = workbook.cell(1, col)
      if scriptName == @myName
        var_col = col
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
    role_index   = find_sheet_with_name(workbook, 'Login')
    if role_index >= 0
      workbook.default_sheet = workbook.sheets[role_index]

      1.upto(workbook.last_column) do |col|
        a_cell = workbook.cell(1, col)
        case a_cell
          when @myName
            login_col = col
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

        case login
          when :id
            key = userid
          when :role
            key = role
          else
            key = role
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
        message_tolog("@login (by #{login}): #{key}=>'#{@login[key].to_yaml}'")
      end if dbg
    end

  rescue
    fatal_to_log("#{__method__}: '#{$!}'")
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

  # TODO ugly, gotta lose the hardcoding...
  def decode_options(strg)
    idx      = 0
    @options = Hash.new
    strg.each_char do |c|
      idx = idx + 1
      case idx
        when 1
          @options['load'] = c.to_i
        when 2
          @options['screenshot'] = c.to_i
          if c.to_i > 0
            @screenCaptureOn = true
          end
        when 3
          @options['hiderun'] = c.to_i
        #      when 4
        #        @options['another'] = c.to_i
      end

    end
    #    puts @options.to_yaml
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

  def sec2hms(s)
    Time.at(s.to_i).gmtime.strftime('%H:%M:%S')
  end

  def select(browser, how, what, which, value, desc = '')
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

  # TODO add check that both list and option exist
  def select_option_by_name_and_index(browser, strg, idx)
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
    msg << "('#{value.to_s}')" if value
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

  def set_checkbox(browser, how, what, desc = '')
    set(browser, :checkbox, how, what, nil, desc)
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
    if how == :value
      set_radio_by_value(browser, what, desc)
    else
      set(browser, :radio, how, what, value, desc)
    end
  rescue
    failed_to_log("#{msg} '#{$!}'")
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
    set(browser, :radio, :index, index, nil, desc)
  end

  def set_radio_by_name(browser, strg, value = nil, desc = '')
    set(browser, :radio, :name, strg, value, desc)
  end

  def set_radio_by_title(browser, strg, value = nil, desc = '')
    set(browser, :radio, :title, strg, value, desc)
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

  def set_radio_by_value(browser, strg, desc = '')
    msg = "Radio :value=>'#{strg}' "
    msg << " '#{desc}' " if desc.length > 0
    browser.radio(:value, strg).set
    if validate(browser, @myName, __LINE__)
      passed_to_log(msg)
      true
    end
  rescue
    failed_to_log("#{msg} '#{$!}'")
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
    set(browser, :radio, :name, strg, value, desc)
  end

# No validation
  def clear(browser, element, how, what, value = nil, desc = '')
    msg = "Clear #{element} #{how}=>'#{what}' "
    msg << "('#{value.to_s}')" if value
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

  def clear_radio(browser, how, what, value = nil, desc = '')
    msg = "Clear radio #{how}=>'#{what.to_s}' "
    msg << "('#{value.to_s}')" if value
    msg << " '#{desc}' " if desc.length > 0
    radio = browser.radio(how, what, value)
    radio.clear
    if validate(browser, @myName, __LINE__)
      passed_to_log(msg)
      true
    end
  rescue
    failed_to_log("#{msg} '#{$!}'")
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

  def close_window_by_title(browser, title, desc = '', text = '')
    msg = "Window '#{title}':"
    if @ai.WinWait(title, text, WAIT) > 0
      passed_to_log("#{msg} appeared. #{desc}")
      myHandle  = @ai.WinGetHandle(title, text)
      full_text = @ai.WinGetText(title)
      debug_to_log("#{msg} hwnd: #{myHandle.inspect}")
      debug_to_log("#{msg} title: '#{title}' text: '#{full_text}'")
      if @ai.WinClose(title, text) > 0
        passed_to_log("#{msg} closed successfully. #{desc}")
      else
        failed_to_log("#{msg} close failed. (#{__LINE__}) #{desc}")
      end
    else
      failed_to_log("#{msg} did not appear after #{WAIT} seconds. (#{__LINE__}) #{desc}")
    end
  rescue
    failed_to_log("#{msg}: Unable to close: '#{$!}'. (#{__LINE__}) #{desc}")
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

# Set skip_value_check = true when string is altered by application and/or
# this method will be followed by validate_text
  def set_textfield_by_id(browser, id, value, desc = '', skip_value_check = false)
    set_text_field(browser, :id, id, value, desc, skip_value_check)
  end

  def set_textfield_by_title(browser, title, value, desc = '', skip_value_check = false)
    set_text_field(browser, :title, title, value, desc, skip_value_check)
  end

  def set_textfield_by_class(browser, strg, value, desc = '', skip_value_check = false)
    set_text_field(browser, :class, strg, value, desc, skip_value_check)
  end

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
category: Logon
tags: logon, login, user, password, url
TODO: Needs to be more flexible about finding login id and password textfields
TODO: Parameterize url and remove references to environment
=end
  def login(browser, user, password)
    myURL  = @myAppEnv.url
    runenv = @myAppEnv.nodename
    message_tolog("URL: #{myURL}")
    message_tolog("Beginning login: User: #{user} Environment: #{runenv}")
    if validate(browser, @myName, __LINE__)
      browser.goto(myURL)
      if validate(browser, @myName)
        set_textfield_by_name(browser, 'loginId', user)
        set_textfield_by_name(browser, 'password', password)
        click_button_by_value(browser, 'Login')
        if validate(browser, @myName)
          passed_to_log("Login successful.")
        end
      else
        failed_to_log("Unable to login to application: '#{$!}'")
        #          screen_capture( "#{@myRoot}/screens/#{myName}_#{@runid}_#{__LINE__.to_s}_#{Time.new.to_f.to_s}.jpg")
      end
    end
  rescue
    failed_to_log("Unable to login to application: '#{$!}'")
  end

=begin rdoc
category: Logon
tags: logon, login, user, password, url, basic authorization
=end
  def basic_auth(browser, user, pswd, url, bypass_validate = false)
    mark_testlevel("Basic Authorization Login", 0)

    message_to_report ("Login:    #{user}")
    message_to_report ("URL:      #{url}")
    message_to_report ("Password: #{pswd}")

    @login_title = "Connect to"

    a = Thread.new {
      browser.goto(url)
    }

    sleep_for(2)
    message_to_log("#{@login_title}...")

    if (@ai.WinWait(@login_title, "", 90) > 0)
      win_title = @ai.WinGetTitle(@login_title)
      debug_to_log("Basic Auth Login window appeared: '#{win_title}'")
      @ai.WinActivate(@login_title)
      @ai.ControlSend(@login_title, '', "[CLASS:Edit; INSTANCE:2]", '!u')
      @ai.ControlSend(@login_title, '', "[CLASS:Edit; INSTANCE:2]", user, 1)
      @ai.ControlSend(@login_title, '', "[CLASS:Edit; INSTANCE:3]", pswd.gsub(/!/, '{!}'), 1)
      @ai.ControlClick(@login_title, "", '[CLASS:Button; INSTANCE:1]')
    else
      debug_to_log("Basic Auth Login window did not appear.")
    end
    a.join

    validate(browser, @myName) unless bypass_validate

    message_to_report("URL: [#{browser.url}] User: [#{user}]")

  end

  def logout(browser, where = @myName, lnbr = __LINE__)
    #TODO Firewatir 1.6.5 does not implement .exists for FireWatir::Firefox class
    debug_to_log("Logging out in #{where} at line #{lnbr}.", lnbr, true)
    debug_to_log("#{__method__}: browser: #{browser.inspect} (#{__LINE__})")

    if ['FF', 'S'].include?(@browserAbbrev) || browser.exists?
      case @browserAbbrev
        when 'FF'
          if is_browser?(browser)
            url   = browser.url
            title = browser.title
            debug_to_log("#{__method__}: Firefox browser url: [#{url}]")
            debug_to_log("#{__method__}: Firefox browser title: [#{title}]")
            debug_to_log("#{__method__}: Closing browser: #{where} (#{lnbr})")
            if url and url.length > 1
              browser.close
            else
              browser = FireWatir::Firefox.attach(:title, title)
              browser.close
            end

          end
        when 'IE'
          hwnd = browser.hwnd
          pid  = Watir::IE::Process.process_id_from_hwnd(hwnd)
          debug_to_log("#{__method__}: Closing browser: hwnd #{hwnd} pid #{pid} #{where} (#{lnbr}) (#{__LINE__})")
          browser.close
          if browser.exists? and pid > 0 and pid < 538976288 # value of uninitialized memory location
            debug_to_log("Retry close browser: hwnd #{hwnd} pid #{pid} #{where} #{lnbr} (#{__LINE__})")
            browser.close
          end
          if browser.exists? and pid > 0 and pid < 538976288 # value of uninitialized memory location
            kill_browser(browser.hwnd, __LINE__, browser, true)
          end
        when 'S'
          if is_browser?(browser)
            url   = browser.url
            title = browser.title
            debug_to_log("Safari browser url: [#{url}]")
            debug_to_log("Safari browser title: [#{title}]")
            debug_to_log("Closing browser: #{where} (#{lnbr})")
            close_modal_s # to close any leftover modal dialogs
            browser.close
          end
        when 'C'
          if is_browser?(browser)
            url   = browser.url
            title = browser.title
            debug_to_log("Chrome browser url: [#{url}]")
            debug_to_log("Chrome browser title: [#{title}]")
            debug_to_log("Closing browser: #{where} (#{lnbr})")
            if url and url.length > 1
              browser.close
              #else
              #browser = FireWatir::Firefox.attach(:title, title)
              #browser.close
            end

          end
        else
          raise "Unsupported browser: '#{@browserAbbrev}'"
      end
    end
    #  rescue => e
    #    if not e.is_a?(Vapir::WindowGoneException)
    #      raise e
    #    end
  end

  #close popup in new window
  def close_new_window_popup(popup)
    if is_browser?(popup)
      url = popup.url
      debug_to_log("Closing popup '#{url}' ")
      popup.close

    end
  end

  def close_panel_by_text(browser, panel, strg = 'Close')
    if validate(browser, @myName, __LINE__)
      if @browserAbbrev == 'IE'
        panel.link(:text, strg).click!
      elsif $USE_FIREWATIR
        begin
          panel.link(:text, strg).click
        rescue => e
          if not rescue_me(e, __method__, "link(:text,'#{strg}').click", "#{panel.class}")
            raise e
          end
        end
      else
        panel.link(:text, strg).click(:wait => false)
      end
      sleep_for(1)
      if validate(browser, @myName, __LINE__)
        passed_to_log("Panel '#{strg}' (by :text) closed.")
        true
      end
    else
      failed_to_log("Panel '#{strg}' (by :text) still open.")
    end
  rescue
    failed_to_log("Click on '#{strg}'(by :text) failed: '#{$!}' (#{__LINE__})")
  end

  #  def close_modal_ie(title="", button="OK", text='', side = 'primary', wait = WAIT)
  def close_popup(title, button = "OK", text = '', side = 'primary', wait = WAIT, desc = '', quiet = false)
    #TODO needs simplifying and debug code cleaned up
    title = translate_popup_title(title)
    msg   = "'#{title}'"
    msg << " with text '#{text}'" if text.length > 0
    msg << " (#{desc})" if desc.length > 0
    @ai.Opt("WinSearchChildren", 1) # Match any substring in the title
    if @ai.WinWait(title, text, wait) > 0
      myHandle  = @ai.WinGetHandle(title, text)
      full_text = @ai.WinGetText(title)
      #debug_to_report("Found popup handle:'#{myHandle}', title:'#{title}', text:'#{full_text}'")
      if myHandle.length > 0
        debug_to_log("hwnd: #{myHandle.inspect}")
        passed_to_log("#{msg} appeared.") unless quiet
        sleep_for(0.5)
        @ai.WinActivate(title, text)
        if @ai.WinActive(title, text) #  > 0   #Hack to prevent fail when windows session locked
          debug_to_log("#{msg} activated.")
          if @ai.ControlFocus(title, text, button) #  > 0
            controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
            if not controlHandle
              button        = "&#{button}"
              controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
            end
            debug_to_log("Handle for button '#{button}': [#{controlHandle}]")
            debug_to_log("#{msg} focus gained.")
            #              sleep_for(2)
            if @ai.ControlClick(title, text, button, side) # > 0
                                                           #            if @ai.ControlClick(title, text, "[Handle:#{controlHandle}]", side) > 0
                                                           #                debug_to_log("#{msg} #{side} click on 'Handle:#{controlHandle}'." )
              debug_to_log("#{msg} #{side} click on '#{button}' successful.")
              sleep_for(1)
              if @ai.WinExists(title, text) > 0
                debug_to_log("#{msg} close popup failed on click '#{button}'. Trying WinClose. (#{__LINE__})")
                @ai.WinClose(title, text)
                if @ai.WinExists(title, text) > 0
                  debug_to_log("#{msg} close popup failed with WinClose('#{title}','#{text}'). (#{__LINE__})")
                  @ai.WinKill(title, text)
                  if @ai.WinExists(title, text) > 0
                    debug_to_log("#{msg} close popup failed with WinKill('#{title}','#{text}'). (#{__LINE__})")
                  else
                    debug_to_log("#{msg} closed successfully with WinKill('#{title}','#{text}').")
                  end
                else
                  debug_to_log("#{msg} closed successfully with WinClose('#{title}','#{text}').")
                end
              else
                passed_to_log("#{msg} closed successfully.") unless quiet
              end
            else
              failed_to_log("#{msg} #{side} click on '#{button}' failed. (#{__LINE__})")
            end
          else
            failed_to_log("#{msg} Unable to gain focus on button (#{__LINE__})")
          end
        else
          failed_to_log("#{msg} Unable to activate (#{__LINE__})")
        end
      else
        failed_to_log("#{msg} did not appear after #{wait} seconds. (#{__LINE__})")
      end
    else
      failed_to_log("#{msg} did not appear after #{wait} seconds. (#{__LINE__})")
    end
  rescue
    failed_to_log("Close popup title=#{title} failed: '#{$!}' (#{__LINE__})")
  end

  alias close_popup_validate_text close_popup

  def close_popup_by_text(popup, strg = 'Close', desc = '')
    count = 0
    url   = popup.url
    if validate(popup, @myName, __LINE__)
      count = string_count_in_string(popup.text, strg)
      if count > 0
        #        @waiter.wait_until( browser.link(:text, strg).exists? ) if @waiter
        begin
          popup.link(:text, strg).click
        rescue => e
          if not rescue_me(e, __method__, "link(:text,'#{strg}')", "#{popup.class}")
            raise e
          end
        end
        passed_to_log("Popup #{url} closed by clicking link with text '#{strg}'. #{desc}")
        true
      else
        failed_to_log("Link :text=>'#{strg}' for popup #{url} not found. #{desc}")
      end
    end
  rescue
    failed_to_log("Close popup #{url} with click link :text+>'#{strg}' failed: '#{$!}' (#{__LINE__})")
    debug_to_log("#{strg} appears #{count} times in popup.text.")
    raise
  end

  #  #close a modal dialog
  def close_modal(browser, title="", button="OK", text='', side = 'primary', wait = WAIT)
    case @targetBrowser.abbrev
      when 'IE'
        close_modal_ie(browser, title, button, text, side, wait)
      when 'FF'
        close_modal_ff(browser, title, button, text, side)
      when 'S'
        close_modal_s
      when 'C', 'GC'
        close_modal_c(browser, title)
    end
  end

# TODO: Logging
  def close_modal_c(browser, title)
    browser.window(:url, title).close
  end

# TODO: Logging
  def close_modal_s
    # simply closes the frontmost Safari dialog
    Appscript.app("Safari").activate; Appscript.app("System Events").processes["Safari"].key_code(52)
  end

  def close_modal_ie(browser, title="", button="OK", text='', side = 'primary', wait = WAIT, desc = '', quiet = false)
    #TODO needs simplifying, incorporating text verification, and debug code cleaned up
    title = translate_popup_title(title)
    msg   = "Modal window (popup) '#{title}'"
    if @ai.WinWait(title, text, wait)
      myHandle = @ai.WinGetHandle(title, text)
      if myHandle.length > 0
        debug_to_log("hwnd: #{myHandle.inspect}")
        passed_to_log("#{msg} appeared.") unless quiet
        window_handle = "[HANDLE:#{myHandle}]"
        sleep_for(0.5)
        @ai.WinActivate(window_handle)
        if @ai.WinActive(window_handle)
          debug_to_log("#{msg} activated.")
          controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
          if not controlHandle.length > 0
            button        = "&#{button}"
            controlHandle = @ai.ControlGetHandle(title, '', "[CLASS:Button; TEXT:#{button}]")
          end
          debug_to_log("Handle for button '#{button}': [#{controlHandle}]")
          debug_to_log("#{msg} focus gained.")
          if @ai.ControlClick(title, '', "[CLASS:Button; TEXT:#{button}]")
            passed_to_log("#{msg} #{side} click on '[CLASS:Button; TEXT:#{button}]' successful.")
            sleep_for(0.5)
            if @ai.WinExists(window_handle)
              debug_to_log("#{msg} close popup failed on click '#{button}'. Trying WinClose. (#{__LINE__})")
              @ai.WinClose(title, text)
              if @ai.WinExists(window_handle)
                debug_to_log("#{msg} close popup failed with WinClose(#{window_handle}). (#{__LINE__})")
                @ai.WinKill(window_handle)
                if @ai.WinExists(window_handle)
                  debug_to_log("#{msg} close popup failed with WinKill(#{window_handle}). (#{__LINE__})")
                else
                  debug_to_log("#{msg} closed successfully with WinKill(#{window_handle}).")
                end
              else
                debug_to_log("#{msg} closed successfully with WinClose(#{window_handle}).")
              end
            else
              passed_to_log("#{msg} closed successfully.")
            end
          else
            failed_to_log("#{msg} #{side} click on '[CLASS:Button; TEXT:#{button}]' failed. (#{window_handle}) (#{__LINE__})")
          end
        else
          failed_to_log("#{msg} Unable to activate (#{window_handle}) (#{__LINE__})")
        end
      else
        failed_to_log("#{msg} did not appear after #{wait} seconds. (#{window_handle}) (#{__LINE__})")
      end
    else
      failed_to_log("#{msg} did not appear after #{wait} seconds.(#{window_handle}) (#{__LINE__})")
    end
  rescue
    failed_to_log("Close popup title=#{title} failed: '#{$!}' (#{__LINE__})")
  end

  #  private :close_modal_ie

  def close_modal_ff(browser, title="", button=nil, text="", side='')
    title = translate_popup_title(title)
    msg   = "Modal dialog (popup): title=#{title} button='#{button}' text='#{text}' side='#{side}':"
    modal = browser.modal_dialog(:timeout => WAIT)
    if modal.exists?
      modal_text = modal.text
      if text.length > 0
        if modal_text =~ /#{text}/
          passed_to_log("#{msg} appeared with match on '#{text}'.")
        else
          failed_to_log("#{msg} appeared but did not match '#{text}' ('#{modal_text}).")
        end
      else
        passed_to_log("#{msg} appeared.")
      end
      if button
        modal.click_button(button)
      else
        modal.close
      end
      if modal.exists?
        failed_to_log("#{msg} close failed. (#{__LINE__})")
      else
        passed_to_log("#{msg} closed successfully.")
      end
    else
      failed_to_log("#{msg} did not appear after #{WAIT} seconds. (#{__LINE__})")
    end
  rescue
    failed_to_log("#{msg} Unable to validate modal popup: '#{$!}'. (#{__LINE__})")
  end

  def handle_popup(title, text = '', button= 'OK', side = 'primary', wait = WAIT, desc = '')
    title = translate_popup_title(title)
    msg   = "'#{title}'"
    if text.length > 0
      msg << " with text '#{text}'"
    end
    @ai.Opt("WinSearchChildren", 1) # match title from start, forcing default

    if button and button.length > 0
      if button =~ /ok|yes/i
        id = '1'
      else
        id = '2'
      end
    else
      id = ''
    end

    if @ai.WinWait(title, '', wait) > 0
      myHandle      = @ai.WinGetHandle(title, '')
      window_handle = "[HANDLE:#{myHandle}]"
      full_text     = @ai.WinGetText(window_handle)
      debug_to_log("Found popup handle:'#{myHandle}', title:'#{title}', text:'#{full_text}'")

      controlHandle = @ai.ControlGetHandle(window_handle, '', "[CLASS:Button; TEXT:#{button}]")
      if not controlHandle
#        button        = "&#{button}"
        controlHandle = @ai.ControlGetHandle(window_handle, '', "[CLASS:Button; TEXT:&#{button}]")
      end

      if text.length > 0
        if full_text =~ /#{text}/
          passed_to_log("Found popup handle:'#{myHandle}', title:'#{title}', text includes '#{text}'. #{desc}")
        else
          failed_to_log("Found popup handle:'#{myHandle}', title:'#{title}', text does not include '#{text}'. Closing it. #{desc}")
        end
      end

      @ai.WinActivate(window_handle, '')
      @ai.ControlClick(window_handle, '', id, side)
      if @ai.WinExists(title, '') > 0
        debug_to_log("#{msg} @ai.ControlClick on '#{button}' (ID:#{id}) with handle '#{window_handle}' failed to close window. Trying title.")
        @ai.ControlClick(title, '', id, side)
        if @ai.WinExists(title, '') > 0
          debug_to_report("#{msg} @ai.ControlClick on '#{button}' (ID:#{id}) with title '#{title}' failed to close window.  Forcing closed.")
          @ai.WinClose(title, '')
          if @ai.WinExists(title, '') > 0
            debug_to_report("#{msg} @ai.WinClose on title '#{title}' failed to close window.  Killing window.")
            @ai.WinKill(title, '')
            if @ai.WinExists(title, '') > 0
              failed_to_log("#{msg} @ai.WinKill on title '#{title}' failed to close window")
            else
              passed_to_log("Killed: popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
              true
            end
          else
            passed_to_log("Forced closed: popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
            true
          end
        else
          passed_to_log("Closed on '#{button}': popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
          true
        end
      else
        passed_to_log("Closed on '#{button}': popup handle:'#{myHandle}', title:'#{title}'. #{desc}")
        true
      end

    else
      failed_to_log("#{msg} did not appear after #{wait} seconds. #{desc} (#{__LINE__})")
    end
  rescue
    failed_to_log("Unable to handle popup #{msg}: '#{$!}' #{desc} (#{__LINE__})")

  end

# howLong is integer, whatFor is a browser object
=begin rdoc
tags: wait
howLong is the number of seconds, text is a string to be found, threshold is the number of seconds
after which a fail message is generated even though the text was detected within the howLong limit.
Use this in place of wait_until_by_text when the wait time needs to be longer than the test automation default.
=end
  def hold_for_text(browser, howLong, text, desc = '', threshold = 20, interval = 0.25)
    countdown = howLong
    while ((not browser.contains_text(text)) and countdown > 0)
      sleep(interval)
      countdown = countdown - interval
    end
    if countdown < howLong
      waittime = howLong - countdown
      passed_tolog("#{__method__}  '#{text}' found after #{waittime} second(s) #{desc}")
      if waittime > threshold
        failed_tolog("#{__method__}  '#{text}' took #{waittime} second(s). (threshold: #{threshold} seconds) #{desc}")
      end
      true
    else
      failed_tolog("#{__method__}  '#{text}' not found after #{howLong} second(s) #{desc}")
      false
    end
  rescue
    failed_tolog("Unable to #{__method__} '#{text}'. '#{$!}' #{desc}")
  end

  alias wait_for_text hold_for_text

  def hover(browser, element, wait = 2)
    w1, h1, x1, y1, xc1, yc1, xlr1, ylr1 = get_element_coordinates(browser, element, true)
    @ai.MoveMouse(xc1, yc1)
    sleep_for(1)
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
  # TODO need version for Firefox
  # TODO need to handle first character underline, e.g. 'Cancel' and '&Cancel'
  def save_file(filepath, download_title = "File Download - Security Warning")
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

  def close_log(scriptName, lnbr = '')
    cmplTS = Time.now.to_f.to_s
    puts ("#{scriptName} finished.  Closing log. #{lnbr.to_s}")
    passed_to_log("#{scriptName} run complete [#{cmplTS}]")
    @myLog.close()
    sleep(2)
  end

  protected :close_log

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

  def find_popup(browser, how, what, desc = '')
    msg   = "Find popup :#{how}=>'#{what}'. #{desc}"
    popup = Watir::IE.find(how, what) # TODO: too browser specific
    sleep_for(1)
    debug_to_log("#{popup.inspect}")
    if is_browser?(popup)
#      title = popup.title
      passed_to_log(msg)
      return popup
    else
      failed_to_log(msg)
    end
  rescue
    failed_to_log("Unable to find popup :#{how}=>'#{what}'. #{desc} '#{$!}' (#{__LINE__})")
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

  # howLong is integer, whatFor is a browser object
  def wait_for_text(browser, howLong, text)
    countdown = howLong
    while ((not browser.contains_text(text)) and countdown > 0)
      sleep(1)
      countdown = countdown - 1
    end
    if countdown
      passed_tolog("wait_for_text '#{text}' found after #{howLong} second(s)")
    else
      failed_tolog("wait_for_text '#{text}' not foundafter #{howLong} second(s)")
    end
    countdown
  end

  def wait_for_element_to_reappear(browser, how, what, desc = '', timeout = 20)
    msg = "Element #{how}=#{what} exists. #{desc}"
    wait_while(browser, "While: #{msg}", timeout) { browser.element(how, what).exists? }
    wait_until(browser, "Until: #{msg}", timeout) { browser.element(how, what).exists? }
  end

  # howLong is integer, whatFor is a browser object
  def wait_for_exists(howLong, whatFor)
    wait_for(howLong, whatFor)
  end

  def wait_for(howLong, whatFor)
    countdown = howLong
    while ((not whatFor.exists?) and countdown > 0)
      sleep(1)
      puts whatFor.inspect+':'+countdown.to_s
      countdown = countdown - 1
    end
    if countdown
      puts 'found '+whatFor.inspect
      passed_tolog("wait_for (#{howLong} found "+whatFor.inspect)
    else
      puts 'Did not find '+whatFor.inspect
      failed_tolog("wait_for (#{howLong} did not find "+whatFor.inspect)
    end
    countdown
  end

  #Sample usage:
  #  if wait_for( 10, browser.link(:id, "wria-messagebox-yes") )
  #    browser.link(:id, "wria-messagebox-yes").click
  # . .
  #  else
  #    @myLog.error('['+__LINE__.to_s+'] '+role+' Validate Expected Confirm Delete messagebox')
  #  end

  def wait_the_hard_way(browser, how, what, wait = 6, intvl = 0.25)
    count = (wait / intvl).to_i + 1
    tally = 0
    ok    = (1 / intvl).to_i + 1
    debug_to_log("#{__method__}: wait: #{wait} secs; intvl: #{intvl} secs; count; #{count}; thresh: #{ok}")
    (1..count).each do |x|
      begin
        if browser.element(how, what).exists?
          tally += 1
          debug_to_log("#{x}: #{(x - 1) * intvl}: #{what} exists.")
        else
          tally = 0
          debug_to_log("#{x}: #{(x - 1) * intvl}: #{what} does not exist.")
        end
      rescue
        tally = 0
        debug_to_log("#{x}: #{(x - 1) * intvl}: #{what} rescue: #{$!}")
      end
      if tally >= ok
        return true
      end
      sleep(intvl)
    end
  end

  def is_browser?(browser)
    myClass = browser.class.to_s
    case @targetBrowser.abbrev
      when 'IE'
        myClass =~ /Watir::/i # TODO: should this be /Watir::IE/i ?
      when 'FF'
        if @version.to_f < 4.0
          myClass =~ /FireWatir::/i
        else
          myClass =~ /Watir::Browser/i
        end
      when 'S'
        myClass =~ /Watir::Safari/i
      when 'C'
        myClass =~ /Watir::Browser/i
    end
  end

  alias is_browser is_browser?

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

  def open_browser(url = nil)
    debug_to_log("Opening browser: #{@targetBrowser.name}")
    debug_to_log("#{__method__}: [#{get_caller_line}] #{get_callers}")
    case @targetBrowser.abbrev
      when 'IE'
        @myBrowser = open_ie
        @myHwnd    = @myBrowser.hwnd
      #@waiter    = Watir::Waiter.new(WAIT)
      when 'FF'
        #version    = "11"
        #@myBrowser = open_ff_for_version(version)
        @myBrowser = open_ff_for_version
      when 'S'
        debug_to_log("Opening browser: #{@targetBrowser.name} legacy.rb:#{__LINE__}")
        aBrowser = Watir::Safari.new
        debug_to_log("Browser instantiated")
        @myBrowser = aBrowser
      #require 'shamisen/awetest_legacy/safari_waiter'
      #@waiter    = Watir::Waiter
      when 'C', 'GC'
        @myBrowser = open_chrome
      ##require 'shamisen/awetest_legacy/webdriver_waiter'
      #require 'shamisen/support/webdriver_ext/browser'
      #@waiter    = Watir::Waiter

      else
        raise "Unsupported browser: #{@targetBrowser.name}"
    end
    get_browser_version(@myBrowser)
    if url
      go_to_url(@myBrowser, url)
    end
    @myBrowser
  end

  def open_ie(process = true)
    check_for_and_clear_other_browsers
    Watir::Browser.default = 'ie'
    #if process && !IS_WIN_2008
    #  browser = Watir::IE.new_process
    #else
    browser                = Watir::IE.new
    #end
    browser
  end

  def open_ff_for_version(version = @targetVersion)
    if version.to_f < 4.0
      browser = open_ff
      #waiter  = Watir::Waiter.new(WAIT)
    else
      browser = Watir::Browser.new(:firefox)
      #require 'shamisen/awetest_legacy/webdriver_waiter'
      #waiter = Watir::Waiter
    end
    browser
  end

  def open_ff
    Watir::Browser.default = 'firefox'
    browser                = Watir::Browser.new
  end

  def open_chrome
    browser = Watir::Browser.new(:chrome)
  end

  #=begin
  # Get the browser to navigate to a given url.  If not supplied in the second argument,
  # defaults to value of FullScript.myURL, which is populated from ApplicationEnvironment.url.
  #=end
  def go_to_url(browser, url = nil, redirect = nil)
    if url
      @myURL = url
    end
    message_tolog("URL: #{@myURL}")
    browser.goto(@myURL)
    if validate(browser, @myName, __LINE__)
#      TODO .url method returns blank in Firewatir
      if redirect
        passed_to_log("Redirected to url '#{browser.url}'.")
        true
      elsif browser.url =~ /#{@myURL}/i # or @browserAbbrev == 'FF'
        passed_to_log("Navigated to url '#{@myURL}'.")
        true
      else
        failed_to_log("Navigated to url '#{browser.url}' but expected '#{@myURL}'.")
      end
    end
  rescue
    fatal_to_log("Unable to navigate to '#{@myURL}': '#{$!}'")
  end

  #def open_log
  #  start = Time.now.to_f.to_s
  #
  #  logTS = Time.at(@myRun.launched.to_f).strftime("%Y%m%d%H%M%S")
  #  xls = @myAppEnv.xls_name.gsub('.xls', '') + '_' if  @myAppEnv.xls_name.length > 0
  #  @logFileSpec = "#{@myRoot}/#{logdir}/#{@myName}_#{@targetBrowser.abbrev}_#{xls}#{logTS}.log"
  #  init_logger(@logFileSpec, @myName)
  #
  #                                                  #    message_tolog( self.inspect )
  #  message_to_log("#{@myName} launched at [#{@myRun.launched.to_f.to_s}][#{@myScript.id}][#{@myRun.id}][#{@myChild.id}]")
  #  debug_to_log("pid: #{$$}")
  #  message_to_log("#{@myName} begin at [#{start}]")
  #  message_to_log("#{@myName} environment [#{@myAppEnv.name}]")
  #  message_to_log("#{@myName} xls_name [#{@myAppEnv.xls_name}]") if  @myAppEnv.xls_name.length > 0
  #  message_to_log("#{@myName} rootDir [#{@myRoot}]")
  #  message_to_log("#{@myName} Target Browser [#{@targetBrowser.name}]")
  #  mark_testlevel(@myParent.name, @myParent.level) # Module
  #  mark_testlevel(@myChild.name, @myChild.level) # SubModule
  #
  #end

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
    rescue => e
      if not rescue_me(e, __method__, "browser(#{msg1}).click", "#{browser.class}")
        raise e
      end
    end
    if validate(browser, @myName, __LINE__)
      passed_to_log(msg)
      true
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

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

  def click_button_by_id(browser, strg, desc = '')
    click(browser, :button, :id, strg, desc)
  end

  def click_link_by_index(browser, strg, desc = '')
    click(browser, :link, :index, strg, desc)
  end

  def click_link_by_href(browser, strg, desc = '')
    click(browser, :link, :href, strg, desc)
  end

  alias click_href click_link_by_href

  def click_link_no_wait_by_href(browser, strg, desc = '')
    click_no_wait(browser, :link, :href, strg, desc)
  end

  alias click_href_no_wait click_link_no_wait_by_href

  def click_button_by_index(browser, index, desc = '')
    click(browser, :button, :index, index, desc)
  end

  def click_button_by_name(browser, strg, desc = '')
    click(browser, :button, :name, strg, desc)
  end

  def click_button_by_text(browser, strg, desc = '')
    click(browser, :button, :text, strg, desc)
  end

  def click_button_by_class(browser, strg, desc = '')
    click(browser, :button, :class, strg, desc)
  end

  def click_button_no_wait_by_id(browser, strg, desc = '')
    click_no_wait(browser, :button, :id, strg, desc)
  end

  alias click_button_by_id_no_wait click_button_no_wait_by_id

  def click_button_no_wait_by_name(browser, strg, desc = '')
    click_no_wait(browser, :button, :name, strg, desc)
  end

  def click_button_no_wait_by_class(browser, strg, desc = '')
    click_no_wait(browser, :button, :class, strg, desc)
  end

  alias click_button_by_class_no_wait click_button_no_wait_by_class

  def click_button_by_value(browser, strg, desc = '')
    click(browser, :button, :value, strg, desc)
  end

  def click_button_by_title(browser, strg, desc = '')
    click(browser, :button, :title, strg, desc)
  end

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

  def click_link_by_id(browser, strg, desc = '')
    click(browser, :link, :id, strg, desc)
  end

  alias click_id click_link_by_id

  def click_link_by_name(browser, strg, desc = '')
    click(browser, :link, :name, strg, desc)
  end

  alias click_name click_link_by_name

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

  def click_link_no_wait_by_id(browser, strg, desc = '')
    click_no_wait(browser, :link, :id, strg, desc)
  end

  alias click_no_wait_id click_link_no_wait_by_id
  alias click_no_wait_by_id click_link_no_wait_by_id
  alias click_id_no_wait click_link_no_wait_by_id
  alias click_no_wait_link_by_id click_link_no_wait_by_id

  def click_file_field_by_id(browser, strg, desc = '')
    click(browser, :file_field, :id, strg, desc)
  end

  def click_img_by_alt(browser, strg, desc = '')
    click(browser, :image, :alt, strg, desc)
  end

  def click_img_by_title(browser, strg, desc = '')
    click(browser, :image, :title, strg, desc)
  end

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

  def click_img_no_wait_by_alt(browser, strg, desc = '')
    click_no_wait(browser, :image, :alt, strg, desc)
  end

  alias click_img_by_alt_no_wait click_img_no_wait_by_alt

  def click_img_by_src(browser, strg, desc = '')
    click(browser, :image, :src, strg, desc)
  end

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

  def click_link_by_value(browser, strg, desc = '')
    click(browser, :link, :value, strg, desc)
  end

  def click_link_by_text(browser, strg, desc = '')
    click(browser, :link, :text, strg, desc)
  end

  alias click_link click_link_by_text
  alias click_text click_link_by_text
  alias click_js_button click_link_by_text

  def click_link_by_class(browser, strg, desc = '')
    click(browser, :link, :class, strg, desc)
  end

  alias click_class click_link_by_class

  def click_button_no_wait_by_text(browser, strg, desc = '')
    click_no_wait(browser, :button, :text, strg, desc)
  end

  def click_button_no_wait_by_value(browser, strg, desc = '')
    click_no_wait(browser, :button, :value, strg, desc)
  end

  def click_link_by_name_no_wait(browser, strg, desc = '')
    click_no_wait(browser, :link, :name, strg, desc)
  end

  alias click_no_wait_name click_link_by_name_no_wait
  alias click_name_no_wait click_link_by_name_no_wait

  def click_link_by_text_no_wait(browser, strg, desc = '')
    click_no_wait(browser, :link, :text, strg, desc)
  end

  alias click_no_wait_text click_link_by_text_no_wait
  alias click_text_no_wait click_link_by_text_no_wait

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

# TODO no logging yet.  slow.
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

  def click_link_by_title(browser, strg, desc = '')
    click(browser, :link, :title, strg, desc)
  end

  alias click_title click_link_by_title

  def click_title_no_wait(browser, strg, desc = '')
    click_no_wait(browser, :link, :title, strg, desc)
  end

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

  def flash_text(browser, strg, count, desc = '')
    msg = "Flash link text='#{strg}' #{count} times."
    msg << " #{desc}" if desc.length > 0
    strgCnt = string_count_in_string(browser.text, strg)
    if strgCnt > 0
      browser.link(:text, strg).flash(count)
      if validate(browser, @myName, __LINE__)
        passed_to_log(msg)
        true
      end
    else
      failed_to_log("#{msg} Link not found.")
    end
  rescue
    failed_to_log("Unable to #{msg} '#{$!}'")
  end

  def flash_id(browser, strg, count)
    msg = "Flash link id='#{strg}' #{count} times."
    msg << " #{desc}" if desc.length > 0
    browser.link(:id, strg).flash(count)
    if validate(browser, @myName, __LINE__)
      passed_to_log(msg)
      true
    end
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

  #TODO put rescue inside the do loop
  #parameters: browser and a list of column link text values
  #example: exercise_sorting(browser,['Division', 'Payee', 'Date'], 'Sortable columns on this page')

  def exercise_sorting(browser, columnList, desc = '')
    columnList.each do |column|
      click(browser, :link, :text, column, desc)
    end
  end

  alias validate_sorting exercise_sorting

  def focus_on_textfield_by_id(browser, strg, desc = '')
    msg = "Set focus on textfield name='#{strg}' "
    msg << " #{desc}" if desc.length > 0
    tf = browser.text_field(:id, strg)
    if validate(browser, @myName, __LINE__)
      tf.focus
      if validate(browser, @myName, __LINE__)
        passed_to_log(msg)
        true
      end
    end
  rescue
    failed_to_log("Unable to #{msg} '#{$!}'")
  end

  def open_popup_through_link_title(browser, title, pattern, name)
    click_title(browser, title)
    #TODO need some kind of wait for process here
    sleep_for 2
    attach_iepopup(browser, pattern, name)
  rescue
    failed_to_log("Unable to open popup '#{name}': '#{$!}' (#{__LINE__})")
  end

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

  def string_count_in_string(strg, substrg)
    count = strg.scan(substrg).length
    count
  end

  def translate_popup_title(title)
    new_title = title
    case @browserAbbrev
      when 'IE'
        if @browserVersion
          case @browserVersion
            when '8.0'
              case title
                when "Microsoft Internet Explorer"
                  new_title = "Message from webpage"
                when "The page at"
                  new_title = "Message from webpage"
              end
            when '7.0'
              case title
                when "Message from webpage"
                  new_title = "Microsoft Internet Explorer"
                when "The page at"
                  new_title = "Windows Internet Explorer"
              end
            when '6.0'
              case title
                when "Message from webpage"
                  new_title = "Microsoft Internet Explorer"
                when "The page at"
                  new_title = "Microsoft Internet Explorer"
              end
            else
              case title
                when "Microsoft Internet Explorer"
                  new_title = "Message from webpage"
                when "The page at"
                  new_title = "Message from webpage"
              end
          end
        else
          case title
            when "Microsoft Internet Explorer"
              new_title = "Message from webpage"
            when "The page at"
              new_title = "Message from webpage"
          end
        end
      when 'FF'
        case title
          when 'File Download'
            new_title = 'Opening'
          when "Microsoft Internet Explorer"
            new_title = 'The page at'
          when "Message from webpage"
            new_title = 'The page at'
        end
      when 'C'
        case title
          when 'File Download'
            new_title = 'Save As'
          when "Microsoft Internet Explorer"
            new_title = 'The page at'
          when "Message from webpage"
            new_title = 'The page at'
        end
    end
    new_title
  end

  #def translate_popup_title(title)
  #  new_title = title
  #  case @browserAbbrev
  #    when 'IE'
  #
  #
  #      case title
  #        when "Microsoft Internet Explorer"
  #          new_title = "Message from webpage"
  #        when "The page at"
  #          new_title = "Message from webpage"
  #      end
  #
  #
  #
  #
  #    when 'FF'
  #      case title
  #        when 'File Download'
  #          new_title = 'Opening'
  #        when "Microsoft Internet Explorer"
  #          new_title = 'The page at'
  #        when "Message from webpage"
  #          new_title = 'The page at'
  #      end
  #
  #    when 'C'
  #      case title
  #        when 'File Download'
  #          new_title = 'Save As'
  #        when "Microsoft Internet Explorer"
  #          new_title = 'The page at'
  #        when "Message from webpage"
  #          new_title = 'The page at'
  #      end
  #  end
  #  new_title
  #end

  def get_browser_version(browser)
    debug_to_log("starting get_browser_version")
    case @targetBrowser.abbrev
      when 'IE'
        @browserAbbrev  = 'IE'
        @browserName    = 'Internet Explorer'
        @browserAppInfo = browser.document.invoke('parentWindow').navigator.appVersion
        @browserAppInfo =~ /MSIE\s(.*?);/
        @browserVersion = $1
      when 'FF'
        #@browserAbbrev = 'FF'
        #@browserName   = 'Firefox'
        #js_stuff       = <<-end_js_stuff
        #var info = Components.classes["@mozilla.org/xre/app-info;1"]
        #.getService(Components.interfaces.nsIXULAppInfo);
        #[info, info.name, info.version];
        #end_js_stuff
        #js_stuff.gsub!("\n", " ")
        #info = browser.execute_script(js_stuff)
        #info, aName, @browserVersion = info.split(',')
        #debug_to_log("FF info: [#{info}]")
        #debug_to_log("FF name: [#{aName}]")
        #debug_to_log("FF vrsn: [#{@browserVersion}]")
        @browserAbbrev  = 'FF'
        @browserName    = 'Firefox'
        @browserVersion = '6.01' #TODO: get actual version from browser
        debug_to_log("Firefox, in get_browser_version (#{@browserVersion})")
      when 'S'
        @browserAbbrev  = 'S'
        @browserName    = 'Safari'
        @browserVersion = '5.0.4' #TODO: get actual version from browser itself
        debug_to_log("Safari, in get_browser_version (#{@browserVersion})")
      when 'C'
        @browserAbbrev  = 'C'
        @browserName    = 'Chrome'
        @browserVersion = '11.0' #TODO: get actual version from browser
        debug_to_log("Chrome, in get_browser_version (#{@browserVersion})")
    end
    # if [notify_queue, notify_class, notify_id].all?
    #  Resque::Job.create(notify_queue, notify_class, :id => notify_id, :browser_used => "#{@browserName} #{@browserVersion}")
    #end
  rescue
    debug_to_log("Unable to determine #{@browserAbbrev} browser version: '#{$!}' (#{__LINE__})")

    # TODO: can we get rid of this?
    # js for getting firefox version information
    #      function getAppID() {
    #        var id;
    #        if("@mozilla.org/xre/app-info;1" in Components.classes) {
    #          // running under Mozilla 1.8 or later
    #          id = Components.classes["@mozilla.org/xre/app-info;1"]
    #                         .getService(Components.interfaces.nsIXULAppInfo).ID;
    #        } else {
    #          try {
    #            id = Components.classes["@mozilla.org/preferences-service;1"]
    #                           .getService(Components.interfaces.nsIPrefBranch)
    #                           .getCharPref("app.id");
    #          } catch(e) {
    #            // very old version
    #            dump(e);
    #          }
    #        }
    #        return id;
    #      }
    #      alert(getAppID());
    # another snippet that shows getting attributes from object
    #      var info = Components.classes["@mozilla.org/xre/app-info;1"]
    #                 .getService(Components.interfaces.nsIXULAppInfo);
    #      // Get the name of the application running us
    #      info.name; // Returns "Firefox" for Firefox
    #      info.version; // Returns "2.0.0.1" for Firefox version 2.0.0.1
  ensure
    message_to_log("Browser: [#{@browserAbbrev} #{@browserVersion}]")
  end

  protected :get_browser_version

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

  def wait_until_exists(browser, element, how, what, desc = '')
    msg = "Wait until (#{element} :#{how}=>#{what}) exists."
    msg << " #{desc}" if desc.length > 0
    start = Time.now.to_f
    # TODO: try Watir::Wait.until { browser.element(how, what).exists? } instead of this (cumbersome) case statement
    # TODO: above fails on frame
    begin
      case element
        when :link
          Watir::Wait.until { browser.link(how, what).exists? }
        when :button
          Watir::Wait.until { browser.button(how, what).exists? }
        when :radio
          Watir::Wait.until { browser.radio(how, what).exists? }
        when :checkbox
          Watir::Wait.until { browser.checkbox(how, what).exists? }
        when :div
          Watir::Wait.until { browser.div(how, what).exists? }
        when :select_list
          Watir::Wait.until { browser.select_list(how, what).exists? }
        when :text_field
          Watir::Wait.until { browser.text_field(how, what).exists? }
        when :frame
          Watir::Wait.until { browser.frame(how, what).exists? }
        when :form
          Watir::Wait.until { browser.form(how, what).exists? }
        when :cell
          Watir::Wait.until { browser.cell(how, what).exists? }
        when :image
          Watir::Wait.until { browser.image(how, what).exists? }
        else
          Watir::Wait.until { browser.element(how, what).exists? }
      end
    rescue => e
      if e.class.to_s =~ /TimeOutException/
        failed_to_log("#{msg}: '#{$!}'")
        return false
      elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
        raise e
      end
    end
    stop = Time.now.to_f
    #debug_to_log("#{__method__}: start:#{start} stop:#{stop}")
    #    sleep 1
    if validate(browser, @myName, __LINE__)
      passed_to_log("#{msg} (#{stop - start} seconds)")
      true
    end
  rescue
    failed_to_log("Unable to complete #{msg}: '#{$!}'")
  end

  #TODO: Would like to be able to see the block code in the log message instead of the identification
  def wait_while(browser, desc, timeout = 45, &block)
    msg   = "Wait while #{desc}:"
    start = Time.now.to_f
    begin
      #Watir::Wait.until(timeout) { block.call(nil) }
      if block.call(nil)
        Watir::Wait.while(timeout) { block.call(nil) }
      end
    rescue => e
      if e.class.to_s =~ /TimeOutException/ or e.message =~ /timed out/
        failed_to_log("#{msg}: '#{$!}' ")
        return false
      elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
        raise e
      end
    end
    stop = Time.now.to_f
    #debug_to_log("#{__method__}: start:#{start} stop:#{stop} block: #{block.to_s}")
    #    sleep 1
    if validate(browser, @myName, __LINE__)
      passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)") #  {#{block.to_s}}")
      true
    end
  rescue
    failed_to_log("Unable to complete #{msg}. '#{$!}'")
  end

  alias wait_while_true wait_while

  #TODO: Would like to be able to see the block code in the log message instead of the identification
  def wait_until(browser, desc, timeout = 45, skip_pass = false, &block)
    msg   = "Wait until #{desc}"
    start = Time.now.to_f
    begin
      Watir::Wait.until(timeout) { block.call(nil) }
    rescue => e
      if e.class.to_s =~ /TimeOutException/ or e.message =~ /timed out/
        failed_to_log("#{msg} '#{$!}'")
        return false
      elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
        raise e
      end
    end
    stop = Time.now.to_f
    #debug_to_log("#{__method__}: start:#{start} stop:#{stop} block: #{block.to_s}")
    #    sleep 1
    if validate(browser, @myName, __LINE__)
      passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)") unless skip_pass #  {#{block.to_s}}")
      true
    end
  rescue
    failed_to_log("Unable to complete #{msg}  '#{$!}'")
  end

  alias wait_until_true wait_until

  def wait_until_by_radio_value(browser, strg, desc = '')
    wait_until_exists(browser, :radio, :value, strg, desc)
  end

  def wait_until_ready(browser, how, what, desc = '', timeout = 90, verbose = false)
    msg = "#{__method__.to_s.titleize}: element: #{how}='#{what}'"
    msg << " #{desc}" if desc.length > 0
    proc_exists  = Proc.new { browser.element(how, what).exists? }
    proc_enabled = Proc.new { browser.element(how, what).enabled? }
    case how
      when :href
        proc_exists  = Proc.new { browser.link(how, what).exists? }
        proc_enabled = Proc.new { browser.link(how, what).enabled? }
    end
    if verbose
      if wait_until(browser, "#{msg} Element exists.", timeout) { proc_exists.call(nil) }
        if wait_until(browser, "#{msg} Element enabled.", timeout) { proc_enabled.call(nil) }
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      else
        failed_to_log(msg)
      end
    else
      start = Time.now.to_f
      if Watir::Wait.until(timeout) { proc_exists.call(nil) }
        if Watir::Wait.until(timeout) { proc_enabled.call(nil) }
          stop = Time.now.to_f
          #debug_to_log("#{__method__}: start:#{"%.5f" % start} stop:#{"%.5f" % stop}")
          passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)")
          true
        else
          failed_to_log(msg)
        end
      else
        failed_to_log(msg)
      end
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  def wait_until_ready_quiet(browser, how, what, desc = '', timeout = 45, quiet = true)
    msg = "#{__method__.to_s.titleize}: element: #{how}='#{what}'"
    msg << " #{desc}" if desc.length > 0
    proc_exists  = Proc.new { browser.element(how, what).exists? }
    proc_enabled = Proc.new { browser.element(how, what).enabled? }
    case how
      when :href
        proc_exists  = Proc.new { browser.link(how, what).exists? }
        proc_enabled = Proc.new { browser.link(how, what).enabled? }
    end
    start = Time.now.to_f
    if Watir::Wait.until(timeout) { proc_exists.call(nil) }
      if Watir::Wait.until(timeout) { proc_enabled.call(nil) }
        stop = Time.now.to_f
        #debug_to_log("#{msg}: start:#{"%.5f" % start} stop:#{"%.5f" % stop}")
        passed_to_log("#{msg} (#{"%.5f" % (stop - start)} seconds)") unless quiet
        true
      else
        failed_to_log(msg)
      end
    else
      failed_to_log(msg)
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  def wait_until_text(browser, strg, desc = '', timeout = 60)
    if not strg.class.to_s.match('String')
      raise "#{__method__} requires String for search target. #{strg.class} is not supported."
    end
    wait_until(browser, "'#{strg}' #{desc}", timeout) { browser.text.include? strg }
  end

  alias wait_until_by_text wait_until_text

  def wait_until_by_link_text(browser, strg, desc = '')
    wait_until_exists(browser, :link, :text, strg, desc)
  end

  def wait_until_enabled(browser, what, how, value, desc = '')
    start = Time.now.to_f
    begin
      case what
        when :link
          Watir::Wait.until { browser.link(how, value).enabled? }
        when :button
          Watir::Wait.until { browser.button(how, value).enabled? }
        when :radio
          Watir::Wait.until { browser.radio(how, value).enabled? }
        when :checkbox
          Watir::Wait.until { browser.checkbox(how, value).enabled? }
        when :div
          Watir::Wait.until { browser.div(how, value).enabled? }
        when :select_list
          Watir::Wait.until { browser.select_list(how, value).enabled? }
        when :text_field
          Watir::Wait.until { browser.text_field(how, value).enabled? }
        when :table
          Watir::Wait.until { browser.table(how, value).enabled? }
        else
          raise "#{__method__}: Element #{what} not supported."
      end
    rescue => e
      if e.class.to_s =~ /TimeOutException/
        failed_to_log("Wait until (#{what} :#{how}=>#{value}) enabled. #{desc}: '#{$!}' #{desc}")
        return false
      elsif not rescue_me(e, __method__, "#{block.to_s}", "#{browser.class}")
        raise e
      end
    end
    stop = Time.now.to_f
    #debug_to_log("#{__method__}: start:#{start} stop:#{stop}")
    #    sleep 1
    if validate(browser, @myName, __LINE__)
      passed_to_log("Wait until (#{what} :#{how}=>#{value}) enabled. #{desc} (#{stop - start} seconds)")
      true
    end
  rescue
    failed_to_log("Unable to complete wait until (#{what} :#{how}=>#{value}) enabled. #{desc}: '#{$!}'")
  end

  def wait_until_visible(browser, element, how, what, desc = '')
    start = Time.now.to_f
    Watir::Wait.until(20) { browser.element(how, what).exists? }
    begin
      case element
        when :link
          Watir::Wait.until { browser.link(how, what).visible? }
        when :button
          Watir::Wait.until { browser.button(how, what).visible? }
        when :radio
          Watir::Wait.until { browser.radio(how, what).visible? }
        when :checkbox
          Watir::Wait.until { browser.checkbox(how, what).visible? }
        when :div
          Watir::Wait.until { browser.div(how, what).visible? }
        when :select_list
          Watir::Wait.until { browser.select_list(how, what).visible? }
        when :text_field
          Watir::Wait.until { browser.text_field(how, what).visible? }
        else
          Watir::Wait.until { browser.element(how, what).visible? }
#          raise "#{__method__}: Element #{what} not supported."
      end
    rescue => e
      if e.class.to_s =~ /TimeOutException/
        failed_to_log("Wait until (#{what} :#{how}=>#{what}) visible. #{desc}: '#{$!}' #{desc}")
        return false
      elsif not rescue_me(e, __method__, '', "#{browser.class}")
        raise e
      end
    end
    stop = Time.now.to_f
    #debug_to_log("#{__method__}: start:#{start} stop:#{stop}")
    #    sleep 1
    if validate(browser, @myName, __LINE__)
      passed_to_log("Wait until (#{element} :#{how}=>#{what}) visible. #{desc} (#{stop - start} seconds)")
      true
    end
  rescue
    failed_to_log("Unable to complete wait until (#{element} :#{how}=>#{what}) visible. #{desc}: '#{$!}'")
  end

  def rescue_me(e, me = nil, what = nil, where = nil, who = nil)
    #TODO: these are rescues from exceptions raised in Watir/Firewatir
    debug_to_log("#{__method__}: Enter")
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

  def close_popup_by_button_title(popup, strg, desc = '')
    click(popup, :link, :title, strg, desc)
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

  #TODO enhance to accept differing percentages in each direction
  def resize_element_with_handle(browser, element, target, dx, dy=nil)
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

  def get_resize_handle_by_id(element, id, dbg=nil)
    handle = get_div_by_id(element, id, dbg)
    sleep_for(1)
    handle.flash(5)
    return handle
  end

  def get_resize_handle_by_class(element, strg, dbg=nil)
    handle = get_div_by_class(element, strg, dbg)
    sleep_for(0.5)
    handle.flash(5)
    return handle
  end

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

  def get_index_for_column_head(panel, table_index, strg)
    rgx = Regexp.new(strg)
    panel.tables[table_index].each do |row|
      if row.text =~ rgx
        index = 1
        row.each do |cell|
          if cell.text =~ rgx
            return index
          end
          index += 1
        end
      end
    end
  end

  def get_index_of_last_row(table, pad = 2, every = 1)
    index = calc_index(table.row_count, every)
    index = index.to_s.rjust(pad, '0')
    #debug_to_log("#{__method__}: index='#{index}' row_count=#{table.row_count} pad=#{pad} every=#{every}")
    index
  end

  alias get_index_for_last_row get_index_of_last_row

  def get_index_of_last_row_with_text(table, strg, column_index = nil)
    debug_to_log("#{__method__}: #{get_callers(5)}")
    msg = "Find last row in table :id=#{table.id} with text '#{strg}'"
    msg << " in column #{column_index}" if column_index
    dbg = "#{__method__}: #{table.id} text by row "
    dbg << "in column #{column_index}" if column_index
    index    = 0
    found    = false
    at_index = 0
    #row_count = table.row_count
    table.rows.each do |row|
      cell_count = get_cell_count(row)
      index      += 1
      text       = ''
      if column_index
        col_idx = column_index.to_i
        if cell_count >= col_idx
          text = row[col_idx].text
        end
      else
        text = row.text
      end
      dbg << "\n#{index}. [#{text}]"
      if text =~ /#{strg}/
        found    = true
        at_index = index
      end
    end
    debug_to_log(dbg)
    if found
      passed_to_log("#{msg} at index #{index}.")
      at_index
    else
      failed_to_log("#{msg}")
      nil
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  alias get_index_for_last_row_with_text get_index_of_last_row_with_text

  def get_index_of_row_with_text(table, strg, column_index = nil, fail_if_found = false)
    debug_to_log("#{__method__}: #{get_callers(5)}")
    if fail_if_found
      msg = 'No '
    else
      msg = 'Find '
    end
    msg << "row in table :id=#{table.id} with text '#{strg}'"
    msg << " in column #{column_index}" if column_index
    dbg = "#{__method__}: #{table.id} text by row "
    dbg << "in column #{column_index}" if column_index
    index = 0
    found = false
    table.rows.each do |row|
      cell_count = row.cells.length
      index      += 1
      text       = ''
      if column_index
        col_idx = column_index.to_i
        if cell_count >= col_idx
          text = row[col_idx].text
        end
      else
        text = row.text
      end
      dbg << "\n#{index}. [#{text}]"
      if text =~ /#{strg}/
        found = true
        break
      end
    end
    debug_to_log(dbg)
    if found
      if fail_if_found
        failed_to_log("#{msg} at index #{index}.")
      else
        passed_to_log("#{msg} at index #{index}.")
      end
      index
    else
      if fail_if_found
        passed_to_log("#{msg}")
      else
        failed_to_log("#{msg}")
      end
      nil
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  def get_index_of_row_with_textfield_value(table, strg, how, what, column_index = nil)
    msg = "Find row in table :id=#{table.id} with value '#{strg}' in text_field #{how}=>'#{what} "
    msg << " in column #{column_index}" if column_index
    index = 0
    found = false
    table.rows.each do |row|
      cell_count = get_cell_count(row)
      index      += 1
      text       = ''
      if column_index
        col_idx = column_index.to_i
        if cell_count >= col_idx
          if  row[col_idx].text_field(how, what).exists?
            value = row[col_idx].text_field(how, what).value
          end
        end
      else
        if  row.text_field(how, what).exists?
          value = row.text_field(how, what).value
          sleep(0.25)
        end
      end
      if value and value =~ /#{strg}/
        found = true
        break
      end
    end
    if found
      passed_to_log("#{msg} at index #{index}.")
    else
      failed_to_log("#{msg}")
    end
    index
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  def get_index_for_table_containing_text(browser, strg, ordinal = 1)
    msg   = "Get index for table containing text '#{strg}'"
    index = 0
    found = 0
    browser.tables.each do |t|
      index += 1
      if t.text =~ /#{strg}/
        found += 1
        if ordinal > 0 and found == ordinal
          break
        end
      end
    end
    if found
      passed_to_log("#{msg}: #{index}")
      index
    else
      passed_to_log("#{msg}.")
      nil
    end
  rescue
    failed_to_log("Unable to find index of table containing text '#{strg}' '#{$!}' ")
  end

  def get_table_containing_text(browser, strg, ordinal = 1)
    msg   = "Get table #{ordinal} containing text '#{strg}'"
    index = get_index_for_table_containing_text(browser, strg, ordinal)
    if index
      passed_to_log(msg)
      browser.tables[index]
    else
      failed_to_log(msg)
      nil
    end
  rescue
    failed_to_log("Unable to find index of table containing text '#{strg}' '#{$!}' ")
  end

  def get_cell_text_from_row_with_string(nc_element, table_index, column_index, strg)
    rgx  = Regexp.new(strg)
    text = ''
    debug_to_log("strg:'#{strg}', rgx:'#{rgx}', table_index:'#{table_index}', column_index:'#{column_index}'")
    nc_element.tables[table_index].each do |row|
      cell_count = get_cell_count(row)
      if cell_count >= column_index
        #TODO this assumes column 1 is a number column
        #        debug_to_log("row:'#{row.cells}'")
        cell_1 = row[1].text
        if cell_1 =~ /\d+/
          row_text = row.text
          if row_text =~ rgx
            text = row[column_index].text
            break
          end
        end
      end
    end
    text
  end

  def count_rows_with_string(container, table_index, strg)
    hit = 0
    container.tables[table_index].each do |row|
      if get_cell_count(row) >= 1
        #        debug_to_log("#{__method__}: #{row.text}")
        #TODO this assumes column 1 is a number column
        if row[1].text =~ /\d+/
          if row.text =~ /#{strg}/i
            hit += 1
            debug_to_log("#{__method__}: #{row.text}")
          end
        end
      end
    end
    debug_to_log("#{__method__}: hit row count: #{hit}")
    hit
  end

  def fetch_array_for_table_column(nc_element, table_index, column_index)
    ary = []
    nc_element.tables[table_index].each do |row|
      if get_cell_count(row) >= column_index
        #TODO this assumes column 1 is a number column
        if row[1].text =~ /\d+/
          ary << row[column_index].text
        end
      end
    end
    return ary f
  end

  def fetch_hash_for_table_column(table, column_index, start_row = 2)
    hash      = Hash.new
    row_count = 0
    table.each do |row|
      row_count += 1
      if get_cell_count(row) >= column_index
        if row_count >= start_row
          hash[row_count] = row[column_index].text
        end
      end
    end
    hash
  end

  def get_row_cells_text_as_array(row)
    ary = []
    row.each do |cell|
      ary << cell.text
    end
    ary
  end

  def count_data_rows(container, data_index, column_index)
    cnt   = 0
    #  get_objects(container, :tables, true)
    table = container.tables[data_index]
    dump_table_and_rows(table)
    if table
      table.rows.each do |row|
        if get_cell_count(row) >= column_index
          #TODO this assumes column 1 is a number column
          if row[column_index].text =~ /\d+/
            cnt += 1
          end
        end
      end
    end
    sleep_for(2)
    cnt
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
        debug_to_log("\n============== #{which}:\nindex:     #{cnt}\n#{obj}\n#{obj.to_yaml}")
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

  def get_cell_count(row)
    #    if @browserAbbrev == 'IE' or $use_firewatir
    row.cells.length
    #    else
    #      row.cell_count
    #    end
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

  #TODO unlikely to work...
  def find_me(where, how, what)
    me = where.element(how, what)
    puts me.inspect
  rescue
    error_to_log("#{where.inspect} doesn't seem to respond to element() #{$!}")
  end

  def click_me(element)
    element.click
  rescue
    error_to_log("#{element.inspect} doesn't seem to respond to click() #{$!}")
  end

  def filter_bailout_from_rescue(err, msg)
    if msg =~ /bailing out/i
      raise err
    else
      error_to_log(msg)
    end
  end

  def get_caller_line
    last_caller = get_callers[0]
    line        = last_caller.split(':', 3)[1]
    line
  end

  def get_call_list(depth = 9, dbg = false)
    myList    = []
    call_list = Kernel.caller
    puts call_list if dbg
    call_list.each_index do |x|
      myCaller = call_list[x].to_s
      break if x > depth or myCaller =~ /:in .run.$/
      myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
      myList << "[#{$1.gsub(/eval/, @myName)}] "
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
      break if x > depth or myCaller =~ /:in .run.$/
      if myCaller.include? @myName
        myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
        myList << "[#{$1.gsub(/eval/, @myName)}] "
        break
      end
    end
    if @projName
      call_list.each_index do |x|
        myCaller = call_list[x].to_s
        break if x > depth or myCaller =~ /:in .run.$/
        if myCaller.include? @projName
          myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          myList << "[#{$1.gsub(/eval/, @projName)}] "
          break
        end
      end
    end
    myList
  end

  def get_call_array(depth = 9)
    arr       = []
    call_list = Kernel.caller
    call_list.each_index do |x|
      myCaller = call_list[x].to_s
      break if x > depth or myCaller =~ /:in .run.$/
      myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
      arr << $1.gsub(/eval/, @myName)
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
          msg <<"\n==== cell: #{cell_cnt}\n#{cell.inspect}\n#{row}\ntext: '#{cell.text}'"
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
        msg <<"\n==== cell: #{cell_cnt}\n#{cell.inspect}\n#{row}\ntext: '#{cell.text}'"
      end
    end
    debug_to_log(msg)
  end

  alias dump_table_rows dump_table_rows_and_cells

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

  def dump_row_cells(row)
    msg      = ''
    cell_cnt = 0
    msg <<"\n=================\nrow: #{row.inspect}\n#{row}\ntext:'#{row.text}'"
    row.each do |cell|
      cell_cnt += 1
      msg <<"\n==== cell: #{cell_cnt}\n#{cell.inspect}\n#{row}\ntext: '#{cell.text}'"
    end
    debug_to_log(msg)
  end

  def dump_select_list_options(element)
    msg     = "#{element.inspect}"
    options = element.options
    cnt     = 1
    options.each do |o|
      msg << "\n\t#{cnt}:\t'#{o}"
      cnt += 1
    end
    debug_to_log(msg)
  end

end
