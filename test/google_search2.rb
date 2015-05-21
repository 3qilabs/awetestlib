module GoogleSearch2

  def run
    mark_testlevel("Awetestlib example: Google Search 2")
    browser = open_browser
    go_to_url(browser, 'www.google.com')
    sleep_for(3)
    run_test(browser)
  end

  def run_test(browser)
    mark_testlevel("Search for 3qilabs in News")
    # click_text(browser, 'News')
    set_textfield_by_id(browser, 'lst-ib', '3qi labs')
    validate_text(browser, '3qi labs', '*** gs2 001 ***')
    validate_text(browser, 'Careers', '*** gs2 002 ***')
    close_browser(browser)
  end

end
