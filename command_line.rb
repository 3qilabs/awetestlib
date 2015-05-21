module CommandLine

  def build_awetestlib_command_line(options)

    option_keys = {
        :browser              => '-b',
        :capture_load_times   => '-L',
        :debug_dsl => '-d',
        :device_id            => '-I',
        :device_type          => '-T',
        :emulator             => '-E',
        :environment_name     => '-n',
        :environment_nodename => '-f',
        :environment_url      => '-e',
        :global_debug         => '-D',
        :library              => '-l',
        :log_path_subdir      => '-S',
        :output_to_log        => '-o',
        :platform  => '-P',
        :pry                  => '-p',
        :remote_url           => '-u',
        :report_all_test_refs => '-R',
        :root_path            => '-r',
        :screencap_path       => '-s',
        :sdk                  => '-K',
        :locate_timeout       => '-t',
        :version              => '-v',
        :xls_path             => '-x',
        :help                 => '-h',
    }

    run_cmd = "awetestlib #{options[:script_file]}"

    option_keys.each_key do |opt|
      if options[opt]
        run_cmd << " #{option_keys[opt]} #{options[opt]}"
      end
    end

    run_cmd

  end

end
