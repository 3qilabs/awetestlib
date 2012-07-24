module CreateZohoAccount2

  def run_test(browser)
    create_account_scenario_1(browser)
    create_account_scenario_2(browser)
  end

  def create_account_scenario_1(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 1)
    create_account(browser)
    create_blank_new_account(browser)
    export_accounts(browser)
    import_accounts(browser)
    signout(browser)
  end

  def create_account_scenario_2(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 1)
    create_blank_new_account(browser)
    reports(browser)
    clone_account(browser)
    pagination(browser)
    verify_accounts(browser)
    search_accounts(browser)
    signout(browser)
  end

  def create_account(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 1)
    sleep_for(3)
    click_text(browser, 'New Account')
    wait_until_ready(browser, :name, /Account Name/)
    set_textfield_by_name(browser, /Account Name/, @var['account_name'], "*** cza007 ***")
    set_textfield_by_name(browser, /Phone/, @var['account_phone'], "*** cza007 ***")

    test_account_lookup(browser)
    browser = attach_browser_by_url(browser, /ShowHomePage/)

    select_option_by_name_and_option_text(browser, /Account Type/, @var['account_type'], "*** cza003a ***")
    select_option_by_name_and_option_text(browser, /Industry/, @var['account_industry'], "*** cza003b ***")
    set_textfield_by_name(browser, /Billing Street/, @var['account_billing_street'], "*** cza003c ***")
    set_textfield_by_name(browser, /Billing City/, @var['account_billing_city'], "*** cza003d ***")
    set_textfield_by_name(browser, /Billing State/, @var['account_billing_state'], "*** cza003e ***")
    set_textfield_by_name(browser, /Billing Code/, @var['account_billing_zipcode'], "*** cza003f ***")
    set_textfield_by_name(browser, /Billing Country/, @var['account_country'], "*** cza003g ***")

    #browser.cell(:text, 'Billing to Shipping').click
    click(browser, :cell, :text, 'Billing to Shipping', "*** cza004 ***")
    click_button_by_value(browser, 'Save')

    wait_until_by_text(browser, @var['account_name'])
    validate_text(browser, @var['account_name'], "*** cza005 ***")
    validate_text(browser, "random", "*** cza006 ***")
  end

  def test_account_lookup(browser)
    mark_testlevel("#{__method__.to_s.titleize}", 1)
    click(browser, :image, :title, 'Account Name Lookup')
    #sleep_for(5)
    popup = attach_browser_by_url(browser, /Parent Account/, "*** cza001 ***")
    if popup
      set_textfield_by_name(popup, 'fldValue', @var['parent_account_pattern'])
      click_button_by_value(popup, 'Go')
      click(popup, :link, :text, @var['parent_account'])
      # TODO: This next line is currently required for Firefox and Chrome to return to original browser window      browser = attach_browser_by_url(browser, /ShowHomePage/)
      validate_textfield_value_by_name(browser, /Parent Account/, @var['parent_account'], "*** cza002 ***")
    end
  end

end
