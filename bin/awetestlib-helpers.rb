def msg(title, &block)
  puts "\n" + "-"*10 + title + "-"*10
  block.call
  puts "-"*10 + "-------" + "-"*10 + "\n"
end


def print_usage
  puts <<EOF
  Usage Options:
  
    awetestlib regression_setup
      setup awetest regression and registers autoitx3.dll

    awetestlib rubymine_setup
      setup a sample rubymine project

    awetestlib netbeans_setup
      setup a sample netbeans project

    awetestlib cucumber_setup
      setup cucumber regression and provides skeleton folder structure

    awetestlib <script_file> [parameters]
      run an awetest regression script

EOF
end