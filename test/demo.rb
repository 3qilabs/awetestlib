module Demo
  def run
    browser = open_browser
    login(browser)
    test_zoho(browser)
  end

  def test_account_lookup(browser)
    mark_testlevel('Account Lookup', 1)
    browser.image(:title, 'Account Name Lookup').click
    sleep_for(5)
    popup = attach_browser_by_url(browser, /Parent/)
    # TODO: This should be transparent:
    if @browserAbbrev == "FF"
      popup = browser
    end
    set_textfield_by_name(popup, 'fldValue', 'test')
    click_button_by_value(popup, 'Go')
    popup.link(:text, /Test Account/).click
    #browser = attach_browser_by_url(browser, /ShowHomePage/)
    #validate_textfield_value_by_name(browser, /Parent Account/, 'Test Account #007')
  end

  def login(browser)
    mark_testlevel('Zoho Login', 2)
    user     = "joeklienwatir@gmail.com" #@zohologin.cell(2,2)
    password = "watir001"                #@zohologin.cell(2,3)
    go_to_url(browser, "https://accounts.zoho.com/login?serviceurl=https://www.zoho.com/&hide_signup=true&css=https://www.zoho.com/css/login.css")
    #browser.goto("https://accounts.zoho.com/login?serviceurl=https://www.zoho.com/&hide_signup=true&css=https://www.zoho.com/css/login.css")
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

  def test_zoho(browser)
    #get_variables("#{@myRoot}/zoho_variables.xls")
    navigate_to_crm(browser) #In Project Util
    create_account(browser)
    #create_blank_new_account(browser)
    #export_accounts(browser)
    #import_accounts(browser)
    #signout(browser)
  end

  def create_account(browser)
    mark_testlevel('Create New Account', 3)
    sleep_for(3)
    click_link(browser, 'Accounts')
    sleep_for(3)
    click_button_by_value(browser, 'New Account')
    sleep_for(5)
    # Watir::Waiter::wait_until { browser.text_field(:name, /Account Name/).exist? }
                                 # Watir::Waiter::wait_until { browser.text_field(:name, /Account Name/).visible? }
    set_textfield_by_name(browser, /Account Name/, "Test Account #1")
    set_textfield_by_name(browser, /Phone/, "415-333-2311")

    test_account_lookup(browser) #In Project Util
    browser = attach_browser_by_url(browser, /ShowHomePage/)
    select_option_by_name_and_option_text(browser, /Account Type/, "Analyst")
    select_option_by_name_and_option_text(browser, /Industry/, "ASP")
    set_textfield_by_name(browser, /Billing Street/, "201 Main St")
    set_textfield_by_name(browser, /Billing City/, "San Francisco")
    set_textfield_by_name(browser, /Billing State/, "CA")
    set_textfield_by_name(browser, /Billing Code/, "94102")
    set_textfield_by_name(browser, /Billing Country/, "USA")
                                 #browser.cell(:text, 'Billing to Shipping').click
    click_button_by_id(browser, 'copyAddress')
    sleep_for(5)
    click_button_by_value(browser, 'Save')

    sleep_for(8)
                                 #wait_until_by_text(browser, 'Test Account #1')
    validate_text(browser, "Test Account #1")
    validate_text(browser, "random")
  end

end
