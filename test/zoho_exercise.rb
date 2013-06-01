module ZohoExercise
  #$watir_script = true

  def run
    browser = open_browser
    go_to_url(browser, 'https://accounts.zoho.com/login?servicename=ZohoCRM&serviceurl=/crm/ShowHomePage.do&hide_signup=true&css=https://www.zoho.com/css/plogin.css')
    sleep_for(2)
    logon_to_zoho(browser)
    logout(browser)
  end

  def logon_to_zoho(browser)
    mark_testlevel()
    set_text_field(browser, :id, 'lid', 'joeklienwatir@gmail.com')
    set_text_field(browser, :name, 'pwd', 'watir001')
    sleep_for(2)
    click(browser, :button, :value, 'Sign In')
    sleep_for(2)
    validate_text(browser, 'Welcome joeklienwatir at Software')
  end
end
