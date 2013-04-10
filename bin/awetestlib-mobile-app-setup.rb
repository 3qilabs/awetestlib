def awetestlib_mobile_app_setup
  if ARGV[1].nil?
    @proj_dir = "sample_mobile_app"
  else
    @proj_dir = ARGV[1]
  end

  @cucumber_dir = File.join(FileUtils.pwd, @proj_dir)
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_mobile_app')

  if File.exists?(@cucumber_dir)
    puts "Mobile app project directory already exists."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a mobile app project named #{ARGV[1]} in this directory" if ARGV[1]
    puts "I'm about to create a mobile app project named sample_mobile_app in this directory" if ARGV[1].nil?
    puts "Please hit return to confirm that's what you want."
    puts "Enter anything else and hit return to abort."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''

  FileUtils.cp_r(@source_dir, @cucumber_dir)

  msg("Info") do
    puts "Configuring files and settings..."
    puts "A skeleton project has been created with a features and step definitions folder"
  end

end
