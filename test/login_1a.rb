module Login1a

  def run

    browser = open_browser

    go_to_url(browser, 'www.yahoo.com')
    sleep(5)
    click(browser, :link, :text, 'Sign In')
    sleep(5)
    set_textfield(browser, :id, 'username', 'awetesta@yahoo.com')
    set_textfield(browser, :id, 'passwd', 'awetest001')
    click(browser, :button, :text, 'Sign In')
    sleep(8)
    validate_text(browser, 'HI, A')
    sleep(8)
    click(browser, :link, :text, 'Sign Out')

    sleep(8)

    go_to_url(browser, 'www.yahoo.com')
    sleep(5)
    click(browser, :link, :text, 'Sign In')
    sleep(5)
    set_textfield(browser, :id, 'username', 'awetestt3@yahoo.com')
    set_textfield(browser, :id, 'passwd', 'awetest001')
    click(browser, :button, :text, 'Sign In')
    sleep(8)
    validate_text(browser, 'HI, T-THREE')
    sleep(8)
    click(browser, :link, :text, 'Sign Out')

    browser.close

  end

end
