module TestGoogle

  def run
    mark_testlevel("This is a google test", 1)
    #browser = Watir::Browser.new :firefox
    browser = open_browser
    go_to_url(browser, 'www.google.com')
    sleep_for(3)
    click_text(browser, 'News')
    set_textfield_by_id(browser, 'q', '3qilabs')
    validate_text(browser, '3qilabs')
    validate_text(browser, 'Stories')
  end

end
