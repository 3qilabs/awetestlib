module Awetestlib
  # Report generator for Awetestlib.
  class NewHtmlReport

    RDTL = '@dtl@'
    RENV = '@env@'
    RSMY = '@smy@'
    RFTR = '@ftr@'
    RSTP = '@stp@'
    RPGL = '@pgl@'

    attr_accessor :report_name,
                  :html_file_name,
                  :json_file_name,
                  :report_summary,
                  :report_header,
                  :report_environment,
                  :report_setup,
                  :report_page_load,
                  :report_detail,
                  :report_footer,
                  :json_content,
                  :line_no,
                  :me,
                  :browser,
                  :page_load #,
    # :col_1_dtl,
    # :col_2_dtl,
    # :col_3_dtl,
    # :col_4_dtl

    # TODO: split the json and html reports to separate classes
    # Initialize the report class
    # @private
    def initialize(report_name, report_dir, browser, ts = nil, report_class = nil, page_load = true) #, options = {})

      @page_load = page_load
      @browser = browser

      if report_class
        puts report_class.instance_variables.to_yaml
        @report_name    = report_class.report_name
        @html_file_name = report_class.html_file_name
        @json_file_name = report_class.json_file_name
        @json_content   = report_class.json_content
        @line_no        = report_class.line_no
      else
        rpt_time            = "#{$begin_time.strftime('%Y%m%d_%H%M%S')}"
        self.html_file_name = File.join(report_dir, "#{report_name}_#{rpt_time}.html")
        self.json_file_name = File.join(report_dir, "#{report_name}_#{rpt_time}.json")
      end

    end

    def set_col_widths
      @four_col_result_width   = @four_col_result_width || '5%'
      @four_col_step_width     = @four_col_step_width || '66%'
      @four_col_location_width = @four_col_location_width || '24%'
      @four_col_duration_width = @four_col_duration_width || '5%'

      @one_col_message_width = '100%'

      @two_col_desc_width  = '70%'
      @two_col_value_width = '30%'

      @three_col_desc_width     = '70%'
      @three_col_location_width = '25%'
      @three_col_duration_width = '5%'
    end

    # Create a report
    # @private
    def create_report(page_load = false)

      set_col_widths

      begin_html
      begin_summary
      begin_environment
      begin_setup
      begin_page_load if page_load
      begin_detail
      begin_footer

      if @json_content
        capture_legacy_json(@json_content)
      else
        init_json
      end

    end

    def init_json
      @json_content                = {}
      @json_content['report_type'] = 'Awetestlib Report'
      @json_content['Data_order']  = 'message, location, result, level, Time.now, line' #, duration'
      @line_no                     = 1
    end

    def capture_legacy_json(json = {})
      unless json.empty?
        json.each_key do |key|
          if json[key].is_a?(Array)
            message = json[key][0] || ''
            if message =~ /^>>/
              if message =~ /Running/
                add_to_environment('', json[key][3], json[key][2], json[key][0])
                # else
                #   add_to_summary('', json[key][3], json[key][2], json[key][0])
              end
            else
              add_to_detail('', json[key][3], json[key][2], json[key][0], json[key][2])
            end
          end
        end
      end
    end

    def begin_html
      rpt_nice_time  = "#{$begin_time.strftime('%m/%d/%Y @ %H:%M:%S %Z')}"
      nice_name      = @report_name.humanize

      # Format the header of the HTML report
      @report_header = '<html>
<head>
<meta content=text/html; charset=ISO-8859-1 http-equiv=content-type>
<title>Awetest: ' + @browser + ' ' + nice_name + '</title>
<style type=text/css>
        table {
            font-family: Verdana, sans-serif;
            font-size: 11px;
            font-weight: normal;
        }

        td, th {
            border: 1px solid #858585;
        }

        .report_title {
            border: none;
            font-size: 13px;
            font-weight: bold;
        }

        .report_body {
            border-collapse: collapse;
            border: 1px solid #858585;
        }

        .environment_description {
            padding-left: 8%;
        }

        .summary_description {
            padding-left: 2%;
            width: ' + @two_col_desc_width + '
        }

        .step_description {
            padding-left: 2%;
            width: ' + @four_col_step_width + '
        }

        .summary_value {
            alignment: center;
            width: ' + @two_col_value_width + '
        }

        .summary_divider, .detail_divider {
            border: none;
            background-color: #E2F4FE;
            font-size: 12px;
            font-weight: bold;
        }

        .divider_cell {
            border-top: 1px solid #858585;
            border-bottom: 1px solid #858585;
            padding-left: 3px;
        }

        .location {
            text-align: center;
            font-size: 10px;
            border-right: 1px solid #858585;
            width: ' + @four_col_location_width + '
        }

        .duration {
            text-align: center;
            width: ' + @four_col_duration_width + '
        }

        .section_divider {
            border: 1px solid #858585;
            background-color: #858585;
            font-size: 13px;
            font-weight: bold;
            text-align: center;
            color: white;
        }

        .instance_divider {
            border: 1px solid #CCCCCC;
            background-color: #CCCCCC;
        }

        .result_level {
            font-weight: normal;
            font-size: 11px;
            text-align: center;
            color: green;
            border-left: 1px solid #858585;
            width: ' + @four_col_result_width + '
        }

        .result_passed {
            font-weight: bold;
            font-size: 12px;
            text-align: center;
            color: green;
            width: ' + @four_col_result_width + '
        }

        .result_failed {
            font-weight: bold;
            font-size: 12px;
            text-align: center;
            color: #0000EE;
            background-color: #EEC8C8;
            width: ' + @four_col_result_width + '
        }

        .step_row {
        }

        .title {
            font-size: 30px;
            font-weight: bold;
            align: left;
            color: #000000;
        }

        .normal_text {
        }

        .large_text {
            font-size: 13px;
            font-weight: normal;
        }

        .border {
            border: 1px solid #000000;
        }

