module ValidateHtml

  include W3CValidators

  def validate_html(container, page, force_browser = false, filter = true)
    mark_testlevel(page)
    require 'iconv'
    require 'diff/lcs'

    if force_browser
      html = container.browser.html
    else
      html = container.html
    end

    url = container.browser.url

    html_with_line_feeds =  html.gsub("\n", '').gsub('>', ">\n")
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
    ic      = Iconv.new("#{encoding}//IGNORE", encoding)
    encoded = ''

    html_array  = html.split(/\n/)
    line_number = 1

    html_array.each do |line|
      valid_string = ic.iconv(line + ' ')[0..-2]
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

  def load_html_validation_filters(file = @refs_spec)
    sheet         = 'HTML Validation Filters'
    workbook      = file =~ /\.xlsx$/ ? Excelx.new(file) : Excel.new(file)
    @html_filters = Hash.new

    sheet_index = find_sheet_with_name(workbook, "#{sheet}")
    if sheet_index > -1
      debug_to_log("Loading worksheet '#{sheet}'.")
      workbook.default_sheet = workbook.sheets[sheet_index]

      columns = Hash.new

      1.upto(workbook.last_column) do |col|
        columns[workbook.cell(1, col).to_sym] = col
      end

      2.upto(workbook.last_row) do |line|
        identifier                = workbook.cell(line, columns[:identifier])
        validator                 = workbook.cell(line, columns[:validator])
        pattern                   = workbook.cell(line, columns[:pattern])
        action                    = workbook.cell(line, columns[:action])
        alt_pattern               = workbook.cell(line, columns[:alt_pattern])
        alt_action                = workbook.cell(line, columns[:alt_action])
        script                    = workbook.cell(line, columns[:script])
        head                      = workbook.cell(line, columns[:head])
        meta                      = workbook.cell(line, columns[:meta])
        body                      = workbook.cell(line, columns[:body])
        frame                     = workbook.cell(line, columns[:frame])
        fragment                  = workbook.cell(line, columns[:fragment])
        report_more               = workbook.cell(line, columns[:report_more])
        description               = workbook.cell(line, columns[:description])

        # pattern = pattern ? Regexp.escape(pattern) : nil
        # alt_pattern = alt_pattern ? Regexp.escape(alt_pattern) : nil

        @html_filters[validator] = Hash.new unless @html_filters[validator]

        @html_filters[validator][identifier] = {
            :validator   => validator,
            :pattern     => pattern,
            :action      => action,
            :alt_pattern => alt_pattern,
            :alt_action  => alt_action,
            :script      => script,
            :head        => head,
            :meta        => meta,
            :body        => body,
            :frame       => frame,
            :fragment    => fragment,
            :report_more => report_more,
            :description => description }
      end
    else
      failed_to_log("Worksheet '#{sheet}' not found #{file}")
    end

    @html_error_references = Hash.new

    sheet       = 'HTML Error References'
    sheet_index = find_sheet_with_name(workbook, "#{sheet}")
    if sheet_index > -1
      debug_to_log("Loading worksheet '#{sheet}'.")
      workbook.default_sheet = workbook.sheets[sheet_index]

      columns = Hash.new

      1.upto(workbook.last_column) do |col|
        columns[workbook.cell(1, col).to_sym] = col
      end

      2.upto(workbook.last_row) do |line|
        validator                       = workbook.cell(line, columns[:validator])
        pattern                         = workbook.cell(line, columns[:pattern])
        reference                       = workbook.cell(line, columns[:reference])
        component                       = workbook.cell(line, columns[:component])
        alm_df                          = workbook.cell(line, columns[:alm_df])
        jira_ref                        = workbook.cell(line, columns[:jira_ref])
        description                     = workbook.cell(line, columns[:description])

        # pattern                         = pattern ? Regexp.escape(pattern) : nil

        @html_error_references[pattern] = {
            :validator   => validator,
            :reference   => reference,
            :component   => component,
            :alm_df      => alm_df,
            :jira_ref    => jira_ref,
            :description => description }
      end
    else
      failed_to_log("Worksheet '#{sheet}' not found #{file}")
    end

    [@html_filters, @html_error_references]
  rescue
    failed_to_log(unable_to)
  end

end
