module Awetestlib
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
    @last_t = t
	  dt       = t.strftime("%H%M%S")
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

  #private log_message

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

=begin rdoc
category: Logging
tags: report, log, test level
=end
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

=begin rdoc
category: Logging
tags: log
=end
  def info_to_log(message, lnbr = __LINE__)
    log_message(INFO, message, nil, lnbr)
  end

  alias message_tolog info_to_log
  alias message_to_log info_to_log
  alias info_tolog info_to_log

=begin rdoc
category: Logging
tags: log, debug
=end
  def debug_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" if dbg or @debug_calls # and not @debug_calls_fail_only)
    log_message(DEBUG, "#{message}", nil, lnbr)
  end

  alias debug_tolog debug_to_log

=begin rdoc
category: Logging
tags: log, error
Do not use for failed validations.
=end
  def error_to_log(message, lnbr = __LINE__)
    log_message(ERROR, message, nil, lnbr)
  end

  alias error_tolog error_to_log

=begin rdoc
category: Logging
tags: log, error, pass, reference, tag, report
=end
  def passed_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" if dbg or @debug_calls # and not @debug_calls_fail_only)
    @my_passed_count += 1 if @my_passed_count
    parse_error_references(message)
    log_message(INFO, "#{message}", PASS, lnbr)
  end

  alias validate_passed_tolog passed_to_log
  alias validate_passed_to_log passed_to_log
  alias passed_tolog passed_to_log
  alias pass_tolog passed_to_log
  alias pass_to_log passed_to_log

=begin rdoc
category: Logging
tags: log, error, fail, reference, tag, report
=end
  def failed_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}" if dbg or @debug_calls or @debug_calls_fail_only
    @my_failed_count += 1 if @my_failed_count
    parse_error_references(message, true)
    log_message(WARN, "#{message}" + " (#{lnbr})]", FAIL, lnbr)
  end

  alias validate_failed_tolog failed_to_log
  alias validate_failed_to_log failed_to_log
  alias failed_tolog failed_to_log
  alias fail_tolog failed_to_log
  alias fail_to_log failed_to_log

=begin rdoc
category: Logging
tags: log, error, fail, reference, tag, fatal, report
=end
  def fatal_to_log(message, lnbr = __LINE__, dbg = false)
    message << " \n#{get_debug_list}"  if dbg or (@debug_calls and not @debug_calls_fail_only)
    @my_failed_count += 1 if @my_failed_count
    parse_error_references(message, true)
    debug_to_report("#{__method__}:\n#{dump_caller(lnbr)}")
    log_message(FATAL, "#{message} (#{lnbr})", FAIL, lnbr)
  end

  #def fatal_to_log(message, lnbr = __LINE__)
  #  log_message(FATAL, "#{message} (#{lnbr})", FAIL, lnbr)
  #  log_message(DEBUG, "\n#{dump_caller(lnbr)}")
  #end

  alias fatal_tolog fatal_to_log

=begin rdoc
category: Logging
tags: log, report
=end
  def message_to_report(message, dbg = false)
    mark_testlevel("#{message}", 0, '', dbg)
  end

=begin rdoc
category: Logging
tags: log, debug, report
=end
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

=begin rdoc
category: Debug
tags: log, caller, trace, report
=end
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
      puts "==> Logfile already exists: #{logFile}. Replacing it."
      begin
        File.delete(logFile)
      rescue
        puts "#{scriptName}: init_logger RESCUE: #{$!}"
      end
    end
    logger               = ActiveSupport::BufferedLogger.new(logFile)
    logger.level         = Logger::DEBUG
    logger.auto_flushing = (true)
    logger.add(INFO, "#{logFile}\n#{ENV["OS"]}")
    logger
  end

  #private init_logger

=begin rdoc
category: Logging
tags: error, fail, reference, tag
=end
  def start_run(ts = nil)
    @start_timestamp = Time.now unless ts
    utc_ts = @start_timestamp.getutc
    loc_tm = "#{@start_timestamp.strftime("%H:%M:%S")} #{@start_timestamp.zone}"
    mark_testlevel(">> Starting #{@myName.titleize}", 9)
  end

  alias start_to_log start_run

=begin rdoc
category: Logging
tags: log, begin, error, reference, validation, pass, fail, tallies, tag
=end
  def finish_run(ts = nil)
    timestamp = Time.now unless ts

    mark_testlevel(">> #{@myName.titleize} duration: #{sec2hms(timestamp - @start_timestamp)}", 0)

    mark_testlevel(">> #{@myName.titleize} validations: #{@my_passed_count + @my_failed_count} "+
                   "fail: #{@my_failed_count}]", 0) if @my_passed_count and @my_failed_count

    tally_error_references

    utc_ts = timestamp.getutc
    loc_tm = "#{timestamp.strftime("%H:%M:%S")} #{timestamp.zone}"
    mark_testlevel(">> End #{@myName.titleize}", 9)

  end

  alias finish_to_log finish_run

=begin rdoc
category: Logging
tags: log, error, reference, tag, tallies
=end
  def tally_error_references(list_tags = @report_all_refs)
    tags_tested = 0
    tags_hit    = 0
    if @my_error_hits and @my_error_hits.length > 0
      mark_testlevel("Tagged Error Hits:", 0)
      tags_hit = @my_error_hits.length
      @my_error_hits.each_key do |ref|
        mark_testlevel("#{ref} - #{@my_error_hits[ref]}", 0)
      end
    end
    if list_tags
      if @my_error_references and @my_error_references.length > 0
        mark_testlevel("Error and Test Case Tags:", 0)
        tags_tested = @my_error_references.length
        @my_error_references.each_key do |ref|
          mark_testlevel("#{ref} - #{@my_error_references[ref]}", 0)
        end
        mark_testlevel("Fails were hit on #{tags_hit} of #{tags_tested} error/test case references", 0)
      else
        mark_testlevel("No Error or Test Case References found.", 0)
      end
    end
  end

=begin rdoc
category: Logging
tags: error, reference, tag, tallies
=end
  def parse_error_references(message, fail = false)
    msg = message.dup
    while msg =~ /(\*\*\*\s+[\w\d_\s,-:;\?]+\s+\*\*\*)/
      capture_error_reference($1, fail)
      msg.sub!($1, '')
    end
  end

=begin rdoc
category: Logging
tags: error, fail, hits, reference, tag, tallies
=end
  def capture_error_reference(ref, fail)
    if fail
      @my_error_hits = Hash.new unless @my_error_hits
      if @my_error_hits[ref]
        @my_error_hits[ref] += 1
      else
        @my_error_hits[ref] = 1
      end
      #debug_to_report("#{__method__}: error hits:\n#{@my_error_hits.to_yaml}")
    end
    @my_error_references = Hash.new unless @my_error_references
    if @my_error_references[ref]
      @my_error_references[ref] += 1
    else
      @my_error_references[ref] = 1
    end
  end

end
end