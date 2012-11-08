def awetestlib_android_setup
  if ARGV[1].nil?
    @proj_dir = "sample_android"
  else
    @proj_dir = ARGV[1]
  end

  @cucumber_dir = File.join(FileUtils.pwd, @proj_dir)
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_android')

  if File.exists?(@cucumber_dir)
    puts "Android project directory already exists."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create an android project named #{@proj_dir} in this directory"
    puts "Please hit return to confirm that's what you want."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''
  FileUtils.cp_r(@source_dir, @cucumber_dir)
  msg("Info") do
    puts "Configuring files and settings"
  end

end