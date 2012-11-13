require 'pry'
def awetestlib_driver_setup
	current_dir = Dir.pwd
	drivers_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "drivers"))
	# binding.pry
	ie_driver = File.join(drivers_dir,"IEDriverServer.exe")
	chrome_driver = File.join(drivers_dir,"chromedriver.exe")
	msg("Question") do
    puts "I'm about to put the chromedriver and IEDriverServer in this directory"
    puts "If it already exists, we will overwrite it"
    puts "Please hit return to confirm that's what you want."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''
	FileUtils.cp(ie_driver, current_dir)
	FileUtils.cp(chrome_driver,current_dir)
  msg("Info") do
    puts "Successfully copied chromedriver and IEDriverServer to #{current_dir}"
  end

end
