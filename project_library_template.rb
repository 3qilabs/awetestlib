module ProjectLibraryTemplate

  # module name is camel-case of file name which should be snake case

  def run
    load_libraries
    start_run unless awetestlib?
    # setup_project

    # NOTE: Replace all xxxx with your project acronym in lowercase.

    begin
      @xls_spec = set_xls_spec('xxxx', 'uat') # project acronym and environment acronym
    rescue
      debug_to_report 'Unable to set xls_spec'
    end

    if get_variables(@xls_spec, :environment)

      url        = ''
      company_id = ''
      user_id    = ''
      password   = ''
      app_id     = ''

      if @env_name and @env_name.length > 0
        env        = @env_name.sub(/^xxxx_/i, '') # a bit of a hack. will help with this and try to fix
        url        = @login[env]['url']
        company_id = @login[env]['companyid']
        user_id    = @login[env]['userid']
        password   = @login[env]['password']
        app_id     = @login[env]['appid']
        node = @login[env]['nodename']
      else
        fail 'Environment name and associated login data must be supplied in data repos \'Login\''
      end

      browser = open_browser
      browser.goto(url)
      if @env_name =~ /^awe/i
        project_name = app_id
        flags        = node
        log_on_awetest(browser, user_id, password)
        run_test(browser, company_id, project_name, flags)
        sign_off_awetest(browser)
      else
        @wd_vp_offsets = window_viewport_offsets(browser)
        log_on_ceo(browser, company_id, user_id, password)
        navigate_to_application(browser, app_id, @ceo_frame)
        run_test(@app_frame)
        sign_off(browser)
      end

    end

  rescue
    failed_to_log(unable_to(@myName))
  ensure
    close_browser(browser) if browser
    finish_run(Time.now) unless awetestlib?
  end

  #================================================================================================
  #================================================================================================
  #================================================================================================
  #================================================================================================
  def load_libraries
    dsl = self.patch ? self.patch : 'awetest_dsl.rb'
    # aut = 'aut_automation_library.rb'
    prj = self.library
    scr = self.script_file

    # if awetestlib?
    #   if File.file?(aut)   #
    #     dsl_lib = dsl
    #     # aut_lib = 'aut_automation_library.rb'
    #     prj_lib = prj
    #     script  = scr
    #   elsif File.file?('../aut_automation_library/' + aut)
    #     dsl_lib = '../aut_automation_library/' + dsl
    #     # aut_lib = '../aut_automation_library/' + aut
    #     prj_lib = prj
    #     script  = scr
    #   elsif File.file?('../aut_automation/' + aut)
    #     dsl_lib = '../aut_automation/' + dsl
    #     # aut_lib = '../aut_automation/' + aut
    #     prj_lib = prj
    #     script  = scr
    #   elsif File.file?('../../../aut-automation/' + aut)
    #     dsl_lib   = '../../../aut-automation/' + dsl
    #     # aut_lib   = '../../../aut-automation/' + aut
    #     prj_lib = '../../../aut-automation/tests/automation/' + prj
    #     script  = '../../../aut-automation/tests/automation/' + scr
    #     @waft_git = true
    #   elsif File.file?("#{@myName}/" + aut)
    #     dsl_lib = "#{@myName}/" + dsl
    #     # aut_lib = "#{@myName}/" + aut
    #     prj_lib = "#{@myName}/" + prj
    #     script  = "#{@myName}/" + scr
    #   else
    #     dsl_lib = '../awetest_dsl.rb'
    #     # aut_lib = '../aut_automation_library.rb'
    #     prj_lib = "../#{prj}"
    #     script  = "../#{scr}"
    #   end
    # else
      dsl_lib = File.join(@myRoot, @myName, dsl)
      # aut_lib = File.join(@myRoot, @myName, aut)
      prj_lib = File.join(@myRoot, @myName, prj)
      script  = File.join(@myRoot, @myName, scr)
    # end

    message_to_log("dsl lib: #{dsl_lib}")
    # message_to_log("aut lib: #{aut_lib}")
    message_to_log("prj lib: #{prj_lib}")
    message_to_log("script:  #{script}")

    unless File.exists?(dsl_lib)
      raise "#{unable_to(dsl_lib)}"
    end
    # unless File.exists?(aut_lib)
    #   raise "#{unable_to(aut_lib)}"
    # end
    unless File.exists?(prj_lib)
      raise "#{unable_to(prj_lib)}"
    end
    unless File.exists?(script)
      raise "#{unable_to(script)}"
    end

    load dsl_lib
    lib_module = File.read(dsl_lib).match(/^module\s+(\w+)/)[1].constantize
    self.extend(lib_module)

    # load aut_lib
    # aut_module = File.read(aut_lib).match(/^module\s+(\w+)/)[1].constantize
    # self.extend(aut_module)

    # re-extend project library and script to capture overrides
    # load prj_lib # already loaded
    prj_module = File.read(prj_lib).match(/^module\s+(\w+)/)[1].constantize
    self.extend(prj_module)

    # load script # already loaded
    scr_module = File.read(script).match(/^module\s+(\w+)/)[1].constantize
    self.extend(scr_module)

  rescue
    failed_to_log(unable_to(msg))
  end

end
