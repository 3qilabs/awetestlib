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

def parse_script_type(options)
  script_options = ['Regression', 'Awetest', 'AwetestDSL', 'Awetestlib', 'Cucumber']
  if script_options.include? ARGV[0]
    case ARGV[0]
      when 'Regression', 'Awetest', 'AwetestDSL', 'Awetestlib'
        options[:script_type] = 'Regression'
      else
        options[:script_type] = ARGV[0]
    end
    options[:script_file] = ARGV[1]
  else
    options[:script_type] = 'Regression'
    options[:script_file] = ARGV[0]
  end
end

def load_time(what = nil, base = nil, time = Time.now)
  if $capture_load_times
    caller = Kernel.caller
    called = $"
    unless what
      drv, file, line, meth = caller[0].split(':')
      if drv.length > 2
        meth = line
        line = file
        file = drv
      end
      what = "#{File.basename(file)} at #{line} #{meth} => #{called[called.length - 1]}"
      #what = "#{File.basename(caller[0])} => #{called[called.length - 1]}"
    end
    if base
      elapsed = time - base
    else
      elapsed = time - $base_time
    end
    msg = "#{what} took #{sprintf('%.4f', elapsed)} seconds"
    $load_times[time.to_f] = msg
    puts("#{time.to_f}: #{msg}")
    $base_time = time unless base
  end
end
