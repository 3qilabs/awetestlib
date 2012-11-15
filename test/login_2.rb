module Login2

  def run

    if @xls_path

      get_variables(@xls_path, :userid)

      login_url = "https://accounts.zoho.com/login?serviceurl=https://www.zoho.com/&hide_signup=true&css=https://www.zoho.com/css/login.css"

      browser = open_browser

      @login.each_key do |key|
        if @login[key]['enabled'] == 'Y'
          userid    = key
          password  = @login[key]['password']
          name      = @login[key][name]

          go_to_url(browser, login_url)
          set_textfield(browser, :name, 'lid', userid)
          set_textfield(browser, :name, 'pwd', password)
          click(browser, :button, :value, 'Sign In')
          go_to_url(browser, 'https://crm.zoho.com/crm/ShowHomePage.do')
          validate_text(browser, "Welcome #{name} at Software")
          click_link(browser, :text, 'sign out')

        end
      end
    end
  end

end
