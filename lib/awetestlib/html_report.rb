module Awetestlib
  # Report generator for Awetestlib.
  class HtmlReport

    attr_accessor :report_name,
                  :html_file_name,
                  :json_file_name

    # TODO: split the json and html reports to separate classes
    # Initialize the report class
    # @private
    def initialize(report_name, report_dir, ts)
      @report_name      = report_name
      @report_content_1 = ''
      @report_content_2 = ''
      rpt_time            = "#{ts.strftime("%Y%m%d_%H%M%S")}"
      self.html_file_name = File.join(report_dir, "#{report_name}_#{rpt_time}.html")
      self.json_file_name = File.join(report_dir, "#{report_name}_#{rpt_time}.json")

    end

    # Create a report
    # @private
    def create_report(report_name)
      # Get current time
      t = Time.now

      @col_1_p          = '66%'
      @col_2_p          = '22%'
      @col_3_p          = '6%'
      @col_4_p          = '6%'

      rpt_nice_time     = "#{t.strftime("%m/%d/%Y @ %H:%M:%S")}"

      # Format the header of the HTML report
      @report_content_1 = '<html>
        <head>
        <meta content=text/html; charset=ISO-8859-1 http-equiv=content-type>
        <title>Awetestlib Test Run</title>
        <style type=text/css>
        .title { font-family: verdana; font-size: 30px;  font-weight: bold; align: left; color: #000000;}
        .bold_text { font-family: verdana; font-size: 11px;  font-weight: bold;}
        .bold_large_text { font-family: verdana; font-size: 12px;  font-weight: bold;}
        .normal_text { font-family: verdana; font-size: 11px; font-weight: normal;}
        .center_text { font-family: verdana; font-size: 11px; font-weight: normal; text-align: center;}
        .small_text { font-family: verdana; font-size: 9px;  font-weight: normal; }
        .border { border: 1px solid #000000;}
        .mark_testlevel_left { border-top: 1px solid #858585; border-left: 1px solid #858585;background-color:#E2F4FE;}
        .mark_testlevel_middle { border-top: 1px solid #858585; background-color:#E2F4FE;}
        .mark_testlevel_right { border-top: 1px solid #858585; border-right: 1px solid #858585;background-color:#E2F4FE;}
        .border_left { border-top: 1px solid #858585; border-left: 1px solid #858585; border-right: 1px solid #858585;}
        .border_middle { border-top: 1px solid #858585; border-right: 1px solid #858585;}
        .border_right { border-top: 1px solid #858585; border-right: 1px solid #858585;}
        .result_ok { font-family: verdana; font-size: 11px;  font-weight: bold; text-align: center; color: green;}
        .result_nok { font-family: verdana; font-size: 11px;  font-weight: bold; text-align: center; color: red;}
        .overall_ok { font-family: verdana; font-size: 11px;  font-weight: bold; text-align: left; color: green;}
        .overall_nok { font-family: verdana; font-size: 11px;  font-weight: bold; text-align: left; color: red;}
        .bborder_left { border-top: 1px solid #858585; border-left: 1px solid #858585; border-bottom: 1px solid #858585; background-color:#858585;font-family: verdana; font-size: 12px;  font-weight: bold; text-align: center; color: white;}
        .bborder_right { border-right: 1px solid #858585; background-color:#858585;font-family: verdana; font-size: 12px;  font-weight: bold; text-align: center; color: white;}
        </style>
        </head>
        <body>
        <br>
        <center>
        <table width=auto border=0 cellpadding=2 cellspacing=2>
        <tbody>
        <tr>
        <td>
        <table width=90% border=0 cellpadding=2 cellspacing=2>
        <tbody>
        <tr>
        <td style=width: 150px;>&nbsp;</td>
        <td align=left><img src="http://awetest.com/images/awetest_logo.png"></img></td>
        <td align=right><p class=title>Test Report</p></td>
        </tr>
        </tbody>
        </table>
        <br>
        <hr width=100% class=border size=1px>
        <center>
        <table border=0 width=100% cellpadding=2 cellspacing=2>
        <tbody>
        <tr>
        <td width=10%><p class=normal_text></p></td>
        <td width=20%><p class=bold_text>Script</p></td>
        <td width=5%><p class=bold_text>:</p></td>
        <td width=65%><p class=normal_text>' + report_name.capitalize + '</p></td>
        </tr>
        <tr>
        <td width=10%><p class=normal_text></p></td>
        <td width=20%><p class=bold_text>Test Execution</p></td>
        <td width=5%><p class=bold_text>:</p></td>
        <td width=65%><p class=normal_text>' + rpt_nice_time + '</p></td>
        </tr>
        <tr>'

      @report_content_2 = '</tr>
        </tbody>
        </table>
        </center>
        <br>
        <center>
        <table width=100% cellpadding=2 cellspacing=0>
        <tbody>
        <tr>
        <td class=bborder_left width=' + @col_1_p + '><p>Test Step</p></td>
        <td class=bborder_left width=' + @col_2_p + '><p>Location</p></td>
        <td class=bborder_left width=' + @col_3_p + '><p>Duration</p></td>
        <td class=bborder_left width=' + @col_4_p + '><p>Result</p></td>
        </tr>' + "\n"

      @json_content                = {}
      @json_content['report_type'] = 'Awetestlib Report'
      @json_content['Data_order'] = 'message, location, result, level, Time.now, line' #, duration'
      @line_no                     = 1


    end

    # Add a row to the report
    # @private
    def add_to_report(message, location, result, duration = 0, level = 1)
      # Format the body of the HTML report

      fmt_duration = "#{'%9.5f' % (duration)}"

      left_class   = 'border_left'
      right_class  = 'border_right'
      pgph_class   = 'normal_text'
      loc_class    = 'center_text'
      dur_class    = 'center_text'
      rslt_class   = 'result_ok'
      middle_class = 'border_middle'

      rslt_class   = 'result_nok' if result == "FAILED"
      case result
        when 'FAILED'
          rslt_class = 'result_nok'
        when 'PASSED'
          rslt_class = 'result_ok'
        else
          if level
            if level >= 1
              pgph_class   = 'bold_large_text'
              left_class   = 'mark_testlevel_left'
              middle_class = 'mark_testlevel_middle'
              right_class  = 'mark_testlevel_right'
              location     = ''
              fmt_duration = ''
            else
              result = ''
            end
          end
      end

      row = '<tr>
        <td class=' + left_class + ' width=' + @col_1_p + '><p class=' + pgph_class + '>' + message + '</p></td>
        <td class=' + middle_class + ' width=' + @col_2_p + '><p class=' + loc_class + '>' + location + '</p></td>
        <td class=' + middle_class + ' width=' + @col_3_p + '><p class=' + dur_class + '>' + fmt_duration + '</p></td>
        <td class=' + right_class + ' width=' + @col_4_p + '><p class=' + rslt_class + '>' + result + '</p></td>
        </tr>'

      @report_content_2                    += row + "\n"
      @json_content["line_no_#{@line_no}"] = [message, location, result, level, Time.now, @line_no] #, duration]
      @line_no                             += 1

    end

    # Close the report HTML
    # @private
    def finish_report

      # HTML Report
      rpt_file = File.open(self.html_file_name, 'w')
      @report_content_2 = @report_content_2 + '<tr>
      <td class=bborder_left width=' + @col_1_p + '><p>&nbsp;</p></td>
      <td class=bborder_left width=' + @col_2_p + '><p>&nbsp;</p></td>
      <td class=bborder_left width=' + @col_3_p + '><p>&nbsp;</p></td>
      <td class=bborder_left width=' + @col_4_p + '><p>&nbsp;</p></td>
      </tr>
      </table>'
      rpt_file.puts(@report_content_1)
      rpt_file.puts(@report_content_2)
      rpt_file.close

      # JSON report
      rpt_json = File.open(self.json_file_name, 'w')
      rpt_json.puts(@json_content.to_json)
      rpt_json.close

      self.html_file_name

    end
  end
end
