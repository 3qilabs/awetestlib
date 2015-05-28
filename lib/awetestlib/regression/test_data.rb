module Awetestlib

  module Regression

    module TestData

      def load_variables(file, key_type = :role, enabled_only = true, dbg = true, scripts = nil)
        mark_test_level(build_message(file, "key:'#{key_type}'"))

        # ok = true

        debug_to_log("#{__method__}: file = #{file}")
        debug_to_log("#{__method__}: key  = #{key_type}")

        workbook = file =~ /\.xlsx$/ ? Roo::Excelx.new(file) : Roo::Excel.new(file)

        if @myName =~ /appium/i
          ok = script_found_in_data = script_found_in_login = true
        else
          script_found_in_data      = load_data_variables(workbook, dbg)
          ok, script_found_in_login = load_login_variables(workbook, enabled_only, file, key_type, scripts, dbg)
        end

        unless @env_name =~ /^gen/
          unless ok and script_found_in_login and script_found_in_data
            ok = false
            failed_to_log("Script found: in Login = #{script_found_in_login}; in Data = #{script_found_in_data}")
          end
        end

        ok
      rescue
        failed_to_log(unable_to)
      end

      alias get_variables load_variables

      def load_login_variables(workbook, enabled_only, file, key_type, scripts, dbg = nil)

        ok                    = true
        script_found_in_login = false
        @login                = Hash.new
        enabled_cnt           = 0
        script_col            = 0
        role_col              = 0
        userid_col            = 0
        company_col           = 0
        password_col          = 0
        url_col               = 0
        env_col               = 0
        name_col              = 0
        appid_col             = 0
        ref_col               = 0
        node_col              = 0
        login_index           = find_sheet_with_name(workbook, 'Login')
        if login_index and login_index >= 0
          workbook.default_sheet = workbook.sheets[login_index]

          1.upto(workbook.last_column) do |col|
            column_name = workbook.cell(1, col).downcase
            case column_name
              when @myName.downcase
                script_col            = col
                script_found_in_login = true
                if scripts.is_a?(Array)
                  scripts << column_name
                else
                  break
                end
              when 'role'
                role_col = col
              when 'userid', 'user_id'
                userid_col = col
              when 'companyid', 'company_id'
                company_col = col
              when 'password'
                password_col = col
              when 'url'
                url_col = col
              when 'environment'
                env_col = col
              when /reference/i
                ref_col = col
              when 'nodename'
                node_col = col
              when 'name'
                name_col = col
              when 'appid', 'app_id'
                appid_col = col
              else
                scripts << column_name if scripts.is_a?(Array)
            end
          end

          2.upto(workbook.last_row) do |line|
            role      = workbook.cell(line, role_col)
            userid    = workbook.cell(line, userid_col)
            password  = workbook.cell(line, password_col)
            url       = workbook.cell(line, url_col)
            env       = workbook.cell(line, env_col)
            username  = workbook.cell(line, name_col)
            nodename  = workbook.cell(line, node_col)
            companyid = workbook.cell(line, company_col)
            appid     = workbook.cell(line, appid_col)
            enabled   = workbook.cell(line, script_col).to_s
            refs      = workbook.cell(line, ref_col)

            case key_type
              when :id, :userid
                key = userid
              when :environment
                key = env
              when :role
                key = role
              else
                key = userid
            end

            if enabled_only and enabled.length == 0
              next
            end

            @login[key]                = Hash.new
            @login[key]['role']        = role
            @login[key]['userid']      = userid
            @login[key]['companyid']   = companyid
            @login[key]['password']    = password
            @login[key]['url']         = url
            @login[key]['name']        = username
            @login[key]['nodename']    = nodename
            @login[key]['enabled']     = enabled
            @login[key]['environment'] = env
            @login[key]['appid']       = appid
            @login[key]['references']  = refs

            if enabled =~ /^y$/i
              case key_type
                when :environment
                  case env
                    when /^gen/i
                      enabled_cnt += 1
                    else
                      enabled_cnt += 1 if @env_name =~ /#{env}/
                  end
                else
                  enabled_cnt += 1
              end
            end

          end

          @login.keys.sort.each do |key|
            message_to_log("@login (by #{key_type}): #{key}='#{@login[key].to_yaml}'")
          end if dbg

        else
          fail "'Login' worksheet not found in #{file}"
        end

        unless enabled_cnt > 0
          ok = false
          case key_type
            when :environment
              err_msg = "No enabled 'Login' entries for rows matching :#{key_type} => '#{@env_name}'"
            else
              err_msg = "No enabled 'Login' entries for rows matching :#{key_type}"
          end
          fail err_msg
        end

        return ok, script_found_in_login
      rescue
        failed_to_log(unable_to)
      end

      def load_data_variables(workbook, dbg = nil)

        script_found_in_data = false

        @var                   = Hash.new
        data_index             = find_sheet_with_name(workbook, 'Data')
        workbook.default_sheet = workbook.sheets[data_index]
        var_col                = 0
        default_col            = 2

        2.upto(workbook.last_column) do |col|
          script_name = workbook.cell(1, col)
          if script_name == 'default'
            default_col = col
          end
          if script_name == @myName
            var_col              = col
            script_found_in_data = true
            break
          end
        end

        defaults = {}
        2.upto(workbook.last_row) do |line|
          name           = workbook.cell(line, 'A')
          value          = workbook.cell(line, default_col).to_s.strip
          defaults[name] = value
        end

        2.upto(workbook.last_row) do |line|
          name  = workbook.cell(line, 'A')
          value = workbook.cell(line, var_col).to_s.strip
          if value and value.length > 0
            @var[name] = value
          else
            @var[name] = defaults[name]
          end
        end

        @var.keys.sort.each do |name|
          message_to_log("@var #{name}: '#{@var[name]}'")
        end if dbg

        script_found_in_data
      rescue
        failed_to_log(unable_to)
      end

      def load_html_validation_filters(file = @refs_spec)
        sheet         = 'HTML Validation Filters'
        workbook      = file =~ /\.xlsx$/ ? Roo::Excelx.new(file) : Roo::Excel.new(file)
        @html_filters = Hash.new

        sheet_index = find_sheet_with_name(workbook, "#{sheet}")
        if sheet_index > -1
          debug_to_log("Loading worksheet '#{sheet}'.")
          workbook.default_sheet = workbook.sheets[sheet_index]

          columns = Hash.new

          1.upto(workbook.last_column) do |col|
            columns[workbook.cell(1, col).to_sym] = col
          end

          2.upto(workbook.last_row) do |line|
            identifier               = workbook.cell(line, columns[:identifier])
            validator                = workbook.cell(line, columns[:validator])
            pattern                  = workbook.cell(line, columns[:pattern])
            action                   = workbook.cell(line, columns[:action])
            alt_pattern              = workbook.cell(line, columns[:alt_pattern])
            alt_action               = workbook.cell(line, columns[:alt_action])
            script                   = workbook.cell(line, columns[:script])
            head                     = workbook.cell(line, columns[:head])
            meta                     = workbook.cell(line, columns[:meta])
            body                     = workbook.cell(line, columns[:body])
            frame                    = workbook.cell(line, columns[:frame])
            fragment                 = workbook.cell(line, columns[:fragment])
            report_more              = workbook.cell(line, columns[:report_more])
            description              = workbook.cell(line, columns[:description])

            # pattern = pattern ? Regexp.escape(pattern) : nil
            # alt_pattern = alt_pattern ? Regexp.escape(alt_pattern) : nil

            @html_filters[validator] = Hash.new unless @html_filters[validator]

            @html_filters[validator][identifier] = {
                :validator   => validator,
                :pattern     => pattern,
                :action      => action,
                :alt_pattern => alt_pattern,
                :alt_action  => alt_action,
                :script      => script,
                :head        => head,
                :meta        => meta,
                :body        => body,
                :frame       => frame,
                :fragment    => fragment,
                :report_more => report_more,
                :description => description }
          end
        else
          failed_to_log("Worksheet '#{sheet}' not found #{file}")
        end

        @html_error_references = Hash.new

        sheet       = 'HTML Error References'
        sheet_index = find_sheet_with_name(workbook, "#{sheet}")
        if sheet_index > -1
          debug_to_log("Loading worksheet '#{sheet}'.")
          workbook.default_sheet = workbook.sheets[sheet_index]

          columns = Hash.new

          1.upto(workbook.last_column) do |col|
            columns[workbook.cell(1, col).to_sym] = col
          end

          2.upto(workbook.last_row) do |line|
            validator                       = workbook.cell(line, columns[:validator])
            pattern                         = workbook.cell(line, columns[:pattern])
            reference                       = workbook.cell(line, columns[:reference])
            component                       = workbook.cell(line, columns[:component])
            alm_df                          = workbook.cell(line, columns[:alm_df])
            jira_ref                        = workbook.cell(line, columns[:jira_ref])
            description                     = workbook.cell(line, columns[:description])

            # pattern                         = pattern ? Regexp.escape(pattern) : nil

            @html_error_references[pattern] = {
                :validator   => validator,
                :reference   => reference,
                :component   => component,
                :alm_df      => alm_df,
                :jira_ref    => jira_ref,
                :description => description }
          end
        else
          failed_to_log("Worksheet '#{sheet}' not found #{file}")
        end

        [@html_filters, @html_error_references]
      rescue
        failed_to_log(unable_to)
      end

      def parse_test_flag(string)
        test    = false
        refs    = nil
        arr     = string.is_a?(Array) ? string : string.to_s.split(/,\s*/)
        ref_arr = []
        arr.each { |r| ref_arr << format_reference(r) }
        if string
          if string == true or string == false
            test = string
          else
            if string.length > 0
              unless string =~ /^no$|^false$/i
                test = true
                unless string =~ /^yes$|^true$/i
                  refs = format_refs(string)
                end
              end
            end
          end
        end
        [test, refs, ref_arr]
      rescue
        failed_to_log(unable_to)
      end


    end
  end
end