</style>
</head>
<body>
<br>
<table width=100% border=0 cellpadding=2 cellspacing=2>
  <tbody>
  <tr>
    <td class=report_title>
      <table width=100% border=0 cellpadding=2 cellspacing=2>
        <tbody>
          <tr align="center">
            <td  class="report_title" width=15%>&nbsp;</td>
            <td  class="report_title" align=left><img src="http://awetest.com/images/awetest_logo.png"/></td>
            <td  class="report_title title" align=right><p class=title>Awetest Run Report: ' + nice_name + '</p></td>
            <td  class="report_title" width=15%>&nbsp;</td>
          </tr>
        </tbody>
      </table>
      <br>
      <hr width=100% class=border size=1px>
    <table border=0 width=100% cellpadding=2 cellspacing=2>
      <tbody>
        <tr>
          <td class=report_title width=15%></td>
          <td class="report_title" width=10%>Component</td>
          <td class="report_title" width=2%>:</td>
          <td class="report_title" width=23%>' + nice_name + '</td>
          <td class="report_title" width=10%></td>
          <td class="report_title" width=2%></td>
          <td class="report_title" width=23%></td>
        </tr>
        <tr>
          <td class=report_title width=15%></td>
          <td class="report_title" width=10%>Test Run</td>
          <td class="report_title" width=2%>:</td>
          <td class="large_text report_title" width=65%>' + rpt_nice_time + '</td>
        </tr>
        <tr></tr>
      </tbody>
    </table>
'
    end

    def begin_environment
      @report_environment = '<br>
<table id="environment" class="report_body" width=100% cellpadding=2 cellspacing=0>
  <tr class=section_divider>
  <th>Environment</th>
</tr>
'
    end

    def add_to_environment(fmt_duration, level, location, message)
      @report_environment += '<tr><td class="environment_description">' + message + '</td></tr>' + "\n"
    end

    def finish_environment
      @report_environment << '</table>' + "\n"
    end

    def begin_summary
      @report_summary = '<table id="summary"  class="report_body" width=100% cellpadding=2 cellspacing=0>
<tr class=section_divider>
  <th class="summary_description">Summary</th>
  <th class="summary_value">References</th>
</tr>
'
    end

    def add_to_summary(fmt_duration, level, location, message, data = nil)
      step_class    = 'summary_description'
      value_class   = 'summary_value'
      if level and level >= 1
        row_class = 'summary_divider'
        step_class   << ' divider_cell'
        value_class  << ' divider_cell'
      else
        row_class = 'step_row'
      end
      location = data ? data : ''

      row = '<tr class=' + row_class + '>
  <td class="' + step_class + '">' + message + '</td>
  <td class="' + value_class + '">' + location + '</td>
</tr>'

      @report_summary += row + "\n"
    end

    def finish_summary
      @report_summary << '</table>' + "\n"
    end

    def begin_page_load
      @report_page_load = '<table id="page_load" class="report_body" width=100% cellpadding=2 cellspacing=0>
<tr class=section_divider>
  <th width=' + @four_col_result_width + '>Result</th>
  <th width=' + @four_col_step_width + '>Page Load</th>
  <th width=' + @four_col_location_width + '>Location</th>
  <th width=' + @four_col_duration_width + '>Duration</th>
</tr>
'
    end

    def add_to_page_load(fmt_duration, level, location, message, result)
      @report_page_load += format_detail_row(fmt_duration, level, location, message, result)
    end

    def finish_page_load
      @report_page_load << '</table>' + "\n"
    end

    def begin_setup
      @report_setup = '<table id="setup" class="report_body" width=100% cellpadding=2 cellspacing=0>
<tr class=section_divider>
  <th width=' + @four_col_result_width + '>Result</th>
  <th width=' + @four_col_step_width + '>Setup Step</th>
  <th width=' + @four_col_location_width + '>Location</th>
  <th width=' + @four_col_duration_width + '>Duration</th>
