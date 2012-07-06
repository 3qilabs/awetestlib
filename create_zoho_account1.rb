module CreateZohoAccount1

  def run_test(browser)
    create_account_scenario_1(browser)
    create_account_scenario_2(browser)
  end

  def create_account_scenario_1(browser)
    create_account(browser)
    create_blank_new_account(browser)
    export_accounts(browser)
    import_accounts(browser)
    signout(browser)
  end

  def create_account_scenario_2(browser)
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
    wait_until_ready(browser, :name, /Account Name/)
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
    click(browser, :cell, :text, 'Billing to Shipping')
    click_button_by_value(browser, 'Save')

    wait_until_by_text(browser, 'Test Account #1')
    validate_text(browser, "Test Account #1")
    validate_text(browser, "random")
  end

  def test_account_lookup(browser)
    mark_testlevel('Account Lookup', 1)
    click(browser, :image, :title, 'Account Name Lookup')
    sleep_for(5)
    popup = attach_browser_by_url(browser, /Parent Account/)
    set_textfield_by_name(popup, 'fldValue', 'test account #00')
    click_button_by_value(popup, 'Go')
    click(popup, :link, :text, 'Test Account #007')
    browser = attach_browser_by_url(browser, /ShowHomePage/)
    validate_textfield_value_by_name(browser, /Parent Account/, 'Test Account #007')
  end


end
