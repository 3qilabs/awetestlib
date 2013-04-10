def edit_config_file
  @new_config_file = File.join(FileUtils.pwd, @proj_dir, "nbproject","private","configs", "Demo.properties")
  @demo_script = File.join(FileUtils.pwd, @proj_dir, "demo.rb")
  workspace_text = File.read(@new_config_file)
  new_workspace_text = workspace_text.gsub(/SAMPLE-SCRIPT/,@demo_script )
  new_workspace_text = new_workspace_text.gsub(/WORK-DIR/, File.dirname(@demo_script))
  File.open(@new_config_file, "w") {|file| file.puts new_workspace_text}
end

def edit_private_file
  @new_private_file = File.join(FileUtils.pwd, @proj_dir, "nbproject", "private", "private.properties")
  @bin_dir = File.join(File.dirname(__FILE__))
  workspace_text = File.read(@new_private_file)
  new_workspace_text = workspace_text.gsub(/BIN-DIR/,@bin_dir )
  File.open(@new_private_file, "w") {|file| file.puts new_workspace_text}
end

def edit_project_file
  @new_project_file = File.join(FileUtils.pwd, @proj_dir, "nbproject", "project.xml")
  project_text = File.read(@new_project_file)
  new_project_text = project_text.gsub(/PROJECT-NAME/, @proj_dir)
  File.open(@new_project_file, "w") {|file| file.puts new_project_text}

end


def awetestlib_netbeans_setup
  if ARGV[1].nil?
    @proj_dir = "sample_netbeans"
  else
    @proj_dir = ARGV[1]
  end

  @netbeans_dir = File.join(FileUtils.pwd, @proj_dir)
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_netbeans')

  if File.exists?(@netbeans_dir)
    puts "Netbeans project directory already exists."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a netbeans project named #{ARGV[1]} in this directory" if ARGV[1]
    puts "I'm about to create a netbeans project named sample_netbeans in this directory" if ARGV[1].nil?
    puts "Please hit return to confirm that's what you want."
    puts "Enter anything else and hit return to abort."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''

  FileUtils.cp_r(@source_dir, @netbeans_dir)
  edit_config_file
  edit_private_file
  edit_project_file

  msg("Info") do
    puts "Configuring files and settings"
  end

end
