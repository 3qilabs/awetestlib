module Awetestlib

  module Regression

    module Reporting

      def get_caller_line
        last_caller = get_call_list[0]
        line        = last_caller.split(':', 3)[1]
        line
      end

      def get_call_list(depth = 9, dbg = false)
        my_list   = []
        call_list = Kernel.caller
        debug_to_log(with_caller(call_list)) if dbg
        call_list.each_index do |x|
          my_caller = call_list[x].to_s
          my_caller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          my_list << "[#{$1.gsub(/eval/, @myName)}] "
          break if x > depth or my_caller =~ /:in .run.$/
        end
        my_list
      rescue
        failed_to_log(unable_to)
      end

      alias get_callers get_call_list

      def get_call_list_new(depth = 15, dbg = $debug)
        a_list    = ['[unknown]']
        proj_name = File.basename(@library) if @library
        call_list = Kernel.caller
        log_message(DEBUG, with_caller(call_list)) if dbg
        call_list.each_index do |x|
          a_caller = call_list[x].to_s
          a_caller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          caller = $1
          if caller =~ /#{@myName}/
            a_list << "#{caller.gsub(/\(eval\)/, "(#{@myName})")}"
          elsif proj_name and caller =~ /#{proj_name}/
            a_list << "#{caller.gsub(/\(eval\)/, "(#{proj_name})")}" if proj_name
          elsif @library2 and caller =~ /#{@library2}/
            a_list << "#{caller.gsub(/\(eval\)/, "(#{@library2})")}" if @library2
          else
            a_list << "#{caller}"
          end
          next if a_caller =~ /:in .run.$/ and not a_caller.include?(@myName)
          break if x > depth
        end
        a_list
      rescue
        failed_to_log(unable_to)
      end

      def get_debug_list(dbg = false, no_trace = false, last_only = false)
        calls = get_call_array(10)
        debug_to_log(with_caller("*** #{__LINE__}\n#{calls.to_yaml}\n***")) if dbg
        arr = []
        calls.each_index do |ix|
          if ix > 1 # skip this method and the logging method
            if filter_call(calls[ix])
              arr << calls[ix]
            end
          end
        end
        debug_to_log(with_caller("*** #{__LINE__}\n#{arr.to_yaml}\n***")) if dbg
        if arr.length > 0
          list = ''
          arr.reverse.each do |l|
            if last_only
              list = l
              break
            else
              list << "=>#{l}"
            end
          end
          if no_trace
            "#{list}"
          else
            " [TRACE:#{list}]"
          end
        else
          ''
        end
      rescue
        failed_to_log(unable_to)
      end

      def filter_call(call)
        modl = call.match(/^(browser|logging|find|runner|tables|user_input|utilities|validations|waits|page_data|legacy|drag_and_drop|awetest)/) || ''
        meth = call.match(/in .(run|each)/) || ''
        true unless "#{modl}#{meth}".length > 0
      end

      def get_test_level(meth = nil)
        arr       = []
        each_line = 0
        call_list = Kernel.caller
        #debug_to_log("#{call_list.to_yaml}")
        call_list.each_index do |x|
          myCaller = call_list[x].to_s
          myCaller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
          string = $1
          unless string =~ /logging\.rb|mark_test_level|mark_test_level|debug_to_report|debug_toreport/
            if string.length > 0
              if string =~ /each|each_key/
                each_line = string.match(/\:(\d+)\:/)[1]
              elsif string.match(/\:(\d+)\:/)[1] == each_line
                next
              else
                arr << string.gsub(/eval/, @myName)
              end
            end
          end
          break if meth and string.match(/#{meth}/)
          break if myCaller =~ /:in .run.$|runner\.rb/
        end
        #debug_to_log("#{arr.length} #{nice_array(arr)}")
        [arr.length, arr]
      end

      # TODO: need to sanitize html for html report
      def html_to_log(element)
        debug_to_log("#{element}\n #{element.html}")
      end

      # @private
      def parse_caller(caller)
        call_script, call_line, call_meth = caller.split(':')
        call_script.gsub!(/\.rb/, '')
        call_script = call_script.camelize
        call_meth =~ /in .([\w\d_ ]+)./
        call_meth = $1
        if call_meth.match(/((rescue|block|eval)\s*in\s*)/)
          delete = $1
          append = $2
          call_meth.sub!(delete, '')
          call_meth << " (#{append})"
        end
        [call_script, call_line, call_meth]
      rescue
        failed_to_log(unable_to)
      end

      def initialize_reference_regexp
        unless @reference_regexp.is_a?(Regexp)
          @reference_template = '(\*\*\*\s+@@@@\s+\*\*\*)'
          @reference_pattern  = @reference_template.sub('@@@@', '([\w\d_\s,-:;\?]+)')
          @reference_regexp   = Regexp.new(@reference_pattern)
        end
      end

      # @private
      def choose_refs(arr, *indices)
        refs = ''
        indices.each do |idx|
          refs << "*** #{arr[idx]} *** "
        end
        refs
      rescue
        failed_to_log(unable_to)
      end

      # @private
      def format_refs(list)
        refs = ''
        if list
          list.split(/,\s*/).each do |ref|
            refs << format_reference(ref)
          end
        end
        refs
      end

      # @private
      def format_reference(ref)
        "*** #{ref} *** "
      end

      # @private
      def collect_references(*strings)
        refs = ''
        strings.each do |strg|
          refs << " #{format_refs(strg)}" if strg and strg.length > 0
        end if strings
        refs
      end

      # @private
      def tally_error_references
        tags_tested = 0
        tags_hit    = 0
        if @my_error_hits and @my_error_hits.length > 0
          mark_test_level(">> Failed Defect or Test Case instances:")
          tags_hit = @my_error_hits.length
          @my_error_hits.keys.sort.each do |ref|
            msg = "#{ref} (#{@my_error_hits[ref]})"
            msg << " -- #{@refs_desc[ref]}" if @refs_desc
            message_to_report(msg)
          end
        end
        if @my_error_references and @my_error_references.length > 0
          tags_tested = @my_error_references.length
          if self.report_all_test_refs
            mark_test_level(">> All tested Defect or Test Case instances:")
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

      def report_results(errors, msg)
        call_script, call_line, call_meth = parse_caller(get_call_array[1])
        msg                               = ">> SUMMARY: #{build_msg("#{call_meth.titleize}:", msg)}"
        if errors > 0
          mark_test_level("#{msg}  ::FAIL::")
        else
          mark_test_level("#{msg}  ::Pass::")
          true
        end
      rescue
        failed_to_log(unable_to)
      end

    end
  end
end