</tr>
'
    end

    def add_to_setup(fmt_duration, level, location, message, result)
      @report_setup += format_detail_row(fmt_duration, level, location, message, result)
    end

    def format_detail_row(fmt_duration, level, location, message, result)
      row_class     = 'step_row'
      step_class    = 'step_description'
      loc_class    =  'location'
      result_value = result
      case result
        when /PASS/i
          result_class = 'result_passed'
        when /FAIL/i
          result_class = 'result_failed'
        else
          if level and level.to_i > 0
            location     = ''
            fmt_duration = ''
            result_class = 'result_level'
            row_class    = 'detail_divider'
            step_class   << ' divider_cell'
            loc_class    << ' divider_cell'
          else
            result_value = ''
            result_class = 'normal_text'
          end
      end

      '<tr class=' + row_class + '>
  <td class="' + result_class + '">' + result_value + '</td>
  <td class="' + step_class + '">' + message + '</td>
  <td class="' + loc_class + '">' + location + '</td>
  <td class="duration">' + fmt_duration + '</td>
</tr>
'
    end

    def finish_setup
      @report_setup << '</table>' + "\n"
    end

    def begin_detail
      @report_detail = '<table id="detail" class="report_body" width=100% cellpadding=2 cellspacing=0>
<tr class=section_divider>
  <td width=' + @four_col_result_width + '>Result</td>
  <td width=' + @four_col_step_width + '>Detail Step</td>
  <td width=' + @four_col_location_width + '>Location</td>
  <td width=' + @four_col_duration_width + '>Duration</td>
</tr>
'
    end

    def add_to_detail(fmt_duration, level, location, message, result)
      @report_detail += format_detail_row(fmt_duration, level, location, message, result)
      if message =~ />> SUMMARY|Traverse Variations/
        @report_detail += '<tr class=instance_divider>
          <td width=' + @four_col_result_width + '>&nbsp;</td>
          <td border=0 width=' + @four_col_step_width + '>&nbsp;</td>
          <td border=0 width=' + @four_col_location_width + '>&nbsp;</td>
          <td width=' + @four_col_duration_width + '>&nbsp;</td>
        </tr>
        '
      end
    end

    def finish_detail
      @report_detail << '</table>' + "\n"
    end

    def begin_footer
      @report_footer = '<table id="footer" class="report_body" width=100% cellpadding=2 cellspacing=0>
<tr class=section_divider>
  <th>End of Run</th>
</tr>
'
    end

    def add_to_footer(fmt_duration, level, location, message)
      @report_footer += '<tr><td class="environment_description">' + message + '</td></tr>' + "\n"
    end

    def finish_footer
      @report_footer << '<tr>
<th class=section_divider></th>
</tr>
</table>
'
    end

    def finish_html
      '</td>
    </tr>
    </tbody>
</table>
</body>
</html>
'
    end

    # Add a row to the report
    # @private
    def add_to_report(message, location, result, duration = 0, level = 1, section = RDTL, data = nil)

      fmt_duration = duration > 0 ? "#{'%9.5f' % (duration)}" : ''
      # result       = level.to_i < 1 ? '' : result

      add_to_json(message, location, result, level, fmt_duration)

      case section
        when RSMY
          add_to_summary(fmt_duration, level, location, message, data)
        when RENV
          add_to_environment(fmt_duration, level, location, message)
        when RSTP
          add_to_setup(fmt_duration, level, location, message, result)
        when RPGL
          add_to_page_load(fmt_duration, level, location, message, result) if @page_load
        when RFTR
          add_to_footer(fmt_duration, level, location, message)
        when RDTL
          add_to_detail(fmt_duration, level, location, message, result)
        else
          add_to_detail(fmt_duration, level, location, message, result)
      end


    end

    def add_to_json(message, location, result, level, duration = nil)
      @json_content["line_no_#{@line_no}"] = [message, location, result, level, Time.now, @line_no] #, duration]
      @line_no                             += 1
    end

    # Close the report HTML
    # @private
    def finish_report

      # HTML Report
      rpt_file = File.open(self.html_file_name, 'w')
      finish_summary
      finish_environment
      finish_setup
      finish_page_load if @page_load
      finish_detail
      finish_footer

      rpt_file.puts(@report_header)
      rpt_file.puts(@report_environment)
      rpt_file.puts(@report_summary)
      rpt_file.puts(@report_setup)
      rpt_file.puts(@report_page_load) if @page_load
      rpt_file.puts(@report_detail)
      rpt_file.puts(@report_footer)
      rpt_file.puts(finish_html)
      rpt_file.close

      # JSON report
      rpt_json = File.open(self.json_file_name, 'w')
      rpt_json.puts(@json_content.to_json)
      rpt_json.close

      self.html_file_name

    end


  end
end
