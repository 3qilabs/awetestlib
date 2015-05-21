module Awetestlib
  # Logging and reporting.

  module Logging
    include ActiveSupport
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
    def log_message(severity, message, tag = '', who_called = nil, exception = nil)
      level  = nil

      t        = Time.now.utc
      @last_t  ||= t
      duration = (t.to_f - @last_t.to_f)

      # durations = calculate_durations(tag, t = Time.now.utc)

      tstmp    = t.strftime("%H%M%S") + '.' + t.to_f.modulo(t.to_i).to_s.split('.')[1].slice(0, 5)
      my_sev = translate_severity(severity)
      my_msg = '%-8s' % my_sev
      my_msg << '[' + tstmp + ']:'

      my_msg << "[#{'%9.5f' % duration}]:"

      if tag
        if tag.is_a? Fixnum
          level = tag.to_i
          tag = '-LVL' + tag.to_s
        end
      end
      my_msg << '[%-6s][:' % tag

      unless who_called
        who_called = get_debug_list(false, true, true)
      end
      my_msg << who_called

      my_msg << ']: ' + message

      @myLog.add(severity, my_msg) if @myLog # add persistent logging for awetestlib. pmn 05jun2012

      puts my_msg + "\n"

      @report_class.add_to_report(message, who_called, text_for_level(tag), duration, level) if tag and tag.length > 0

      @last_t = t

      nil # so method doesn't return whole @output.
    end

    #private log_message

    # Translates tag value to corresponding value for +pass+ column in database.
    # @private
    # @param [String, Fixnum] tag
    # @return [String] Single word
    def text_for_level(tag)
      case tag
        when /PASS/
          'PASSED'
        when /FAIL/
          'FAILED'
        #when tag =~ /\d+/ # avoid having to require andand for awetestlib. pmn 05jun2012
        when /\d+/
          unless tag == '0'
            tag.to_s
          end
        when /DONE/
          'DONE'
        when /role/
          'ROLE'
        else
          ''
      end
    end

    # @private
    def log_sikuli_output(output_file, passed)
      output_lines = File.open(output_file, 'r') { |f| f.readlines }
      puts "IM FAILING?! #{passed}"

      # if passed

      log_messages = ['[log]', '[error]']
      output_lines = output_lines.select { |l| log_messages } #.detect{|msg| l.include?(msg)} }
      while line == output_lines.shift do
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
    def mark_test_level(message = '', lvl = nil, desc = '', caller = 1, wai_lvl = 4, dbg = nil)
      strg = ''
      list = nil
      call_arr = get_call_array

      debug_to_log("#{call_arr.to_yaml}") if $debug
      call_script, call_line, call_meth = parse_caller(call_arr[caller])

      if not lvl or lvl > 1
        lvl, list = get_test_level
        strg << "#{call_meth.titleize}: "
      end

      if lvl == 0
        parse_error_references(message)
      end
      strg << "#{message}" if message.length > 0
      strg << " (#{desc})" if desc.length > 0
      strg << " [#{call_line}]" if $debug
      strg << "\n#{list.to_yaml}" if list and $debug

      log_message(INFO, strg, lvl, where_am_i?(wai_lvl))
      true
    rescue
      failed_to_log(unable_to)
    end

    alias mark_testlevel mark_test_level

    # @param [String] message The text to place in the log
    # @return [void]
    def info_to_log(message)
      log_message(INFO, message)
    end

    alias message_tolog info_to_log
    alias message_to_log info_to_log
    alias info_tolog info_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def debug_to_log(message, wai_lvl = 3)
      message << "\n#{get_debug_list}" if $debug
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      log_message(DEBUG, "#{message}", nil, where_am_i?(lvl))
      true
    end

    alias debug_tolog debug_to_log

    # @note Do not use for failed validations. Use only for serious error conditions.
    # @return [void]
    # @param [String] message The text to place in the log and report
    def error_to_log(message, wai_lvl = 3, exception = nil)
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      log_message(ERROR, message, nil, where_am_i?(lvl), exception)
      false
    end

    alias error_tolog error_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def passed_to_log(message, wai_lvl = 3, dbg = false)
      message << " \n#{get_debug_list}" if $debug
      @my_passed_count += 1 if @my_passed_count
      parse_error_references(message)
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      log_message(INFO, "#{message}", PASS, where_am_i?(lvl))
      true
    end

    alias validate_passed_tolog passed_to_log
    alias validate_passed_to_log passed_to_log
    alias passed_tolog passed_to_log
    alias pass_tolog passed_to_log
    alias pass_to_log passed_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def failed_to_log(message, wai_lvl = 3, exception = nil)
      message << " \n#{get_debug_list}" if $debug
      @my_failed_count += 1 if @my_failed_count
      parse_error_references(message, true)
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      log_message(WARN, "#{message}", FAIL, where_am_i?(lvl), exception)
      false
    end

    alias validate_failed_tolog failed_to_log
    alias validate_failed_to_log failed_to_log
    alias failed_tolog failed_to_log
    alias fail_tolog failed_to_log
    alias fail_to_log failed_to_log

    # @param [String] message The text to place in the log and report
    # @return [void]
    def fatal_to_log(message, wai_lvl = 3, exception = nil)
      message << " #{get_debug_list}"
      @my_failed_count += 1 if @my_failed_count
      parse_error_references(message, true)
      debug_to_report("#{__method__}:\n#{dump_caller(nil)}")
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      log_message(FATAL, "#{message} '#{$!}'", FAIL, where_am_i?(lvl), exception)
      false
    end

    alias fatal_tolog fatal_to_log

    # @param [String] message The text to place in the log and report
    # @return [Boolean] Always returns true
    def message_to_report(message, wai_lvl = 4)
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      mark_test_level(message, 0, '', 1, lvl)
      true
    end

    # @param [String] message The text to place in the log and report
    # @return [void]
    def debug_to_report(message, wai_lvl = 4)
      scr_lvl = first_script_index
      lvl     = scr_lvl ? scr_lvl : wai_lvl
      mark_test_level("(DEBUG): ", 0, "#{message}", 1, lvl)
      true
    end

    # @private
    # @severity [Fixnum] used by logger.
    def translate_severity(severity)
      case severity
        when 0
          'DEBUG'
        when 1
          'INFO'
        when 2
          'WARN'
        when 3
          'ERROR'
        when 4
          'FATAL'
        when 4
          'UNKNOWN'
        else
          ''
      end
    end

    # @private
    def get_caller(lnbr=nil, exception=nil)
      script_name ||= File.basename(@myName)
      if lnbr && script_type.eql?("Selenium")
        [script_name, lnbr, 'in run()'].join(":")
      elsif lnbr && script_type.eql?("MobileNativeApp")
        [script_name, lnbr, 'in scenario()'].join(":")
      else
        caller_object = exception ? exception.backtrace : Kernel.caller
        call_frame    = caller_object.detect do |frame|
          frame.match(/#{script_name}/) or
              (library && frame.match(/#{library}/)) or
              (@library2 && frame.match(/#{@library2}/))
        end
        if call_frame.nil?
          'unknown'
        else
          call_frame.gsub!(/^C:/, '')
          file, line, method = call_frame.split(":")
          [File.basename(file), line, method].join(":")
        end
      end
    end

    # @private
    def init_logger(log_spec, script_name = nil)
      if File.exist?(log_spec)
        puts "==> log_spec already exists: #{log_spec}. Replacing it."
        begin
          File.delete(log_spec)
        rescue
          puts "#{script_name}: init_logger RESCUE: #{$!}"
        end
      end
      @log_spec    = log_spec
      logger       = ActiveSupport::Logger.new(log_spec)
      logger.level = ActiveSupport::Logger::DEBUG
      #logger.auto_flushing = (true)
      logger.add(INFO, "#{log_spec}\n#{ENV["OS"]}")
      logger
    end

    #private init_logger

    # @private
    def log_begin_run(ts = nil)
      @start_timestamp = ts ? ts : Time.now
      @my_failed_count = 0 unless @my_failed_count
      @my_passed_count = 0 unless @my_passed_count
      utc_ts           = @start_timestamp.getutc
      loc_tm           = "#{@start_timestamp.strftime("%H:%M:%S")} #{@start_timestamp.zone}"
      message_to_report(">> Starting #{@myName.titleize} #{utc_ts} (#{loc_tm}) (Awetestlib)")
    rescue
      failed_to_log(unable_to)
    end

    # @private
    # Tally and report duration, validation and failure counts, and end time for the script.
    # @param [DateTime] ts Time stamp indicating the time the script completed.
    def log_finish_run(ts = Time.now)
      tally_error_references
      message_to_report(
          ">> #{@myName.titleize} duration: #{sec2hms(ts - @start_timestamp)}")
      message_to_report(">> #{@myName.titleize} validations: #{@my_passed_count + @my_failed_count} "+
                            "fail: #{@my_failed_count}]") if @my_passed_count and @my_failed_count
      utc_ts = ts.getutc
      loc_tm = "#{ts.strftime("%H:%M:%S")} #{ts.zone}"
      message_to_report(">> End #{@myName.titleize} #{utc_ts} (#{loc_tm})")
    end

    # @private
    def tally_error_references(list_tags = @report_all_refs)
      tags_tested = 0
      tags_hit    = 0
      if @my_error_hits and @my_error_hits.length > 0
        mark_test_level(">> Failed Defect or Test Case instances:") #, -1)
        #message_to_report(">> Failed Defect or Test Case instances:")
        tags_hit = @my_error_hits.length
        @my_error_hits.keys.sort.each do |ref|
          msg = "#{ref} (#{@my_error_hits[ref]})"
          msg << " -- #{@refs_desc[ref]}" if @refs_desc
          message_to_report(msg)
        end
      end
      if @my_error_references and @my_error_references.length > 0
        mark_test_level(">> All tested Defect or Test Case instances:") #, -1)
        #message_to_report(">> All tested Defect or Test Case instances:")
        tags_tested = @my_error_references.length
        if list_tags
          @my_error_references.keys.sort.each do |ref|
            msg = "#{ref} (#{@my_error_references[ref]})"
            msg << " -- #{@refs_desc[ref]}" if @refs_desc
            message_to_report(msg)
          end
        end
        message_to_report(">> Fails on tested Defect or Test Case references: #{tags_hit} of #{tags_tested}")
      else
        message_to_report(">> No Defect or Test Case references found.")
      end
    end

    # @private
    def parse_error_references(message, fail = false)
      initialize_reference_regexp unless @reference_regexp
      msg = message.dup
      while msg.match(@reference_regexp)
        capture_error_reference($2, fail)
        msg.sub!($1, '')
      end
    rescue
      failed_to_log(unable_to)
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
    rescue
      failed_to_log(unable_to)
    end

    def calculate_durations(tag, t = Time.now.utc)
      last_log_ts ||= t
      last_lvl_ts ||= t
      last_val_ts ||= t
      log_dur     = "%9.5f" % (t.to_f - last_log_ts.to_f)
      lvl_dur     = "%9.5f" % (t.to_f - last_lvl_ts.to_f)
      val_dur     = "%9.5f" % (t.to_f - last_val_ts.to_f)
      last_log_ts = t
      case tag
        when /LVL/i
          last_lvl_ts = t
          dur         = lvl_dur
        when /PASS|FAIL/i
          last_val_ts = t
          dur         = val_dur
        else
          dur = log_dur
      end
      [dur, log_dur, lvl_dur, val_dur]
    end

    def initialize_reference_regexp
      unless @reference_regexp.is_a?(Regexp)
        @reference_template = '(\*\*\*\s+@@@@\s+\*\*\*)'
        @reference_pattern  = @reference_template.sub('@@@@', '([\w\d_\s,-:;\?]+)')
        @reference_regexp   = Regexp.new(@reference_pattern)
      end
    end

    def with_caller(message = '', *strings)
      call_arr                          = get_call_array
      call_script, call_line, call_meth = parse_caller(call_arr[1])
      strg                              = "#{call_meth.titleize}"
      strg << ':' # if strings.size > 0
      strg << ' '
      strg << build_message(message, *strings)
      strg
    end

    alias message_with_caller with_caller
    alias msg_with_caller with_caller

    def where_am_i?(index = 2)
      calls = get_call_list_new
      log_message(DEBUG, "=== #{__LINE__}\n#{calls.to_yaml}\n===") if $debug
      if calls[index]
        where = calls[index].dup.to_s
        here  = where.gsub(/^\[/, '').gsub(/\]\s*$/, '')
      else
        here = 'unknown'
      end
      here
    rescue
      failed_to_log(unable_to)
    end

    def first_script_index(script = @myName)
      here      = nil
      call_list = get_call_list_new
      log_message(DEBUG, with_caller("=== #{__LINE__}\n#{call_list.to_yaml}\n===")) if $debug
      call_list.each_index do |x|
        a_caller = call_list[x].to_s
        a_caller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
        caller = $1
        if caller =~ /#{script}/
          here = x
          break
        end
      end
      here
    rescue
      failed_to_log(unable_to)
    end

  end
end
