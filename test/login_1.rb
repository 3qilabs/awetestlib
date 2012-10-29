module Login1

  def run

    browser = open_browser

    go_to_url(browser, 'www.yahoo.com')
    wait_until_exists(browser, :link, :text, 'Sign In')
    click(browser, :link, :text, 'Sign In')
    wait_until_exists(browser, :text_field, :id, 'username')
    set_textfield(browser, :id, 'username', 'awetesta@yahoo.com')
    set_textfield(browser, :id, 'passwd', 'awetest001')
    #wait_until_exists(browser, :button, :text, 'Sign In')
    click(browser, :button, :text, 'Sign In')
    sleep_for(8)
    wait_until_text(browser, 'HI, A')
    sleep_for(3)
    click(browser, :link, :text, 'Sign Out')

    go_to_url(browser, 'www.yahoo.com')
    wait_until_exists(browser, :link, :text, 'Sign In')
    click(browser, :link, :text, 'Sign In')
    wait_until_exists(browser, :text_field, :id, 'username')
    set_textfield(browser, :id, 'username', 'awetestt3@yahoo.com')
    set_textfield(browser, :id, 'passwd', 'awetest001')
    #wait_until_exists(browser, :button, :text, 'Sign In')
    click(browser, :button, :text, 'Sign In')
    sleep_for(8)
    wait_until_text(browser, 'HI, T-THREE')
    sleep_for(3)
    click(browser, :link, :text, 'Sign Out')

    browser.close

  end

end
