module ZohoUtil

  def run
   #mark_testlevel(">> Starting #{@myName}", 9)

   #zohofile = "#{@myRoot}/zoho_variables.xls"
   #@zohologin = Excel.new(zohofile)

   browser = open_browser
   login(browser)
   test_zoho(browser)

   sleep(3)
   login_2(browser)
   test_zoho_2(browser)
  end

  def login(browser)
    mark_testlevel('Zoho Login', 2)
    user = "joeklienwatir@gmail.com" #@zohologin.cell(2,2)
    password = "watir001" #@zohologin.cell(2,3)
    browser.goto("https://accounts.zoho.com/login?serviceurl=https://www.zoho.com/&hide_signup=true&css=https://www.zoho.com/css/login.css")
    set_textfield_by_name(browser, 'lid', user)
    set_textfield_by_name(browser, 'pwd', password)
    click_button_by_value(browser, 'Sign In')
    go_to_url(browser, url = 'https://crm.zoho.com/crm/ShowHomePage.do')
    validate_text(browser, 'Welcome joeklienwatir at Software')
    #click_text(browser, 'Old Version')

  end

  def login_2(browser)
    mark_testlevel('Zoho Login', 2)
    user = "joeklienwatir@gmail.com" #@zohologin.cell(2,2)
    password = "watir001" #@zohologin.cell(2,3)
    browser.goto("https://accounts.zoho.com/login?serviceurl=https://www.zoho.com/&hide_signup=true&css=https://www.zoho.com/css/login.css")
    set_textfield_by_name(browser, 'lid', user)
    set_textfield_by_name(browser, 'pwd', password)
    click_button_by_value(browser, 'Sign In')
    go_to_url(browser, url = 'https://crm.zoho.com/crm/ShowHomePage.do')
    validate_text(browser, 'Welcome joeklienwatir at Software')
    #click_text(browser, 'Old Version')

  end

  def navigate_to_crm(browser)
    mark_testlevel('Navigate to CRM', 1)
    click_text(browser, 'CRM')
  end

  def navigate_to_project(browser)
    mark_testlevel('Navigate to Project', 0)
    click_text(browser, 'Projects')
  end

  def signout(browser)
    mark_testlevel('Sign Out', 9)
    click_text(browser, /Sign Out/)
  end

  def create_blank_new_account(browser)
    mark_testlevel('Create a blank Account',2)
    click_text(browser, 'New Account')
    validate_text(browser, 'Create Account')
    click_button_by_value(browser, 'Save')
    sleep(1)
    close_popup('Message from webpage')
  end

  def export_accounts(browser)
    mark_testlevel('Export Accounts',5)
    click_text(browser, 'Setup')
    sleep_for(2)
    click_text(browser,'Export Data')
    sleep_for(2)
    select_option_by_name_and_option_value(browser, 'module', 'Accounts')
    if use_sikuli
      run_sikuli_script("exportaccounts")
      close_popup('File Download')
    else
      click_button_by_value(browser, 'Export')

      mark_testlevel('Download', 1)
      filename = 'Account_Export.cvs'
      filepath = "#{@myRoot}/downloads/#{filename}"
      filepath.gsub!('/','\\')
      message_to_log("#{filepath.to_s}")
      if File.exist?(filepath)
        File.delete(filepath)
      end
      sleep(3)

      click_button_no_wait_by_value(browser, 'Export')
      sleep_for(6)
      save_file_here(filepath)
      sleep_for(4)

      popup_exists?(popup, 'File Download')
      save_file(filepath)
      click_popup_button('File Download', 'Save')
      file_download(browser)
      save_file_orig(filepath)
      close_popup_by_button_title(popup, 'Close', 'Download Complete')
    end
  end

  def import_accounts(browser)
    mark_testlevel('Import Accounts',6)
    #click_class(browser, 'menuOn', 'Accounts')
    click_text(browser, 'Accounts')
    click_text(browser, 'Import My Accounts')
    validate_text(browser, 'Import My Accounts Wizard')
    #click_button_by_name(browser, 'theFile')
    #file_upload(filepath)
    #click_button_by_class(browser, 'button')
    #select_option_by_name_and_option_value(browser, 'CrmAccount:ACCOUNTNAME', 'Account Name')
    #click_button_by_class(browser, 'button')
    #click_button_by_value(browser, 'Import')
    #validate_no_text(browser, '0', 'No of Records added:')
  end

  def verify_accounts(browser)
    mark_testlevel('Verify Accounts', 3)
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
    mark_testlevel('Reports', 4)
    click_text(browser, 'Reports')
    validate_text(browser, 'Recently Accessed Reports')
    validate_text(browser, '<No Recent Reports Found >')
  end

  def search_accounts(browser)
    mark_testlevel('Search Accounts', 6)
    select_option_by_name_and_option_value(browser, 'searchCategory', 'Accounts')
    set_textfield_by_id(browser, 'searchword', 'Test Account #1')
    click_button_by_value(browser, 'Go')
    sleep(3)
    validate_text(browser, 'Search Results')
  end

  def clone_account(browser)
    mark_testlevel('Clone a Lead Account', 5)
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
    mark_testlevel('Pagination', 6)
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
    mark_testlevel('Click Headers', 10)
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
    mark_testlevel('New Lead', 3)
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


    set_textfield_by_name(browser, 'property(Street)', '1600 Holloway Avenue')   ## Address
    set_textfield_by_name(browser, 'property(State)', 'California')
    set_textfield_by_name(browser, 'property(City)', 'San Francisco')
    set_textfield_by_name(browser, 'property(Zip Code)', '94541')
    set_textfield_by_name(browser, 'property(Country)', 'USA')

    set_textfield_by_name(browser, 'property(Description)', 'This is a description')
    click_button_by_value(browser, 'Save')
    sleep(2)
  end

  def find_leads(browser)
    mark_testlevel('Find Leads', 4)
    click_text(browser, 'Leads')
    sleep(1)
    set_textfield_by_name(browser, 'newsearchString', 'Test Zoho Company')
    click_button_by_name(browser, 'Go')
    sleep(2)
    validate_text(browser, 'Test Zoho Company')
  end

  def leads_delete_message(browser)
    mark_testlevel('Leads Delete', 5)
    click_text(browser, 'Leads')
    sleep(1)
    set_checkbox_by_name(browser, 'allcheck')
    sleep(1)
    clear_checkbox_by_name(browser, 'allcheck')
    sleep(1)
    click_button_by_value(browser, 'Delete')
    sleep(1)
    close_popup('Message from webpage')
  end

  def find_lead_reports(browser)         ## Find Lead Reports by Source
    mark_testlevel('Lead Reports', 6)
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
    mark_testlevel('Create Chart', 7)
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
    mark_testlevel('Create Campaign', 7)
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
    mark_testlevel('Create Task', 8)
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


    #browser.image(:title, 'Calculator').click
    #sleep(4)
    #attach_popup_by_url(browser, "https://crmold.zoho.com/crm/Calc.do?currFld=property(Annual%20Revenue)")
    #sleep(3)
    #close_modal_ie(browser, 'Calculator')

  def save_file(filepath)
    ai = WIN32OLE.new("AutoItX3.Control")
    ai.WinWait("File Download", "", 5)
    ai.ControlFocus("File Download", "", "&Save")
    sleep 1
    ai.ControlClick("File Download", "", "&Save", "left")
    ai.WinWait("Save As", "", 5)
    sleep 1
    ai.ControlSend("Save As", "", "Edit1",filepath)
    ai.ControlClick("Save As", "", "&Save", "left")
    ai.WinWait("Download complete", "", 5)
    ai.ControlClick("Download complete", "", "Close")
  end

  def click_button_no_wait_by_value(browser, strg, desc = '')

  if not desc and not strg.match(/Save|Open|Close|Submit|Cancel/)

    desc = 'to navigate to selection'
  end
  begin
    browser.button(:value, strg).click_no_wait

    if validate(browser, @myName, __LINE__)
      log_message(INFO, 'Button "' + strg.to_s + '" (by :value) clicked ' + desc, PASS)

      true
    end
  rescue
    log_message(ERROR, 'Button "' + strg.to_s + '" (by :value) not found ', FAIL)

  end
 end

  def save_file_here( filepath )
    begin
      limit = 120.seconds
      #Timeout::timeout( limit ) {
        wait = 20
        ai = WIN32OLE.new("AutoItX3.Control")
        ai.WinWait("File Download - Security Warning", "", wait)
        ai.ControlFocus("File Download - Security Warning", "", "&Save")
        sleep 1
        ai.ControlClick("File Download - Security Warning", "", "&Save", "left")
        ai.WinWait("Save As", "", wait)
        sleep 1
        ai.ControlSend("Save As", "", "Edit1", filepath)
        ai.ControlClick("Save As", "", "&Save", "left")
        sleep 1
        ai.WinWait("Download complete", "", wait)
        ai.ControlClick("Download complete", "", "Close")
        sleep 1
      #}
      passed_to_log('Download Complete')
    rescue Timeout::Error
      failded_to_log("File Download timeout after #{limit} (#{$!})")
    end
  end

