module PopupChild1
#http://www.entheosweb.com/website_design/pop_up_windows.asp

  def run
    browser = open_browser
    #go_to_url(browser, 'http://www.entheosweb.com')
    go_to_url(browser, 'http://www.entheosweb.com/website_design/pop_up_windows.asp')

    wait_until_ready(browser, :text, 'Click here')

    click(browser, :link, :text, 'Click here')
    popup = attach(browser, :title, 'Preview Business Template 1')

    if popup
      validate_text(popup, 'Smart Rollover Pictures')

      verify_rollover(popup, 'Services')

      close_child_window(popup)
    end

    sleep(1)

    close_browser(browser)

  end

  def verify_rollover(popup, heading)
    mark_test_level
    true
  end

end
