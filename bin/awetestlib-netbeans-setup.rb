def edit_config_file
  @new_config_file = File.join(FileUtils.pwd,"sample_netbeans","nbproject","private","configs", "Demo.properties")
  @demo_script = File.join(FileUtils.pwd,"sample_netbeans", "demo.rb")
  workspace_text = File.read(@new_config_file)
  new_workspace_text = workspace_text.gsub(/SAMPLE-SCRIPT/,@demo_script )
  File.open(@new_config_file, "w") {|file| file.puts new_workspace_text}
end

def edit_private_file
  @new_private_file = File.join(FileUtils.pwd,"sample_netbeans","nbproject","private", "private.properties")
  @bin_dir = File.join(File.dirname(__FILE__))
  workspace_text = File.read(@new_private_file)
  new_workspace_text = workspace_text.gsub(/BIN-DIR/,@bin_dir )
  File.open(@new_private_file, "w") {|file| file.puts new_workspace_text}
end

def awetestlib_netbeans_setup
  @netbeans_dir = File.join(FileUtils.pwd, "sample_netbeans")
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_netbeans')

  if File.exists?(@netbeans_dir)
    puts "Sample Netbeans directory already exists."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a sample netbeans project in this directory"
    puts "Please hit return to confirm that's what you want."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''
  FileUtils.cp_r(@source_dir, @netbeans_dir)
  edit_config_file
  edit_private_file
  msg("Info") do
    puts "Configuring files and settings"
  end

end