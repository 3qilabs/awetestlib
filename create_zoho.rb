module CreateZoho
## put variables.xls in project directory

  def test_zoho(browser)
    #get_variables("#{@myRoot}/zoho_variables.xls")
    #navigate_to_crm(browser) #In Project Util
    create_account(browser)
    create_blank_new_account(browser)
    export_accounts(browser)
    import_accounts(browser)
    signout(browser)
  end

  def test_zoho_2(browser)
    create_blank_new_account(browser)
    reports(browser)
    clone_account(browser)
    pagination(browser)
    verify_accounts(browser)
    search_accounts(browser)
    signout(browser)
  end

  def create_account(browser)
    mark_testlevel('Create New Account', 1)
    sleep_for(3)
    click_text(browser, 'New Account')
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
    browser.cell(:text, 'Billing to Shipping').click
    click_button_by_value(browser, 'Save')


    wait_until_by_text(browser, 'Test Account #1')
    validate_text(browser, "Test Account #1")
    validate_text(browser, "random")
  end

  def test_account_lookup(browser)
    mark_testlevel('Account Lookup', 1)
    browser.image(:title, 'Account Name Lookup').click
    sleep_for(5)
    popup = attach_browser_by_url(browser, /Parent Account/)
    set_textfield_by_name(popup, 'fldValue', 'test')
    click_button_by_value(popup, 'Go')
    popup.link(:text, 'Test Account #007').click
    browser = attach_browser_by_url(browser, /ShowHomePage/)
    validate_textfield_value_by_name(browser, /Parent Account/, 'Test Account #007')
  end

end
