def awetestlib_regression_setup
  using_windows = !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM =~ /mswin|mingw/))
  using_osx     = RUBY_PLATFORM =~ /darwin/

  if using_windows
    msg("Question") do
      puts "I'm about to setup awetest regression support and register the AutoItX3.dll"
      puts "Please hit return to confirm that's what you want."
      puts "Enter anything else and hit return to abort."
      puts "NOTE: You may need to run this command as an administrator."
    end
    exit 2 unless STDIN.gets.chomp == ''

    autoit_file = File.join(File.dirname(__FILE__),"AutoItX3.dll")
    system("regsvr32 #{autoit_file}")

    msg("Info") do
      puts "Configuring files and settings for Windows"
    end
  elsif using_osx
    msg("Info") do
      puts "Currently nothing needed to configure settings for OSX"
    end
  else
    msg("Error") do
      puts "Unsupported operating system: #{RUBY_PLATFORM}"
    end
  end

end