###################### METHODS #############
#  def click_button_no_wait_by_value(browser, strg, desc = '')
#    if not desc and not strg.match(/Save|Open|Close|Submit|Cancel/)
#      desc = 'to navigate to selection'
#    end
#    begin
#      if @browserAbbrev == 'FF'
#        browser.button(:value, strg).click
#      else
#        browser.button(:value, strg).click_no_wait
#      end
#      if validate(browser, @myName, __LINE__)
#        passed_to_log('Button "' + strg.to_s + '" (by :value) clicked ' + desc)
#        true
#      end
#
#    rescue
#      failed_to_log('Button "' + strg.to_s + '" (by :value) not found ')
#    end
#  end
#
#
#

  #
  #def test_account_lookup(browser)
  #  mark_testlevel('Account Lookup', 7)
  #  browser.image(:title, 'Account Name Lookup').click
  #  sleep_for(5)
  #  popup = attach_popup_by_url(browser, /Parent Account/)
  #  set_textfield_by_name(popup, 'fldValue', 'test')
  #  click_button_by_value(popup, 'Go')
  #  popup.link(:text, 'Test Account #007').click
  #  validate_textfield_value_by_name(browser, /Parent Account/, 'Test Account #007')
  #end

    def get_variables(file, login = :role)
      @var                   = Hash.new
      workbook               = Excel.new(file)
      data_index             = find_sheet_with_name(workbook, 'Data')
      workbook.default_sheet = workbook.sheets[data_index]

      2.upto(workbook.last_column) do |col|
        script_name = workbook.cell(1, col)
        if script_name == @myName
          @varCol = col
          break
        end
      end

      2.upto(workbook.last_row) do |line|
        name       = workbook.cell(line, 'A')
        value      = workbook.cell(line, @varCol).to_s
        @var[name] = value
      end

      @var.each do |name, value|
        message_tolog("@var #{name}: '#{value}'")
      end

      @login     = Hash.new
      role_index = find_sheet_with_name(workbook, 'Login')
      if role_index >= 0
        workbook.default_sheet = workbook.sheets[role_index]

        4.upto(workbook.last_column) do |col|
          script_name = workbook.cell(1, col)
          if script_name == @myName
            @login_column = col
            break
          end
        end

        2.upto(workbook.last_row) do |line|
          role     = workbook.cell(line, 'A')
          userid   = workbook.cell(line, 'B')
          password = workbook.cell(line, 'C')
          url      = workbook.cell(line, 'D')
          enabled  = workbook.cell(line, @login_column).to_s

          case login
            when :id
              key = userid
            when :role
              key = role
            else
              key = role
          end

          if enabled == 'Y'
            @login['role']     = role
            @login['url']      = url
            @login['userid']   = userid
            @login['password'] = password
          end
          #if enabled == 'Y'
          #  @login[key]             = Hash.new
          #  @login[key]['role']     = role
          #  @login[key]['url']      = url
          #  @login[key]['userid']   = userid
          #  @login[key]['password'] = password
          #  @login[key]['enabled']  = enabled
          #end

        end

        @login.each do |key, data|
          message_tolog("@login (by #{login}): #{key}=>'#{data}'")
        end
      end

    end

end
