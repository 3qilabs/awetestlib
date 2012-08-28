def edit_config_file
  @new_config_file = File.join(FileUtils.pwd,"sample_rubymine",".idea","workspace.xml")
  @demo_script = File.join(FileUtils.pwd,"sample_rubymine", "demo.rb")
  @awetestlib_file = File.join(File.dirname(__FILE__), "awetestlib")
  workspace_text = File.read(@new_config_file)
  new_workspace_text = workspace_text.gsub(/SAMPLE-SCRIPT/,@demo_script )
  new_workspace_text = new_workspace_text.gsub(/RUBY-SCRIPT/, @awetestlib_file)
  File.open(@new_config_file, "w") {|file| file.puts new_workspace_text}
end

def awetestlib_rubymine_setup
  @rubymine_dir = File.join(FileUtils.pwd, "sample_rubymine")
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_rubymine')

  if File.exists?(@rubymine_dir)
    puts "Sample Rubymine directory already exists."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a sample rubymine project in this directory"
    puts "Please hit return to confirm that's what you want."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''
  FileUtils.cp_r(@source_dir, @rubymine_dir)
  edit_config_file
  msg("Info") do
    puts "Configuring files and settings"
  end

end