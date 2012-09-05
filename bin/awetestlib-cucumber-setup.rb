def awetestlib_cucumber_setup
  @cucumber_dir = File.join(FileUtils.pwd, "sample_cucumber")
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_cucumber')

  if File.exists?(@cucumber_dir)
    puts "Sample Cucumber features directory already exists."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a sample cucumber feature in this directory"
    puts "Please hit return to confirm that's what you want."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''
  FileUtils.cp_r(@source_dir, @cucumber_dir)
  msg("Info") do
    puts "Configuring files and settings"
    puts "From the sample_cucumber/features folder, you may now run command below:"
    puts "cucumber yahoo_mail.feature"
  end

end