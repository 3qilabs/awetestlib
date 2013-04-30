def msg(title, &block)
  puts "\n" + "-"*10 + title + "-"*10
  block.call
  puts "-"*10 + "-------" + "-"*10 + "\n"
end


def print_usage
  puts <<EOF
  Usage Options:
  
    awetestlib regression_setup
      setup awetest regression and register autoitx3.dll in Windows

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

def load_time(what = nil, time = Time.now)
  if $capture_load_times
    caller = Kernel.caller
    called = $"
    unless what
      what = "#{caller[0]} => #{called[called.length - 1]}"
    end
    elapsed = time - $base_time
    msg = "#{what} #{sprintf('%.4f', elapsed)}"
    $load_times[time.to_f] = msg
    begin
      debug_to_report("#{time.to_f}: #{msg}")
    rescue
      puts("#{time.to_f}: #{msg}")
    end
    $base_time = time
  end
end
