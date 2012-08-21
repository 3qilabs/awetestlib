module Awetestlib
  module Regression
    module Legacy

      #--
      ##def open_log
      #  start = Time.now.to_f.to_s
      #
      #  logTS = Time.at(@myRun.launched.to_f).strftime("%Y%m%d%H%M%S")
      #  xls = @myAppEnv.xls_name.gsub('.xls', '') + '_' if  @myAppEnv.xls_name.length > 0
      #  @logFileSpec = "#{@myRoot}/#{logdir}/#{@myName}_#{@targetBrowser.abbrev}_#{xls}#{logTS}.log"
      #  init_logger(@logFileSpec, @myName)
      #
      #                                                  #    message_tolog( self.inspect )
      #  message_to_log("#{@myName} launched at [#{@myRun.launched.to_f.to_s}][#{@myScript.id}][#{@myRun.id}][#{@myChild.id}]")
      #  debug_to_log("pid: #{$$}")
      #  message_to_log("#{@myName} begin at [#{start}]")
      #  message_to_log("#{@myName} environment [#{@myAppEnv.name}]")
      #  message_to_log("#{@myName} xls_name [#{@myAppEnv.xls_name}]") if  @myAppEnv.xls_name.length > 0
      #  message_to_log("#{@myName} rootDir [#{@myRoot}]")
      #  message_to_log("#{@myName} Target Browser [#{@targetBrowser.name}]")
      #  mark_testlevel(@myParent.name, @myParent.level) # Module
      #  mark_testlevel(@myChild.name, @myChild.level) # SubModule
      #
      #end
      #++

      #def find_me(where, how, what)
      #  me = where.element(how, what)
      #  puts me.inspect
      #rescue
      #  error_to_log("#{where.inspect} doesn't seem to respond to element() #{$!}")
      #end

    #  def click_me(element)
    #    element.click
    #  rescue
    #    error_to_log("#{element.inspect} doesn't seem to respond to click() #{$!}")
    #  end


    end
  end
end

