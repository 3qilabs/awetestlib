#require 'screencap'
module Logging

  def self.included(mod)
    # puts "RegressionSupport::Logging extended by #{mod}"
  end

  def log_message(severity, message, tag = '', lnbr = nil, addts = 1, exception=nil)
    # caller = get_caller(lnbr, exception)

    # @sequence ||= log_properties ? log_properties.fetch('sequence', 0) : 0
    # @sequence += 1

    t       = Time.now.utc
    @last_t ||= t

    # if log_properties
    #   log_args = {
    #     :cycle =>                 @cycle,
    #    :browser_sequence =>      @browser_sequence,
    #     :session_num =>           @session_num,
    #     :sequence =>              @sequence,
    #     :job_id =>                log_properties['job_id'],
    ##     :project_version_id =>    log_properties['project_version_id'],
    #     :test_run_id =>           log_properties['test_run_id'],
    #     :script_id =>             log_properties['script_id'],
    #     :caller =>                caller.split(":")[0] || 'unknown',
    #     :caller_line =>           caller.split(":")[1].to_i,
    #     :caller_method =>         caller.split(":")[2],
    #     :severity =>              severity,
    #     :message =>               message.gsub(/[\x80-\xff]/,"?"),
    #     :detail_timestamp =>      t.to_f.to_s,
    #     :duration =>              t.to_f-@last_t.to_f,
    #     :created_at =>            t,
    ###     :company_id =>            log_properties['company_id'],
    #     :project_id =>            log_properties['project_id'],
    #     :level =>                 tag.andand.is_a?(Fixnum) ? tag : nil,
    #     :pass =>                  pass_code_for(tag),
    #     :test_category_id =>      log_properties['test_category_id'],
    #     :test_case_id =>          log_properties['test_case_id'],
    #     :application_role_id =>   nil, # not implemented yet
    #     :screen_path =>           nil
    #   }
    #   Resque::Job.create(log_queue.to_sym, log_class, log_args) if log_queue && log_class
    #
    #   ::Screencap.capture(Shamisen::BROWSER_MAP[@browser],
    #                       log_properties['test_run_id'], @sequence, root_path) if @screencap_path
    #end

    @last_t = t

    dt       = t.strftime("%Y%m%d %H%M%S")+' '+t.usec.to_s[0, 4]
    mySev    = translate_severity(severity)
    myCaller = get_caller(lnbr) || 'unknown'

    myMsg = "%-8s" % mySev
    myMsg << '[' + dt + ']:'
    if tag
      if tag.is_a? Fixnum
        tag = '-LVL' + tag.to_s
      end
    end

    myMsg << "[%-5s]:" % tag
    #myMsg << '[' + t.to_f.to_s + ']:'
    #myMsg << '[' + myCaller + ']:'
    #myMsg << "#{get_call_list[-1]}#{get_call_list[-2]} "
    myMsg << get_call_list_new.to_s
    myMsg << ' '+message
    #    myMsg << " {#{lnbr}} " if lnbr

    # # TODO This is broken: @myBrowser is not necessarily populated
    # if @screenCaptureOn and is_browser?(@myBrowser)
    #   if severity >= @options['screenshot'] andand
    #           tag.match(/PASS|FAIL/)
    #   then
    #     capture_screen(@myBrowser, t)
    #   end
                                          # end

    @myLog.add(severity, myMsg) if @myLog # add persistent logging for awetestlib. pmn 05jun2012
    puts myMsg+"\n"

    nil # so method doesn't return whole @output.
  end

  # hate this
  def pass_code_for(tag)
    case
      when tag =~ /PASS/
        'P'
      when tag =~ /FAIL/
        'F'
      #when tag =~ /\d+/ # avoid having to require andand for awetestlib. pmn 05jun2012
      when tag.andand.is_a?(Fixnum)
        'H'
      when tag =~ /DONE/
        'D'
      when tag =~ /role/
        'R'
    end
  end

  def log_sikuli_output(output_file, passed)
    output_lines = File.open(output_file, 'r') { |f| f.readlines }
    puts "IM FAILING?! #{passed}"

                                                            # if passed

    log_messages = ['[log]', '[error]']
    output_lines = output_lines.select { |l| log_messages } #.detect{|msg| l.include?(msg)} }
    while line = output_lines.shift do
      puts "line to be logged: #{line}"
      if line.include? '[log]'
        passed_to_log line
      elsif line.include? '[error]'
        failed_to_log line
      elsif line.match /\s*Exception/
        failed_to_log output_lines.join("\n")
        break
      else
        debug_tolog line
      end
    end

    # else
    # failed_to_log "SIKULI LOG:\n\n #{output_lines.join('\n')}"
    # end

    return { :result => passed, :msg => output_str }
  end

  #private log_message


  # Put status message to the log and output window
  # TODO: figure out a way to do the leveling automatically based on actual call depth within script (and project library?)
  # When using to mark test groupings, include
  # level 'lvl' (numeric literal, 1 through 9, usually 1-4)
  # indicating test grouping hierarchy:
  #   0  lowest level test case, a single validation
  #      a.k.a TEST CASE, VALIDATION
  #      not normally used in scripts as it is
  #      implied by method with 'validate' in name
  #   1  group of closely related level 0 validations
  #      a.k.a TEST GROUP
  #      should never be followed by another level 1
  #      or higher level message without intervening
  #      level 0 validations.
  #   2  group of closely related level 1 validation sets.
  #      a.k.a TEST SET, SUBMODULE, USE CASE
  #      should never be followed by another level 2
  #      or higher level message without intervening
  #      lower levels.
  #   3  group of closely related level 2 validation sets.
  #      a.k.a TEST SET, TEST SUITE, MODULE, USE CASE
  #      should never be followed by another level 3
  #      or higher level message without intervening
  #      lower levels.
  #   4  group of closely related level 3 validation sets.
  #      a.k.a TEST SUITE, APPLICATION UNDER TEST, PLAN, PROJECT
  #      should never be followed by another level 4
  #      or higher level message without intervening
  #      lower levels. Will seldom appear directly in
  #      scripts

  def mark_testlevel(message, lvl, desc = '', dbg = nil)
    strg = ''
    strg << message
    strg << " [#{desc}]" if desc.length > 0
    strg << " \n#{get_debug_list}" if dbg or @debug_calls
    log_message(INFO, strg, lvl, 1)
  rescue
    failed_to_log("#{__method__}: #{$!}")
  end

  alias mark_test_level mark_testlevel

  def info_to_log(message, lnbr = __LINE__)
    log_message(INFO, message, nil, lnbr)
  end

  alias message_tolog info_to_log
  alias message_to_log info_to_log
  alias info_tolog info_to_log

  def debug_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" if dbg or @debug_calls # and not @debug_calls_fail_only)
    log_message(DEBUG, "#{message}", nil, lnbr)
  end

  alias debug_tolog debug_to_log

  # do not use for failed validations
  def error_to_log(message, lnbr = __LINE__)
    log_message(ERROR, message, nil, lnbr)
  end

  alias error_tolog error_to_log

  def passed_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" if dbg or @debug_calls # and not @debug_calls_fail_only)
    @my_passed_count += 1 if @my_passed_count
    log_message(INFO, "#{message}", PASS, lnbr)
  end

  alias validate_passed_tolog passed_to_log
  alias validate_passed_to_log passed_to_log
  alias passed_tolog passed_to_log
  alias pass_tolog passed_to_log
  alias pass_to_log passed_to_log

  def failed_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" # if dbg or @debug_calls or @debug_calls_fail_only
    @my_failed_count += 1 if @my_failed_count
    parse_error_references(message)
    log_message(WARN, "#{message}" + " (#{lnbr})]", FAIL, lnbr)
    #debugger if debug_on_fail
  end

  alias validate_failed_tolog failed_to_log
  alias validate_failed_to_log failed_to_log
  alias failed_tolog failed_to_log
  alias fail_tolog failed_to_log
  alias fail_to_log failed_to_log

  def fatal_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" #  if dbg or (@debug_calls and not @debug_calls_fail_only)
    @my_failed_count += 1 if @my_failed_count
    debug_to_report("#{__method__}:\n#{dump_caller(lnbr)}")
    log_message(FATAL, "#{message} (#{lnbr})", FAIL, lnbr)
  end

  #def fatal_to_log(message, lnbr = __LINE__)
  #  log_message(FATAL, "#{message} (#{lnbr})", FAIL, lnbr)
  #  log_message(DEBUG, "\n#{dump_caller(lnbr)}")
  #end

  alias fatal_tolog fatal_to_log

  def message_to_report(message, dbg = false)
    mark_testlevel("#{message}", 0, '', dbg)
  end

  def debug_to_report(message, dbg = false)
    mark_testlevel("(DEBUG):  \n", 0, "#{message}", dbg)
  end

  def translate_severity(severity)
    mySev = ''
    case
      when severity == 0
        mySev = 'DEBUG'
      when severity == 1
        mySev = 'INFO'
      when severity == 2
        mySev = 'WARN'
      when severity == 3
        mySev = 'ERROR'
      when severity == 4
        mySev = 'FATAL'
      when severity > 4
        mySev = 'UNKNOWN'
    end
    mySev
  end

  def get_caller(lnbr=nil, exception=nil)
    script_name ||= File.basename(script_file)
    if lnbr && script_type.eql?("Selenium")
      [script_name, lnbr, 'in run()'].join(":")
    elsif lnbr && script_type.eql?("MobileNativeApp")
      [script_name, lnbr, 'in scenario()'].join(":")
    else
      caller_object = exception ? exception.backtrace : Kernel.caller
      call_frame    = caller_object.detect do |frame|
        frame.match(/#{script_name}/) or (library && frame.match(/#{library}/))
      end
      unless call_frame.nil?
        call_frame.gsub!(/^C:/, '')
        file, line, method = call_frame.split(":")
        [File.basename(file), line, method].join(":")
      else
        'unknown'
      end
    end
  end

  def init_logger(logFile, scriptName = nil)
    if File.exist?(logFile)
      puts "==>Logfile already exists: #{logFile}. Replacing it."
      begin
        File.delete(logFile)
      rescue
        puts "#{scriptName}: init_logger RESCUE: #{$!}"
      end
    end
    @myLog               = ActiveSupport::BufferedLogger.new(logFile)
    @myLog.level         = Logger::DEBUG
    @myLog.auto_flushing = (true)
    @myLog.add(INFO, "#{logFile}\n")
  end

  def start_to_log(ts)
    utc_ts = ts.getutc
    loc_tm = "#{ts.strftime("%H:%M:%S")} #{ts.zone}"
    mark_testlevel(">> Starting #{@myName.titleize} #{utc_ts} (#{loc_tm})", 9)
  end

  def finish_to_log(ts)
    mark_testlevel(
        ">> #{@myName.titleize} duration: #{sec2hms(ts - @start_timestamp)}", 0)
    mark_testlevel(">> #{@myName.titleize} validations: #{@my_passed_count + @my_failed_count} "+
                  "fail: #{@my_failed_count}]", 0) if @my_passed_count and @my_failed_count
    @my_error_hits.each_key do |ref|
      mark_testlevel("#{ref} - #{@my_error_hits[ref]}", 0)
    end if @my_error_hits
    utc_ts = ts.getutc
    loc_tm = "#{ts.strftime("%H:%M:%S")} #{ts.zone}"
    mark_testlevel(">> End #{@myName.titleize} #{utc_ts} (#{loc_tm})", 9)
  end

end
