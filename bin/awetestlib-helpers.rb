def msg(title, &block)
  puts "\n" + "-"*10 + title + "-"*10
  block.call
  puts "-"*10 + "-------" + "-"*10 + "\n"
end


def print_usage
  puts <<EOF
  Usage Options:
  
    awetestlib regression_setup
      setup awetest regression and register autoitx3.dll

    awetestlib rubymine_setup <project_name>
      setup a rubymine project 

    awetestlib netbeans_setup <project_name>
      setup a netbeans project

    awetestlib mobile_app_setup <project_name>
      setup a mobile app project

    awetestlib cucumber_setup <project_name>
      setup cucumber regression and provide skeleton folder structure

    awetestlib <script_file> [parameters]
      run an awetest regression script

EOF
end

def check_script_type(options)
  script_options = ['Regression', 'Cucumber']
  if script_options.include? ARGV[0]
    options[:script_type] = ARGV[0]
    options[:script_file] = ARGV[1]
  else
    options[:script_type] = 'Regression'
    options[:script_file] = ARGV[0]
  end
end