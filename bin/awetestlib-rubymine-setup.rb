def edit_config_file
  @new_config_file = File.join(FileUtils.pwd, @proj_dir, ".idea", "workspace.xml")
  @demo_script = File.join(FileUtils.pwd, @proj_dir, "demo.rb")
  @awetestlib_file = File.join(File.dirname(__FILE__), "awetestlib")
  workspace_text = File.read(@new_config_file)
  new_workspace_text = workspace_text.gsub(/SAMPLE-SCRIPT/,@demo_script )
  new_workspace_text = new_workspace_text.gsub(/RUBY-SCRIPT/, @awetestlib_file)
  new_workspace_text = new_workspace_text.gsub(/WORK-DIR/, File.dirname(@demo_script))
  File.open(@new_config_file, "w") {|file| file.puts new_workspace_text}
end

def awetestlib_rubymine_setup
  if ARGV[1].nil?
    @proj_dir = "sample_rubymine"
  else
    @proj_dir = ARGV[1]
  end

  @rubymine_dir = File.join(FileUtils.pwd, @proj_dir)
  @source_dir = File.join(File.dirname(__FILE__), '..', 'setup_samples', 'sample_rubymine')

  if File.exists?(@rubymine_dir)
    puts "Rubymine project directory (#{@rubymine_dir}) already exists."
    exit 1
  end

  msg("Question") do
    if ARGV[1]
      puts "I'm about to create a rubymine project named #{ARGV[1]} in this directory"
    else
      puts "I'm about to create a rubymine project named sample_rubymine in this directory"
    end
    puts "Please hit return to confirm that's what you want."
    puts "Enter anything else and hit return to abort."
    puts "NOTE: You may need to run this command as an administrator."
  end
  exit 2 unless STDIN.gets.chomp == ''

  FileUtils.cp_r(@source_dir, @rubymine_dir)
  edit_config_file
  msg("Info") do
    puts "Configuring files and settings"
  end

end
