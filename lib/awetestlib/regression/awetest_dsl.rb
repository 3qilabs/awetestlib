# require 'color/rgb'
# require 'color/rgb/contrast'
require 'selenium/webdriver/common'
require 'digest/sha1'

module Awetestlib

  RDTL       = '@dtl@'
  RENV       = '@env@'
  RSMY       = '@smy@'
  RFTR       = '@ftr@'
  RSTP       = '@stp@'
  RPGL       = '@pgl@'

  # include Selenium::Webdriver::Proxy
  $log_count = 0

  $default_font_size   = 16
  $default_line_height = 26

  if ::USING_WINDOWS
    $default_screen_dpi = 96
  else
    $default_screen_dpi = 72
  end

  # @focus_moves                  = {
  #     :remove => { :blur => 0, :tab => 0, :enter => 0, :fail => 0, :already => 0 },
  #     :return => { :onclick => 0, :onfocus => 0, :focus => 0, :click => 0, :shift_tab => 0, :fail => 0, :already => 0 }
  # }

  module Logging

    def mark_test_level(message = '', lvl = nil, desc = '', caller = 1, wai_lvl = 4, data = nil, trc = $debug)
      strg     = ''
      list     = nil
      call_arr = get_call_array

      debug_to_log("#{call_arr.to_yaml}") if trc
      call_script, call_line, call_meth = parse_caller(call_arr[caller])

      if not lvl or lvl > 1
        lvl, list = get_test_level
        strg << "#{call_meth.titleize}: "
      end

      strg << "#{message}" if message.length > 0
      strg << " (#{desc})" if desc.length > 0
      strg << " [#{call_line}]" if trc
      strg << "\n#{list.to_yaml}" if list and trc

      log_message(INFO, strg, lvl, where_am_i?(wai_lvl), nil, data)

      if lvl == 0
        parse_error_references(message)
      end

      true
    rescue
      failed_to_log(unable_to)
    end

    def message_to_report(message, wai_lvl = 4, data = nil)
      scr_lvl = first_script_index
      lvl     = scr_lvl > 0 ? scr_lvl : wai_lvl
      mark_test_level(message, 0, '', 1, lvl + 1, data)
      true
    end

    def info_to_log(message, wai_lvl = 3)
      log_message(INFO, message, '', where_am_i?(wai_lvl))
    end

    def log_begin_run(begin_time)
      sctn = RENV
      mark_test_level("#{sctn}Begin Test Run") # not getting here, already executed from Logging
      message_to_report("#{sctn}>> Running on host '#{$os.nodename}'")
      message_to_report("#{sctn}>> Running #{$os.name} version #{$os.version}")
      @my_failed_count = 0 unless @my_failed_count
      @my_passed_count = 0 unless @my_passed_count
      utc_ts           = begin_time.getutc
      loc_tm           = "#{begin_time.strftime("%H:%M:%S")} #{begin_time.zone}"
      message_to_report("#{sctn}>> Starting #{@myName.titleize} #{utc_ts} (#{loc_tm})")
      debug_to_log("\nAwetestlib #{$metadata.to_yaml}")
    rescue
      failed_to_log(unable_to)
    end

    def log_message(severity, message, tag = '', who_called = nil, exception = nil, data = nil)
      level = nil

      # $log_count += 1

      t        = Time.now.utc
      @last_ts ||= t
      duration = (t.to_f - @last_ts.to_f)

      # durations = calculate_durations(tag, t = Time.now.utc)

      tstmp    = t.strftime('%H%M%S') + '.' + t.to_f.modulo(t.to_i).to_s.split('.')[1].slice(0, 5)
      my_sev   = translate_severity(severity)
      my_msg   = '%-8s' % my_sev
      my_msg << '[' + tstmp + ']:'

      my_msg << "[#{'%9.5f' % duration}]:"

      if tag
        if tag.is_a? Fixnum
          level = tag.to_i
          tag   = '-LVL' + tag.to_s
        end
      end
      my_msg << '[%-6s][:' % tag

      unless who_called
        who_called = exception.nil? ? get_debug_list(false, true, true) : get_caller(exception)
      end
      my_msg << who_called

      message, section = set_report_section(message)

      message.sub!(/^@\w{3}@/, '')

      my_msg << ']: ' + message

      @logger.add(severity, my_msg) if @logger

      puts my_msg + "\n"

      @report_class.add_to_report(message, who_called, text_for_level(tag), duration, level, section, data) if tag and tag.length > 0

      @last_ts = t

    rescue
      puts with_caller("#{section}#{message} \n#{get_debug_list}")
      debug_to_log("#{section}#{message} \n#{get_debug_list}")
    end

    def text_for_level(tag)
      case tag
        when /PASS/i
          'PASSED'
        when /FAIL/i
          build_link_for_fail
        #when tag =~ /\d+/ # avoid having to require andand for awetestlib. pmn 05jun2012
        when /\d+/
          unless tag == '0'
            tag.to_s
          end
        when /DONE/i
          'DONE'
        when /role/i
          'ROLE'
        else
          ''
      end
    end

    def build_link_for_fail
      rtrn = 'FAILED'
      if @current_instance
        # debug_to_log(with_caller("#{File.basename(__FILE__)}\n#{@current_instance.to_yaml}"))
        if @current_instance[:fail_href]
          href = @current_instance[:fail_href]
          unless @current_instance[:ref_done] == href
            rtrn                         = "<a id=\"#{href}\"></a><a href=\"#summary\">FAILED</a>"
            @current_instance[:ref_done] = href
            # debug_to_log(with_caller("#{File.basename(__FILE__)}\n#{@current_instance.to_yaml}"))
          end
        end
      end
      rtrn
    end

    def set_report_section(message)
      section = case message
                  when /#{RDTL}/
                    message.sub!(RDTL, '')
                    RDTL
                  when /#{RENV}/
                    message.sub!(RENV, '')
                    RENV
                  when /#{RSMY}/
                    message.sub!(RSMY, '')
                    RSMY
                  when /#{RSTP}/
                    message.sub!(RSTP, '')
                    RSTP
                  when /#{RPGL}/
                    message.sub!(RPGL, '')
                    RPGL
                  when /#{RFTR}/
                    message.sub!(RFTR, '')
                    RFTR
                  else
                    RDTL
                end
      [message, section]
    end

    def failed_to_log(message, wai_lvl = 3, exception = nil)
      message << " \n#{get_debug_list}" if $debug
      @my_failed_count += 1 if @my_failed_count
      scr_lvl          = first_script_index
      lvl              = scr_lvl > 0 ? scr_lvl : wai_lvl
      parse_error_references(message, true)
      log_message(WARN, "#{message}", FAIL, where_am_i?(lvl), exception)
      false
    rescue
      debug_to_log("#{message} \n#{get_debug_list}")
    end

    def run_summary(ts = Time.now, begin_time = $begin_time)
      # msg  = tally_error_references
      mark_test_level(RFTR)
      # message_to_report(msg)
      @run_elapsed = sec2hms(ts - begin_time)
      elapsed_msg  = ">> #{@myName.titleize} elapsed: #{@run_elapsed}"
      message_to_report("#{RENV}#{elapsed_msg}")
      message_to_report("#{RFTR}#{elapsed_msg}")
      if @my_passed_count and @my_failed_count
        total_count = @my_passed_count + @my_failed_count
        tally_msg   = ">> #{@myName.titleize} validations: #{total_count} "+
            "fail: #{@my_failed_count} (#{nice_percent(@my_failed_count, total_count, 2)}%)"
        message_to_report("#{RENV}#{tally_msg}")
        message_to_report("#{RFTR}#{tally_msg}")
      end
      utc_ts = ts.getutc
      loc_tm = "#{ts.strftime('%H:%M:%S')} #{ts.zone}"
      message_to_report("#{RFTR}>> End #{@myName.titleize} #{utc_ts} (#{loc_tm})")
    end

    alias log_finish_run run_summary

    def where_am_i?(index = 2, sctn = RDTL)
      index = index ? index : 2
      calls = get_call_list_new
      log_message(DEBUG, "#{sctn}=== #{__LINE__}\n#{calls.to_yaml}\n===",
                  '', "#{File.basename($0)}:#{__LINE__}:in '#{__method__}'",
                  "@current_location: #{@current_location}"
      ) if @debug_dsl
      if @current_location
        here              = @current_location
        @current_location = nil
      elsif calls[index]
        where = calls[index].dup.to_s
        here  = where.gsub(/^\[/, '').gsub(/\]\s*$/, '')
      else
        here = 'unknown'
      end
      if @lib_name
        name = parse_caller(here)[0]
        if @lib_name == name
          here.sub!(/#{name}:/, '')
        end
      end
      here
    rescue
      failed_to_log(unable_to(sctn))
    end

    def first_script_index(script = @myName)
      target    = @deeper_call ? @deeper_call : script
      here      = 0
      where_idx = 2
      who       = ''
      call_list = get_call_list_new
      log_message(DEBUG, with_caller("=== #{__LINE__} @deeper_call:[#{@deeper_call}]  where_idx: #{where_idx}\n#{call_list.to_yaml}\n==="),
                  '', where_am_i?(where_idx)) if @debug_dsl and @deeper_call
      call_list.each_index do |x|
        a_caller = call_list[x].to_s
        a_caller =~ /([\(\)\w_\_\-\.]+\:\d+\:?.*?)$/
        caller = $1
        if caller =~ /#{target}|#{script}/
          here = x
          who  = caller
          break
        end
      end
      log_message(DEBUG, with_caller("=== #{__LINE__} index: [#{here}] @deeper_call:[#{@deeper_call}] where_idx: #{where_idx} who: [#{who}]"),
                  '', where_am_i?(where_idx)) if @debug_dsl and @deeper_call
      here
    rescue
      failed_to_log(unable_to)
    end

    def with_caller(message = '', *strings)
      call_arr             = get_call_array
      call_line, call_meth = get_previous_caller(call_arr, 1)[1, 2]

      if strings.include?(/^(@...@)$/)
        strg = "#{$1}#{call_meth}[#{call_line}]: "
      else
        strg = "#{call_meth}(): "
      end
      @current_location = call_arr[1]
      strg << build_message(message, *strings)
      strg
    end

    def get_previous_caller(call_arr, how_far = 1)
      script, line, meth = parse_caller(call_arr[how_far])
      meth.sub!(/^#{@method_prefix}_/i, '') if @method_prefix
      meth.sub!(/\s*\(*block\)*\s*/, '')
      [script, line, meth]
    end

  end

  module Regression

    class Runner

      def initiate_html_report(ts)
        html_report_dir = File.join(FileUtils.pwd, 'awetest_report')
        FileUtils.mkdir html_report_dir unless File.directory? html_report_dir
        @report_class = Awetestlib::HtmlReport2.new(@myName, html_report_dir, ts)
        @report_class.create_report(@myName)
      end

      def start
        before_run
        run
      rescue Exception => e
        failed_to_log(e.to_s, 3, e) unless e.message =~ /not currently supported by WatirNokogiri/i
      ensure
        after_run
      end

      def load_manifest
        sctn = RENV

        if @myRoot =~ /shamisen/i
          manifest_file = File.join(@myRoot, @myName, 'manifest.json')
        else
          manifest_file = File.join(@myRoot, 'manifest.json')
        end

        manifest = ::JSON.parse(File.open(manifest_file).read, :symbolize_names => true)[:params]

        unless @myRoot =~ /shamisen/i
          manifest[:browser]                         = @targetBrowser.abbrev
          manifest[:script_file]                     = "#{@myName}.rb"
          manifest[:log_properties]                  =
              {
                  :sequence           => 0,
                  :job_id             => Process.pid,
                  :project_version_id => nil,
                  :project_id         => 0,
                  :test_run_id        => "local#{$begin_time.strftime('%Y%m%d%H%M%S')}",
                  :script_id          => nil,
                  :company_id         => 3,
                  :test_case_id       => nil,
                  :test_category_id   => nil
              }
          manifest[:variables][:temp][:alm_run_type] = 'full'

          case manifest[:log_properties][:project_id]
            when 13
              manifest[:log_properties][:project_name] = 'WFRIA2'
            when 32
              manifest[:log_properties][:project_name] = 'WRIA2 Sandbox'
          end


        end

        msg = build_message("#{sctn}>> Job: #{manifest[:log_properties][:job_id]}",
                            "Run: #{manifest[:log_properties][:test_run_id]}",
                            "Project: #{manifest[:log_properties][:project_id]}",
                            "(#{manifest[:log_properties][:project_name]})"
        )
        debug_to_log(msg)
        # message_to_report(msg)
        debug_to_log(with_caller("\n#{('*' * 60)}\n#{manifest.to_yaml}\n#{('*' * 60)}")) if @debug_dsl

        manifest

      rescue
        failed_to_log(unable_to(sctn))
      end

    end

    module Reporting

      def report_results(errors, msg, component_symb = nil)
        call_meth = parse_caller(get_call_array[1])[2]
        full_msg  = ">> SUMMARY: #{build_msg("#{call_meth.titleize}:", msg)}"

        if errors > 0
          mark_test_level("#{full_msg}   ::FAIL::")
        else
          mark_test_level("#{full_msg}   ::Pass::")
        end

        if @current_instance
          # debug_to_log(with_caller("\n#{@current_instance.to_yaml}"))

          alm_pfx   = @current_instance[:alm_pfx]
          component = @wf2_components[component_symb][:name]

          if @current_instance[:errors].empty?
            @component_instances[component][alm_pfx][:status] = 'passed'
          else
            ref_list = []
            @current_instance[:errors].each_key do |ref|
              href  = @current_instance[:errors][ref][:href]
              count = @current_instance[:errors][ref][:count]
              text  = "#{ref}(#{count})"
              ref_list << "<a href=\"##{href}\">#{text}</a>"
            end

            @component_instances[component][alm_pfx][:smy_msg] =
                "[#{alm_pfx}] " +
                    "Page: #{@current_instance[:page]} " +
                    "Title: #{@current_instance[:title]}  " +
                    "(#{@current_instance[:ord_seq]})" +
                    "#{@current_instance[:desc]}"

            @component_instances[component][alm_pfx][:errors]   = @current_instance[:errors]
            @component_instances[component][alm_pfx][:ref_list] = ref_list
            @component_instances[component][alm_pfx][:status]   = 'failed'

          end
        end

      rescue
        failed_to_log(unable_to('*** waft014 ***'))
      end

      # def report_results(errors, msg, component_symb = nil)
      #   call_meth = parse_caller(get_call_array[1])[2]
      #   full_msg  = ">> SUMMARY: #{build_msg("#{call_meth.titleize}:", msg)}"
      #   status    = 'passed'
      #   if errors > 0
      #     mark_test_level("#{full_msg}   ::FAIL::")
      #     status = 'failed'
      #   else
      #     mark_test_level("#{full_msg}   ::Pass::")
      #     true
      #   end
      #     # if component_symb and @component_instances
      #     #   name = @wf2_components[component_symb][:name]
      #     #   @component_instances[name][]
      #     # end
      # rescue
      #   failed_to_log(unable_to)
      # end

      def tally_error_references
        tags_tested = 0
        tags_hit    = 0
        sctn        = RSMY
        mark_test_level(sctn + '>> Failed Defect or Test Case instances:')
        if @my_error_hits and @my_error_hits.length > 0
          @my_error_hits.keys.sort.each do |ref|
            # NOTE: WAFT specific override
            unless reference_is_alm?(ref)
              msg = format_reference_tally_msg(ref, @my_error_hits)
              message_to_report("#{sctn}#{msg}")
              tags_hit += 1
            end
          end
        else
          message_to_report(sctn + 'No failed defect or test case instances encountered.')
        end
        if @my_error_references and @my_error_references.length > 0
          if self.report_all_test_refs
            mark_test_level(sctn + '>> All tested Defect or Test Case instances:')
            @my_error_references.keys.sort.each do |ref|
              # NOTE: WAFT specific override
              unless reference_is_alm?(ref) or reference_is_waft_wip?(ref)
                msg = format_reference_tally_msg(ref, @my_error_references)
                message_to_report("#{sctn}#{msg}")
                tags_tested += 1
              end
            end
          end
        else
          message_to_report(sctn + '>> No Defect or Test Case references found.')
        end

        ">> One or more failures logged for #{tags_hit} of #{tags_tested} (#{nice_percent(tags_hit, tags_tested)}%)"
      end

      def format_reference_tally_msg(ref, source)
        sctn = RSMY
        msg  = "#{sctn}#{ref} (#{source[ref]})"
        msg << " -- #{@refs_desc[ref]}" if @refs_desc
        msg << " -- #{array_to_list(@alm_refs[:waft][ref])}" if alm_ref_exists?(ref)
        msg << " [waft_tc: #{@refs_waft_tc[ref]}]" if @refs_waft_tc[ref]
        if @refs_waft_wip
          if @refs_waft_wip[ref] and @bypass_wip
            msg << " (wip: #{array_to_list(@refs_waft_wip[ref])})"
          end
        end
        msg
      end

      def unformat_refs_to_arr(refs)
        out = []
        if refs.is_a?(Array)
          refs.each { |ref| out << unformat_reference(ref) }
        elsif refs.is_a?(Hash)
          refs.each_value { |v| out << unformat_reference(v) }
        else
          out << refs
        end
        out
      rescue
        failed_to_log(unable_to)
      end

      def parse_caller(caller)
        call_script, call_line, call_meth = caller.split(':')
        call_script.gsub!(/\.rb/, '')
        call_script = call_script.camelize
        call_meth =~ /in .([\w\d_ \?]+)./
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

      def parse_error_references(message, fail = false)
        initialize_reference_regexp unless @reference_regexp
        msg = message.dup
        while msg.match(@reference_regexp)
          fmt_ref = $1
          ref     = $2
          msg.sub!(fmt_ref, '')
          capture_error_reference(ref, fail)
          if fail and @current_instance
            capture_instance_fails(ref)
          end
        end
      rescue
        failed_to_log(unable_to('*** waft014 ***'))
      end

      def capture_instance_fails(ref)
        @current_instance[:errors][ref] = {} unless @current_instance[:errors][ref]
        @current_instance[:errors][ref][:count] ? @current_instance[:errors][ref][:count] += 1 : @current_instance[:errors][ref][:count] = 1

        @current_instance[:log][@my_failed_count] = [] unless @current_instance[:log][@my_failed_count]
        @current_instance[:log][@my_failed_count] << ref unless @current_instance[:log][@my_failed_count].include?(ref)

        unless @current_instance[:errors][ref][:href]
          @current_instance[:errors][ref][:href] =
              "#{@current_instance[:alm_pfx]}_#{@my_failed_count}"
              # "#{@current_instance[:alm_pfx]}_#{ref}_#{@current_instance[:errors][ref][:count]}"
        end

        unless @current_instance[:ref_done] == @current_instance[:errors][ref][:href]
          @current_instance[:fail_href] = @current_instance[:errors][ref][:href]
        end

        @current_instance[:status] = 'failed'
        debug_to_log(with_caller("\n#{@current_instance.to_yaml}"))
      end

      # def parse_error_references(message, fail = false)
      #   initialize_reference_regexp unless @reference_regexp
      #   msg = message.dup
      #   while msg.match(@reference_regexp)
      #     capture_error_reference($2, fail)
      #     msg.sub!($1, '')
      #   end
      # rescue
      #   failed_to_log(unable_to)
      # end

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

      # @private
      def unformat_reference(ref)
        r = nil
        if ref
          r = ref.dup
          r.gsub!('***', '')
          r.strip!
        end
        r
      rescue
        failed_to_log(unable_to)
      end

    end

    module TestData

      def instantiate_style_list
        @style_list =
            ['-webkit-app-region', '-webkit-appearance', '-webkit-background-composite',
             '-webkit-border-horizontal-spacing', '-webkit-border-vertical-spacing',
             '-webkit-box-align', '-webkit-box-decoration-break', '-webkit-box-direction',
             '-webkit-box-flex', '-webkit-box-flex-group', '-webkit-box-lines',
             '-webkit-box-ordinal-group', '-webkit-box-orient', '-webkit-box-pack',
             '-webkit-box-reflect', '-webkit-column-break-after', '-webkit-column-break-before',
             '-webkit-column-break-inside', '-webkit-column-count', '-webkit-column-gap',
             '-webkit-column-rule-color', '-webkit-column-rule-style', '-webkit-column-rule-width',
             '-webkit-column-span', '-webkit-column-width', '-webkit-font-smoothing', '-webkit-highlight',
             '-webkit-hyphenate-character', '-webkit-line-box-contain', '-webkit-line-break',
             '-webkit-line-clamp', '-webkit-locale', '-webkit-margin-after-collapse',
             '-webkit-margin-before-collapse', '-webkit-mask-box-image', '-webkit-mask-box-image-outset',
             '-webkit-mask-box-image-repeat', '-webkit-mask-box-image-slice', '-webkit-mask-box-image-source',
             '-webkit-mask-box-image-width', '-webkit-mask-clip', '-webkit-mask-composite',
             '-webkit-mask-image', '-webkit-mask-origin', '-webkit-mask-position', '-webkit-mask-repeat',
             '-webkit-mask-size', '-webkit-print-color-adjust', '-webkit-rtl-ordering',
             '-webkit-tap-highlight-color', '-webkit-text-combine', '-webkit-text-decorations-in-effect',
             '-webkit-text-emphasis-color', '-webkit-text-emphasis-position', '-webkit-text-emphasis-style',
             '-webkit-text-fill-color', '-webkit-text-orientation', '-webkit-text-security',
             '-webkit-text-stroke-color', '-webkit-text-stroke-width', '-webkit-user-drag',
             '-webkit-user-modify', '-webkit-user-select', 'align-content', 'align-items', 'align-self',
             'alignment-baseline', 'animation-delay', 'animation-direction', 'animation-duration',
             'animation-fill-mode', 'animation-iteration-count', 'animation-name', 'animation-play-state',
             'animation-timing-function', 'backface-visibility', 'background-attachment', 'background-blend-mode',
             'background-clip', 'background-color', 'background-image', 'background-origin',
             'background-position', 'background-repeat', 'background-size', 'baseline-shift', 'border-bottom-color',
             'border-bottom-left-radius', 'border-bottom-right-radius', 'border-bottom-style', 'border-bottom-width',
             'border-collapse', '-webkit-border-image', 'border-image-outset', 'border-image-repeat',
             'border-image-slice', 'border-image-source', 'border-image-width', 'border-left-color',
             'border-left-style', 'border-left-width', 'border-right-color', 'border-right-style',
             'border-right-width', 'border-top-color', 'border-top-left-radius', 'border-top-right-radius',
             'border-top-style', 'border-top-width', 'bottom', 'box-shadow', 'box-sizing', 'buffered-rendering',
             'caption-side', 'clear', 'clip', 'clip-path', 'clip-rule', 'color', 'color-interpolation',
             'color-interpolation-filters', 'color-rendering', 'cursor', 'cx', 'cy', 'direction', 'display',
             'dominant-baseline', 'empty-cells', 'fill', 'fill-opacity', 'fill-rule', 'filter', 'flex-basis',
             'flex-direction', 'flex-grow', 'flex-shrink', 'flex-wrap', 'float', 'flood-color', 'flood-opacity',
             'font-family', 'font-kerning', 'font-size', 'font-stretch', 'font-style', 'font-variant',
             'font-variant-ligatures', 'font-weight', 'glyph-orientation-horizontal', 'glyph-orientation-vertical',
             'height', 'image-rendering', 'isolation', 'justify-content', 'left', 'letter-spacing', 'lighting-color',
             'line-height', 'list-style-image', 'list-style-position', 'list-style-type', 'margin-bottom', 'margin-left',
             'margin-right', 'margin-top', 'marker-end', 'marker-mid', 'marker-start', 'mask', 'mask-type', 'max-height',
             'max-width', 'min-height', 'min-width', 'mix-blend-mode', 'object-fit', 'object-position', 'opacity', 'order',
             'orphans', 'outline-color', 'outline-offset', 'outline-style', 'outline-width', 'overflow-wrap', 'overflow-x',
             'overflow-y', 'padding-bottom', 'padding-left', 'padding-right', 'padding-top', 'page-break-after',
             'page-break-before', 'page-break-inside', 'paint-order', 'perspective', 'perspective-origin', 'pointer-events',
             'position', 'r', 'resize', 'right', 'rx', 'ry', 'shape-image-threshold', 'shape-margin', 'shape-outside',
             'shape-rendering', 'speak', 'stop-color', 'stop-opacity', 'stroke', 'stroke-dasharray', 'stroke-dashoffset',
             'stroke-linecap', 'stroke-linejoin', 'stroke-miterlimit', 'stroke-opacity', 'stroke-width', 'tab-size',
             'table-layout', 'text-align', 'text-anchor', 'text-decoration', 'text-indent', 'text-overflow', 'text-rendering',
             'text-shadow', 'text-transform', 'top', 'touch-action', 'transform', 'transform-origin', 'transform-style',
             'transition-delay', 'transition-duration', 'transition-property', 'transition-timing-function', 'unicode-bidi',
             'vector-effect', 'vertical-align', 'visibility', 'white-space', 'widows', 'width', 'will-change', 'word-break',
             'word-spacing', 'word-wrap', 'writing-mode', '-webkit-writing-mode', 'x', 'y', 'z-index', 'zoom']
      end

      def load_variables(file, key_type = :role, enabled_only = true, dbg = true, scripts = nil, sctn = RSTP)
        message_to_report(with_caller(sctn, file, "key: '#{key_type}'"))

        # ok = true

        debug_to_log("#{__method__}: file = #{file}")
        debug_to_log("#{__method__}: key  = #{key_type}")

        workbook = file =~ /\.xlsx$/ ? Roo::Excelx.new(file) : Roo::Excel.new(file)

        if @myName =~ /appium/i
          ok = script_found_in_data = script_found_in_login = true
        else
          script_found_in_data      = load_data_variables(workbook, dbg)
          ok, script_found_in_login = load_login_variables(workbook, enabled_only, file, key_type, scripts, dbg)
        end

        unless @env_name =~ /^gen/
          unless ok and script_found_in_login and script_found_in_data
            ok = false
            failed_to_log("#{sctn}Script found: in Login = #{script_found_in_login}; in Data = #{script_found_in_data}")
          end
        end

        workbook.close

        [ok, script_found_in_login, script_found_in_data]
      rescue
        failed_to_log(unable_to(sctn))
      end

    end

    module Utilities

      REG_COLOR_HEX = /(#([0-9a-f]{6}|[0-9a-f]{3})([\s;]|$))/i
      REG_COLOR_NUM = Regexp.new('((hsl|rgb)[\s]*\([\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*\))', Regexp::IGNORECASE)
      REG_COLOR_OPA = Regexp.new('((hsla|rgba)[\s]*\([\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*\))', Regexp::IGNORECASE)
      REG_COLOR     = Regexp.union(REG_COLOR_NUM, REG_COLOR_OPA, REG_COLOR_HEX)

      REG_GRADIENT = /[-a-z]*gradient\([-a-z0-9 .,#%()]*\)/im

      # def validate_col_percent(browser, expected_percentage)
      #   actual = calculate_col_percentage(browser)
      #   msg = "Column percentage equals #{expected_percentage}?"
      #   if actual == expected_percentage
      #     pass_to_log(msg)
      #   else
      #     fail_to_log("#{msg} Found '#{actual}'.")
      #   end
      # end
      #
      # def calculate_col_percentage(browser)
      #   #TODO: make more generic and remove instance variable
      #   bodysize        = browser.body.style 'width'
      #   bodysize        = bodysize.to_f
      #   col_size        = browser.div(:class, 'wf2-u').style 'width'
      #   col_size        = col_size.to_f
      #   ((col_size/bodysize)*100).to_i
      # end

      # def set_current_instance(desc, page, tc_hash)
      #   @current_instance = {
      #       :component => tc_hash['component'],
      #       :page      => page,
      #       :ord_seq   => tc_hash[:ord_seq],
      #       :alm_pfx   => tc_hash[:alm_pfx],
      #       :title     => tc_hash['title'],
      #       :desc      => desc,
      #       :errors    => {},
      #       :log       => {},
      #       :status    => 'pending'
      #   }
      # end

      def get_sha1_by_git_style(filespec)
        mem_buf = File.open(filespec) { |io| io.read }
        size    = mem_buf.size
        puts "size is #{size}"

        header = "blob #{size}\0" # type(space)size(null byte)
        store  = header + mem_buf

        sha1 = Digest::SHA1.hexdigest(store)
      end

      def nice_array(arr, space_to_underscore = false)
        new_arr = Array.new
        if space_to_underscore
          arr.each do |nty|
            new_arr << nty.gsub(/\s/, '_')
          end
        else
          new_arr = arr if arr
        end
        "['#{new_arr.join("', '")}']"
      end

      def string_array_numeric_sort(arr, direction = 'asc')
        #TODO: almost certainly a more 'rubyish' and less clunky way to do this
        trgt = arr.dup
        narr = []
        trgt.each do |n|
          narr << n.to_i
        end

        narr.sort!
        unless direction =~ /^asc/i
          narr.reverse!
        end

        sarr = []
        narr.each do |n|
          sarr << n.to_s
        end

        sarr
      end

      def set_xls_spec(proj_acro = 'unknown', env = @env_name.downcase.underscore, fix = :prefix, xlsx = $xlsx)
        env = env.split(/:[\s_]*/)[1] if env =~ /:/
        case fix
          when :prefix
            xls_name = "#{proj_acro}_#{env}.xls"
          when :suffix
            xls_name = "#{env}_#{proj_acro}.xls"
          when :none
            xls_name = "#{env.gsub('-', '_')}.xls"
          else
            failed_to_log(with_caller("#{RSTP}Unknown fix type: '#{fix}'.  Must be 'prefix', 'suffix', or 'none'."))
            return nil
        end
        spec = "#{@myRoot}/#{xls_name}"
        spec << 'x' if xlsx
        debug_to_log("#{where_am_i?}: #{spec}")
        spec
      rescue
        failed_to_log(unable_to(RSTP))
      end

      def set_env_name(xls = @xls_path, fix = :prefix, strg = 'toad')
        if fix == :prefix
          pattern = /#{strg}_([\w\d]+)\.xls$/
        else
          pattern = /([\w\d]+)_#{strg}\.xls$/
        end
        if awetestlib?
          if @runenv
            @env_name = @myAppEnv.name.downcase.underscore
          else
            @env_name = 'dev'
            #if xls
            #  xls =~ pattern
            #  @env_name = $1
            #else
            #  @env_name = 'sit'
            #end
          end
        else
          @env_name = @myAppEnv.name.downcase # .underscore #.gsub(/^toad./, '')
        end
      rescue
        failed_to_log(unable_to(RSTP))
      end

      def get_awetest_manifest
        if @myRoot =~ /shamisen/i

        else

        end
      end

      def deeply_sort_hash(object)
        return object unless object.is_a?(Hash)
        hash = {}
        # hash = RUBY_VERSION >= '1.9' ? Hash.new : ActiveSupport::OrderedHash.new
        object.each { |k, v| hash[k] = deeply_sort_hash(v) }
        sorted = hash.sort { |a, b| a[0].to_s <=> b[0].to_s }
        hash.class[sorted]
      end

      def to_valid_symbol(strg, sctn = RSTP)
        rtrn = ''
        if strg =~ /^\d/
          rtrn = '_'
        end
        rtrn << strg.gsub(/-|\s+|\./, '_').downcase
        rtrn.to_sym
      rescue
        failed_to_log(unable_to(sctn))
      end

      def array_to_list(arr, delim = ',', spaces = true)
        list = ''
        arr.each do |entry|
          strg = entry.to_s
          if strg =~ /#{delim}/
            list << "\"#{strg}\""
          else
            list << strg
          end
          unless entry == arr.last
            list << "#{delim}"
            list << ' ' if spaces
          end
        end
        list
      end

      def dump_option_array(options, desc = '', to_report = false)
        msg   = with_caller(desc, "\n")
        count = 1
        options.each do |option|
          msg << "#{count}: innerText: #{option.attribute_value('innerText')} text: '#{option.text}' label: '#{option.label}' value: '#{option.value}' selected: #{option.selected?}\n"
          count += 1
        end
        if to_report
          debug_to_report(msg)
        else
          debug_to_log(msg)
        end
      end

      def extract_selected(selected_options, which = :text, sctn = RDTL)
        arr = Array.new
        selected_options.each do |so|
          case which
            when :text
              arr << so.attribute_value('innerText')
            when :value
              arr << so.value
            when :label
              arr << so.label
            when :inner
              arr << so.attribute_value('innerText')
            else
              arr << so.value
          end
        end
        arr.sort
      rescue
        failed_to_log(unable_to(sctn))
      end

      def build_message(strg1, *strings)
        msg = "#{strg1}"
        strings.each do |strg|
          if strg.is_a?(Array)
            strg.each do |str|
              next if str =~ /^@...@$/
              msg << " #{str}" if str and str.size > 0
            end
          else
            next if strg =~ /^@...@$/
            msg << " #{strg}" if strg and strg.size > 0
          end
        end if strings
        msg
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def html_to_rgb(html, a = true)
        if html and html.length > 0
          html, opacity = html.split(/\s+/)
          html          = html.gsub(%r{[#;]}, '')
          case html.size
            when 3
              colors = html.scan(%r{[0-9A-Fa-f]}).map { |el| (el * 2).to_i(16) }
            when 6
              colors = html.scan(%r<[0-9A-Fa-f]{2}>).map { |el| el.to_i(16) }
          end
          rgb = 'rgb'
          rgb << 'a' if a
          rgb << '('
          colors.each do |c|
            rgb << "#{c}, "
          end
          if a
            if opacity
              opacity = normalize_opacity(opacity)
              rgb << opacity
            else
              rgb << '1'
            end
            rgb << ')'
          else
            rgb.strip!.chop!
            rgb << ')'
          end
          rgb
        else
          html
        end
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def normalize_opacity(a, int = true)
        opacity = a.dup
        case opacity
          when /%/
            opacity = opacity.sub(/%/, '').to_f / 100.0
          when /(-?[\d\.]+)\w+/
            opacity = $1.to_f
          else
            opacity = opacity.to_f
        end
        # case opacity
        #   when 0.0
        #     opacity = 0
        #   when 1.0
        #     opacity = 1
        # end
        opacity = opacity.round if int
        opacity.to_s
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def normalize_color_value(value, rgba = true, int = true)
        case value
          when /^#/
            html_to_rgb(value, rgba)
          when /^rgba/i
            if rgba
              value =~ /^rgba\(0,\s*0,\s*0,\s*0\)/ ? 'rgba(255, 255, 255, 0)' : value
            else
              html_to_rgb(rgb_to_html(value), rgba)
            end
          when /^rgb\s*\(/i
            if rgba
              rgb_to_rgba(value, int)
            else
              value
            end
          when /^transparent/i, /^0$/i
            if rgba
              'rgba(255, 255, 255, 0)'
            else
              'rgb(255, 255, 255)'
            end
          when /white/
            if rgba
              'rgba(255, 255, 255, 1)'
            else
              'rgb(255, 255, 255)'
            end
          else
            html_to_rgb(translate_color_name(value), rgba)
        end
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def contrast_ratio(color1, color2)
        # Calculate contrast ratio acording to WCAG 2.0 formula
        # Will return a value between 1 (no contrast) and 21 (max contrast)
        # @link http://www.w3.org/TR/WCAG20/#contrast-ratiodef
        # Credit: Marcus Bointon <marcus@synchromedia.co.uk>
        lum1 = relative_luminance(color1)
        lum2 = relative_luminance(color2)
        if lum1 < lum2
          lum3 = lum1
          lum1 = lum2
          lum2 = lum3
        end
        (lum1 + 0.05) / (lum2 + 0.05);
      end

      def relative_luminance(color)
        # Calculate relative luminance in sRGB colour space for use in WCAG 2.0 compliance
        # @link http://www.w3.org/TR/WCAG20/#relativeluminancedef
        # Credit: Marcus Bointon <marcus@synchromedia.co.uk>
        rgb = normalize_color_value(color, false)
        rgb =~ /rgb\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\)/i
        arr = [($1.to_i / 255.0), ($2.to_i / 255.0), ($3.to_i / 255.0)]
        cor = []
        arr.each do |raw|
          if raw <= 0.03928
            new = raw / 12.92
          else
            new = ((raw + 0.055) / 1.055) ** 2.4
          end
          cor << new
        end
        r   = (cor[0] * 0.2126)
        g   = (cor[1] * 0.7152)
        b   =(cor[2] * 0.0722)
        lum = r + g + b
        lum
      end

      def rgb_to_html(rgb)
        rgb =~ /rgba?\((.+)\)/
        if $1
          r, g, b, a = $1.split(/,\s*/)
          if a and a.to_i == 0
            '#ffffff'
          else
            "#%02x%02x%02x" % [r, g, b]
          end
        else
          rgb
        end
      end

      def rgb_to_rgba(rgb, int = true)
        target = rgb.dup
        if target.match(/^(rgb\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\))/i)
          hit = $1
          r   = $2
          g   = $3
          b   = $4
          op  = target.sub(hit, '')
          op.strip! if op
          if op.length > 0
            op = normalize_opacity(op, int)
          else
            op = '1'
          end
          rtrn = "rgba(#{r}, #{g}, #{b}, #{op})" #waft-1148
        else
          rtrn = rgb
        end
        rtrn
      end

      # TODO: translate this to ruby to calculate relative luminance and contrast ratio.
      #       /**
      #  * Calculate relative luminance in sRGB colour space for use in WCAG 2.0 compliance
      #  * @link http://www.w3.org/TR/WCAG20/#relativeluminancedef
      #       * @param string $col A 3 or 6-digit hex colour string
      #       * @return float
      #       * @author Marcus Bointon <marcus@synchromedia.co.uk>
      #       */
      # function relativeluminance($col) {
      #     //Remove any leading #
      #       $col = trim($col, '#');
      #       //Convert 3-digit to 6-digit
      #       if (strlen($col) == 3) {
      #           $col = $col[0] . $col[0] . $col[1] . $col[1] . $col[2] . $col[2];
      #       }
      #       //Convert hex to 0-1 scale
      #       $components = array(
      #           'r' => hexdec(substr($col, 0, 2)) / 255,
      #           'g' => hexdec(substr($col, 2, 2)) / 255,
      #           'b' => hexdec(substr($col, 4, 2)) / 255
      #       );
      #       //Correct for sRGB
      #                 foreach($components as $c => $v) {
      #             if ($v <= 0.03928) {
      #                 $components[$c] = $v / 12.92;
      #             } else {
      #                 $components[$c] = pow((($v + 0.055) / 1.055), 2.4);
      #             }
      #             }
      #             //Calculate relative luminance using ITU-R BT. 709 coefficients
      #             return ($components['r'] * 0.2126) + ($components['g'] * 0.7152) + ($components['b'] * 0.0722);
      #             }
      #
      #             /**
      #  * Calculate contrast ratio acording to WCAG 2.0 formula
      #  * Will return a value between 1 (no contrast) and 21 (max contrast)
      #  * @link http://www.w3.org/TR/WCAG20/#contrast-ratiodef
      #             * @param string $c1 A 3 or 6-digit hex colour string
      #             * @param string $c2 A 3 or 6-digit hex colour string
      #             * @return float
      #             * @author Marcus Bointon <marcus@synchromedia.co.uk>
      #             */
      # function contrastratio($c1, $c2) {
      #     $y1 = relativeluminance($c1);
      #     $y2 = relativeluminance($c2);
      #     //Arrange so $y1 is lightest
      #             if ($y1 < $y2) {
      #                 $y3 = $y1;
      #             $y1 = $y2;
      #             $y2 = $y3;
      #             }
      #             return ($y1 + 0.05) / ($y2 + 0.05);
      #             }

      def px_to_fixnum(px, int = true)
        if px =~ /px/i
          strg = px.sub('px', '').strip
          if int
            nbr = strg.to_i
          else
            nbr = strg.to_f
          end
        else
          nbr = nil
        end
        nbr
      end

      def unable_to(message = '', no_dolbang = false, verify_that = false, caller_index = 1)
        call_arr = get_call_array
        puts call_arr
        call_script, call_line, call_meth = parse_caller(call_arr[caller_index])
        strg                              = build_message(RDTL, 'Unable to')
        strg << ' verify' if verify_that
        strg << " #{call_meth.titleize}:"
        strg << '?' if call_meth =~ /\?/
        strg << ':'
        strg << " #{message}" if message.length > 0
        strg << " '#{$!}'" unless no_dolbang
        strg << ' *** waft011 ***' if message and message =~ /undefined method/i
        strg
      end

      def thread_counts
        list    = Thread.list
        total   = list.count
        running = list.select { |thread| thread.status == 'run' }.count
        [total, running]
      end

      def explore_focus(container, limit = 20)

        (1..limit).each do |cnt|
          active = get_active_element(container)
          debug_to_report(with_caller(RDTL, "#{cnt}: #{active}",
                                      "class:'#{active.attribute_value('class')}'",
                                      ("html:#{active.html}" if active.tag_name == 'a')
                          ))
          send_a_key(container, :tab)
          sleep(3)
        end

      end

      def nice_percent(numerator, denominator, decimals = 2)
        percent = denominator > 0 ? (numerator.to_f/denominator.to_f) * 100.0 : 0.0
        sprintf("%.#{decimals}f", percent)
      end

      def truncate_string(strg, side = 'right', max = 30)
        trgt = strg.to_s
        if side == 'right'
          trgt.to_s.length <= max ? trgt : "#{trgt.slice(0, max - 3)}..."
        else
          trgt.to_s.length <= max ? trgt : "...#{trgt.slice(-(max - 3), trgt.size)}"
        end
      end

      def element_action_message(element, action, how = nil, what = nil, value = nil, desc = '', refs = '')
        if element.respond_to?(:tag_name)
          begin
            name = element.tag_name #.upcase
          rescue
            name = element.to_s
          end
        else
          name = element.to_s
        end
        how, what = extract_locator(element, how)[1, 2] unless how and what
        build_message(RDTL, desc, action, "#{name}",
                      (what ? "with #{how}=>'#{what}'" : nil),
                      (value ? "and value=>'#{value}'" : nil), refs)
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def extract_locator(element, how = nil, desc = '', refs = '', sctn = RDTL)
        if element.respond_to?(:tag_name)
          tag = element.tag_name.to_sym
        else
          element = element.body.elements[0]
          tag     = element.tag_name.to_sym
        end
        what = nil
        case how
          when nil
            [:id, :name, :title, :class, :value, :text, :index].each do |attr|
              case attr
                when :id
                  what = element.id
                when :text
                  what = element.text
                when :index
                  what = element.index
                else
                  what = element.attribute_value(attr.to_s)
              end
              if what and what.length > 0 and what != 'undefined'
                how = attr
                break
              end
            end
          else
            if how.is_a?(Symbol)
              if [:id, :name, :title, :class, :value, :text, :index].include?(how)
                case how
                  when :text
                    what = element.text
                  when :index
                    what = element.index
                  else
                    what = element.attribute_value(how.to_s)
                end
              else
                failed_to_log(with_caller(sctn, desc, "Parameter 'how' must be :id, :name, :title, :class, :value, :text, or :index. Found ('#{how}')",
                                          refs, '*** waft015 ***'))
              end
            else
              failed_to_log(with_caller(sctn, desc, "Parameter 'how' must be Symbol or nil. Found ('#{how}')",
                                        refs, '*** waft015 ***'))
            end
        end
        debug_to_log(with_caller("#{tag}:#{how}:#{what} Index may not reflect context.")) if how == :index
        [tag, how, what]
      rescue
        failed_to_log(unable_to(build_message(sctn, ":#{tag}, :#{how}='#{what}'", desc, refs)))
      end

      def format_locator(tag, how = nil, what = nil)
        if tag.is_a?(Array)
          "#{tag[0]}:#{tag[1]}:#{tag[2]}"
        else
          "#{tag}:#{how}:#{what}"
        end
      end

      alias nbr2wd number_to_word

      def get_project_git(proj_name, proj_dir = Dir.pwd)
        debug_to_log(with_caller(proj_dir))
        branch   = nil
        git_data = nil
        git_hash = {}

        curr_dir     = Dir.pwd
        version_file = "#{proj_name.downcase.gsub(' ', '_')}_version"

        if Dir.exists?(proj_dir)

          Dir.chdir(proj_dir) unless proj_dir == curr_dir

          if Dir.exists?('.git')
            require 'git'
            git    = Git.open(Dir.pwd)
            branch = git.current_branch
            commit = git.gblob(branch).log(5).first
            sha    = commit.sha
            date   = commit.date

            git_data = "#{proj_name}: #{branch}, #{date}, #{sha}"

            git_hash[:branch]    = branch
            git_hash[:commit]    = commit
            git_hash[:date]      = date
            git_hash[:sha]       = sha
            git_hash[:short_sha] = sha.to_s.slice(0, 8)

            write_project_version_file(curr_dir, git_data, version_file)

          end

          Dir.chdir(curr_dir) unless proj_dir == curr_dir

        end

        unless branch
          version_file = File.join(Dir.pwd, version_file)
          if File.exists?(version_file)
            vers                 = File.open(version_file).read
            branch, date, sha    = parse_list(vers.chomp)
            git_hash[:branch]    = branch
            git_hash[:commit]    = ''
            git_hash[:date]      = date
            git_hash[:sha]       = sha
            git_hash[:short_sha] = sha.to_s.slice(0, 8)

            git_data = "#{branch}, #{date}, #{sha}"
          end
        end

        [git_data, git_hash]
      end

      def write_project_version_file(curr_dir, git_data, version_file)
        version_file = File.join(curr_dir, version_file)
        file         = File.open(version_file, 'w')
        file.puts git_data
        file.close
        version_file
      end

      def who_is_in_front(high, low, sctn = RDTL)
        # Order matters, high is above low in html
        h_who, h_z, h_pos = high
        l_who, l_z, l_pos = low

        front = l_who

        unless h_z == l_z
          if h_pos =~ /fixed|absolute|relative/i and l_pos =~ /fixed|absolute|relative/i
            if h_z.to_i > l_z.to_i
              front = h_who
            end
          else
            if h_pos =~ /fixed|absolute|relative/i
              if h_z =~ /-?\d+/
                front = h_who
              end
            end
          end
        end

        front

      rescue
        failed_to_log(unable_to(sctn))
      end

      def normalize_background_style(value, rgba = true)
        weight, style, color = parse_list(value, ' ', 3)
        norm_color           = normalize_color_value(color, rgba)
        "#{weight} #{style} #{norm_color}"
      end

      def normalize_border_style(value, rgba = true)
        weight, style, color = parse_list(value, ' ', 3)
        norm_color           = normalize_color_value(color, rgba)
        "#{weight} #{style} #{norm_color}"
      end

      def normalize_outline(value, rgba = false)
        if value == '0'
          'rgb(255, 255, 255) none 0px'
        else
          style, color, weight = parse_list(value, ' ', 3)
          norm_color           = normalize_color_value(color, rgba)
          "#{weight} #{style} #{norm_color}"
        end
      end

      def pixel_to_fixnum(value)
        if value
          rtrn = value.dup
          rtrn.gsub!('px', '')
          rtrn.to_f
        end
      end

      def normalize_pixel_size(value)
        mtch = value.match(/^(\d+)\.?\d*?\s*px/)
        norm = mtch[1]
        "#{norm}px"
      end

      alias normalize_border_width normalize_pixel_size

      def normalize_font_size(size, to_unit = 'px', desc = '', refs = '', prnt_px = $default_font_size)
        convert_font_size(size, to_unit, prnt_px, desc, refs)
      end

      def convert_font_size(size, to, prnt_px = $default_font_size, desc = '', refs = '', formatted = false, sctn = RDTL)
        size.match(/^([-+\d\.]+)\s*(px|em|rem|pt|%)$/)
        value = $1
        from  = $2
        cnvt  = nil
        unit  = nil
        case from
          when 'px'
            cnvt, unit = px_to(value, to, prnt_px)
          when 'em'
            cnvt, unit = em_to(value, to, prnt_px)
          when 'rem'
            cnvt, unit = rem_to(value, to, prnt_px)
          when 'pt'
            cnvt, unit = pt_to(value, to, prnt_px)
          when '%'
            cnvt, unit = pct_to(value, to, prnt_px)
          else
            # CSS absolute size keywords:	xx-small	x-small	small	medium	large	x-large	xx-large
            # HTML absolute font sizes:
            # (interpolated Mozilla values)	1	 	2	3	4	5	6	7
            # HTML headings:
            # (interpolated Mosaic values)	h6	 	h5	h4	h3	h2	h1
            # normalized scaling factor:	60% - 3:5	75% - 3:4	89% - 8:9	100% - 1:1	120% - 6:5	150% - 3:2	200% - 2:1	300% - 3:1
            # px computed from a 16 ppem base: e.g., 12pt @ 96ppi or 16pt @ 72ppi
            # (XP 5.0 UA default)	10px 12px 14px 16px 19px 24px 32px 48px
            if size =~ /^0$|^initial$|^inherit$|^none$/
              cnvt = size
            else
              failed_to_log(with_caller(RDTL, "'#{value}' #{from} to #{to} not supported.", desc, refs))
            end
        end

        if cnvt
          if unit
            if formatted
              rtrn = "#{'%.4g' % cnvt}#{unit}"
            else
              rtrn = "#{'%.4g' % cnvt}"
            end
          else
            rtrn = cnvt
          end
        else
          failed_to_log(unable_to(with_caller(RDTL, "'#{value}' #{from} to #{to}.", desc, refs)))
          rtrn = nil
        end unless cnvt == 'nil'
        [rtrn, unit]
      end

      def px_to(value, to, prnt_px = $default_font_size)
        # debug_to_log(with_caller(value, to))
        unit = nil
        case to
          when 'px', :px
            unit = 'px'
          when 'em', :em
            value = (value.to_f / prnt_px)
            unit  = 'em'
          when 'rem', :rem
            value = (value.to_f / $default_font_size)
            unit  = 'rem'
          when 'pt', :pt
            value = (value.to_f * (72.0 / $default_screen_dpi)).round
            unit  = 'pt'
          when '%', 'pct', 'percent', :pct, :percent
            value = (value.to_f / prnt_px) * 100.0
            unit  = '%'
          else
            failed_to_log(with_caller(RDTL, "px to #{to} not supported."))
            value = 'nil'
        end
        [value, unit]
      end

      def em_to(value, to, prnt_px = $default_font_size)
        # debug_to_log(with_caller(value, to))
        unit = nil
        case to
          when 'px', :px
            value = (value.to_f * prnt_px)
            unit  = 'px'
          when 'em', :em
            unit = 'em'
          when 'rem', :rem
            value = (value.to_f * $default_font_size)
            unit  = 'rem'
          when 'pt', :pt
            value = ((value.to_f * prnt_px) * (72.0 / $default_screen_dpi)).round
            unit  = 'pt'
          when '%', 'pct', 'percent', :pct, :percent
            value = (value.to_f * 100.0)
            unit  = '%'
          else
            failed_to_log(with_caller(RDTL, "em to #{to} not supported."))
            value = 'nil'
        end
        [value, unit]
      end

      def rem_to(value, to, prnt_px = $default_font_size)
        # debug_to_log(with_caller(value, to))
        unit = nil
        case to
          when 'px', :px
            value = (value.to_f * $default_font_size)
            unit  = 'px'
          when 'em', :em
            unit = 'em'
          when 'rem', :rem
            unit = 'rem'
          when 'pt', :pt
            value = ((value.to_f * $default_font_size) * (72.0 / $default_screen_dpi)).round
            unit  = 'pt'
          when '%', 'pct', 'percent', :pct, :percent
            value = (value.to_f * 100.0)
            unit  = '%'
          else
            failed_to_log(with_caller(RDTL, "rem to #{to} not supported."))
            value = 'nil'
        end
        [value, unit]
      end

      def pt_to(value, to, prnt_px = $default_font_size)
        # debug_to_log(with_caller(value, to))
        unit = nil
        case to
          when 'px', :px
            value = (value.to_f / (72.0 / $default_screen_dpi)).round
            unit  = 'px'
          when 'em', :em
            value = ((prnt_px * value.to_f) / (72.0 / $default_screen_dpi))
          when 'rem', :rem
            value = (($default_font_size * value.to_f) / (72.0 / $default_screen_dpi))
            unit  = 'rem'
          when 'pt', :pt
            unit = 'pt'
          when '%', 'pct', 'percent', :pct, :percent
            value = (((prnt_px) * (value.to_f / 100.0)) / (72.0 / $default_screen_dpi))
            unit  = '%'
          else
            failed_to_log(with_caller(RDTL, "pt to #{to} not supported."))
            value = 'nil'
        end
        [value, unit]
      end

      def pct_to(value, to, prnt_px = $default_font_size)
        # debug_to_log(with_caller(value, to))
        unit = nil
        case to
          when 'px', :px
            ((value.to_f * prnt_px) / 100).round
            unit = 'px'
          when 'em', :em
            (value.to_f / 100.0)
          when 'rem', :rem
            (value.to_f / 100.0)
            unit = 'rem'
          when 'pt', :pt
            value = nil
            unit  = 'pt'
          when '%', 'pct', 'percent', :pct, :percent
            unit = '%'
          else
            failed_to_log(with_caller(RDTL, "% to #{to} not supported."))
            value = 'nil'
        end

        [value, unit]
      end

      def parse_border(value, rgba = true)
        weight, style, color = parse_list(value, ' ', 3)
        [weight, style, normalize_color_value(color, rgba)]
      end

      def normalize_gradient_value(value, rgba = true, structure = 'linear')
        gradient = nil

        # linear-gradient(to bottom, #2f6e97 0, #0b4e79 100%)
        # linear-gradient(rgba(11, 78, 121, 1), rgba(47, 110, 151, 0))
        debug_to_log(with_caller("input:  '#{value}'"))

        if value.match(/^#{structure}-gradient\((.+)\)/i)
          content = $1.dup
          # puts "'#{content}'"
          mtch1   = content.match(REG_COLOR)
          # puts "'#{mtch1}'"
          content.sub!(/#{Regexp.escape(mtch1.to_s.strip)}/, '')
          # puts "'#{content}'"
          mtch2 = content.match(REG_COLOR)
          # puts "'#{mtch2}'"
          content.sub!(/#{Regexp.escape(mtch2.to_s.strip)}/, '')
          # puts "'#{content}'"

          arr = content.split(/,\s*/)
          debug_to_log(with_caller(nice_array(arr)))

          case arr.length
            when 3
              if arr[0] =~ /to top/i
                left  = "#{mtch2}#{arr[2].strip}"
                right = "#{mtch1}#{arr[1].strip}"
              else
                left  = "#{mtch1}#{arr[1].strip}"
                right = "#{mtch2}#{arr[2].strip}"
              end
            when 2
              left  = "#{mtch1}#{arr[0].strip}"
              right = "#{mtch2}#{arr[1].strip}"
            else
              left  = "#{mtch1.strip}"
              right = "#{mtch2.strip}"
          end

          debug_to_log(with_caller("left:  '#{left}'", "right: '#{right}'"))

          norm_left  = normalize_color_value(left, rgba)
          norm_right = normalize_color_value(right, rgba)

          gradient = "#{structure}-gradient(#{norm_left}, #{norm_right})"

          # if value =~ /\#/
          #   if value.match(/^linear-gradient\((.+)\)/)
          #     dir, one, two = parse_list($1)
          #     norm_one      = normalize_color_value(one, rgba)
          #     norm_two      = normalize_color_value(two, rgba)
          #     if dir == 'top'
          #       gradient = "linear-gradient(#{norm_one}, #{norm_two})"
          #     else
          #       gradient = "linear-gradient(#{norm_two}, #{norm_one})"
          #     end
          #   end
          # end
          # debug_to_log(with_caller("'#{value}' => '#{gradient}'"))
          # gradient ? gradient : value

        end
        gradient
      end

      def normalize_box_shadow_value(value, rgba = false)
        box_shadow = nil
        ok         = true

        # rgb(141, 200, 19) 0px 0px 0px 2px
        # 0px 0px 0px 2px #8dc813

        rgb_ptrn   = /rgb\((\d+),\s+(\d+),\s+(\d+)\)\s+(\d+)px\s+(\d+)px\s+(\d+)px\s+(\d+)px/
        hex_ptrn   = /(\d+)px\s+(\d+)px\s+(\d+)px\s+(\d+)px\s+#([\d\w]+)/

        if value.match(hex_ptrn)
          rgb        = html_to_rgb($5, rgba)
          box_shadow = "#{rgb} #{$1}px #{$2}px #{$3}px #{$4}px"
        elsif value.match(rgb_ptrn)
          box_shadow = value
        elsif value =~ /none/i
          box_shadow = value
        else
          failed_to_log("Unrecognized box-shadow value '#{value}'  *** waft015 ***")
          ok = false
        end
        [ok, box_shadow]
      end

      def rescue_me(e, me = nil, what = nil, where = nil, who = nil)
        #TODO: these are rescues from exceptions raised in Watir or Watir-webdriver
        debug_to_log(with_caller('Begin rescue'))
        ok = false
        begin
          gaak    = who.inspect
          located = gaak =~ /located=true/i
        rescue
          debug_to_log(with_caller(" gaak: '#{gaak}'"))
        end
        msg = e.message
        debug_to_log(with_caller(" msg = #{msg}"))
        if msg =~ /undefined method\s+.join.\s+for/i # firewatir to_s implementation error
          ok = true
        elsif msg =~ /the server refused the connection/i
          ok = true
        elsif msg =~ /undefined method\s+.match.\s+for.+WIN32OLERuntimeError/i # watir and firewatir
          ok = true
        elsif msg =~ /undefined method\s+.match.\s+for.+UnknownObjectException/i # watir
          ok = true
        elsif msg =~ /window\.getBrowser is not a function/i # firewatir
          ok = true
        elsif msg =~ /WIN32OLERuntimeError/i # watir
          ok = true
        elsif msg =~ /undefined method\s+.match.\s+for/i # watir
          ok = true
        elsif msg =~ /wrong number of arguments \(1 for 0\)/i
          ok = true
        elsif msg =~ /unable to locate element/i
          if located
            ok = true
          elsif where == 'Watir::Div'
            ok = true
          end
        elsif msg =~ /(The SafariDriver does not interact with modal dialogs)/i
          to_report = $1
          ok        = true
        elsif msg =~ /HRESULT error code:0x80070005/
          ok = true
          #elsif msg =~ /missing\s+\;\s+before statement/
          #  ok = true
        end
        call_list = get_call_list(6, true)
        if ok
          debug_to_log(with_caller("RESCUED: \n#{who.to_yaml}=> #{what} in #{me}()\n=> '#{$!}'"))
          debug_to_log(with_caller("#{who.inspect}")) if who
          debug_to_log(with_caller("#{where.inspect}"))
          debug_to_log(with_caller("#{call_list}"))
          failed_to_log(with_caller("#{to_report}  #{call_list}"))
        else
          debug_to_log(with_caller("NO RESCUE: #{e.message}"))
          debug_to_log(with_caller("NO RESCUE: \n#{call_list}"))
        end
        debug_to_log(with_caller('Exit'))
        ok
      end

      def get_element_properties(element, list = [])
        hash = {}

        list.each do |prop|
          style = nil
          attr  = nil
          begin
            style = element.style(prop)
            if style
              case prop
                when /color/i
                  style = normalize_color_value(style)
                when 'border'
                  style = normalize_border_style(style)
                when 'background-image'
                  style = normalize_gradient_value(style)
              end
            end
          rescue
            debug_to_log(with_caller("Can't find style '#{prop}"))
          end
          begin
            attr = element.attribute_value(prop)
          rescue
            debug_to_log(with_caller("Can't find attribute '#{prop}"))
          end

          hash[prop] = style ? style : attr
        end

        # NOTE: tweaks to handle outliers, especially for initial and inherit
        if hash['outline-style'] == 'none' and hash['outline-width'] == '0px'
          if hash['outline-color'] == 'rgba(0, 0, 0, 1)'
            hash['outline-color'] = 'rgba(255, 255, 255, 1)'
            debug_to_log(with_caller(element, 'outline-color'))
          end
        end

        hash
      rescue
        failed_to_log(unable_to)
      end

      def escape_stuff(strg)
        if strg.nil?
          rslt = strg
        else
          if strg.respond_to?(:dup)
            rslt = strg.dup
            unless rslt.is_a?(Regexp)
              if rslt.match(/[\/\(\)]/)
                rslt.gsub!('/', '\/')
                rslt.gsub!('(', '\(')
                rslt.gsub!(')', '\)')
                rslt = Regexp.new(rslt)
              end
            end
          else
            rslt = strg
          end
        end
        rslt
      rescue
        failed_to_log(unable_to("#{rslt}"))
      end

      def element_query_message(element, query, how = nil, what = nil, value = nil, desc = '', refs = '', tag = '')
        who  = nil
        name = '(unknown)'
        if element.exists?
          # name = element.respond_to?(:tag_name) ? element.tag_name.upcase : element.to_s
          who, how, what = extract_locator(element)
          name           = who.to_s.upcase if who
        else
          if tag and tag.length > 0
            name = tag.upcase
          elsif who
            name = who.to_s.upcase
          end
        end
        build_message(desc, "#{name}",
                      (what ? "with #{how}=>'#{what}'" : nil),
                      (value ? "and value=>'#{value}'" : nil),
                      query, refs)
      rescue
        failed_to_log(unable_to)
      end

    end

    module Find

      def get_attribute_value(container, element, how, what, attribute, desc = '', refs = '')
        msg   = build_message(desc, "'#{attribute}' in :#{element.to_s.upcase} :#{how}='#{what}'.")
        code  = build_webdriver_fetch(element, how, what)
        value = eval("#{code}.attribute_value('#{attribute}')")
        if value
          passed_to_log(with_caller(msg, desc, refs))
          value
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_element_colors(element, colors = [], desc = '', refs = '')
        msg    = build_message(desc, "Get colors for #{element.tag_name.upcase}.", refs)

        colors = [
            'color', 'background-color', 'border-bottom-color', 'border-left-color', 'border-right-color',
            'border-top-color', 'border-color'
        ] unless colors.size > 0

        hash = {}
        colors.each do |color|
          hash[color] = normalize_color_value(element.style(color))
        end

        hash
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_element_attribute(element, attribute, desc = '', refs = '', how = '', what = nil)
        msg   = build_message(RDTL, desc, "Get '#{attribute}' for #{element.tag_name.upcase}", (":#{how}=>'#{what}'" if what), refs)
        value = element.attribute_value(attribute)
        if value
          passed_to_log(with_caller(msg))
        else
          failed_to_log(with_caller(msg))
        end
        value
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_selected_options(browser, how, what, desc = '', refs = '')
        msg      = build_message(desc, with_caller("in Select list #:#{how}=>#'#{what}'"), refs)
        selected = nil
        begin
          list = browser.select_list(how, what)
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(:select_list, how, what), "#{browser.class}")
            raise e
          end
        end
        if list
          selected = list.selected_options
          if selected and selected.length > 0
            passed_to_log(msg + " Found #{selected.length} selected options:" + " (first: value/text: #{selected[0].value}/#{selected[0].text})")
            selected
          else
            failed_to_log(msg + ' Found no selected options.')
          end
        else
          failed_to_log(with_caller(desc, "Select List #{how}=#{what} not found.", refs))
        end
        selected
      rescue
        failed_to_log(unable_to(msg))
      end

      def get_style(container, element, how, what, style, desc = '', refs = '')
        msg   = build_message(desc, "Get '#{style}' in :#{element.to_s.upcase} :#{how}='#{what}'.")
        code  = build_webdriver_fetch(element, how, what)
        value = eval("#{code}.style('#{style}')")
        if value
          passed_to_log(with_caller(msg, "value=>'#{value}'", desc, refs))
          value
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      alias get_style_value get_style

      def get_directory(path)
        if File.directory?(path)
          debug_to_log("Directory already exists, '#{path}'.") if @debug_dsl
        else
          Dir::mkdir(path)
          debug_to_log("Directory was created, '#{path}'.") if @debug_dsl
        end
        path
      end

      def get_element(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        msg                        = build_message(RDTL, desc, "Return #{element.to_s.upcase} with :#{how}='#{what}'", value, refs)
        timeout                    = options[:timeout] ? options[:timeout] : 30
        code                       = build_webdriver_fetch(element, how, what, options)
        code                       = "#{code}.when_present(#{timeout})" unless options[:exists_only] or container.to_s =~ /noko/i
        debug_to_log(with_caller("{#{code}")) if $mobile
        target = eval(code)
        if target and target.exists?
          # if options[:flash] and target.respond_to?(:flash)
          #   target.wd.location_once_scrolled_into_view
          #   target.flash
          # end
          if target.class =~ /element/i
            target = target.to_subtype
            msg.sub!(element.tag_name, target.tag_name)
          end
          passed_to_log(msg)
          target
        else
          failed_to_log(msg)
          nil
        end
      rescue => e
        unless rescue_me(e, __method__, rescue_me_command(target, how, what), "#{container.class}", target)
          failed_to_log(unable_to(msg))
          raise e
        end
      end

      def capture_value_desc(value, desc, refs, options = nil)
        opt = options.dup if options
        unless opt.kind_of?(Hash)
          opt = Hash.new
        end

        if value
          vlu = value.dup
        elsif opt[:value]
          vlu = opt[:value]
        end

        if desc
          dsc = desc.dup
        elsif opt[:desc]
          dsc = opt[:desc]
        end

        if refs
          rfs = refs.dup
        elsif opt[:refs]
          rfs = opt[:refs]
        end

        [vlu, dsc, rfs, opt]
      rescue
        failed_to_log(unable_to)
      end

      def ancestor_is_a?(descendant, tag_name, generation = 1, desc = '', refs = '')
        tag_name = 'a' if tag_name == 'link'
        msg      = build_message(RDTL, desc, "#{descendant.tag_name.upcase} with id '#{descendant.attribute_value('id')}' has", "tag: '#{tag_name}'", "#{generation} level above")
        ancestor = descendant.dup
        count    = 0
        while count < generation
          ancestor = ancestor.parent
          count    += 1
        end
        if ancestor.respond_to?(:tag_name) and ancestor.tag_name.downcase == tag_name.downcase
          passed_to_log(with_caller(msg, desc, refs))
          true
        else
          failed_to_log(with_caller(msg, desc, refs))
        end
      rescue
        failed_to_log(unable_to(RDTL), false, true)
      end

      def scroll_to_page_top(browser, desc = '', refs = '')
        send_a_key(browser, :home, :control, with_caller(desc), refs)
      end

      def scroll_to_page_bottom(browser, desc = '', refs = '')
        send_a_key(browser, :end, :control, with_caller(desc), refs)
      end

      def gather_ancestors(descendant, targets = [], dbg = @debug_dsl)
        hash       = nil
        ancestor   = descendant
        generation = 0
        hit_count  = 0
        hits       = {}
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{descendant.attribute_value('id')}'") if dbg

        until ancestor.tag_name =~ /html/i do
          ancestor = ancestor.parent
          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{descendant.attribute_value('id')}'") if dbg
          generation -= 1
          type       = ancestor.respond_to?(:type) ? ancestor.type : ''
          hash       = Hash.new unless hash
          class_name = ancestor.class_name
          hit_on     = []
          targets.each do |tgt|
            if class_name =~ /#{tgt}/i
              hit_count += 1
              hit_on << tgt
              hits[tgt] ? hits[tgt] += 1 : hits[tgt] = 1
            end
          end
          hash[generation] = { :id         => ancestor.attribute_value('id'),
                               :class_name => class_name,
                               :tag        => ancestor.tag_name,
                               :type       => type,
                               :hit_on     => hit_on
          }
        end

        [hash, hit_count, hits]
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def get_ancestor(descendant, element, how, what, desc = '', refs = '', dbg = @debug_dsl)
        found = false
        how   = 'class_name' if how.to_s == 'class'
        tag   = element.to_s.downcase
        debug_to_log("target: #{descendant.to_s.upcase} :id=>#{descendant.attribute_value('id')}") if dbg
        debug_to_log("goal:   #{tag.upcase} :#{how}='#{what}' #{desc}") if dbg
        ancestor = descendant.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' #{refs}") if dbg
        code = "ancestor.#{how}"
        what.is_a?(Regexp) ? code << " =~ /#{what.source}/" : code << " == '#{what}'"
        debug_to_log("#{code}") if dbg
        until found do
          break unless ancestor
          break if ancestor.tag_name =~ /html/i
          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{ancestor.attribute_value('id')}' #{refs}") if dbg
          if ancestor.tag_name == tag
            if eval(code)
              found = true
              break
            end
          end
          ancestor = ancestor.parent
        end
        msg = build_message(
            with_caller(RDTL, desc),
            "- Descendant is #{descendant.tag_name.upcase} :id=>#{descendant.attribute_value('id')}.",
            "Find ancestor #{tag.upcase} :#{how}='#{what}'."
        )
        if found
          passed_to_log(msg)
          ancestor
        else
          failed_to_log(msg)
          nil
        end

      rescue
        failed_to_log(unable_to)
      end

      def get_ancestor2(descendant, element, how, what, desc = '', dbg = @debug_dsl)
        elements = Array.new
        if element.is_a?(Array)
          element.each do |e|
            elements << e.to_s.downcase
          end
        else
          elements[0] = element.tag_name.downcase
        end
        found = false
        how   = 'class_name' if how.to_s == 'class'
        debug_to_log("target: #{descendant.tag_name} :id=>'#{descendant.attribute_value('id')}'") if dbg
        debug_to_log("goal:   #{nice_array(elements)} :#{how}='#{what}'   #{desc}") if dbg
        ancestor = descendant.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}'") if dbg
        code = "ancestor.#{how}"
        what.is_a?(Regexp) ? code << " =~ /#{what.source}/" : code << " == '#{what}'"
        debug_to_log("#{code}") if dbg

        until found do
          break unless ancestor
          if ancestor.tag_name =~ /html/i
            ancestor = nil
            break
          end

          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{ancestor.attribute_value('id')}'") if dbg
          if elements.include?(ancestor.tag_name.downcase)
            if eval(code)
              found = true
              break
            end
          end

          ancestor = ancestor.parent
        end

        [ancestor, (ancestor.tag_name.downcase if ancestor)]
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def get_ancestor3(descendant, elements = [:any], hows = [], whats = [], desc = '', dbg = @debug_dsl)
        fail 'Parameter \'elements\' must be an array.' unless elements.is_a?(Array)
        fail 'Parameter \'hows\' must be an array.' unless hows.is_a?(Array)
        fail 'Parameter \'whats\'  must be an array.' unless whats.is_a?(Array)
        fail 'Parameters \'hows\' and \'whats\'  must be the same length.' unless hows.length == whats.length

        found = false

        debug_to_log("target: #{descendant.tag_name} :id=>'#{descendant.attribute_value('id')}'") if dbg
        debug_to_log("goal:   #{element.tag_name.upcase} :#{how}='#{what}'   #{desc}") if dbg
        ancestor = descendant.parent
        debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}'") if dbg
        code == ''
        (0..hows.length).each do |idx|
          hows[idx] = 'class_name' if hows[idx].to_s == 'class'
          code      = "ancestor.#{how}"
          whats[idx].is_a?(Regexp) ? code << " =~ /#{whats[idx].source}/" : code << " == '#{whats[idx]}'"
          code << ' and ' if idx < hows.length
          debug_to_log("#{code}") if dbg
        end
        until found do
          break unless ancestor
          break if ancestor.tag_name =~ /html/i
          debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{descendant.attribute_value('id')}'") if dbg
          if elements.include?(ancestor.tag_name.downcase.to_sym)
            if eval(code)
              found = true
              break
            end
          end
          ancestor = ancestor.parent
        end
        [ancestor, ancestor.tag_name.downcase]
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def get_ancestor4(descendant, args = {})
        desc   = args[:desc] if args[:desc]
        errors = Array.new
        [:elements, :hows, :whats].each do |key|
          if args.keys.include?(key)
            unless args[key].is_a?(Array)
              args[key] = [args[key]]
            end
            eval("#{key.to_s} = args[#{key}]")
          else
            errors << "Parameter '#{key}' is required. "
          end
        end
        if hows and whats
          unless hows.length == whats.length
            errors << "Parameters 'hows' and 'whats' must be the same length. "
          end
        end
        if errors.length > 0
          failed_to_log("#{method_to_title(__method__)}: #{nice_array(errors)} #{desc}")
        else
          found    = false
          ancestor = descendant.parent
          code == ''
          (0..hows.length).each do |idx|
            hows[idx] = 'class_name' if hows[idx].to_s == 'class'
            code      = "ancestor.#{how}"
            whats[idx].is_a?(Regexp) ? code << " =~ /#{whats[idx].source}/" : code << " == '#{whats[idx]}'"
            code << ' and ' if idx < hows.length
            debug_to_log("#{code}") if @debug_dsl
          end
          until found do
            break unless ancestor
            debug_to_log("#{ancestor.tag_name}: :class=>'#{ancestor.class_name}' :id=>'#{descendant.attribute_value('id')}'") if @debug_dsl
            if elements.include?(ancestor.tag_name.downcase.to_sym)
              if eval(code)
                found = true
                break
              end
            end
            ancestor = ancestor.parent
          end
          [ancestor, ancestor.tag_name.downcase]
        end
      rescue
        failed_to_log(unable_to(RDTL))
      end

      def get_active_element(container)
        container.browser.execute_script('return document.activeElement')
      end

      alias find_element_with_focus get_active_element

      def identify_active_element(container, desc = '', refs = '', no_fail = false, parent = false)
        element        = get_active_element(container)
        element        = element.parent if parent
        tag, how, what = extract_locator(element, nil, with_caller(desc), refs)
        msg            = with_caller(RDTL, desc, "#{tag}:#{how}:#{what}'", "is parent?=>#{parent}", refs)
        if tag and how and what
          no_fail ? message_to_report(msg) : passed_to_log(msg)
          [element, tag, how, what]
        else
          no_fail ? message_to_report(msg) : failed_to_log(msg)
          nil
        end
      rescue
        failed_to_log(unable_to)
      end

      # def highlight_element(element)
      #   # not really different than .flash unless the two js scripts are separated by a sleep.
      #   # probably needs to make sure that original color and border can be restored.
      #   #public void highlightElement(WebDriver driver, WebElement element)
      #   # { for (int i = 0; i < 2; i++)
      #   # { JavascriptExecutor js = (JavascriptExecutor) driver;
      #   # js.executeScript("arguments[0].setAttribute('style', arguments[1]);", element, "color: yellow; border: 2px solid yellow;");
      #   # js.executeScript("arguments[0].setAttribute('style', arguments[1]);", element, "");
      #   # }
      #   # }
      #   # - See more at: http://selenium.polteq.com/en/highlight-elements-with-selenium-webdriver/#sthash.JShjPbsj.dpuf
      # end

      # ALM synch methods
      def alm_doc_to_hash(doc, entity_type, page_id, page_count, ptrn = nil, collection = 'entities')
        # beg = Time.now.to_f

        filtered       = ptrn ? true : false
        entity_count   = 0
        filtered_count = 0
        entity_hash    = { :alias => {}, :entities => {}, :ids => {}, :names => {} }

        alm_hash = Hash.from_xml(doc.to_s)

        if collection == 'entities'
          entity_hash    = { :alias => {}, :entities => {}, :ids => {}, :names => {} }
          entity_count   = alm_hash['Entities']['TotalResults'].to_i
          filtered_count = 0

          case
            when entity_count == 1
              entity = alm_hash['Entities']['Entity']
              if entity['Type'].downcase == entity_type.downcase
                filtered_count, take_it = capture_entity(entity, entity_hash, entity_type, filtered_count, page_id, ptrn)
                entity_count            -= 1 unless take_it
              end
            when entity_count > 1
              if ptrn
                alm_hash['Entities']['Entity'].each do |item|
                  if item['Type'].downcase == entity_type.downcase
                    filtered_count, take_it = capture_entity(item, entity_hash, entity_type, filtered_count, page_id, ptrn)
                    entity_count            -= 1 unless take_it
                  end
                end

              else
                alm_hash['Entities']['Entity'].each do |item|
                  if item['Type'].downcase == entity_type.downcase
                    filtered_count, take_it = capture_entity(item, entity_hash, entity_type, filtered_count, page_id, ptrn)
                    entity_count            -= 1 unless take_it
                  end
                end
              end
            else
              debug_to_log(with_caller('Entity collection is empty'))
          end
          debug_to_log(with_caller("entity: #{entity_type},", "entity count: #{entity_count},",
                                   "captured count: #{entity_hash[:entities].length}",
                                   "filtered count: #{filtered_count}",
                                   "pattern: [#{ptrn}]", "rest page #{page_count}"))
        else
          case collection
            when 'lists', 'fields'
              entity_hash  = alm_hash
              entity_count = filtered_count = entity_hash.first.second.first.second.length
            when 'entity'
              entity_count            = 1
              entity_hash             = { :alias => {}, :entities => {}, :ids => {}, :names => {} }
              filtered_count, take_it = capture_entity(alm_hash['Entity'], entity_hash, entity_type, filtered_count, page_id, ptrn)
            else
              debug_to_log(with_caller("Unknown collection type: '#{collection}'"))
          end
        end

        [entity_hash, entity_count, filtered_count, filtered]

      rescue
        failed_to_log(unable_to('*** waft014 ***'))
        # ensure
        #   debug_to_log(with_caller("Elapsed: #{Time.now.to_f - beg}"))
      end

      def capture_entity(entity, entity_hash, entity_type, filtered_count, page_id, ptrn)
        take_it, id, name, fields, aliases = capture_alm_fields(entity, page_id, entity_hash, ptrn)

        if take_it
          entity_hash[:alias] = aliases unless entity_hash[:alias]

          if name
            entity_hash[:names][id]          = name
            name_key                         = to_valid_symbol(name)
            entity_hash[:ids][name_key]      = id
            entity_hash[:entities][name_key] = fields
          else
            entity_hash[:entities][id] = fields
          end

          filtered_count += 1
          debug_to_log(with_caller("Taking entity #{entity_type}:#{id}:#{name}")) if $waft_debug
        end

        [filtered_count, take_it]
      end

      def capture_alm_fields(entity, page_id, entity_hash, ptrn = nil)
        id      = nil
        name    = nil
        take_it = true
        fields  = {}
        aliases = {}

        entity['Fields']['Field'].each do |field|
          field_symb          = to_valid_symbol(field['Name'])
          aliases[field_symb] = field['Name'] unless aliases[field_symb]
          name                = field['Value'] if field_symb == :name
          id                  = field['Value'] if field_symb == :id
          fields[field_symb]  = field['Value']
        end

        if page_id
          unless fields[:parent_id] == page_id or fields[:cycle_id] == page_id
            take_it = false
          end
        end

        if take_it
          case ptrn.class.to_s
            when 'Regexp'
              take_it = false unless name =~ ptrn
            when 'Array'
              take_it = false unless ptrn.include?(id.to_s)
            when 'String'
              take_it = false unless ptrn.strip =~ /^#{name}$|^#{id}$/
            when 'Fixnum'
              take_it = false unless ptrn == id
            when 'NilClass'
              take_it = true
            else
              debug_to_log(with_caller("Unexpected pattern type: #{ptrn.inspect}"))
          end

        else
          debug_to_log(with_caller("Parent id '#{fields[:parent_id]}' does not match Page id '#{page_id}'"))
        end

        [take_it, id, name, fields, aliases]

      rescue
        failed_to_log(unable_to('*** waft014 ***'))
      end

      def id_list_from_collection(input_arr, collection, as_array = false)

        output_arr = []
        if input_arr.empty?
          collection[:ids].each_key { |key| output_arr << collection[:ids][key] }
        else
          input_arr.each do |tgt|
            if tgt =~ /^\d+$/
              output_arr << tgt.to_i
            elsif tgt.match(/^(\w\w?)-?/i)
              page = $1
              collection[:ids].each_key do |key|
                if key =~ /^#{page}_/i
                  output_arr << collection[:ids][key].to_i
                  break
                end
              end
            else
              output_arr << collection[:ids][to_valid_symbol(tgt)].to_i
            end
          end
        end

        if as_array
          output_arr.sort!
        else
          array_to_list(output_arr.sort, ',', false)
        end
      rescue
        failed_to_log(unable_to('*** waft014 ***'))
      end

      def build_alm_acro_lookup
        hash = {}
        @wf2_components.each do |key, comp|
          hash[comp[:alm_acro]] = key
        end
        hash
      end

      def define_alm_queries
        @queries = {
            :tc_master_folder      => { :query  => 'test-folders?query={name[WRIA2_Master_Suite]}',
                                        :entity => 'test-folder', :field => 'name', :collection => 'entities' },

            :tc_component_folders  => { :query  => 'test-folders?query={parent-id[IIIII]}',
                                        :entity => 'test-folder', :field => 'parent-id', :collection => 'entities' },

            :tc_component          => { :query  => 'test-folders?query={name[NNNNN]}',
                                        :entity => 'test-folder', :field => 'name', :collection => 'entities' },

            :tc_page_folders       => { :query  => 'test-folders?query={parent-id[IIIII]}',
                                        :entity => 'test-folder', :field => 'parent-id', :collection => 'entities' },

            :tc_cases_in_page      => { :query  => "tests?query={parent-id[IIIII]}&page-size=#{@page_size}&start-index=#####",
                                        :entity => 'test', :field => 'parent-id', :collection => 'entities' },

            :tc_cases_by_name      => { :query  => "tests?query={name[NNNNN]}&page-size=#{@page_size}&start-index=#####",
                                        :entity => 'test', :field => 'name', :collection => 'entities' },
            :tc_cases_by_type      => { :query  => "tests?query={subtype_id[NNNNN]}&page-size=#{@page_size}&start-index=#####",
                                        :entity => 'test', :field => 'name', :collection => 'entities' },

            :test_configs          => { :query  => 'test-configs?query={parent-id[IIIII]}',
                                        :entity => 'test-config', :field => 'parent-id', :collection => 'entities' },

            :component_test_defs   => { :query  => 'tests?query={name[NNNNN_A_01*]}',
                                        :entity => 'test', :field => 'name', :collection => 'entities' },

            :component_test_cases  => { :query  => 'tests?query={name[NNNNN*]}',
                                        :entity => 'test', :field => 'name', :collection => 'entities' },

            :set_master_folder     => { :query  => "test-set-folders?query={name[#{@target_options[:set_root]}]}",
                                        :entity => 'test-set-folder', :field => 'name', :collection => 'entities' },
            :set_component_folders => { :query  => 'test-set-folders?query={parent-id[IIIII]}',
                                        :entity => 'test-set-folder', :field => 'parent-id', :collection => 'entities' },
            :set_page_folders      => { :query  => 'test-set-folders?query={parent-id[IIIII]}',
                                        :entity => 'test-set-folder', :field => 'parent-id', :collection => 'entities' },
            :sets                  => { :query  => 'test-sets?query={parent-id[IIIII]}',
                                        :entity => 'test-set', :field => 'parent-id', :collection => 'entities' },
            :sets_by_id            => { :query  => 'test-sets?query={id[IIIII]}',
                                        :entity => 'test-set', :field => 'parent-id', :collection => 'entities' },
            :test_instances        => { :query  => "test-instances?query={cycle-id[IIIII]}&page-size=#{@page_size}&start-index=#####",
                                        :entity => 'test-instance', :field => 'cycle_id', :collection => 'entities' },

            :template_runs         => { :query  => "runs?query={name[WRIA2*]}&page-size=#{@page_size}&start-index=#####",
                                        :entity => 'run', :field => 'name', :collection => 'entities' },
            :template_runs_cmpnt   => { :query  => "runs?query={name[\"WRIA2 Template NNNNN*\"]}&page-size=#{@page_size}&start-index=#####",
                                        :entity => 'run', :field => 'name', :collection => 'entities' },


            :releases              => { :query  => 'releases',
                                        :entity => 'release', :ptrn => /^\d\.\d+\.\d$/, :collection => 'entities' },
            :cycles                => { :query  => 'release-cycles?query={parent-id[IIIII]}',
                                        :entity => 'release-cycle', :field => 'parent-id', :collection => 'entities' },

            :test_fields           => { :query  => 'customization/entities/test/fields',
                                        :entity => 'test', :collection => 'fields' },
            :config_fields         => { :query  => 'customization/entities/test-config/fields',
                                        :entity => 'test-config', :collection => 'fields' },
            :set_fields            => { :query  => 'customization/entities/test-set/fields',
                                        :entity => 'test-set', :collection => 'fields' },
            :set_folder_fields     => { :query  => 'customization/entities/test-set-folder/fields',
                                        :entity => 'test-set-folder', :collection => 'fields' },
            :instance_fields       => { :query  => 'customization/entities/test-instance/fields',
                                        :entity => 'test-instance', :collection => 'fields' },
            :run_fields            => { :query  => 'customization/entities/run/fields',
                                        :entity => 'run', :collection => 'fields' },
            :test_lists            => { :query  => 'customization/entities/test/lists',
                                        :entity => 'test', :collection => 'lists' },
            :config_lists          => { :query  => 'customization/entities/test-config/lists',
                                        :entity => 'test-config', :collection => 'lists' },
            :set_lists             => { :query  => 'customization/entities/test-set/lists',
                                        :entity => 'test-set', :collection => 'lists' },
            :instance_lists        => { :query  => 'customization/entities/test-instance/lists',
                                        :entity => 'test-instance', :collection => 'lists' },
            :run_lists             => { :query  => 'customization/entities/run/lists',
                                        :entity => 'run', :collection => 'lists' },
            :checkout_test         => { :query  => 'tests/4403/versions/check-out',
                                        :entity => 'test', :collection => 'tests' }
        }
      end

    end

    module Validations

      include W3CValidators

      def meets_wcag_contrast_standard?(color1, color2, font_size, font_weight, desc = '', refs = '')
        ratio = contrast_ratio(color1, color2)
        if font_weight =~ /bold/i
          standard = font_size >= 14.0 ? 3 : 4.5
        else
          standard = font_size >= 18.0 ? 3 : 4.5
        end
        msg = with_caller(desc, "colors: #{color1}, #{color2}", "font: #{font_size}pt #{font_weight}",
                          "wcag minimum: #{standard}", "actual: #{sprintf('%.1f', ratio)}", refs)
        if ratio >= standard
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
          false
        end
      rescue
        failed_to_log(unable_to('verify that'))
      end

      def focused_element_in_locators(container, locators, desc = '', refs = '')
        focused = get_active_element(container)
        if focused
          focus_locator, found, index, longest = locator_in_array(focused, locators, desc, refs)
          if focus_locator.length > longest
            focus_locator = "#{focus_locator.slice(0, (longest + 15))}..."
          end
          msg = build_msg("Focused element locator (#{focus_locator})",
                          ("(#{focused.text})" if focused.respond_to?(:text) and focused.text),
                          'is found in locators array', refs)
          if found
            passed_to_log("#{msg} at index #{index}.")
            true
          else
            failed_to_log(msg)
            false
          end
        else
          failed_to_log("Cannot locate focused element in DOM (#{focused})")
          false
        end
        focused
      rescue
        failed_to_log(unable_to('verify that'))
      end

      def locator_in_array(focused, locators, desc = '', refs = '')
        found         = false
        focus_locator = nil
        index         = 0
        longest       = 0
        locators.each do |loc|
          who, how, what = parse_locator(loc)
          focus_locator  = format_locator(extract_locator(focused, how, with_caller(desc), refs))
          target_locator = format_locator(who, how, what)

          if focus_locator == target_locator
            found = true
            break
          end
          longest = loc.length > longest ? loc.length : longest
          index   += 1
        end
        [focus_locator, found, index, longest]
      rescue
        failed_to_log(unable_to('verify that'))
      end

      def focused_element_not_in_locators(container, locators, desc = '', refs = '')
        focused = get_active_element(container)
        if focused
          focus_locator, found, index, longest = locator_in_array(focused, locators, desc, refs)
          if focus_locator.length > longest
            focus_locator = "#{focus_locator.slice(0, (longest + 15))}..."
          end
          msg = build_msg("Focused element locator (#{focus_locator})",
                          "is not found in locators array (#{locators}", refs)
          if found
            failed_to_log("#{msg} Found at index #{index}.")
            false
          else
            passed_to_log(msg)
            true
          end
        else
          passed_to_log("Cannot locate focused element in DOM (#{focused})")
          true
        end
      rescue
        failed_to_log(unable_to('verify that'))
      end

      def is_true?(actual, message, desc = '', refs = '')
        msg = build_message(desc, "Is '#{message}' true?", refs)
        if actual
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      end

      def is_false?(actual, message, desc = '', refs = '')
        msg = build_message(desc, "Is '#{message}' false?", refs)
        if actual
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      end

      def verify_months(list, language = 'English', abbrev = 0, desc = '', refs = '')
        msg         = build_message(desc, "List of xxxx months in #{language} is correct and in order.")
        list        = [nil].concat(list)
        month_names = get_months(language, abbrev)
        if abbrev > 0
          msg.gsub!('xxxx', "#{nbr2wd(abbrev)} character")
        else
          msg.gsub!('xxxx', 'fully spelled')
        end
        if list == month_names
          passed_to_log(with_caller(msg, refs))
          true
        else
          failed_to_log(with_caller(msg, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def verify_days(list, language = 'English', abbrev = 0, offset = 0, desc = '', refs = '')
        #TODO: Handle different starting day: rotate_array(arr, target, index = 0, stop = 0)
        msg       = build_message(desc, "List of xxxx weekdays in #{language} is correct and in order.")
        day_names = get_days(language, abbrev)
        day_names = rotate_array(day_names, offset) if offset > 0
        if abbrev > 0
          msg.gsub!('xxxx', "#{nbr2wd(abbrev)} character")
        else
          msg.gsub!('xxxx', 'fully spelled')
        end
        if list == day_names
          passed_to_log(with_caller(msg, refs))
          true
        else
          failed_to_log(with_caller(msg, refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def greater_than?(actual, expected, desc = '', refs = '', act = nil, exp = nil)
        act_name = act ? act : 'Actual'
        exp_name = exp ? exp : 'expected'
        msg      = build_message(desc, "#{act_name} '#{actual}' greater than #{exp_name} '#{expected}'.", refs)
        if actual > expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def greater_than_or_equal_to?(actual, expected, desc = '', refs = '', act = nil, exp = nil)
        act_name = act ? act : 'Actual'
        exp_name = exp ? exp : 'expected'
        msg      = build_message(desc, "#{act_name} '#{actual}' greater than or equal to #{exp_name} '#{expected}'.", refs)
        if actual >= expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias greater_than_or_equal? greater_than_or_equal_to?
      alias greater_or_equal? greater_than_or_equal_to?
      alias count_greater_or_equal? greater_than_or_equal_to?

      def less_than?(actual, expected, desc = '', refs = '', act = nil, exp = nil)
        act_name = act ? act : 'Actual'
        exp_name = exp ? exp : 'expected'
        msg      = build_message(desc, "#{act_name} '#{actual}' less than #{exp_name} '#{expected}'.", refs)
        if actual < expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def less_than_or_equal_to?(actual, expected, desc = '', refs = '', act = nil, exp = nil)
        act_name = act ? act : 'Actual'
        exp_name = exp ? exp : 'expected'
        msg      = build_message(desc, "#{act_name} '#{actual}' less than or equal to #{exp_name} '#{expected}'.", refs)
        if actual <= expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias count_less_or_equal? less_than_or_equal_to?
      alias less_than_or_equal? less_than_or_equal_to?
      alias less_or_equal? less_than_or_equal_to?

      def number_equals?(actual, expected, desc = '', refs = '', act = nil, exp = nil)
        act_name = act ? act : 'Actual'
        exp_name = exp ? exp : 'expected'
        msg      = build_message(desc, "#{act_name} '#{actual}' equals #{exp_name} '#{expected}'.", refs)
        if actual == expected
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias count_equals? number_equals?

      def number_does_not_equal?(actual, expected, desc = '', refs = '', act = nil, exp = nil)
        act_name = act ? act : 'Actual'
        exp_name = exp ? exp : 'expected'
        msg      = build_message(desc, "#{act_name} '#{actual}' does not equal #{exp_name} '#{expected}'.", refs)
        if actual == expected
          failed_to_log("#{msg}")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias count_does_not_equal? number_does_not_equal?

      def within_range?(actual, min, max)
        (min..max).include?(actual)
      rescue
        failed_to_log(unable_to, false, true)
      end

      alias number_within_range? within_range?
      alias count_within_range? within_range?

      def within_target_range?(actual, target, low, high = nil)
        if high
          ((target - low)..(target + high)).include?(actual)
        else
          ((target - low)..(target + low)).include?(actual)
        end
      rescue
        failed_to_log(unable_to, false, true)
      end

      alias number_within_target_range? within_target_range?
      alias count_within_target_range? within_target_range?

      def within_tolerance?(actual, expected, tolerance, desc = '', refs = '')
        min = expected - tolerance
        max = expected + tolerance
        msg = build_message(desc, "#{actual} is between #{min} and #{max}.", refs)
        if min <= actual and max >= actual
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias number_within_tolerance? within_tolerance?
      alias count_within_tolerance? within_tolerance?

      def dimensions_equal?(first_name, first_value, second_name, second_value, desc = '', refs = '')
        msg = build_message(desc, "#{first_name}: #{first_value} equals #{second_name}: #{second_value}.", refs)
        if first_value == second_value
          passed_to_log("#{msg}")
          true
        else
          failed_to_log("#{msg}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def dimensions_not_equal?(first_name, first_value, second_name, second_value, desc = '', refs = '')
        msg = build_message(desc, "#{first_name}: #{first_value} does not equal #{second_name}: #{second_value}.", refs)
        if first_value == second_value
          failed_to_log("#{msg}")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def dimension_within_tolerance?(name, actual, expected, tolerance, desc = '', refs = '')
        within_tolerance?(actual, expected, tolerance, with_caller("#{desc}, Dimension", name), refs = '')
      end

      # def centered_horizontally?(container, element, desc = '', refs = '', tolerance = 2)
      #   c_tag, c_how, c_what = extract_locator(container, nil, with_caller(desc), refs)
      #   e_tag, e_how, e_what = extract_locator(element, nil, with_caller(desc), refs)
      #   msg                  = build_message(with_caller(desc), format_locator(e_tag, e_how, e_what),
      #                                        'centered horizontally in', format_locator(c_tag, c_how, c_what), refs)
      #
      # end

      # def centered?(container, element, desc = '', refs = '')
      #   name                      = element.respond_to?(:tag_name) ? element.tag_name.upcase : 'DOM'
      #   msg                       = build_message(desc, "is centered @@@.", refs)
      #
      #   element_x, element_y      = element.dimensions
      #   element_left, element_top = element.client_offset
      #
      #   horizontally = (((element_left * 2) + element_x.floor).to_i) == viewport_x
      #   h_msg        = msg.sub('@@@', 'horizontally')
      #   if horizontally
      #     passed_to_log(h_msg)
      #   else
      #     failed_to_log(h_msg)
      #   end
      #
      #   # At <= 600BP, should be full size of viewport
      #   vertically = true
      #   unless element_top <= 1 || element_x <= 601
      #     vertically = ((element_top * 2) + element_y) == viewport_y
      #     v_msg      = msg.sub('@@@', 'vertically')
      #
      #     if vertically
      #       passed_to_log(v_msg)
      #     else
      #       failed_to_log(v_msg)
      #     end
      #   end
      #
      #   if horizontally and vertically
      #     true
      #   else
      #     false
      #   end
      #
      # rescue
      #   failed_to_log(unable_to(msg.sub('@@@ ', ''), false, true))
      # end
      #
      def class_equals?(container, element, how, what, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_class_equals?(target, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      def element_class_equals?(container, element, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, ":class equals '#{expected}'.", how, what, nil, desc, refs)
        element_wait(element)
        if element.class_name == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}. Found '#{element.class_name}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def class_does_not_contain?(container, element, how, what, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_class_does_not_contain?(target, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      def element_class_does_not_contain?(element, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, ":class does not contain '#{expected}'.", how, what, nil, desc, refs)
        element_wait(element)
        if element.class_name.match(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def class_contains?(container, element, how, what, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_class_contains?(target, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      alias verify_class class_contains?

      def element_class_contains?(element, expected, desc = '', refs = '', how = nil, what = nil)
        msg        = element_query_message(element, ":class contains '#{expected}'.", how, what, nil, desc, refs)
        class_name = element.class_name
        if class_name.match(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}. Found '#{class_name}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias verify_class class_contains?

      def columns_match?(exp, act, dir, col, org = nil, desc = '', refs = '')
        msg = build_message(desc, "Click on #{dir} column '#{col}' produces expected sorted list.", refs)
        ok  = arrays_match?(exp, act, msg)
        unless ok
          debug_to_log("Original order ['#{org.join("', '")}']") if org
          debug_to_log("Expected order ['#{exp.join("', '")}']")
          debug_to_log("  Actual order ['#{act.join("', '")}']")
        end
        ok
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def hashes_match?(exp, act, desc = '', refs = '')
        msg = build_message(desc, 'Hashes match?', refs)
        if exp == act
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def array_includes?(array, expected, desc = '', refs = '')
        msg = build_message(desc, "Array includes '#{expected}'.", refs)
        if array.include?(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def array_does_not_include?(array, expected, desc = '', refs = '')
        msg = build_message(desc, "Array does not include '#{expected}'.", refs)
        if array.include?(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def arrays_match?(exp, act, desc = '', refs = '')
        msg = build_message(desc, 'Arrays match?', refs)
        exp = exp.is_a?(Array) ? exp.dup : [exp]
        act = act.is_a?(Array) ? act.dup : [act]
        if exp == act
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias arrays_match arrays_match?

      def attribute_contains?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", ";#{attribute}", "contains '#{expected}'.", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual.match(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_does_not_contain?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{attribute}", "does not contain '#{expected}'.", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual.match(expected)
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_equals?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{attribute}", "equals '#{expected}'.", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual == expected
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_does_not_equal?(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{attribute}", "does not equal '#{expected}.", refs)
        actual = container.element(how, what).attribute_value(attribute)
        if actual
          if actual == expected
            failed_to_log(msg)
          else
            passed_to_log("#{msg} Found '#{actual}'")
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def checked?(container, element, how, what, value = nil, desc = '', refs = '')
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_checked?(target, desc, refs, how, what, value)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias checkbox_checked? checked?
      alias checkbox_set? checked?

      def element_checked?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, "is checked.", how, what, value, desc, refs)
        if element.checked?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_checked?(container, how, what, value = nil, desc = '', refs = '')
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_checked?(target, desc, refs, how, what, value)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias checkbox_not_checked? not_checked?
      alias checkbox_not_set? not_checked?

      def element_not_checked?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, "is not checked.", how, what, value, desc, refs)
        if element.checked?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def checkbox_has_checked?(checkbox, desc = '', refs = '')
        msg  = element_query_message(checkbox, "has 'checked' attribute", nil, nil, nil, desc, refs)
        html = checkbox.html
        if html =~ /checked/ and not html =~ /checked=""/
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def checkbox_does_not_have_checked?(checkbox, desc = '', refs = '')
        msg  = element_query_message(checkbox, "does not have 'checked' attribute", nil, nil, nil, desc, refs)
        html = checkbox.html
        if html =~ /checked=""/ or not html =~ /checked/
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_in_html?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_in_html?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_in_html?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' exists in html.", how, what, nil, desc, refs)
        # element_wait(element)
        ptrn = /#{attribute}(?:\s|>|=|$)/
        debug_to_log(with_caller("[#{element.html}]::", "[#{ptrn}")) if @debug_dsl
        if element.html =~ ptrn
          attr_vlu = element.attribute_value(attribute)
          passed_to_log("#{msg} Value = '#{attr_vlu}'")
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_not_in_html?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_not_in_html?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_not_in_html?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' does not exist in html.", how, what, nil, desc, refs)
        ptrn = /#{attribute}(?:\s|>|=|$)/
        debug_to_log(with_caller("[#{element.html}]::", "[#{ptrn}")) if @debug_dsl
        if element.html =~ ptrn
          attr_vlu = element.attribute_value(attribute)
          failed_to_log("#{msg} Value = '#{attr_vlu}'")
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_exists?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_exists?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_exists?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' exists.", how, what, nil, desc, refs)
        # element_wait(element)
        ptrn = /(?:<|\s)#{attribute}(?:\s|>|=|$)/
        if element.html =~ ptrn
          value = element.attribute_value(attribute)
          passed_to_log("#{msg} '#{attribute}' found with value '#{value}'.")
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def attribute_does_not_exist?(container, how, what, attribute, desc = '', refs = '')
        target = container.element(how, what)
        element_attribute_does_not_exist?(target, attribute, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_does_not_exist?(element, attribute, desc = '', refs = '', how = nil, what = nil)
        msg  = element_query_message(element, "attribute '#{attribute}' does not exist.", how, what, nil, desc, refs)
        # element_wait(element)
        ptrn = /(?:<|\s)#{attribute}(?:\s|>|=|$)/
        if element.html =~ ptrn
          value = element.attribute_value(attribute)
          failed_to_log("#{msg} '#{attribute}' found with value '#{value}'.")
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_inline_attribute_contains?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg          = element_query_message(element, "Inline attribute '#{attribute}' contains '#{force_string(expected)}'.", how, what, nil, desc, refs)
        element_html = element.html
        if element_html.include? attribute
          inline_attr = "#{attribute}" + '=' + '"' + "#{expected}" + '"'
          puts inline_attr
          if element_html.include? inline_attr
            pass_to_log(msg)
          else
            fail_to_log(msg)
          end
        end
      end

      # def element_inline_attribute_equals?(element, attribute, expected, desc = '', refs = '')
      #   element_html = element.html
      #   if element_html.include? attribute
      #     inline_attr = "#{attribute}" + '=' + '"' + "#{value}" + '"'
      #     puts inline_attr
      #     if element_html.include? inline_attr
      #       pass_to_log("#{attribute} has the expected value of #{value}")
      #     else
      #       fail_to_log("#{attribute} missing the expected value of #{value} ")
      #     end
      #   end
      # end

      def element_attribute_equals?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg    = element_query_message(element, "attribute '#{attribute}' equals '#{force_string(expected)}'.", how, what, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual == expected
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_does_not_equal?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg    = element_query_message(element, "attribute '#{attribute}' does not equal '#{force_string(expected)}'.", how, what, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual == expected
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias element_attribute_not_equal? element_attribute_does_not_equal?

      def element_attribute_contains?(element, attribute, expected, desc = '', refs = '', how = nil, what = nil)
        msg    = element_query_message(element, "attribute '#{attribute}' contains '#{force_string(expected)}'.", how, what, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual.match(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def element_attribute_does_not_contain?(element, attribute, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attribute}' does not contain '#{force_string(expected)}'.", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attribute)
        if actual
          if actual.match(expected)
            msg << " Found '#{actual.match(expected)[1]}'"
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def element_attribute_greater?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' greater than '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i > expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_less?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' less than '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i < expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_greater_or_equal?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' greater than or equal to '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i >= expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_attribute_less_or_equal?(element, attr_name, expected, desc = '', refs = '')
        msg    = element_query_message(element, "attribute '#{attr_name}' less than or equal to '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.attribute_value(attr_name)
        if actual
          if actual.to_i <= expected.to_i
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_value_equals?(element, expected, desc = '', refs = '')
        msg = element_query_message(element, "value equals '#{expected}'.", nil, nil, nil, desc, refs)

        if element.responds_to?('value')
          actual = element.value
          if actual
            if actual == expected
              passed_to_log(msg)
              true
            else
              failed_to_log(msg)
            end
          else
            failed_to_log("#{msg} 'value' not found.")
          end
        else
          failed_to_log("#{msg} Element does not respond to 'value'")
        end

      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_text_equals?(element, expected, desc = '', refs = '', how = nil, what = nil)
        msg    = element_query_message(element, "text equals '#{expected}'.", how, what, nil, desc, refs)
        actual = element.text
        if actual
          if actual == expected
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{actual}'")
          end
        else
          failed_to_log("#{msg} element text not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_text_does_not_equal?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text does not '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual == expected
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} 'text' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_text_includes?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text includes '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual.include?(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log("#{msg} 'text' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias element_includes_text? element_text_includes?

      def element_text_does_not_include?(element, expected, desc = '', refs = '')
        msg    = element_query_message(element, "text does not include '#{expected}'.", nil, nil, nil, desc, refs)
        actual = element.text
        if actual
          if actual.include?(expected)
            failed_to_log(msg)
          else
            passed_to_log(msg)
            true
          end
        else
          failed_to_log("#{msg} '#{attribute}' not found.")
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias element_does_not_include_text? element_text_does_not_include?

      def element_wait(element, sleep = 0.25)
        if element.respond_to?(:wait)
          element.wait
        elsif element.respond_to?(:wait_until_present)
          element.wait_until_present
        else
          sleep(sleep)
        end
      end

      def contains_text?(container, element, how, what, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}' contains '#{expected}'.", refs)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        if target
          element_wait(target)
          if target.text.match(expected)
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg} Found '#{text}'. #{desc}")
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def does_not_contain_text?(container, element, how, what, expected, desc = '', refs = '')
        msg    = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}' does not contain '#{expected}'.", refs)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        if target
          element_wait(target)
          if target.text.match(expected)
            failed_to_log("#{msg} Found '#{text}'. #{desc}")
          else
            passed_to_log(msg)
            true
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def element_contains_text?(element, expected, desc = '', refs = '', how = '', what = '', skip_fail = false)
        msg = element_query_message(element, "text contains '#{expected}'.", how, what, nil, desc, refs)
        element_wait(element)
        if element.text.match(expected)
          passed_to_log(msg)
          true
        else
          if skip_fail
            debug_to_log(build_msg(msg, '(Fail suppressed)'))
          else
            failed_to_log("#{msg} Found '#{element.text}'")
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_text_contains? element_contains_text?

      def element_does_not_contain_text?(element, expected, desc = '', refs = '', how = '', what = '')
        msg = element_query_message(element, "text does not contain '#{expected}'.", how, what, nil, desc, refs)
        element_wait(element)
        if element.text.match(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_text_does_not_contain? element_does_not_contain_text?

      def directory_exists?(directory)
        File.directory?(directory)
      end

      def html_contains?(strg, target, desc = '', refs = '', side = 'right')
        msg = build_message(desc, "HTML '#{truncate_string(strg, side).gsub(/<>/, '%')}'", " contains '#{truncate_string(target)}'.", refs)
        if strg.match(target)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      end

      def string_contains?(strg, target, desc = '', refs = '', side = 'right', trunc = 30)
        msg = build_message(desc, "String '#{truncate_string(strg, side, trunc)}'",
                            "contains '#{truncate_string(target, side, trunc)}'.", refs)
        if strg.match(target)
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      end

      alias validate_string string_contains?
      alias validate_string_contains string_contains?

      def string_does_not_contain?(strg, target, desc = '', refs = '', side = 'right', trunc = 30)
        msg = build_message(desc, "String '#{truncate_string(strg, side, trunc)}'",
                            "does not contain '#{truncate_string(target, side, trunc)}'.", refs)
        if strg.match(target)
          failed_to_log(msg)
          true
        else
          passed_to_log(msg)
        end
      end

      def boolean_equals?(actual, expected, desc = '', refs = '')
        msg = build_message(desc, "Boolean '#{actual}' equals expected '#{expected}'.", refs)
        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      # def string_contains?(strg, target, desc = '', refs = '')
      #   msg = build_message("String '#{strg}' contains '#{target}'.", desc, refs)
      #   if strg.match(target)
      #     passed_to_log(msg)
      #     true
      #   else
      #     failed_to_log(msg)
      #   end
      # end

      def string_equals?(actual, expected, desc = '', refs = '', side = 'right', trunc = 30)
        msg = build_message(desc, "String '#{truncate_string(actual, side, trunc)}'",
                            "equals expected '#{truncate_string(expected, side, trunc)}'.", refs)
        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg, refs)
      end

      def string_does_not_equal?(actual, expected, desc = '', refs = '', side = 'right', trunc = 30)
        msg = build_message(desc, "String '#{truncate_string(actual, side, trunc)}'",
                            "does not equal expected '#{truncate_string(expected, side, trunc)}'.", refs)
        if actual == expected
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias string_not_equal? string_does_not_equal?

      def text_does_not_contain?(container, ptrn, desc = '', refs = '')
        name = container.respond_to?(:tag_name) ? container.tag_name.titleize : 'DOM'
        msg  = build_message(desc, "#{name} text does not contain '#{ptrn}'.", refs)

        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end

        if container.text.match(target)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      def text_contains?(container, ptrn, desc = '', refs = '', skip_fail = false, skip_sleep = false)
        name = container.respond_to?(:tag_name) ? container.tag_name.titleize : 'DOM'
        msg  = build_message(desc, "#{name} text contains '#{ptrn}'.", refs)
        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end

        if container.text.match(target)
          passed_to_log("#{msg}")
          true
        else
          if skip_fail
            debug_to_log("#{name} text does not contain the text: '#{ptrn}'.  #{desc} (Fail suppressed)")
          else
            failed_to_log(msg)
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias text_equals? text_contains?
      alias validate_text text_contains?
      # alias element_text_equals? text_contains?
      # alias element_text_contains? text_contains?

      def validate_html(container, page, force_browser = false, filter = true)
        mark_testlevel(": #{page}")
        # require 'nokogiri-pretty'
        # require 'iconv'
        require 'diff/lcs'

        if force_browser
          html = container.browser.html
        else
          html = container.html
        end

        url = container.browser.url

        html_with_line_feeds = html.gsub("\n", '').gsub('>', ">\n")
        html_with_line_feeds = "<!DOCTYPE html>\n" + html_with_line_feeds unless html_with_line_feeds =~ /^\s*\<\!DOCTYPE/

        pretty_html, html_array = validate_encoding(html_with_line_feeds)

        html_context = html_line_context(html_array, container)

        file_name = page.gsub(' ', '_').gsub('-', '_').gsub('__', '_').gsub(':', '')
        file_name << "_#{get_timestamp('condensed_seconds')}_pretty.html"
        spec = File.join(@myRoot, 'log', file_name)
        file = File.new(spec, 'w')
        file.puts(pretty_html)
        file.close

        exceptions = Hash.new

        validate_with_nokogiri(pretty_html, exceptions)
        validate_with_tidy(url, pretty_html, exceptions)
        # validate_with_w3c_markup_file(spec, exceptions)
        validate_with_w3c_markup(pretty_html, exceptions)

        report_html_exceptions(container, exceptions, html_array, html_context, page, filter)

      rescue
        failed_to_log(unable_to, 2)
      end

      def validate_encoding(html, encoding = 'UTF-8')
        # ic      = Iconv.new("#{encoding}//IGNORE", encoding)
        encoded = ''

        html_array  = html.split(/\n/)
        line_number = 1

        html_array.each do |line|
          # valid_string = ic.iconv(line + ' ')[0..-2]
          valid_string = line.encode('UTF-16', :invalid => :replace, :replace => '').encode('UTF-8')
          unless line == valid_string
            diffs     = Diff::LCS.diff(valid_string, line)
            diffs_arr = diffs[0]
            debug_to_log("#{diffs_arr}")
            #TODO make message more meaningful by interpretting the nested array.
            debug_to_report("line #{line_number}: '#{diffs.to_s}' removed from '#{line}' to avoid W3C invalid UTF-8 characters error")
          end

          encoded << valid_string << "\n"

          line_number += 1
        end

        [encoded, html_array]

      rescue
        failed_to_log(unable_to)
      end

      def validate_with_nokogiri(html, exceptions)
        # mark_test_level
        nokogiri_levels = { '0' => 'None', '1' => 'Warning', '2' => 'Error', '3' => 'Fatal' }

        errors = Nokogiri::HTML(html).errors
        debug_to_log("Nokogiri: error count: #{errors.length}")

        instance = 1
        errors.each do |excp|
          debug_to_log("#{instance.to_s.ljust(4, ' ')}: #{excp}", 4)
          line                                                   = excp.line.to_i
          column                                                 = excp.column.to_i
          exceptions['nokogiri']                                 = Hash.new unless exceptions['nokogiri']
          exceptions['nokogiri'][:excps]                         = Hash.new unless exceptions['nokogiri'][:excps]
          exceptions['nokogiri'][:excps][line]                   = Hash.new unless exceptions['nokogiri'][:excps][line]
          exceptions['nokogiri'][:excps][line][column]           = Hash.new unless exceptions['nokogiri'][:excps][line][column]
          exceptions['nokogiri'][:excps][line][column][instance] = "line #{line} column #{column} - #{nokogiri_levels[excp.level.to_s]}: #{excp.message} (nokogiri)"
          instance                                               += 1
        end

      rescue
        failed_to_log(unable_to)
      end

      def validate_with_w3c_markup_file(html, exceptions)
        # mark_test_level
        @w3c_markup_validator = MarkupValidator.new(
            :validator_uri => 'http://wnl-svr017c.wellsfargo.com/w3c-validator/check'
        ) unless @w3c_markup_validator
        result                = @w3c_markup_validator.validate_file(html)
        parse_w3c_result(result, exceptions)
      end

      def validate_with_w3c_markup(html, exceptions)
        # mark_test_level
        @w3c_markup_validator = MarkupValidator.new(
            :validator_uri => 'http://wnl-svr017c.wellsfargo.com/w3c-validator/check'
        ) unless @w3c_markup_validator
        result                = @w3c_markup_validator.validate_text(html)
        parse_w3c_result(result, exceptions)
      end

      def parse_w3c_result(result, exceptions)

        debug_to_log("W3c Markup: #{result.debug_messages}")
        debug_to_log("W3c Markup: error count: #{result.errors.length}")

        instance = 1
        result.errors.each do |excp|
          begin
            debug_to_log("#{instance.to_s.ljust(4, ' ')}: #{excp}", 4)
            if excp =~ /not allowed on element/
              debug_to_log("[#{excp.explanation}]")
            end

            if excp.line
              line                                                     = excp.line.to_i
              column                                                   = excp.col.to_i
              exceptions['w3c_markup']                                 = Hash.new unless exceptions['w3c_markup']
              exceptions['w3c_markup'][:excps]                         = Hash.new unless exceptions['w3c_markup'][:excps]
              exceptions['w3c_markup'][:excps][line]                   = Hash.new unless exceptions['w3c_markup'][:excps][line]
              exceptions['w3c_markup'][:excps][line][column]           = Hash.new unless exceptions['w3c_markup'][:excps][line][column]
              exceptions['w3c_markup'][:excps][line][column][instance] = "line #{line} column #{column} - (#{excp.message_id}) #{excp.message} (w3c_markup)"
            end
            instance += 1
          rescue
            debug_to_log(unable_to("#{instance}"))
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      def validate_with_tidy(url, html, exceptions)
        # mark_test_level
        @html_validator = ::PageValidations::HTMLValidation.new(
            File.join(@myRoot, 'log'),
            [
                #'-access 2'
            ],
            {
                # :ignore_proprietary => true
                #:gnu_emacs          => true
            }
        ) unless @html_validator

        validation = @html_validator.validation(html, url)
        results    = validation.exceptions.split(/\n/)

        debug_to_log("HTML Tidy: error count: #{results.length}")

        instance = 1
        results.each do |excp|
          debug_to_log("#{instance.to_s.ljust(4, ' ')}: #{excp}", 4)
          begin
            mtch = excp.match(/line\s*(\d+)\s*column\s*(\d+)\s*-\s*(.+)$/)
            if mtch
              line   = mtch[1].to_i
              column = mtch[2].to_i
              excp.chomp!
              exceptions['tidy']                                 = Hash.new unless exceptions['tidy']
              exceptions['tidy'][:excps]                         = Hash.new unless exceptions['tidy'][:excps]
              exceptions['tidy'][:excps][line]                   = Hash.new unless exceptions['tidy'][:excps][line]
              exceptions['tidy'][:excps][line][column]           = Hash.new unless exceptions['tidy'][:excps][line][column]
              exceptions['tidy'][:excps][line][column][instance] = excp + ' (tidy)'
            end
            instance += 1
          rescue
            debug_to_log(unable_to("#{instance}"))
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      def report_html_exceptions(container, exceptions, html_array, html_location, page, filter = true, pre_length = 25, post_length = 50)
        mark_test_level(page)
        message_to_report(build_message('(Filtering disabled)')) unless filter

        exception_count = 0
        error_count     = 0
        log_count       = 0
        warn_count      = 0
        ignored_count   = 0
        unknown_count   = 0
        no_filtering    = 0


        exceptions.keys.sort.each do |validator|
          mark_test_level("Validator: #{validator.titleize}", 5)
          exceptions[validator][:tallies]           = Hash.new
          exceptions[validator][:tallies][:ignore]  = 0
          exceptions[validator][:tallies][:log]     = 0
          exceptions[validator][:tallies][:warn]    = 0
          exceptions[validator][:tallies][:fail]    = 0
          exceptions[validator][:tallies][:unknown] = 0

          # debug_to_log("[#{validator}]")
          exceptions[validator][:excps].keys.sort.each do |line|
            # debug_to_log("[#{line}]")
            next unless line.is_a?(Fixnum)
            exceptions[validator][:excps][line].keys.sort.each do |column|
              # debug_to_log("[#{column}]")
              exceptions[validator][:excps][line][column].keys.sort.each do |instance|

                excp            = exceptions[validator][:excps][line][column][instance]
                exception_count += 1

                mtch       = excp.match(/line\s*(\d+)\s*column\s*(\d+)\s*-\s*(.+)$/)
                arr_line   = (mtch[1].to_i - 1)
                int_column = (mtch[2].to_i - 1)
                desc       = mtch[3]

                tag     = "#{validator}/#{line}/#{column}/#{instance} "
                # debug_to_log(tag, 4)

                excerpt = format_html_excerpt(html_array[arr_line], int_column, pre_length, post_length, tag)
                out     = "#{desc}: line #{line} col #{column} #{excerpt}"

                annotate_html_message(out, html_location[arr_line], line, column)

                if filter

                  filter_id, action, alt_value = filter_html_exception?(desc, out, html_array[arr_line], validator, html_location[arr_line])
                  alt_value_msg                = alt_value ? "'#{alt_value}'" : nil

                  if filter_id
                    case action
                      when 'log'
                        log_count                             += 1
                        exceptions[validator][:tallies][:log] += 1
                        debug_to_log(build_message("LOGGED [#{filter_id}]: #{out}", alt_value_msg), 5)
                      when 'warn'
                        warn_count                             += 1
                        exceptions[validator][:tallies][:warn] += 1
                        message_to_report(build_message("WARN [#{filter_id}]: #{out}", alt_value_msg), 4)
                      when 'ignore'
                        ignored_count                            += 1
                        exceptions[validator][:tallies][:ignore] += 1
                        debug_to_log(build_message("IGNORED [#{filter_id}]: #{out}", alt_value_msg), 5)
                      else
                        unknown_count                             += 1
                        exceptions[validator][:tallies][:unknown] += 1
                        debug_to_log("unknown action '#{action}' [#{filter_id}]: #{out}", 4)
                    end
                  else
                    out.sub!(/Warning:|\(html5\)/i, 'ERROR:')
                    ref, desc, tag, id = fetch_html_err_ref(out)
                    ref                = ref.size > 0 ? format_reference(ref) : nil
                    if id
                      elem = container.element(:id, id)
                      debug_to_log(with_caller(build_message(elem.to_subtype, "class=#{elem.class_name}")), 5)
                    end
                    failed_to_log(build_message(out, desc, ref), 6)
                    error_count                            += 1
                    exceptions[validator][:tallies][:fail] += 1
                  end
                else
                  debug_to_report(out)
                  no_filtering += 1
                end

              end
            end
          end
        end

        if error_count > 0
          message_to_report(with_caller("#{error_count} HTML validation errors reported"))
        else
          message_to_report(with_caller('No HTML validation errors reported'))
        end
        message_to_report(with_caller("#{warn_count} HTML validation warnings reported")) if warn_count > 0
        debug_to_log(with_caller("total #{exception_count},", "filtering turned off? #{no_filtering},", " errors #{error_count},",
                                 " warn #{warn_count},", " log #{log_count},", " ignored #{ignored_count}",
                                 " unknown #{unknown_count}"))

        report_results(error_count, with_caller(page))

      rescue
        failed_to_log(unable_to)
      end

      def annotate_html_message(out, location, line, column)
        if location[:script]
          out << " (in script #{line}/#{column})"
        else
          if location[:head]
            out << " (in head)"
            if location[:meta]
              out << " (in meta)"
            end
          end
        end
        if location[:in_frame]
          out << " (in frame)"
        end
        # out << " (in meta)" if in_meta
        # out << " (in body)" if in_body
        if location[:fragment]
          out << " (in fragment)"
        end
      end

      def fetch_html_err_ref(strg)
        ref    = ''
        desc   = nil
        tag    = nil
        anchor = nil
        @html_error_references.each_key do |ptrn|
          begin
            mtch = strg.match(ptrn)
          rescue
            debug_to_report(with_caller("'#{$!}'"))
          end
          if mtch
            ref  = @html_error_references[ptrn][:reference]
            desc = @html_error_references[ptrn][:description]
            tag  = mtch[1] if mtch[1]
            case strg
              when /\s*anchor\s*/
                anchor = mtch[2] if mtch[2]
            end
            break
          end
        end
        [ref, desc, tag, anchor]
      rescue
        failed_to_log(unable_to)
      end

      def format_html_excerpt(line, column, pre_length, post_length, tag)
        # debug_to_log(with_caller(tag))
        if line
          column      = 0 if line.size < post_length
          pre_length  = column if column < pre_length
          pre_excerpt = line.slice(column - pre_length, pre_length)
          pre_excerpt.gsub!(/^\s+/, '')
          post_excerpt = line.slice(column, post_length)
          excerpt      = '['
          excerpt << '...' if (column - pre_length) > 1
          excerpt << pre_excerpt if pre_excerpt
          excerpt << '^'
          excerpt << post_excerpt if post_excerpt
          excerpt << '...' if line.size >= (pre_length + post_length)
          excerpt << ']'
          excerpt.ljust(excerpt.size + 1, ' ')
        else
          debug_to_log("Line for #{tag} is nil")
        end
      rescue
        failed_to_log(unable_to)
      end

      def filter_html_exception?(excp, out, line, validator, location)
        filter    = nil
        action    = nil
        alt_value = nil

        if @html_filters[validator]
          @html_filters[validator].each_key do |key|
            pattern = @html_filters[validator][key][:pattern]
            if excp.match(pattern)
              # msg = build_message('(filtered):', "[id:#{key}]", out, @html_filters[validator][key][:description])

              action = @html_filters[validator][key][:action]

              filter, action, alt_value = html_alt_filter(validator, key, action, line, location)

              case action
                when /ignore|log|warn/i
                  filter = key
                when /fail/i
                  filter = nil
                else
                  debug_to_log(with_caller("Unknown action '#{action}'"))
                  filter = nil
              end
              break
            end
          end
        end
        [filter, action, alt_value]
      rescue
        failed_to_log(unable_to)
      end

      def html_alt_filter(validator, key, action, line, location)
        filter     = key
        alt_action = action
        mtch_value = nil

        if @html_filters[validator][key][:alt_pattern]

          alt_pattern = @html_filters[validator][key][:alt_pattern]
          mtch        = line.match(alt_pattern)
          if mtch
            mtch_value = mtch[1] if mtch[1]
            alt_action = @html_filters[validator][key][:alt_action]
            case alt_action
              when ''
                filter = nil
              when /fail/i
                filter = nil
              when /ignore/i, /warn/i, /log/i
                filter = key
              else
                debug_to_log(with_caller("Unknown alt_action '#{alt_action}'"))
                alt_action = 'warn'
            end

          else
            alt_action = action
            filter     = nil if action =~ /fail/i
          end

        else
          # TODO This hierarchy is over simple.
          # NOTE: Current assumption is that first found wins
          # NOTE: and only one will be set with an action for a given filter
          [:script, :meta, :head, :body, :fragment, :frame].each do |loc|
            if location[loc] and @html_filters[validator][key][loc]
              alt_action = @html_filters[validator][key][loc]
              filter     = nil if alt_action =~ /fail/i
              break
            end
          end
        end

        [filter, alt_action, mtch_value]
      rescue
        failed_to_log(unable_to, 2)
      end

      def html_line_context(html, container)
        in_script   = false
        in_head     = false
        in_meta     = false
        in_body     = false
        in_frame    = false
        in_fragment = false

        line            = 0
        hash            = {}
        container_class = container.class.to_s
        debug_to_log("container class='#{container_class}'")

        case container_class
          when /frame/i
            in_frame = true
          when /browser/i
            in_frame = false
          else
            in_fragment = true
        end
        html.each do |l|
          target = l.dup.strip

          hash[line] = Hash.new

          hash[line][:frame]    = in_frame
          hash[line][:fragment] = in_fragment

          in_script             = true if target.match(/^\s*<script/)
          in_head               = true if target.match(/^\s*<head>/)
          in_meta               = true if target.match(/^\s*<meta/)
          in_body               = true if target.match(/^\s*<body/)

          hash[line][:script] = in_script
          hash[line][:head]   = in_head
          hash[line][:meta]   = in_meta
          hash[line][:body]   = in_body

          in_script           = false if target.match(/^\s*<script.*\/>$/)
          in_script           = false if target.match(/<\/script>$/)
          in_head             = false if target.match(/<\/head>/)
          in_meta             = false if target.match(/<\/meta.*\/>$/)
          in_script           = false if target.match(/<\/meta>$/)
          in_body             = false if target.match(/<\/body/)

          line += 1
        end

        hash
      end

      def text_does_not_equal?(container, ptrn, desc = '', refs = '')
        name = container.respond_to?(:tag_name) ? container.tag_name.titleize : 'DOM'
        msg  = build_message(desc, "#{name} text contains '#{ptrn}'.", refs)
        if ptrn.is_a?(Regexp)
          target = ptrn
        else
          target = Regexp.new(Regexp.escape(ptrn))
        end
        if container.respond_to?(:wait)
          container.wait
        elsif container.respond_to?(:wait_until_present)
          container.wait_until_present
        else
          sleep(3)
        end
        if container.text.match(target)
          failed_to_log(msg)
        else
          passed_to_log("#{msg}")
          true
        end
      rescue
        failed_to_log(unable_to)
      end

      alias validate_no_text text_does_not_equal?
      alias element_text_does_not_equal? text_does_not_equal?

      def textfield_equals?(browser, how, what, expected, desc = '', refs = '')
        msg    = build_message(desc, "Expected value to equal '#{expected}' in textfield #{how}='#{what}'.", refs)
        actual = browser.text_field(how, what).value
        if actual.is_a?(Array)
          actual = actual[0].to_s
        end
        if actual == expected
          passed_to_log(msg)
          true
        else
          act_s = actual.strip
          exp_s = expected.strip
          if act_s == exp_s
            passed_to_log("#{msg} (stripped)")
            true
          else
            debug_to_report(
                "#{__method__} (spaces underscored):\n "+
                    "expected:[#{expected.gsub(' ', '_')}] (#{expected.length})\n "+
                    "actual:[#{actual.gsub(' ', '_')}] (#{actual.length}) (spaces underscored)"
            )
            failed_to_log("#{msg}. Found: '#{actual}'")
          end
        end
      rescue
        failed_to_log(unable_to("#{how}='#{what}'", false, true))
      end

      alias validate_textfield_value textfield_equals?
      alias text_field_equals? textfield_equals?

      def textfield_contains?(container, how, what, expected, desc = '', refs = '')
        msg      = build_message(desc, "Does text field #{how}='#{what}' contains '#{expected}'.", refs)
        contents = container.text_field(how, what).when_present.value
        if contents =~ /#{expected}/
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Contents: '#{contents}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias text_field_contains? textfield_contains?

      def textfield_empty?(browser, how, what, desc = '', refs = '')
        msg      = build_message(desc, "Text field #{how}='#{what}' is empty.", refs)
        contents = browser.text_field(how, what).value
        if contents.to_s.length == 0
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Contents: '#{contents}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias validate_textfield_empty textfield_empty?
      alias text_field_empty? textfield_empty?

      def existence(container, should_be, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        if should_be
          element_exists?(target, desc, refs, how, what, value)
        else
          element_does_not_exist?(target, desc, refs, how, what, value)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def element_existence(element, should_be, desc = '', refs = '', how = '', what = '')
        should_be = force_boolean(should_be)
        if should_be
          element_exists?(element, desc, refs, how, what, nil)
        else
          element_does_not_exist?(element, desc, refs, how, what, nil)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def exists?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_exists?(target, desc, refs, how, what, value)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_exists?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'exists?', how, what, value, desc, refs)
        if element.exists?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def does_not_exist?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_does_not_exist?(target, value, desc, refs, how, what, element)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_does_not_exist?(element, value = nil, desc = '', refs = '', how = nil, what = nil, tag = nil)
        msg = element_query_message(element, 'does not exist?', how, what, value, desc, refs, tag)
        if element.exists?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def presence(container, should_be, element, how, what, value = nil, desc = '', refs = '')
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        if should_be
          element_is_present?(target, desc, refs, how, what, value)
        else
          element_not_present?(target, desc, refs, how, what, value)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def element_presence(element, should_be, desc = '', refs = '', how = '', what = '')
        should_be = force_boolean(should_be)
        if should_be
          element_is_present?(element, desc, refs, how, what, nil)
        else
          element_not_present?(element, desc, refs, how, what, nil)
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def is_present?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_is_present?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      def element_is_present?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is_present?', how, what, value, desc, refs)
        if element.present?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_present? element_is_present?

      def not_present?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_present?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      def element_not_present?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is not present?', how, what, value, desc, refs)
        if element.present?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_is_not_present? element_not_present?

      def force_boolean(boolean)
        case boolean
          when true, false
            should_be = boolean
          when /yes/i, /true/i
            should_be = true
          else
            should_be = false
        end
        should_be
      end

      def expected_url?(container, expected, desc = '', refs = '')
        msg = build_message(desc, "Is browser at url #{expected}.", refs)
        if container.url == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Found #{container.url}")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_focused?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_focused?(target, how, what, value, desc, refs)
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      alias is_not_focused? not_focused?

      def element_not_focused?(element, how, what, value = nil, desc = '', refs = '')
        msg     = element_query_message(element, 'does not have focus?', how, what, value, desc, refs)
        current = element.browser.execute_script("return document.activeElement")
        if element == current
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_is_not_focused? element_not_focused?

      def is_focused?(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_focused?(target, how, what, value, desc, refs)
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      def element_focused?(element, how, what, value = nil, desc = '', refs = '')
        msg     = element_query_message(element, 'has focus?', how, what, value, desc, refs)
        current = get_active_element(element)
        if element == current
          passed_to_log(msg)
          true
        else
          if current.id and (element.id == current.id)
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_is_focused? element_focused?

      def visibility(container, boolean, element, how, what, desc = '', refs = '')
        should_be = force_boolean(boolean)
        if should_be
          visible?(container, element, how, what, desc, refs)
        else
          not_visible?(container, element, how, what, desc, refs)
        end
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      def visible?(container, element, how, what, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_visible?(target, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(build_msg(element, how, what), refs)
      end

      def element_visible?(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, 'is visible?', how, what, nil, desc, refs)
        if element.visible?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_visible?(container, element, how, what, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_not_visible?(target, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what), false, true))
      end

      def element_not_visible?(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, 'is not visible?', how, what, nil, desc, refs)
        if element.visible?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def disablement(container, boolean, element, how, what, desc = '', refs = '')
        should_be = force_boolean(boolean)
        if should_be
          disabled?(container, element, how, what, desc, nil, refs)
        else
          enabled?(container, element, how, what, desc, nil, refs)
        end
      rescue
        failed_to_log(unable_to(desc, false, true))
      end

      def disabled?(container, element, how, what, desc = '', value = nil, refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_disabled?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      def element_disabled?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is disabled?', how, what, value, desc, refs)
        # element_wait(element)
        if element.respond_to?(:disabled?)
          if element.disabled?
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          failed_to_log(build_message("#{element} does not respond to .disabled."), msg)
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def not_disabled?(container, element, how, what, desc = '', value = nil, refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval(code)
        element_not_disabled?(target, desc, refs, how, what, value)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, value), false, true))
      end

      alias enabled? not_disabled?

      def element_not_disabled?(element, desc = '', refs = '', how = nil, what = nil, value = nil)
        msg = element_query_message(element, 'is enabled?', how, what, value, desc, refs)
        # element_wait(element)
        if element.disabled?
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_enabled? element_not_disabled?

      def element_disablement(target, disabled, desc = '', refs = '')
        #TODO: Is this really necessary?
        is_disabled = target.disabled?
        disablement = false
        should_be   = disabled ? true : false
        msg         = build_message(desc, "(in #{method_to_title(__method__)})", "should be #{should_be}", "is #{is_disabled}", refs)
        if should_be == is_disabled
          passed_to_log(msg)
          disablement = true
        else
          failed_to_log(msg)
        end
        [is_disabled, disablement]
      rescue
        rescue_msg_for_validation(msg)
      end

      def pixels_do_not_equal?(container, element, how, what, style, expected, desc = '', refs = '', rounding = 'up')
        code   = build_webdriver_fetch(element, how, what)
        actual = eval("#{code}.style('#{style}')")

        if actual =~ /px$/
          expected = expected.to_s + 'px'
        else
          case rounding
            when 'ceil', 'up'
              actual = actual.to_f.ceil
            when 'down', 'floor'
              actual = actual.to_f.floor
            else
              actual = actual.to_f.round
          end
        end

        msg = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "pixel size '#{style}",
                            "equals '#{expected}' (with rounding #{rounding}).", refs)

        if actual == expected
          failed_to_log("#{msg} Found '#{actual}'")
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias pixels_not_equal? pixels_do_not_equal?

      def pixels_equal?(container, element, how, what, style, expected, desc = '', refs = '', rounding = 'up')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_pixels_equal?(target, style, expected, desc, refs, how, what)
          # actual = eval("#{code}.style('#{style}')")
          #
          # if actual =~ /px$/
          #   expected = expected.to_s + 'px'
          # else
          #   case rounding
          #     when 'ceil', 'up'
          #       actual = actual.to_f.ceil
          #     when 'down', 'floor'
          #       actual = actual.to_f.floor
          #     else
          #       actual = actual.to_f.round
          #   end
          # end
          #
          # msg = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{style}",
          #                     "equals '#{expected}' (with rounding #{rounding}).", refs)
          #
          # if actual == expected
          #   passed_to_log(msg)
          #   true
          # else
          #   failed_to_log("#{msg} Found '#{actual}'")
          # end
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_pixels_equal?(element, style, expected, desc = '', refs = '', how = nil, what = nil, rounding = 'up')
        msg      = build_message(desc, "Element #{element.to_s.upcase} :#{how}='#{what}'", "attribute '#{style}",
                                 "equals '#{expected}' (with rounding #{rounding}).", refs)
        actual   = element.style(style)

        # if actual =~ /px$/
        #   expected = expected.to_s + 'px' unless expected =~ /px$/
        # else
        actual   = actual =~ /px$/ ? actual.sub(/px$/, '').to_f : actual.to_f
        expected = expected =~ /px$/ ? expected.sub(/px$/, '').to_f : expected.to_f
        case rounding
          when 'ceil', 'up'
            actual = actual.to_f.ceil
          when 'down', 'floor'
            actual = actual.to_f.floor
          else
            actual = actual.to_f.round
        end
        # end

        if actual == expected
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg} Found '#{actual}'")
        end
      end

      def style_does_not_contain?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_style_does_not_contain?(target, style, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, style), false, true))
      end

      def element_style_does_not_contain?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, "style '#{style}' does not contain '#{expected}'.", how, what, nil, desc, refs)
        element_wait(element)
        if element.style(style).match(expected)
          failed_to_log(msg)
        else
          passed_to_log(msg)
          true
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def style_contains?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_style_contains?(target, style, expected, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, style), false, true))
      end

      def element_style_contains?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg = element_query_message(element, "style '#{style}' contains '#{expected}'.", how, what, nil, desc, refs)
        element_wait(element)
        if element.style(style).match(expected)
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}. Found '#{element.class_name}'")
        end
      rescue
        rescue_msg_for_validation(msg)
      end

      def style_does_not_equal?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")

        element_style_does_not_equal?(target, style, expected, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias color_not_equal? style_does_not_equal?
      alias style_not_equal? style_does_not_equal?
      alias color_does_not_equal? style_does_not_equal?

      def element_style_does_not_equal?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        msg           = element_query_message(element, "style '#{style}' does not equal '#{expected}'.", how, what, nil, desc, refs)
        actual        = element.style(style)
        actual_norm   = style =~ /color/ ? normalize_color_value(actual) : actual
        expected_norm = style =~ /color/ ? normalize_color_value(expected) : expected

        if actual
          if actual_norm == expected_norm
            failed_to_log(msg)
          else
            found = style =~ /color/ ? "#{rgb_to_html(actual).upcase} (#{actual_norm})" : "#{actual}"
            passed_to_log("#{msg}. Found #{found}")
            true
          end
        else
          failed_to_log("#{msg} '#{style}' not found.")
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_color_does_not_equal? element_style_does_not_equal?
      alias element_color_not_equal? element_style_does_not_equal?
      alias element_style_not_equal? element_style_does_not_equal?

      def style_equals?(container, element, how, what, style, expected, desc = '', refs = '')
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}")
        element_style_equals?(target, style, expected, desc, refs, how, what)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      alias color_equals? style_equals?

      def element_style_equals?(element, style, expected, desc = '', refs = '', how = nil, what = nil)
        # msg    = element_query_message(element, "style '#{style}' equals '#{expected}'.", how, what, nil, desc, refs)
        actual = element.style(style)
        actual = element.attribute_value(style) unless actual and actual.length > 0
        case style
          when /color$/
            actual_norm   = normalize_color_value(actual)
            expected_norm = normalize_color_value(expected)
          when /opacity/
            actual_norm   = actual.to_f
            expected_norm = expected.to_f
          when /^border$/
            actual_norm   = normalize_border_style(actual)
            expected_norm = normalize_border_style(expected)
          when /width$/, /size$/
            actual_norm   = normalize_pixel_size(actual)
            expected_norm = normalize_pixel_size(expected)
          when /box-shadow$/
            actual_norm   = normalize_box_shadow_value(actual)
            expected_norm = normalize_box_shadow_value(expected)
          else
            actual_norm   = actual
            expected_norm = expected
        end

        # if style =~ /color/
        #   debug_to_log(with_caller("'#{style}'", "actual:   raw: '" + actual + "'  normalized: '" + actual_norm + "'"))
        #   debug_to_log(with_caller("'#{style}'", "expected: raw: '" + expected + "'  normalized: '" + expected_norm + "'"))
        # end

        msg = element_query_message(element, "style '#{style}' equals '#{expected_norm}'.", how, what, nil, desc, refs)
        if actual and actual.length > 0
          if actual_norm == expected_norm
            passed_to_log(msg)
            true
          else
            found = style =~ /color/ ? "#{rgb_to_html(actual)} (#{actual_norm})" : "#{actual}"
            failed_to_log("#{msg}. Found #{found}")
          end
        else
          failed_to_log("#{msg} '#{style}' not found.")
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      alias element_color_equals? element_style_equals?

      def border_colors_equal?(container, element, how, what, desc, refs, *colors)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_border_colors_equal?(target, how, what, desc, refs, *colors)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_border_colors_equal?(element, how = nil, what = nil, desc = '', refs = '', *colors)
        msg    = element_query_message(element, "Border colors are '#{colors}'.", how, what, nil, desc, refs)
        errors = 0
        errs   = []

        sides = ['top', 'bottom', 'left', 'right']
        sides.each do |side|
          idx      = sides.index(side)
          color    = colors[idx] ? colors[idx] : colors[0] # handles situation where all sides are same
          expected = normalize_color_value(color)
          debug_to_log(with_caller(desc, side, 'expected normalized:', expected)) if @debug_dsl
          # msg    = element_query_message(element, "'border-#{side}-color' equals '#{expected}'.", how, what, nil, desc, refs)
          actual = normalize_color_value(element.style("border-#{side}-color"))
          unless actual == expected
            errors += 1
            errs << "#{side}:#{actual}"
          end
        end

        if errors == 0
          passed_to_log(with_caller(msg))
          true
        else
          failed_to_log(with_caller(msg, "Found #{nice_array(errs)}"))
        end

      rescue
        rescue_msg_for_validation(msg)
      end

      def border_sizes_equal?(container, element, how, what, attribute, desc, refs, *pixels)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_border_sizes_equal?(target, how, what, attribute, desc, refs, *pixels)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_border_sizes_equal?(element, how, what, attribute, desc, refs, *pixels)
        attribute = attribute.downcase.gsub(/s$/, '')
        msg       = element_query_message(element, "Border #{attribute}s are '#{pixels}'.", how, what, nil, desc, refs)
        errors    = 0
        errs      = []

        sides = ['top', 'bottom', 'left', 'right']

        sides.each do |side|
          idx      = sides.index(side)
          value    = pixels[idx] ? pixels[idx] : pixels[0]
          expected = value =~ /px$/ ? value.to_s : "#{value}px"
          target   = attribute == 'padding' ? "#{attribute}-#{side}" : "border-#{side}-#{attribute}"
          actual   = element.style(target)
          unless actual == expected
            errors += 1
            errs << "#{side}:#{actual}"
          end
        end

        if errors == 0
          passed_to_log(with_caller(msg))
          true
        else
          failed_to_log(with_caller(msg, "Found #{nice_array(errs)}"))
        end

      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def border_styles_equal?(container, element, how, what, desc, refs, *styles)
        code   = build_webdriver_fetch(element, how, what)
        target = eval(code)
        element_border_sizes_equal?(target, how, what, desc, refs, *styles)
      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def element_border_styles_equal?(element, how, what, desc, refs, *styles)
        msg    = element_query_message(element, "Border styles are '#{styles}'.", how, what, nil, desc, refs)
        errors = 0
        errs   = []

        sides = ['top', 'bottom', 'left', 'right']

        sides.each do |side|
          idx      = sides.index(side)
          expected = styles[idx] ? styles[idx] : styles[0]
          actual   = element.style("border-#{side}-style")
          unless actual == expected
            errors += 1
            errs << "#{side}:#{actual}"
          end
        end

        if errors == 0
          passed_to_log(with_caller(msg))
          true
        else
          failed_to_log(with_caller(msg, "Found #{nice_array(errs)}"))
        end

      rescue
        rescue_msg_for_validation(desc, refs)
      end

      def margins_equal?(container, element, how, what, desc, refs, *pixels)
        border_sizes_equal?(container, element, how, what, 'margin', desc, refs, *pixels)
      end

      def border_widths_equal?(container, element, how, what, desc, refs, *pixels)
        border_sizes_equal?(container, element, how, what, 'width', desc, refs, *pixels)
      end

      def padding_equal?(container, element, how, what, desc, refs, *pixels)
        border_sizes_equal?(container, element, how, what, 'padding', desc, refs, *pixels)
      end

      def select_list_includes?(browser, how, what, which, option, desc = '', refs = '')
        msg         = build_message(desc, "Select list #{how}='#{what}' includes option '#{option}'.")
        select_list = browser.select_list(how, what)
        options     = select_list.options
        found       = false
        where       = nil

        whiches  = [:inner_text, :label, :value, :text]
        opt_hash = {}

        options.each do |opt|
          opt_arr = [opt.attribute_value('innerText'), opt.label, opt.value, opt.text]
          whiches.each_index { |i| opt_hash[whiches[i]] = opt_arr[i] }
          opt_arr.each_index do |idx|
            if opt_arr[idx] == option
              found = true
              where = whiches[idx]
              debug_to_log(with_caller("Target string '#{option}' found in option #{where}")) if @debug_dsl
            end
          end
        end

        if found
          passed_to_log(build_message(msg, "Found in #{where} (#{which})", refs))
          true
        else
          failed_to_log("#{msg} #{refs}")
        end

      rescue
        rescue_msg_for_validation(msg, refs)
      end

      def select_list_does_not_include?(browser, how, what, which, option, desc = '', refs = '')
        msg         = build_message(desc, "Select list #{how}='#{what}' does not include option with '#{option}'.")
        select_list = browser.select_list(how, what)
        options     = select_list.options
        found       = false
        where       = nil

        whiches  = [:text, :label, :value, :inner_text]
        opt_hash = {}

        options.each do |opt|
          opt_arr = [opt.text, opt.label, opt.value, opt.attribute_value('innerText')]
          whiches.each_index { |i| opt_hash[whiches[i]] = opt_arr[i] }
          opt_arr.each_index do |idx|
            if opt_arr[idx] == option
              found = true
              where = whiches[idx]
              debug_to_log(with_caller("Target string '#{option}' found in option #{where}")) if @debug_dsl
            end
          end
        end

        if found
          failed_to_log(build_message(msg, "Found in #{where} (#{which})", refs))
        else
          passed_to_log("#{msg} #{refs}")
          true
        end

      rescue
        rescue_msg_for_validation(msg, refs)
      end

      def validate_selected_options(browser, how, what, list, desc = '', refs = '', which = :text)
        selected_options = browser.select_list(how, what).selected_options.dup
        selected         = extract_selected(selected_options, which)
        sorted_list      = list.dup.sort
        if list.is_a?(Array)
          msg = build_message(desc, "Expected options [#{list.sort}] are selected by #{which} [#{selected}].", refs)
          if selected == sorted_list
            passed_to_log(msg)
            true
          else
            failed_to_log(msg)
          end
        else
          if selected.length == 1
            msg      = build_message(desc, "Expected option [#{list}] was selected by #{which}.", refs)
            esc_list = Regexp.escape(list)
            if selected[0] =~ /#{esc_list}/
              passed_to_log(msg)
              true
            else
              failed_to_log("#{msg} Found [#{selected}]. #{desc}")
            end
          else
            msg = build_message(desc, "Expected option [#{list}] was found among multiple selections by #{which} [#{selected}].", refs)
            if selected.include?(list)
              failed_to_log(msg)
            else
              failed_to_log(msg)
            end
          end
        end

      rescue
        failed_to_log(unable_to)
      end

      def verify_attribute(container, element, how, what, attribute, expected, desc = '', refs = '')
        msg    = element_query_message(element, "#{attribute} equals '#{expected}'.", how, what, nil, desc, refs)
        actual = get_attribute_value(container, element, how, what, attribute, desc)
        if actual == expected
          passed_to_log(msg)
        else
          failed_to_log("#{msg} Found '#{actual}'")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      alias validate_attribute_value verify_attribute
      alias verify_attribute_value verify_attribute

    end

    module UserInput

      def focus(container, element, how, what, desc = '', refs = '', wait = 10)
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}.when_present(#{wait})")
        focus_element(target, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(msg))
      end

      def focus_element(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, 'Set focus on', how, what, nil, desc, refs)
        element.focus
        sleep(0.2)
        if element.focused?
          passed_to_log(with_caller(msg))
          true
        else
          current = get_active_element(element)
          if element == current
            passed_to_log(with_caller(msg))
            true
          else
            if element.id == current.id
              passed_to_log(with_caller(msg))
              true
            else
              failed_to_log(with_caller(msg))
            end
          end
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def blur_element(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, 'Trigger blur', how, what, nil, desc, refs)
        element.fire_event('onBlur')
        if element.focused?
          passed_to_log(with_caller(msg))
          true
        else
          failed_to_log(with_caller(msg))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def clear(container, tag, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        msg                        = element_action_message(tag, 'Clear', how, what, value, desc, refs)
        code                       = build_webdriver_fetch(tag, how, what, options)
        target                     = eval(code)
        target                     = target.to_subtype if tag == :input
        before                     = target.value
        after                      = ''
        cleared                    = false

        target.clear

        klass = target.class.to_s
        case klass
          when /textfield/i
            after   = target.value
            cleared = true if after.length == 0
          when /textarea/i
            after   = target.value
            cleared = true if after.length == 0
          when /checkbox/i, /radio/i
            cleared != eval("#{code}.set.")
          else
            failed_to_log(with_caller(desc, "Invalid object class (#{klass}) for clear. *** waft002 ****"), refs)
        end

        if cleared
          passed_to_log("#{msg} (#{klass}) Before: '#{before}'")
          true
        else
          failed_to_log("#{msg} (#{klass}) Before: '#{before}' Found '#{after}'")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def click(container, element, how, what, desc = '', refs = '', wait = 10)
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}.when_present(#{wait})")
        click_element(target, desc, refs, how, what, value = nil)
      rescue
        failed_to_log(unable_to(build_message(desc, "#{element.to_s.upcase} :#{how}=>'#{what}'", refs)))
      end

      alias click_js click

      def click_element(element, desc = '', refs = '', how = '', what = '', value = '')
        msg = element_action_message(element, 'Click', how, what, value, desc, refs)
        begin
          element.click
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(element, how, what, __method__.to_s))
            raise e
          end
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      alias element_click click_element

      def click_as_needed(browser, target_container, target_elem, target_how, target_what,
                          confirm_container, confirm_elem, confirm_how, confirm_what,
                          desc = '', neg = false, alternate = false, limit = 6.0, increment = 0.5, interval = 2.0)
        rtrn = true
        nope = neg ? 'not ' : ''

        debug_to_log("#{__method__.to_s.titleize}: Target:  :#{target_elem} :#{target_how}='#{target_what}' in #{target_container}")
        debug_to_log("#{__method__.to_s.titleize}: Confirm: :#{confirm_elem} :#{confirm_how}='#{confirm_what}' in #{confirm_container}")
        windows_to_log(browser)
        click(target_container, target_elem, target_how, target_what, desc)
        last_action = 'click'

        if confirm_elem == :window
          query = 'current?'
        else
          query = 'present?'
        end

        if confirm_what.is_a?(Regexp)
          code = "#{nope}confirm_container.#{confirm_elem.to_s}(:#{confirm_how}, /#{confirm_what}/).#{query}"
        else
          code = "#{nope}confirm_container.#{confirm_elem.to_s}(:#{confirm_how}, '#{confirm_what}').#{query}"
        end
        debug_to_log("#{__method__}: code=[#{code}]")

        seconds = 0.0
        until eval(code) do
          debug_to_log("#{__method__}: seconds=[#{seconds}] [#{code}]")
          sleep(increment)
          seconds += increment
          if seconds > limit
            rtrn = false
            break
          end
          if seconds.modulo(interval) == 0.0
            if alternate
              if last_action == 'click'
                fire_event(target_container, target_elem, target_how, target_what, 'onclick', "#{desc} (#{seconds} seconds)")
                last_action = 'fire'
              else
                click(target_container, target_elem, target_how, target_what, "#{desc} (#{seconds} seconds)")
                last_action = 'click'
              end
            else
              click(target_container, target_elem, target_how, target_what, "#{desc} (#{seconds} seconds)")
            end
          end
        end
        unless rtrn
          focus(browser, target_elem, target_how, target_what)
          sleep(0.1)
          send_a_key(browser, :enter)
          sleep(interval)
          rtrn = eval(code)
        end
        rtrn
      rescue
        failed_to_log(unable_to)
      end

      def fire_event(container, element, how, what, event, desc = '', refs = '', wait = 10)
        code   = build_webdriver_fetch(element, how, what)
        target = eval("#{code}.when_present(#{wait})")
        element_fire_event(target, event, desc, refs, how, what)
      rescue
        failed_to_log(unable_to(build_msg(element, how, what, event)))
      end

      def element_fire_event(element, event, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, "Fire '#{event}' event on", how, what, nil, desc, refs)
        begin
          element.fire_event(event)
        rescue => e
          unless rescue_me(e, __method__, rescue_me_command(element, how, what, __method__.to_s, event))
            raise e
          end
        end
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      def element_hover(element, desc = '', refs = '', how = nil, what = nil)
        msg = element_action_message(element, 'Hover over', how, what, nil, desc, refs)
        element.hover
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      def set(container, element, how, what, value = nil, desc = '', refs = '', options = {})
        value, desc, refs, options = capture_value_desc(value, desc, refs, options) # for backwards compatibility
        code                       = build_webdriver_fetch(element, how, what, options)
        target                     = eval("#{code}")
        #TODO: Fix this!
        set_element(target, value, desc, refs, how, what)
      rescue
        failed_to_log("#{msg} '#{$!}'")
      end

      def set_element(element, value = nil, desc = '', refs = '', how = '', what = '')
        msg = element_action_message(element, "Set", how, what, nil, desc, refs)
        case element.class.to_s
          when /radio/i, /checkbox/i
            element.set
            passed_to_log(msg)
            true
          when /text_field|textfield|text_area|textarea/i
            element_set_text(element, value, desc, refs, how, what)
          else
            failed_to_log(with_caller(desc, "#{element} not supported", refs))
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def element_set_text(element, value, desc = '', refs = '', how = '', what = '')
        msg = element_action_message(element, "Set to '#{value}':", how, what, nil, desc, refs)
        element.when_present.set(value)
        if element.value == value
          passed_to_log(msg)
          true
        else
          failed_to_log("#{msg}: Found:'#{element.value}'.")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def set_text_field(browser, how, what, value, desc = '', refs = '', skip_value_check = false)
        #TODO: fix this to handle Safari password field
        msg = build_message(desc, with_caller("#{how}='#{what}' to '#{value}'"), refs)
        msg << ' (Skip value check)' if skip_value_check
        browser.text_field(how, what).when_present.set(value)
        if skip_value_check
          passed_to_log(msg)
          true
        else
          if browser.text_field(how, what).value == value
            passed_to_log(msg)
            true
          else
            failed_to_log("#{msg}: Found:'#{browser.text_field(how, what).value}'.")
          end
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def select_option(browser, how, what, which, option, desc = '', refs = '', nofail = false)
        list = browser.select_list(how, what).when_present
        msg  = build_message(desc, with_caller("from list with :#{how}='#{what} by #{which}"))
        select_option_from_list(list, which, option, msg, refs, nofail)
      rescue
        failed_to_log(unable_to)
      end

      def select_next_option_from_list(list, desc = '', refs = '')
        msg            = build_message(desc, refs)
        options        = list.options
        #This doesnt seem to account for the last option already being selected. ex. calendar with dec selected
        selected_index = list.selected_options[0].index
        if selected_index == options.length - 1
          new_index = 0
        else
          new_index = options[selected_index + 1] ? selected_index + 1 : 0
        end

        select_option_from_list(list, :index, new_index, with_caller(desc), refs)
      rescue
        failed_to_log(unable_to(msg))
      end

      def select_previous_option_from_list(list, desc = '', refs = '')
        msg            = build_message(desc, refs)
        options        = list.options
        #This doesnt seem to account for the last option already being selected. ex. calendar with dec selected
        selected_index = list.selected_options[0].index
        if selected_index == options.length - 1
          new_index = 0
        else
          new_index = options[selected_index - 1] ? selected_index - 1 : 0
        end

        select_option_from_list(list, :index, new_index, with_caller(desc), refs)
      rescue
        failed_to_log(unable_to(msg))
      end

      def select_option_from_list(list, how, what, desc = '', refs = '', nofail = false)
        msg = build_message(desc, "Select option :#{how}='#{what}'", refs)
        ok  = true
        if list
          case how
            when :text, :inner_text, :label
              list.select(what) #TODO: regex?
            when :value
              list.select_value(what) #TODO: regex?
            when :index
              list.option(:index, what.to_i).select
            else
              failed_to_log("#{msg}  Select by #{how} not supported.")
              ok = false
          end
          if ok
            passed_to_log(msg)
            true
          else
            if nofail
              passed_to_log("#{msg} Option not found. No Fail specified.")
              true
            else
              failed_to_log("#{msg} Option not found.")
            end
          end
        else
          failed_to_log("#{msg} Select list not found.")
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def option_selected?(container, how, what, which, option, desc = '', refs = '')
        list = container.select_list(how, what).when_present
        msg  = build_message(desc, with_caller("from list with :#{how}='#{what}"))
        option_selected_from_list?(list, which, option, desc, refs)
      rescue
        failed_to_log(unable_to(msg))
      end

      def option_selected_from_list?(list, which, what, desc = '', refs = '')
        msg = build_message(desc, "Option :#{which}='#{what}' is selected.", refs)
        if list.option(which, what).selected?
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def resize_browser_window(browser, width, height, offsets = @wd_vp_offsets, move_to_origin = true)
        msg = "#{__method__.to_s.humanize} to (#{width}, #{height}) with offsets (#{offsets[0]}, #{offsets[1]})"
        #browser = browser.browser if browser.respond_to?(:tag_name)
        browser.browser.driver.manage.window.resize_to(width + offsets[0], height + offsets[1])
        sleep(0.5)
        if move_to_origin
          browser.browser.driver.manage.window.move_to(0, 0)
          msg << ' and move to origin (0, 0).'
        end
        #scroll_to_top(browser)
        passed_to_log(msg)
        true
      rescue
        failed_to_log(unable_to(msg))
      end

      alias resize_window resize_browser_window

      def tab_until_focused(container, tag, how, what, class_strg = nil, desc = '', refs = '', limit = 15)
        ok     = nil
        target = get_element(container, tag, how, what, nil, with_caller(desc, "(#{limit})"), refs)
        msg    = build_message("#{tag.to_s.upcase}", "#{how}='#{what}'", "class='#{target.attribute_value('class')}'", refs)
        count  = 0
        (0..limit).each do |cnt|
          #debug_to_log("tab #{cnt}")
          if class_strg
            if target.class_name.include?(class_strg)
              passed_to_log(with_caller(msg, "(#{cnt} tabs)"))
              ok = true
              break
            end
          else
            if target.focused?
              passed_to_log(with_caller(msg, "(#{cnt} tabs)"))
              ok = true
              break
            end
          end
          container.browser.send_keys(:tab)
          count = cnt
        end

        failed_to_log(unable_to(msg, "(#{count} tabs)")) unless ok

        ok
      rescue
        failed_to_log(unable_to)
      end

      def key_until_focused(container, key, tag, how, what, class_strg = nil, desc = '', refs = '', limit = 15)
        ok     = nil
        target = get_element(container, tag, how, what, nil, with_caller(desc, "(#{limit})"), refs)
        msg    = build_message("#{key.to_s}_until_focused(): #{tag.to_s.upcase}", "#{how}='#{what}'", "class='#{target.attribute_value('class')}'", refs)
        count  = 0
        (0..limit).each do |cnt|
          #debug_to_log("tab #{cnt}")
          if class_strg
            if target.class_name.include?(class_strg)
              passed_to_log(with_caller(msg, "(#{cnt} #{key.to_s}s)"))
              ok = true
              break
            end
          else
            if target.focused?
              passed_to_log(with_caller(msg, "(#{cnt} #{key.to_s}s)"))
              ok = true
              break
            end
          end
          container.browser.send_keys(key)
          count = cnt
        end

        failed_to_log(unable_to(msg, "(#{count} #{key.to_s}s)")) unless ok

        ok
      rescue
        failed_to_log(unable_to)
      end

      def shift_tab_until_focused_in_locators(container, locators, desc = '', refs = '', limit = 15)
        tab_until_focused_in_locators(container, locators, desc, refs, 15, :shift)
      rescue
        failed_to_log(unable_to)
      end

      def tab_until_focused_in_locators(container, locators, desc = '', refs = '', limit = 15, modifier = nil)
        locator = nil
        count   = 0
        if modifier
          keys = [modifier.to_sym, :tab]
        else
          keys = :tab
        end
        (0..limit).each do |cnt|
          #debug_to_log("tab #{cnt}")

          locators.each do |loc|
            tag, how, what = parse_locator(loc)
            msg            = with_caller("#{tag.to_s.upcase}", "#{how}='#{what}'")
            code           = build_webdriver_fetch(tag, how, what)
            target         = eval(code)
            if target
              if target.focused?
                passed_to_log(with_caller(desc, msg, "(#{cnt} tabs)", refs))
                locator = loc
                break
              end
            else
              debug_to_report(build_message(desc, 'Unable to locate', msg))
            end
          end
          break if locator
          container.browser.send_keys(keys)
          count = cnt
        end

        failed_to_log(unable_to(desc, "(#{count} tabs)")) unless locator

        locator
      rescue
        failed_to_log(unable_to(desc))
      end

      def tab_until_not_focused_in_locators(container, locators, desc = '', refs = '', limit = 15, modifier = nil)
        locator = nil
        count   = 0
        if modifier
          keys = [modifier.to_sym, :tab]
        else
          keys = :tab
        end
        (0..limit).each do |cnt|
          #debug_to_log("tab #{cnt}")

          locators.each do |loc|
            tag, how, what = parse_locator(loc)
            msg            = with_caller("#{tag.to_s.upcase}", "#{how}='#{what}'")
            code           = build_webdriver_fetch(tag, how, what)
            target         = eval(code)
            if target
              if target.focused?
                debug_to_log(with_caller(desc, msg, "(#{cnt} tabs)", refs))
                locator = loc
                break
              end
            else
              debug_to_report(build_message(desc, 'Unable to locate', msg))
            end
          end
          break unless locator
          container.browser.send_keys(keys)
          count = cnt
        end

        failed_to_log(unable_to(desc, "(#{count} tabs)")) if locator

        locator
      rescue
        failed_to_log(unable_to(desc))
      end

      def type_in_text_field(element, strg, desc = '', refs = '')
        msg = build_message(desc, "Type (send_keys) '#{strg}' into text input :id=>'#{element.attribute_value('id')}'", refs)
        element.send_keys(strg)
        if element.value == strg
          passed_to_log(msg)
          true
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def send_a_key(browser, key, modifier = nil, desc = '', refs = '')
        if modifier
          msg = build_message(desc, "Sent #{modifier.upcase}+#{key.upcase} to browser", refs)
          browser.send_keys [modifier, key]
        else
          msg = build_message(desc, "Sent #{key.upcase} to browser", refs)
          browser.send_keys key
        end
        message_to_report(msg)
      end

      def send_page_down(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :page_down, modifier, desc, refs)
      end

      alias press_page_down send_page_down

      def send_page_up(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :page_up, modifier, desc, refs)
      end

      alias press_page_up send_page_up

      def send_spacebar(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :space, modifier, desc, refs)
      end

      alias press_spacebar send_spacebar
      alias press_space send_spacebar
      alias send_space send_spacebar

      def send_enter(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :enter, modifier, desc, refs)
      end

      alias press_enter send_enter

      def send_tab(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :tab, modifier, desc, refs)
      end

      alias press_tab send_tab

      def send_shift_tab(browser, desc = '', refs = '', modifier = :shift)
        send_a_key(browser, :tab, modifier, desc, refs)
      end

      alias press_shift_tab send_shift_tab

      def send_up_arrow(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :arrow_up, modifier, desc, refs)
      end

      alias press_up_arrow send_up_arrow

      def send_down_arrow(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :arrow_down, modifier, desc, refs)
      end

      alias press_down_arrow send_down_arrow

      def send_right_arrow(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :arrow_right, modifier, desc, refs)
      end

      alias press_right_arrow send_right_arrow

      def send_left_arrow(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :arrow_left, modifier, desc, refs)
      end

      alias press_left_arrow send_left_arrow

      def send_escape(browser, desc = '', refs = '', modifier = nil)
        send_a_key(browser, :escape, modifier, desc, refs)
      end

      alias press_escape send_escape

    end

    module Browser

      def open_ie
        begin
          proxy = Selenium::WebDriver::Proxy.new(
              :type => :pac,
              :pac  => 'http://pac.wellsfargo.net/'
          )
        rescue
          debug_to_log(unable_to)
        end

        caps = Selenium::WebDriver::Remote::Capabilities.internet_explorer(
            #:nativeEvents => false,
            #'nativeEvents' => false,
            # :initialBrowserUrl                                   => 'about:blank',
            :proxy                       => proxy,
            :requireWindow_Focus         => true,
            :enablePersistentHover       => false,
            # :enableElementCacheCleanup   => true,
            :ignoreProtectedModeSettings => true,
            # :introduceFlakinessByIgnoringSecurityDomains         => true,
            # :introduceInstabilityByIgnoringProtectedModeSettings => true,
            :unexpectedAlertBehaviour    => 'ignore'
        )
        Watir::Browser.new(:ie, :desired_capabilities => caps)
      rescue
        failed_to_log(unable_to)
      end

      def activate_first_window(browser)
        browser.driver.switch_to.window(browser.driver.window_handles[0])
      rescue
        failed_to_log(unable_to)
      end

      def go_to_url(browser, url = nil)
        if url
          @myURL = url
        end
        message_to_report(with_caller("URL: #{@myURL}"))
        browser.goto(@myURL)
        sleep(1)
        if browser.alert.exists?
          debug_to_report(with_caller('Alert encountered.', "#{browser.alert.text}"))
          browser.alert.dismiss
        end
        true
      rescue
        fatal_to_log("Unable to navigate to '#{@myURL}': '#{$!}'")
      end

    end

    module DragAndDrop

      def remove_focus(container, element, desc = '', refs = '', tab_twice = false)
        msg = build_message(desc, refs)
        ok  = true
        if element.focused?
          debug_to_log('element has focus')
          element.fire_event('onblur')
          debug_to_log("Fired 'onblur' event")
          which = :blur
          if element.focused?
            container.send_keys(:tab)
            debug_to_log('Sent tab')
            which = :tab
            if tab_twice
              container.send_keys(:tab)
              debug_to_log('Sent second tab')
              which = :tab
            end
            if element.focused?
              container.send_keys(:enter)
              debug_to_log('Sent enter')
              which = :enter
            end
          end
          if element.focused?
            failed_to_log(unable_to(msg))
            which = :fail
            ok    = false
          else
            passed_to_log(with_caller("#{element.tag_name}", msg))
          end
        else
          debug_to_log('Element does not have focus to remove.')
          which = :already
        end
        begin
          if @focus_moves
            @focus_moves[:remove][which] += 1
            if which == :tab and tab_twice
              @focus_moves[:remove][which] += 1
            end
          end
        rescue
          debug_to_log(with_caller("'#{$!}'", msg))
        end
        ok
      rescue
        failed_to_log(unable_to(msg))
      end

      def return_focus(container, element, desc = '', refs = '')
        msg = build_message(desc, refs)
        ok  = true
        if element.focused?
          debug_to_log('Element already has focus.')
          which = :already
        else
          element.fire_event('onclick')
          debug_to_log("Fired 'onclick' event")
          which = :onclick
          unless element.focused?
            element.fire_event('onfocus')
            debug_to_log("Fired 'onfocus' event")
            which = :onfocus
            unless element.focused?
              element.focus
              debug_to_log('Called focus method')
              which = :focus
              unless element.focused?
                element.click
                debug_to_log('Called click method')
                which = :click
                unless element.focused?
                  container.send_keys([:shift, :tab])
                  debug_to_log('Sent shift tab')
                  which = :shift_tab
                end
              end
            end
          end
          if element.focused?
            passed_to_log(with_caller("#{element.tag_name}", msg))
          else
            failed_to_log(unable_to(msg))
            which = :fail
            ok    = false
          end
        end
        begin
          @focus_moves[:remove][which] += 1 if @focus_moves
        rescue
          debug_to_log(with_caller("'#{$!}'", msg))
        end
        ok
      rescue
        failed_to_log(unable_to(msg))
      end

      #TODO: needs work: should succeed if browser is other container or element
      def get_browser_coord(browser, dbg = @debug_dsl)
        title = browser.title
        x, y  = browser.position
        w, h  = browser.size
        if dbg
          debug_to_log("\n\t\tBrowser #{browser.inspect}\n"+
                           "\t\tdimensions:   x: #{w} y: #{h}"+
                           "\t\tscreen offset x: #{x} y: #{y}")
        end
        [x, y, w, h]
      end

      def get_element_screen_coordinates(browser, element, dbg = @debug_dsl)
        hash                            = Hash.new
        bx, by                          = browser.position
        ox, oy                          = window_viewport_offsets(browser)
        rect                            = element.bounding_client_rectangle
        w                               = rect['width']
        h                               = rect['height']
        hash['width']                   = w
        hash['height']                  = h
        xc                              = rect['left']
        yc                              = rect['top']
        xcc                             = xc + w/2
        ycc                             = yc + h/2
        # screen offset:
        xs                              = bx + ox + xc - 1
        ys                              = by + oy + yc - 1
        hash['left']                    = xs
        hash['top']                     = ys
        # screen center:
        xsc                             = xs + w/2
        ysc                             = ys + h/2
        hash['screen_center_left']      = xsc
        hash['screen_center_top']       = ysc
        xslr                            = xs + w
        yslr                            = ys + h
        hash['screen_lower_right_left'] = xslr
        hash['screen_lower_right_top']  = xs
        if dbg
          debug_to_log(
              "\n\t\tElement: #{element.inspect}"+
                  "\n\t\tbrowser screen offset: x: #{bx} y: #{by}"+
                  "\n\t\t           dimensions: x: #{w} y: #{h}"+
                  "\n\t\t         client offset x: #{xc} y: #{yc}"+
                  "\n\t\t         screen offset x: #{xs} y: #{ys}"+
                  "\n\t\t         client center x: #{xcc} y: #{ycc}"+
                  "\n\t\t         screen center x: #{xsc} y: #{ysc}"+
                  "\n\t\t    screen lower right x: #{xslr} y: #{yslr}")
        end
        hash
      end

      def viewport_size(browser, use_body = false)
        browser = browser.browser if browser.respond_to?(:tag_name)
        if @targetBrowser.abbrev == 'IE' and @browserVersion.to_i < 9
          x, y = insert_viewport_div(browser)
        else
          bx = browser.body.attribute_value('clientWidth')
          by = browser.body.attribute_value('clientHeight')
          wx = browser.execute_script('return window.innerWidth')
          wy = browser.execute_script('return window.innerHeight')
          # debug_to_report(with_caller('body client:', "[#{bx}, #{by}]",
          #                             'window inner:', "[#{wx}, #{wy}]", "use_body: #{use_body}", '*** waft023 ***')) if $waft_debug
          if use_body
            x = bx
            y = by
          else
            x = wx
            y = wy
          end
        end

        [x, y]

      rescue => e
        unless rescue_me(e, __method__, "#{__method__}(browser, #{use_body})")
          raise e
        end
      end

      def screen_size(browser)
        [browser.execute_script('return screen.width'),
         browser.execute_script('return screen.height')]
      rescue => e
        unless rescue_me(e, __method__, "#{__method__}(browser)")
          raise e
        end
      end

      def screen_available_size(browser)
        [browser.execute_script('return screen.availWidth'),
         browser.execute_script('return screen.availHeight')]
      rescue => e
        unless rescue_me(e, __method__, "#{__method__}(browser)")
          raise e
        end
      end

      def insert_viewport_div(browser)
        browser.execute_script(
            'var test = document.createElement( "div" );' +
                'test.style.cssText = "position: fixed;top: 0;left: 0;bottom: 0;right: 0;"; ' +
                'test.id = "awetest-temp-viewport"; ' +
                'document.documentElement.insertBefore( test, document.documentElement.firstChild ); '
        )
        viewport = browser.div(:id, 'awetest-temp-viewport')
        x        = browser.execute_script("return arguments[0].offsetWidth", viewport)
        y        = browser.execute_script("return arguments[0].offsetHeight", viewport)
        browser.execute_script("document.documentElement.removeChild( arguments[0] )", viewport)
        [x, y]
      end

      def scroll_into_view(container, element, how, what, desc = '', refs = '', options = {})
        msg   = build_message(desc, "#{__method__.to_s.humanize} :#{element.to_s.upcase} :#{how}='#{what}'", refs)
        code  = build_webdriver_fetch(element, how, what, options)
        point = eval("#{code}.when_present.wd.location_once_scrolled_into_view")
        if point
          passed_to_log(msg)
          [point.x, point.y]
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(msg))
      end

      def scroll_element_into_view(element, desc = '', refs = '')
        msg   = build_message(desc, "#{__method__.to_s.humanize}", refs)
        point = element.wd.location_once_scrolled_into_view
        if point
          passed_to_log(msg)
          [point.x, point.y]
        else
          failed_to_log(msg)
        end
      rescue
        failed_to_log(unable_to(desc))
      end

      def scroll_to(browser, param, desc = '', refs = '')
        ok = true
        case param
          when Array
            what = nice_array(param)
          when param.respond_to?(:tag_name)
            what = translate_tag_name(param)
          else
            what = "#{param}"
        end

        #Thanks to Alex Rodionov (p0deje)
        args = case param
                 when :top, :start
                   'window.scrollTo(0, 0);'
                 when :center
                   'window.scrollTo(document.body.scrollWidth / 2, document.body.scrollHeight / 2);'
                 when :bottom, :end
                   'window.scrollTo(0, document.body.scrollHeight);'
                 when Watir::Element, Watir::WhenPresentDecorator
                   ['arguments[0].scrollIntoView();', param]
                 when Array
                   ['window.scrollTo(arguments[0], arguments[1]);', Integer(param[0]), Integer(param[1])]
                 else
                   if param.respond_to?(:tag_name)
                     target = param.element
                     ['arguments[0].scrollIntoView();', target]
                   else
                     failed_to_log(build_message(with_caller(desc, what), refs, "Don't know how to scroll to: #{param.to_s}!"))
                     ok = false
                   end
               end

        if ok
          browser.execute_script(*args)
        end
        ok
      rescue
        failed_to_log(unable_to(build_message(desc, what, refs)))
      end

      def scroll_in_element(scrollable, direction, amount, desc = '', refs = '')
        #TODO remove in favor of scroll_in_scrollable
        ortho  = ''
        pixels = amount
        case direction
          when :up, :top
            ortho = 'Top'
          when :down
            ortho  = 'Top'
            pixels = -amount
          when :left
            ortho = 'Left'
          when :right
            ortho  = 'Left'
            pixels = -amount
          else
            failed_to_log(with_caller("Invalid direction '#{direction}'"))
        end
        debug_to_log(with_caller(desc, ortho, "#{scrollable}", "#{pixels}")) if @debug_dsl
        scrollable.browser.execute_script("return arguments[0].scroll#{ortho} = arguments[1]", scrollable, pixels)

          # Scroll inside web element vertically (e.g. 100 pixel)
          # js.executeScript("arguments[0].scrollTop = arguments[1];",driver.findElement(By.id("<div-id>")), 100);

          # eula = dr.find_element_by_id('eulaFrame')
          # dr.execute_script('arguments[0].scrollTop = arguments[0].scrollHeight', eula)

          # JavascriptExecutor jse = (JavascriptExecutor) localDriver;
          # //locate web element you need for scroll and its height
          #                               WebElement element = localDriver.findElement(By.id("DIV_element"));
          #                               String blockHeight = "return arguments[0].offsetHeight";
          #
          #                               String myscript = "arguments[0].scrollTop"+jse.executeScript(blockHeight,element);
          #
          #                               element.click();
          #                               pause(100);
          #                               jse.executeScript(myscript, element);

          # If you want to scroll inner div element, not window you can try this below code:
          #                                                                                //Get div element having scroll bar you want to do
          #   WebElement scrollArea = driver.findElement(By.xpath("//"));
          #   // Initialize Javascript executor
          #   JavascriptExecutor js = (JavascriptExecutor) driver;
          #   // Scroll inside web element vertically (e.g. 1000 pixel)
          #   js.executeScript("arguments[0].scrollTop = arguments[1];",scrollArea, 1000);
          #   Thread.sleep(1000);
          #   // do something (ex. choose an item in list ...)
          #   Good luck! hihi
      rescue
        failed_to_log(unable_to(ortho, pixels))
      end

      def scroll_in_scrollable(scrollable, amount, desc = '', refs = '', direction = :top)
        ortho = ''
        amount
        case direction
          when :up, :top, :down, /up/i, /top/i, /down/i
            ortho = 'Top'
          when :left, :right, /left/i, /right/i
            ortho = 'Left'
          else
            failed_to_log(with_caller("Invalid direction '#{direction}'", refs))
        end
        debug_to_log(with_caller(desc, ortho, "#{scrollable}", "#{amount}px")) if @debug_dsl
        scrollable.browser.execute_script("return arguments[0].scroll#{ortho} = arguments[1]", scrollable, amount)

      rescue
        failed_to_log(unable_to(ortho, amount))
      end

      def element_in_view_in_scrollable(element, scrollable, desc = '')

        element_dims    = get_element_dimensions(element.browser, element, with_caller(desc, 'Element'))
        scrollable_dims = get_element_dimensions(scrollable.browser, scrollable, with_caller(desc, 'Scrollable'))

        element_o_top    = element_dims[:offsetTop]
        element_o_height = element_dims[:offsetHeight]

        scrollable_o_top    = scrollable_dims[:offsetTop]
        scrollable_o_height = scrollable_dims[:offsetHeight]

        scrollable_s_top = scrollable_dims[:scrollTop]

        top_in_view    = element_o_top >= scrollable_s_top
        bottom_in_view = (element_o_top + element_o_height) <= scrollable_o_height + scrollable_s_top

        debug_to_log(with_caller(desc, "in view: top: #{top_in_view}, bottom: #{bottom_in_view}")) if @debug_dsl
        (top_in_view and bottom_in_view)

      rescue
        failed_to_log(unable_to(direction, destination))
      end

      def window_viewport_offsets(browser)
        x = 0
        y = 0

        if $mobile
          debug_to_log(with_caller('Not supported for mobile browsers'))
        else
          browser = browser.browser if browser.respond_to?(:tag_name)
          wd_dim  = browser.window.size
          vp_dim  = viewport_size(browser)
          x       = (wd_dim.width - vp_dim[0])
          y       = (wd_dim.height - vp_dim[1])
          y       += 1 if @targetBrowser.abbrev == 'FF'
        end

        [x, y]
      rescue
        failed_to_log(unable_to)
      end

      def window_dimensions(browser)
        browser = browser.browser if browser.respond_to?(:tag_name)
        wd_dim  = browser.window.size
        wd_pos  = browser.window.position
        vp_dim  = viewport_size(browser)
        off_x   = (wd_dim.width - vp_dim[0])
        off_y   = (wd_dim.height - vp_dim[1])
        off_y   += 1 if @targetBrowser.abbrev == 'FF'

        just_inside_x = wd_pos.x + wd_dim.width - off_x - 3
        just_inside_y = wd_pos.y + off_x + 3

        debug_to_log(with_caller("\nposition: [#{wd_pos.x},#{wd_pos.y}]",
                                 "\nsize:     [#{wd_dim.width},#{wd_dim.height}] ",
                                 "\nviewport: [#{vp_dim[0]},#{vp_dim[1]}]",
                                 "\noffsets:  [#{off_x},#{off_y}]",
                                 "\njust_inside: [#{just_inside_x},#{just_inside_y}]"
                     ))
        [wd_pos.x, wd_pos.y,
         wd_dim.width, wd_dim.height,
         vp_dim[0], vp_dim[1],
         off_x, off_y,
         just_inside_x, just_inside_y]
      rescue
        failed_to_log(unable_to)
      end

      def mouse_outside_of_element(element, desc = '', refs = '')
        x, y    = get_outside_location(element, desc, refs, 5, 'top', 'right')
        browser = element.browser
        if @browserAbbrev == 'FF'
          browser.driver.mouse.move_to(element, x, y)
        else
          browser.driver.mouse.move_to(browser, x, y)
        end
        browser.driver.mouse.down
        browser.driver.mouse.up
      rescue
        failed_to_log(unable_to)
      end

      def mouse_to_browser_edge(container, offset_x = 8, offset_y = 8)
        # x, y = window_dimensions(container)[4, 2]
        dims         = get_element_dimensions(container, container.browser.body)
        client_width = dims[:clientWidth]
        debug_to_log(with_caller("\n#{dims.to_yaml}"))

        to_x = client_width - offset_x
        to_y = offset_y

        begin
          container.driver.mouse.move_to(container.driver[:tag_name => 'body'], to_x, to_y)
        rescue => e
          if e.message =~ 'Unable to Mouse To Browser Edge'
            debug_to_log(with_caller(e))
          else
            raise e
          end
        end
        container.driver.mouse.down
        container.driver.mouse.up
      rescue
        failed_to_log(unable_to)
      end

      def set_viewport_size(browser, width, height, offsets = @wd_vp_offsets, move_to_origin = true, use_body = false, desc = '', refs = '')
        # TODO: viewport offsets differ between browser versions and whether windows is running Aero desktop
        if $mobile
          debug_to_log(with_caller('Not supported for mobile browsers'))
        else
          offsets = window_viewport_offsets(browser.browser) unless offsets
          resize_browser_window(browser.browser, width, height, offsets, move_to_origin)
          sleep(0.5)
          msg          = build_message(desc, "viewport (#{width}, #{height})",
                                       "(offsets (#{offsets[0]}, #{offsets[1]}))")
          act_x, act_y = viewport_size(browser.browser, use_body)
          if width == act_x.to_i and height == act_y.to_i
            if @targetBrowser.abbrev == 'FF'
              debug_to_log(with_caller(msg, 'FF', refs))
            else
              debug_to_log(with_caller(msg, refs))
            end
            true
          else
            if @targetBrowser.abbrev == 'FF'
              debug_to_report(with_caller(msg, "FF Found (#{act_x}, #{act_y})", refs, '*** waft023 ***'))
            else
              debug_to_report(with_caller(msg, "Found (#{act_x}, #{act_y})", refs, '*** waft023 ***'))
            end
          end
        end
      rescue
        failed_to_log(unable_to)
      end

      # @deprecated
      def get_viewport_to_win_diff(browser)
        window_viewport_offsets(browser)[0]
      end

      def overlay?(inner, outer, side = :bottom)
        i_dims = inner.bounding_client_rectangle
        o_dims = outer.bounding_client_rectangle
        case side
          when :bottom
            overlay = i_dims['bottom'] > o_dims['top']
          when :top
            overlay = i_dims['top'] > o_dims['top']
          when :left
            overlay = i_dims['left'] > o_dims['right']
          when :right
            overlay = i_dims['right'] > o_dims['right']
          when :inside
            overlay =
                !(i_dims['top'] > o_dims['top'] and
                    i_dims['right'] < o_dims['right'] and
                    i_dims['left'] > o_dims['left'] and
                    i_dims['bottom'] < o_dims['bottom']
                )
          else
            overlay =
                (i_dims['top'] > o_dims['bottom'] or
                    i_dims['right'] < o_dims['left'] or
                    i_dims['left'] > o_dims['right'] or
                    i_dims['bottom'] < o_dims['top']
                )
        end
        overlay
      rescue
        failed_to_log("Unable to determine overlay. '#{$!}'")
      end

      def get_element_dimensions(container, element, desc = '', refs = '', dbg = nil)
        hash                = Hash.new
        #hash[:text]         = element.text
        #hash[:unit]         = element
        hash[:clientLeft]   = element.attribute_value('clientLeft').to_i
        hash[:clientTop]    = element.attribute_value('clientTop').to_i
        hash[:clientWidth]  = element.attribute_value('clientWidth').to_i
        hash[:clientHeight] = element.attribute_value('clientHeight').to_i
        #hash[:offsetParent] = element.attribute_value('offsetParent')
        hash[:offsetLeft]   = element.attribute_value('offsetLeft').to_i
        hash[:offsetTop]    = element.attribute_value('offsetTop').to_i
        hash[:offsetWidth]  = element.attribute_value('offsetWidth').to_i
        hash[:offsetHeight] = element.attribute_value('offsetHeight').to_i
        hash[:scrollLeft]   = element.attribute_value('scrollLeft').to_i
        hash[:scrollTop]    = element.attribute_value('scrollTop').to_i
        hash[:scrollWidth]  = element.attribute_value('scrollWidth').to_i
        hash[:scrollHeight] = element.attribute_value('scrollHeight').to_i
        if desc.length > 0
          debug_to_log("#{desc} #{refs}\n#{hash.to_yaml}") if @debug_dsl or dbg
        end
        hash
      rescue
        failed_to_log(unable_to)
      end

      def get_element_dimensions1(container, element, desc = '', refs = '', dbg = nil)
        hash                = Hash.new
        #hash[:text]         = element.text
        #hash[:unit]         = element
        hash[:clientLeft]   = container.execute_script("return arguments[0].clientLeft", element)
        hash[:clientTop]    = container.execute_script("return arguments[0].clientTop", element)
        hash[:clientWidth]  = container.execute_script("return arguments[0].clientWidth", element)
        hash[:clientHeight] = container.execute_script("return arguments[0].clientHeight", element)
        #hash[:offsetParent] = container.execute_script("return arguments[0].offsetParent", element)
        hash[:offsetLeft]   = container.execute_script("return arguments[0].offsetLeft", element)
        hash[:offsetTop]    = container.execute_script("return arguments[0].offsetTop", element)
        hash[:offsetWidth]  = container.execute_script("return arguments[0].offsetWidth", element)
        hash[:offsetHeight] = container.execute_script("return arguments[0].offsetHeight", element)
        hash[:scrollLeft]   = container.execute_script("return arguments[0].scrollLeft", element)
        hash[:scrollTop]    = container.execute_script("return arguments[0].scrollTop", element)
        hash[:scrollWidth]  = container.execute_script("return arguments[0].scrollWidth", element)
        hash[:scrollHeight] = container.execute_script("return arguments[0].scrollHeight", element)
        if desc.length > 0
          debug_to_log("#{desc} #{refs}\n#{hash.to_yaml}") if @debug_dsl or dbg
        end
        hash
      rescue
        failed_to_log(unable_to)
      end

      def get_outside_location(element, desc = '', refs = '', offset = 10, vertical = 'top', horizontal = 'right')
        dimensions = get_element_dimensions(element.browser, element, with_caller(desc), refs)

        if vertical =~ /top/i
          y = dimensions[:offsetTop].to_i
        else
          y = dimensions[:offsetTop].to_i + dimensions[:offsetHeight].to_i
        end
        if horizontal =~ /right/i
          x = dimensions[:offsetLeft].to_i + dimensions[:offsetWidth].to_i + offset
        else
          x = dimensions[:offsetLeft].to_i - offset
        end

        [x, y]
      rescue
        failed_to_log(unable_to)
      end

      def get_default_font_size(container)
        size = container.browser.execute_script(
            'var test = document.createElement( "span" );' +
                'test.style.cssText = "display:inline-block; padding:0; line-height:1; position:absolute; visibility:hidden; font-size:1em;"; ' +
                'test.id = "awetest-temp-span"; ' +
                'test.appendChild(document.createTextNode("M")); ' +
                'document.body.appendChild(test); ' +
                'var fs= [test.offsetWidth, test.offsetHeight]; ' +
                # 'document.body.removeChild(test); ' +
                'return fs; '
        )
        size << container.browser.body.style('line-height')
        $default_font_size = size[1]
        size
      end

    end


  end
end

module Watir
  class Element

    # // Get the color value of .element:before
    # var color = window.getComputedStyle(
    #     document.querySelector('.element'), ':before'
    # ).getPropertyValue('color');
    #
    # // Get the content value of .element:before
    # var content = window.getComputedStyle(
    #     document.querySelector('.element'), ':before'
    # ).getPropertyValue('content');


    def list_attributes
      attributes = browser.execute_script(%Q[
                var s = [];
                var attrs = arguments[0].attributes;
                for (var l = 0; l < attrs.length; ++l) {
                    var a = attrs[l]; s.push(a.name + ': ' + a.value);
                } ;
                return s;],
                                          self
      )
      hash       = {}
      attributes.each do |entry|
        attr, value = entry.split(/:\s+/, 2)
        hash[attr]  = value
      end
      hash
    end

    def styles(list = []) # no js method 'styles'
      hash = Hash.new
      list.each do |prop|
        hash[prop] = style(prop)
      end
      hash
    end

    def attribute_values
      hash = Hash.new
      ['id', 'offsetParent', 'style', 'currentstyle',
       'offsetHeight', 'offsetWidth', 'offsetLeft', 'offsetTop',
       'clientHeight', 'clientWidth', 'clientLeft', 'clientTop',
       'scrollHeight', 'scrollWidth', 'scrollLeft', 'scrollTop',
       'className', 'resizable',
       'visible', 'sourceIndex'].each do |attr|
        hash[attr] = attribute_value(attr)
      end
      hash
    end

    def dimensions
      hash = bounding_client_rectangle
      [hash['width'], hash['height']]
    end

    def bounding_client_rectangle
      assert_exists
      self.browser.execute_script('return arguments[0].getBoundingClientRect()', self)
    end

    ###################################
    def bottom_edge
      bounding_client_rectangle['bottom']
    end

    ###################################
    def top_edge
      bounding_client_rectangle['top']
    end

    ###################################
    def left_edge
      bounding_client_rectangle['left']
    end

    ###################################
    def right_edge
      bounding_client_rectangle['right']
    end

    ###################################
    def client_offset
      hash = bounding_client_rectangle
      [hash['left'], hash['top']]
    end


  end
end

class Hash

  def depth
    a = self.to_a
    d = 1
    while (a.flatten!(1).map! { |e| (e.is_a? Hash) ? e.to_a.flatten(1) : (e.is_a? Array) ? e : nil }.compact!.size > 0)
      d += 1
    end
    d
  end

  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end

end

class String

  def -(other)
    self.index(other) == 0 ? self[other.size..self.size] : nil
  end
end

class HTMLValidationResult

  def validate
    require 'fileutils'

    html_file = 'tidy_this.html'
    err_file  = 'tidy_err.txt'
    done_file = 'tidy_done.html'
    # FileUtils.touch(err_file) unless File.exists?(err_file)

    puts "#{__method__}: #{Dir.pwd}"
    html = File.new(html_file, 'w')
    html.puts(@html)
    html.close

    cmd = "tidy -quiet -f #{err_file} -o #{done_file} #{html_file}"

    out = `#{cmd}`
    puts out

    errs   = File.open(err_file)
    result = errs.read
    errs.close
    result

  end

end

# class Module
#
#   def timed(name)
#     original_method = instance_method(name)
#     define_method(name) do |*args|
#       puts "Calling #{name} with #{args.inspect}."
#       original_method.bind(self).call(*args)
#       puts "Completed #{name}."
#     end
#   end
#
# end
