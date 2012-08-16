def awetestlib_regression_setup
  msg("Question") do
    puts "I'm about to setup awetest regression support."
    puts "Please hit return to confirm that's what you want."
	puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''
  
  autoit_file = File.join(File.dirname(__FILE__),"AutoItX3.dll")
  system("regsvr32 #{autoit_file}")

  msg("Info") do
    puts "Configuring files and settings..."
  end

end