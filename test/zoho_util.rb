module ZohoUtil

  def run
    if @xls_path
      get_variables(@xls_path, :role)
      @login.each_key do |key|
        if @login[key]['enabled'] == 'Y'
          @user = @login[key]['userid']
          @pass = @login[key]['password']
          @role = @login[key]['role']
          @url1 = @login[key]['url']
          debug_to_report("@user: #{@user}, @pass: #{@pass}, @role: #{@role} (#{__LINE__})")
          break
        end
      end
    else
      @user = "joeklienwatir@gmail.com"
      @pass = 'watir001'
      @url1 = "https://accounts.zoho.com/login?serviceurl=https://www.zoho.com/&hide_signup=true&css=https://www.zoho.com/css/login.css"
    end

    home_url   = 'https://crm.zoho.com/crm/ShowHomePage.do'
    validation = 'Welcome joeklienwatir at Software'

    browser = open_browser
    go_to_url(browser, @url1)
    zoho_login(browser, @user, @pass, home_url, validation)
    run_test(browser)
    logout(browser)

  rescue
    fatal_to_log("#{@myName} '#{$!}'")
    browser.close
    raise
  end

  def zoho_login(browser, userid, password, url, validation = 'Welcome joeklienwatir at Software')
    msg = build_message("#{__method__.to_s.titleize}", "userid:'#{userid}",
                        "password:'#{password}", "URL:#{url}")
    mark_testlevel(msg, 8)
    set_textfield_by_name(browser, 'lid', userid)
    set_textfield_by_name(browser, 'pwd', password)
    click_button_by_value(browser, 'Sign In')
    go_to_url(browser, url)
    validate_text(browser, validation)
  end

  def navigate_to_crm(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 3)
    click_text(browser, 'CRM')
  end

  def navigate_to_project(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 3)
    click_text(browser, 'Projects')
  end

  def signout(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 8)
    click_text(browser, /Sign Out/)
  end

  def create_blank_new_account(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 3)
    click_text(browser, 'New Account')
    validate_text(browser, 'Create Account')
    click_button_by_value(browser, 'Save')
    sleep(1)
    close_popup(browser, 'Message from webpage')
  end

  def export_accounts(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 5)
    click_text(browser, 'Setup')
    sleep_for(2)
    click_text(browser, 'Export Data')
    sleep_for(2)
    select_option_by_name_and_option_value(browser, 'module', 'Accounts')
    if @use_sikuli
      run_sikuli_script("exportaccounts")
      close_popup(browser, 'File Download')
    else
      #click_button_no_wait_by_value(browser, 'Export')
      # Make sure popups are allowed by browser

      mark_testlevel("#{__method__.to_s.titleize} Download", 4)
      filename = 'Account_Export.cvs'
      filepath = "#{@myRoot}/#{filename}"
      filepath.gsub!('/', '\\')
      message_to_log("#{filepath.to_s}")
      if File.exist?(filepath)
        File.delete(filepath)
      end
      sleep(3)

      click_button_no_wait_by_value(browser, 'Export')
      sleep_for(5)
      close_popup(browser, 'Message from webpage', 'Are you sure?')
      sleep_for(1)

      click_button_no_wait_by_value(browser, 'Export')
      sleep_for(3)
      close_popup(browser, 'Message from webpage', 'Are you sure?')
      sleep_for(3)

      save_file1(filepath)
      sleep_for(4)

      #if popup_exists?(popup, 'File Download')
      #  save_file(filepath)
      #  click_popup_button('File Download', 'Save')
      #  file_download(browser)
      #  save_file_orig(filepath)
      #  close_popup_by_button_title(popup, 'Close', 'Download Complete')
      #end
    end
  end

  def import_accounts(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 5)
    #click_class(browser, 'menuOn', 'Accounts')
    click_text(browser, 'Accounts')
    click_text(browser, 'Import Accounts')
    click(browser, :button, :value, 'Import Accounts')
    validate_text(browser, 'Import Accounts')
    #click_button_by_name(browser, 'theFile')
    #file_upload(filepath)
    #click_button_by_class(browser, 'button')
    #select_option_by_name_and_option_value(browser, 'CrmAccount:ACCOUNTNAME', 'Account Name')
    #click_button_by_class(browser, 'button')
    #click_button_by_value(browser, 'Import')
    #validate_no_text(browser, '0', 'No of Records added:')
  end

  def verify_accounts(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 5)
    click_text(browser, 'Accounts')
    validate_text(browser, '<No Accounts found >')
    #select_option_by_class_and_option_value(browser, 'select', 'My Accounts')
    #sleep(1)
    #select_option_by_class_and_option_value(browser, 'select', 'New This Week')
    #sleep(1)
    #select_option_by_class_and_option_value(browser, 'select', 'New Last Week')
    #sleep(1)
    #select_option_by_class_and_option_value(browser, 'select', 'Unread Accounts')
    #sleep(1)
  end

  def reports(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 6)
    click_text(browser, 'Reports')
    validate_text(browser, 'Recently Accessed Reports')
    validate_text(browser, '<No Recent Reports Found >')
  end

  def search_accounts(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 6)
    select_option_by_name_and_option_value(browser, 'searchCategory', 'Accounts')
    set_textfield_by_id(browser, 'searchword', 'Test Account #1')
    click_button_by_value(browser, 'Go')
    sleep(3)
    validate_text(browser, 'Search Results')
  end

  def clone_account(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 5)
    click_text(browser, 'Home')
    sleep(1)
    validate_text(browser, 'Welcome tester at Software')
    click_text(browser, 'Tester')
    sleep(2)
    validate_text(browser, 'Lead Details')
    validate_text(browser, 'Lead Information')
    click_button_by_name(browser, 'Clone')
    sleep(2)
    validate_text(browser, 'Clone Account')
    click_button_by_value(browser, 'Save')
  end

  def pagination(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 6)
    click_text(browser, 'Accounts')
    sleep(1)
    click_text(browser, 'A')
    sleep(1)
    click_text(browser, 'B')
    sleep(1)
    click_text(browser, 'C')
    sleep(1)
    click_text(browser, 'D')
    sleep(1)
    click_text(browser, 'E')
    sleep(1)
    click_text(browser, 'F')
    sleep(1)
  end

  def click_headers(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 6)
    click_text(browser, 'Leads')
    sleep(1)
    click_text(browser, 'Accounts')
    sleep(1)
    click_text(browser, 'Contacts')
    sleep(1)
    click_text(browser, 'Potentials')
    sleep(1)
    click_text(browser, 'Campaigns')
    sleep(1)
    click_text(browser, 'Reports')
    sleep(1)
    click_text(browser, 'Dashboards')
    sleep(1)
    click_text(browser, 'Activities')
    sleep(1)
    click_text(browser, 'Cases')
    sleep(1)
  end

  def new_lead(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 3)
    click_text(browser, 'Leads')
    sleep(2)
    validate_text(browser, 'Leads: All Open Leads')
    click_button_by_value(browser, 'New Lead ')
    sleep(2)
    validate_text(browser, 'Create Lead')
    select_option_by_name_and_option_value(browser, 'property(saltName)', 'Mr.')
                                                                               #browser.select_list(:name, 'property(saltName)').select_value(Mr.)

    set_textfield_by_name(browser, 'property(Company)', 'Test Zoho Company')
    set_textfield_by_name(browser, 'property(Last Name)', 'Tester')
    set_textfield_by_name(browser, 'property(Phone)', '415-999-9999')

    select_option_by_name_and_option_value(browser, 'property(Lead Source)', 'Advertisement')
    select_option_by_name_and_option_value(browser, 'property(Industry)', 'ASP')
    select_option_by_name_and_option_value(browser, 'property(Lead Status)', 'Contacted')
    select_option_by_name_and_option_value(browser, 'property(Rating)', 'Active')


    browser.image(:title, 'Calculator').click
    sleep(4)
    attach_popup_by_url(browser, "https://crmold.zoho.com/crm/Calc.do?currFld=property(Annual%20Revenue)")
    sleep(3)
    close_modal_ie(browser, 'Calculator')
    set_checkbox_by_name(browser, 'property(Email Opt Out)')
    sleep(2)
    clear_checkbox_by_name(browser, 'property(Email Opt Out)')


    set_textfield_by_name(browser, 'property(Street)', '1600 Holloway Avenue') ## Address
    set_textfield_by_name(browser, 'property(State)', 'California')
    set_textfield_by_name(browser, 'property(City)', 'San Francisco')
    set_textfield_by_name(browser, 'property(Zip Code)', '94541')
    set_textfield_by_name(browser, 'property(Country)', 'USA')

    set_textfield_by_name(browser, 'property(Description)', 'This is a description')
    click_button_by_value(browser, 'Save')
    sleep(2)
  end

  def find_leads(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 5)
    click_text(browser, 'Leads')
    sleep(1)
    set_textfield_by_name(browser, 'newsearchString', 'Test Zoho Company')
    click_button_by_name(browser, 'Go')
    sleep(2)
    validate_text(browser, 'Test Zoho Company')
  end

  def leads_delete_message(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 4)
    click_text(browser, 'Leads')
    sleep(1)
    set_checkbox_by_name(browser, 'allcheck')
    sleep(1)
    clear_checkbox_by_name(browser, 'allcheck')
    sleep(1)
    click_button_by_value(browser, 'Delete')
    sleep(1)
    close_popup(browser, 'Message from webpage')
  end

  def find_lead_reports(browser) ## Find Lead Reports by Source
    mark_testlevel("#{__method__.to_s.titleize}", 6)
    click_text(browser, 'Reports')
    sleep(2)
    click_text(browser, 'Lead Reports')
    sleep(2)
    click_text(browser, 'Leads By Source')
    sleep(2)
    validate_text(browser, 'Leads By Source')

    select_option_by_name_and_option_value(browser, 'stdDateFilter', 'today')
    click_button_by_value(browser, 'Apply Filter')
    sleep(2)
    validate_text(browser, 'tester')
  end

  def create_chart(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 7)
    click_button_by_value(browser, 'Delete Chart')
    sleep(2)
    click_button_by_value(browser, 'Create Chart')
    sleep(2)
    validate_text(browser, 'Create Chart: Leads By Source')

    browser.frame(:name, 'chartLayer').cell(:text, 'Vertical Bar').click

    #click_id(browser, 'chart1')  ## Vertical Bar chart
    sleep(2)
    click_button_by_value(browser, 'Save')
    sleep(3)
  end

  def create_campaign(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 7)
    click_text(browser, 'Home')
    sleep(1)
    click_text(browser, 'Create Campaign')
    set_textfield_by_name(browser, 'property(Campaign Name)', 'Zoho Campaign')
    select_option_by_name_and_option_value(browser, 'property(Type)', 'Conference')
    select_option_by_name_and_option_value(browser, 'property(Status)', 'Planning')
    sleep(1)
    set_textfield_by_name(browser, 'property(Start Date)', '03/11/2012')
    set_textfield_by_name(browser, 'property(End Date)', '05/20/2012')
    #browser.button(:onclick, 'showCalc('property(Actual Cost)')'

  end

  def create_task(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 8)
    click_text(browser, 'Home')
    sleep(1)
    click_text(browser, 'New Task')
    sleep(2)
    validate_text(browser, 'Create Task')

    browser.image(:title, 'Subject Name Lookup').click
    sleep(2)
    popup = attach_browser_by_url(browser, /Subject/)

    sleep(2)
    popup.link(:text, 'Product Demo').click
    validate_textfield_value_by_name(browser, /Subject/, 'Product Demo')

    set_textfield_by_name(browser, 'property(Due Date)', '03/11/2012')
    select_option_by_name_and_option_value(browser, 'property(leContModSel)', 'Leads')
    sleep(1)
    select_option_by_name_and_option_value(browser, 'property(leContModSel)', 'Contacts')

    browser.image(:id, 'modNameImg').click
    sleep(2)
    #attach_popup(browser, :title, /Zoho CRM - Account Name Lookup/)
    popup = attach_browser_by_url(browser, "https://crmold.zoho.com/crm/Search.do?searchmodule=Accounts&fldName=modname&fldId=modid&fldLabel=Accounts&fldValue=&user=undefined&condition=undefined")
    sleep(1)
    set_textfield_by_name(popup, 'fldValue', 'Test Account #1')
    click_button_by_value(popup, 'Go')
    popup.link(:text, 'Test Account #1').click
    close_modal_ie(browser, 'Account Name Lookup')
    sleep(2)

    select_option_by_name_and_option_value(browser, 'property(Status)', 'In Progress')
    select_option_by_name_and_option_value(browser, 'property(Priority)', 'Normal')
    set_textfield_by_name(browser, 'property(Description)', 'This is the task information')
    click_button_by_value(browser, 'Save')
    sleep(3)
  end

########################################################################
# EVERYTHING BELOW: TEMPORARY OVERRIDES/ADDITIONS NOT YET IN SHAMISEN  pmn 12jul1012
########################################################################

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

end
