module CommandLine

  def build_awetestlib_command(options)

    option_keys = {
        :browser              => '-b',
        :version              => '-v',
        :environment_name     => '-n',
        :environment_url      => '-e',
        :environment_nodename => '-f',
        :library              => '-l',
        :xls_path             => '-x',
        :root_path            => '-r',
        :emulator             => '-E',
        :device_id            => '-I',
        :sdk                  => '-K',
        :device_type          => '-T',
        :timeout              => '--timeout',
        # :report_upload_url => '--report_upload_url',
        :pry                  => '-p',
        :debug_on_fail        => '-d',
        :output_to_log        => '-o',
        :log_path_subdir      => '--log_path_subdir',
        :report_all_test_refs => '--report_all_test_refs',
        :capture_load_times   => '-t',
        :screencap_path       => '-s',
        :remote_url           => '-u',
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
