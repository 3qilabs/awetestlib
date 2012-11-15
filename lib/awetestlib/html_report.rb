module Awetestlib
  # Report generator for Awetestlib.
  class HtmlReport

    # Initialize the report class
    # @private
    def initialize(report_name)
      @reportname = report_name
      @reportContent1 = ''
      @reportContent2 = ''
    end

    # Create a report
    # @private
    def create_report(reportName)
      # Get current time
      t = Time.now

      # Create the report name
      strTime = "#{t.strftime("%Y%m%d_%H%M%S")}"
      strNiceTime = "#{t.strftime("%m/%d/%Y @ %H:%M:%S")}"
      strTotalReport = "#{reportName}_#{strTime}.html"

      # Create the HTML report
      strFile = File.open(strTotalReport, 'w')

      # Format the header of the HTML report
      @reportContent1 = '<html>
        <head>
        <meta content=text/html; charset=ISO-8859-1 http-equiv=content-type>
        <title>Awetestlib Test Run</title>
        <style type=text/css>
        .title { font-family: verdana; font-size: 30px;  font-weight: bold; align: left; color: #000000;}
        .bold_text { font-family: verdana; font-size: 12px;  font-weight: bold;}
        .bold_large_text { font-family: verdana; font-size: 13px;  font-weight: bold;}
        .normal_text { font-family: verdana; font-size: 12px;  font-weight: normal;}
        .small_text { font-family: verdana; font-size: 10px;  font-weight: normal; }
        .border { border: 1px solid #000000;}
        .mark_testlevel_left { border-top: 1px solid #858585; border-left: 1px solid #858585;background-color:#E2F4FE;}
        .mark_testlevel_right { border-top: 1px solid #858585; border-right: 1px solid #858585;background-color:#E2F4FE;}
        .border_left { border-top: 1px solid #858585; border-left: 1px solid #858585; border-right: 1px solid #858585;}
        .border_right { border-top: 1px solid #858585; border-right: 1px solid #858585;}
        .result_ok { font-family: verdana; font-size: 12px;  font-weight: bold; text-align: center; color: green;}
        .result_nok { font-family: verdana; font-size: 12px;  font-weight: bold; text-align: center; color: red;}
        .overall_ok { font-family: verdana; font-size: 12px;  font-weight: bold; text-align: left; color: green;}
        .overall_nok { font-family: verdana; font-size: 12px;  font-weight: bold; text-align: left; color: red;}
        .bborder_left { border-top: 1px solid #858585; border-left: 1px solid #858585; border-bottom: 1px solid #858585; background-color:#858585;font-family: verdana; font-size: 12px;  font-weight: bold; text-align: center; color: white;}
        .bborder_right { border-right: 1px solid #858585; background-color:#858585;font-family: verdana; font-size: 12px;  font-weight: bold; text-align: center; color: white;}
        </style>
        </head>
        <body>
        <br>
        <center>
        <table width=800 border=0 cellpadding=2 cellspacing=2>
        <tbody>
        <tr>
        <td>
        <table width=100% border=0 cellpadding=2 cellspacing=2>
        <tbody>
        <tr>
        <td style=width: 150px;>&nbsp;</td>
        <td align=left><img src="https://raw.github.com/3qilabs/awetestlib/develop/images/logo.png"></img></td>
        <td align=right><p class=title>Test Report</p></td>
        </tr>
        </tbody>
        </table>
        <br>
        <hr width=100% class=border size=1px>
        <center>
        <table border=0 width=95% cellpadding=2 cellspacing=2>
        <tbody>
        <tr>
        <td width=20%><p class=bold_text>Script</p></td>
        <td width=5%><p class=bold_text>:</p></td>
        <td width=75%><p class=normal_text>' + @reportname.capitalize + '</p></td>
        </tr>
        <tr>
        <td width=20%><p class=bold_text>Test Execution</p></td>
        <td width=5%><p class=bold_text>:</p></td>
        <td width=75%><p class=normal_text>' + strNiceTime + '</p></td>
        </tr>
        <tr>'

      @reportContent2 = '</tr>
        </tbody>
        </table>
        </center>
        <br>
        <center>
        <table width=95% cellpadding=2 cellspacing=0>
        <tbody>
        <tr>
        <td class=bborder_left width=80%><p>Test Step</p></td>
        <td class=bborder_left width=20%><p>Result</p></td>
        </tr>'

      # Close the report
      strFile.close

      return strTotalReport
    end

    # Add a row to the report
    # @private
    def add_to_report(step, result, level = 1)
      # Format the body of the HTML report
      if (result == 'PASSED')
        @reportContent2 = @reportContent2 + '<tr><td class=border_left width=80%><p class=normal_text>' + step + '</p></td>'
        @reportContent2 = @reportContent2 + '<td class=border_right width=20%><p class=result_ok>' + result + '</p></td>'
      elsif (result == 'FAILED')
        @reportContent2 = @reportContent2 + '<tr><td class=border_left width=80%><p class=normal_text>' + step + '</p></td>'
        @reportContent2 = @reportContent2 + '<td class=border_right width=20%><p class=result_nok>' + result + '</p></td>'
      elsif level < 1
        @reportContent2 = @reportContent2 + '<tr><td class=border_left width=80%><p class=normal_text>' + step + '</p></td>'
        @reportContent2 = @reportContent2 + '<td class=border_right width=20%><p class=result_nok>' + result + '</p></td>'
      else
        @reportContent2 = @reportContent2 + '<tr><td class=mark_testlevel_left width=80%><p class=bold_large_text>' + step + '</p></td>'
        @reportContent2 = @reportContent2 + '<td class=mark_testlevel_right width=20%><p class=result_nok>' + result + '</p></td>'
      end
    end

    # Close the report HTML
    # @private
    def finish_report(reportName)
      # Open the HTML report
      strFile = File.open(reportName, 'a')

      @reportContent2 = @reportContent2 + '<tr>
      <td class=bborder_left width=80%><p>&nbsp;</p></td>
      <td class=bborder_left width=20%><p>&nbsp;</p></td>
      </tr>
      </table>'

      strFile.puts(@reportContent1)

      strFile.puts(@reportContent2)

      # Close the report
      strFile.close
    end
  end
end
