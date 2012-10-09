module ZohoExercise
  $watir_script = true

  def run
    browser = open_browser
    go_to_url(browser, 'http://crm.zoho.com/crm/login.sas')
    sleep_for(2)
    logon_to_zoho(browser)
    logout(browser)
  end

  def logon_to_zoho(browser)
    mark_testlevel("#{__method__.to_s.humanize}", 8)
    click(browser, :link, :text, 'Sign In')
    sleep_for(2)
    frame = get_frame(browser, :id, 'zohoiam')
    set_text_field(frame, :id, 'lid', 'joeklienwatir@gmail.com')
    set_text_field(frame, :name, 'pwd', 'watir001')
    sleep(1)
  end
end
