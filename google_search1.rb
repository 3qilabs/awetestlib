module GoogleSearch1

  def run
    mark_testlevel("Awetestlib example: Google Search 1", 1)
    browser = open_browser
    go_to_url(browser, 'www.google.com')
    sleep_for(3)
    click_text(browser, 'News')
    set_textfield_by_id(browser, 'gbqfq', '3qilabs')
    #click(browser, :button, :id, 'gbqfb')
    validate_text(browser, '3qilabs')
    validate_text(browser, 'Stories')
    logout(browser)
  end

end
