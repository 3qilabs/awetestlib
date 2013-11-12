module Awetestlib
  # Logging and reporting.
  module Logging

    # @deprecated
    def self.included(mod)
      # puts "RegressionSupport::Logging extended by #{mod}"
    end

    # Format log message and write to STDOUT.  Write to physical log if indicated.
    # @private
    # @param [Fixnum] severity Severity level of message. Use constants DEBUG, INFO, WARN, ERROR, FATAL, or UNKNOWN
    # @param [String] message The message to be placed in the log.
    # @param [String, Fixnum] tag Indicates the type of message. Valid string values are 'FAIL' and 'PASS'.
    # Valid number values are 0 to 9.
    # @param [Fixnum] lnbr the line number in the calling script
    # @param [Fixnum] addts Obsolete, no longer used.
    # @param [String] exception Obsolete, no longer used.
    def log_message(severity, message, tag = '', lnbr = nil, addts = 1, exception = nil)
      t        = Time.now.utc
      @last_t  ||= t
      duration = (t.to_f - @last_t.to_f)
      @last_t  = t
      tstmp    = t.strftime("%H%M%S") + '.' + t.to_f.modulo(t.to_i).to_s.split('.')[1].slice(0, 5)
      my_sev    = translate_severity(severity)
      my_msg = "%-8s" % my_sev
      my_msg << '[' + tstmp + ']:'
      my_msg << "[#{"%9.5f" % duration}]:"
      if tag
        if tag.is_a? Fixnum
          tag = '-LVL' + tag.to_s
        end
      end
      my_msg << "[%-5s]:" % tag
      my_msg << get_debug_list(false, true, true)
      my_msg << ' '+message
      my_msg << " [#{lnbr}] " if lnbr

      @myLog.add(severity, my_msg) if @myLog # add persistent logging for awetestlib. pmn 05jun2012
      puts my_msg+"\n"

      nil # so method doesn't return whole @output.
    end

    #private log_message

    # Translates tag value to corresponding value for +pass+ column in database.
    # @private
    # @param [String, Fixnum] tag
    # @return [String] Single character
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

    # @private
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

      return { :result => passed, :msg => output_lines }
    end


    # Write a status message to the log and report indicating location or activity
    # in the script. mark_test_level automatically determines the call hierarchy level
    # of the calling method within the script and project utility methods.  The top level
    # method of the script is always level 1.  The method also prefixes the calling method
    # name (titleized) to the message to be placed in the log.
    # @param [String] message The text to place in the log and report after the titleized
    # calling method name.
    # @param [Fixnum] lvl '0' forces a message to the report without a specific level
    # attached. Any other integer is ignored in favor of the calculated level
    # @param [String] desc Any additional information to add to the message.
    # @param [Boolean] dbg When set to true adds a trace to the message.
    # @return [void]
    def mark_test_level(message = '', lvl = nil, desc = '', dbg = nil)
      call_arr = get_call_array()
      #debug_to_log("#{call_arr.to_yaml}")
      strg = ''
      call_script, call_line, call_meth = parse_caller(call_arr[1])
      if not lvl or lvl > 1
        lvl, list = get_test_level
        strg << "#{call_meth.titleize}"
      end
      strg << "#{message}" if message.length > 0
      strg << " (#{desc})" if desc.length > 0
      strg << " [#{call_line}]" if dbg or @debug_calls
      strg << "\n#{list.to_yaml}" if dbg or @debug_calls
      @report_class.add_to_report(strg, "&nbsp", "&nbsp", lvl || 1) unless Awetestlib::Runner.nil?
      log_message(INFO, strg, lvl, nil, 1)
    rescue
      failed_to_log("#{__method__}: #{$!}")
    end

    alias mark_testlevel mark_test_level

    # @param [String] message The text to place in the log
    # @return [void]
    def info_to_log(message, lnbr = nil)
      log_message(INFO, message, 0, lnbr)
    end

    alias message_tolog info_to_log
    alias message_to_log info_to_log
    alias info_tolog info_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def debug_to_log(message, lnbr = nil, dbg = false)
      message << "\n#{get_debug_list}" if dbg or @debug_calls # and not @debug_calls_fail_only)
      log_message(DEBUG, "#{message}", nil, lnbr)
    end

    alias debug_tolog debug_to_log

    # @note Do not use for failed validations. Use only for serious error conditions.
    # @return [void]
    # @param [String] message The text to place in the log and report
    def error_to_log(message, lnbr = nil)
      log_message(ERROR, message, nil, lnbr)
    end

    alias error_tolog error_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def passed_to_log(message, lnbr = nil, dbg = false)
      message << " \n#{get_debug_list}" if dbg or @debug_calls # and not @debug_calls_fail_only)
      @my_passed_count += 1 if @my_passed_count
      parse_error_references(message)
      @report_class.add_to_report(message, get_caller(lnbr), "PASSED") unless Awetestlib::Runner.nil?
      log_message(INFO, "#{message}", PASS, lnbr)
    end

    alias validate_passed_tolog passed_to_log
    alias validate_passed_to_log passed_to_log
    alias passed_tolog passed_to_log
    alias pass_tolog passed_to_log
    alias pass_to_log passed_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def failed_to_log(message, lnbr = nil, dbg = false, exception = nil)
      message << " \n#{get_debug_list}" if dbg.to_s == 'true' or @debug_calls or @debug_calls_fail_only
      @my_failed_count += 1 if @my_failed_count
      parse_error_references(message, true)
      @report_class.add_to_report("#{message}", get_caller(lnbr), "FAILED") unless Awetestlib::Runner.nil?
      log_message(WARN, "#{message}", FAIL, lnbr, nil, exception)
    end

    alias validate_failed_tolog failed_to_log
    alias validate_failed_to_log failed_to_log
    alias failed_tolog failed_to_log
    alias fail_tolog failed_to_log
    alias fail_to_log failed_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def fatal_to_log(message, lnbr = nil, dbg = false, exception = nil)
      message << " \n#{get_debug_list}" if dbg.to_s == 'true' or (@debug_calls and not @debug_calls_fail_only)
      @my_failed_count += 1 if @my_failed_count
      parse_error_references(message, true)
      @report_class.add_to_report("#{message}", get_caller(lnbr), "FAILED") unless Awetestlib::Runner.nil?
      debug_to_report("#{__method__}:\n#{dump_caller(lnbr)}")
      log_message(FATAL, "#{message} (#{lnbr})", FAIL, lnbr, nil, exception)
    end

    alias fatal_tolog fatal_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def message_to_report(message, dbg = false)
      mark_testlevel(message, 0, '', dbg)
    end

    # @param [String] message The text to place in the log and report
    # @return [void]
    def debug_to_report(message, dbg = false)
      mark_testlevel("(DEBUG): ", 0, "#{message}", dbg)
    end

    # @private
    # @return [Fixnum] required by logger.
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

    # @private
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

    # @private
    def init_logger(log_spec, scriptName = nil)
      if File.exist?(log_spec)
        puts "==> log_spec already exists: #{log_spec}. Replacing it."
        begin
          File.delete(log_spec)
        rescue
          puts "#{scriptName}: init_logger RESCUE: #{$!}"
        end
      end
      @log_spec = log_spec
      logger               = ActiveSupport::BufferedLogger.new(log_spec)
      logger.level         = ActiveSupport::BufferedLogger::DEBUG
      logger.auto_flushing = (true)
      logger.add(INFO, "#{log_spec}\n#{ENV["OS"]}")
      logger
    end

    #private init_logger

    # @private
    def start_run(ts = nil)
      @start_timestamp = Time.now unless ts
      utc_ts = @start_timestamp.getutc
      loc_tm = "#{@start_timestamp.strftime("%H:%M:%S")} #{@start_timestamp.zone}"
      message_to_report(">> Starting #{@myName.titleize} #{utc_ts} (#{loc_tm})")
      message_to_report(">> Logging to #{File.join(@myRoot, @log_spec)}") if @log_spec
    end

    alias start_to_log start_run

    # @private
    # Tally and report duration, validation and failure counts, and end time for the script.
    # @param [DateTime] ts Time stamp indicating the time the script completed.
    def finish_run(ts = Time.now)
      tally_error_references
      message_to_report(
          ">> #{@myName.titleize} duration: #{sec2hms(ts - @start_timestamp)}")
      message_to_report(">> #{@myName.titleize} validations: #{@my_passed_count + @my_failed_count} "+
                         "fail: #{@my_failed_count}]") if @my_passed_count and @my_failed_count
      utc_ts = ts.getutc
      loc_tm = "#{ts.strftime("%H:%M:%S")} #{ts.zone}"
      message_to_report(">> End #{@myName.titleize} #{utc_ts} (#{loc_tm})")
    end

    alias finish_to_log finish_run

    # @private
    def tally_error_references(list_tags = @report_all_refs)
      tags_tested = 0
      tags_hit    = 0
      if @my_error_hits and @my_error_hits.length > 0
        message_to_report(">> Failed Defect or Test Case references:")
        tags_hit = @my_error_hits.length
        @my_error_hits.each_key do |ref|
          message_to_report("#{ref} - #{@my_error_hits[ref]}")
        end
      end
      if list_tags
        if @my_error_references and @my_error_references.length > 0
          message_to_report(">> All tested Defect or Test Case references")
          tags_tested = @my_error_references.length
          @my_error_references.each_key do |ref|
            message_to_report("#{ref} - #{@my_error_references[ref]}")
          end
          message_to_report(">> Fails on tested Defect or Test Case references: #{tags_hit} of #{tags_tested}")
        else
          message_to_report(">> No Defect or Test Case references found.")
        end
      end
    end

  # @private
    def parse_error_references(message, fail = false)
      msg = message.dup
      while msg =~ /(\*\*\*\s+[\w\d_\s,-:;\?]+\s+\*\*\*)/
        capture_error_reference($1, fail)
        msg.sub!($1, '')
      end
    end

    # @private
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
