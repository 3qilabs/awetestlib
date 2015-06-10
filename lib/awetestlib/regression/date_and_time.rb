module Awetestlib

  module Regression

    module DateAndTime

      def get_date_names(date = Date.today, language = 'English')
        this_month = date.month
        next_month = this_month == 12 ? 1 : this_month + 1
        prev_month = this_month == 1 ? 12 : this_month - 1

        month_arr = get_months(language)

        this_month_name = month_arr[this_month]
        next_month_name = month_arr[next_month]
        prev_month_name = month_arr[prev_month]

        arr = [date.year.to_s, date.day.to_s, this_month_name, next_month_name, prev_month_name]
        debug_to_log("#{__method__} #{nice_array(arr)}")
        arr
      end

      def get_days(language = 'English', abbrev = 0)
        case language
          when /english/i
            full_arr = Date::DAYNAMES

          # TODO: commented words with diacriticals until we can fix encoding confusion with mac/safari
          when /french/i, /francais/i #, /français/i
            full_arr = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]

          else
            failed_to_log(with_caller("Language #{language} not yet supported."))
            full_arr = nil
        end

        if abbrev > 0
          rtrn_arr = []
          full_arr.each do |m|
            rtrn_arr << m.slice(0, abbrev)
          end
        else
          rtrn_arr = full_arr
        end

        rtrn_arr
      rescue
        failed_to_log(unable_to)
      end

      def next_day(yr, mo, dy, diff = 1)
        tdy = DateTime.new(yr.to_i, mo.to_i, dy.to_i, 0, 0, 0)
        tdy.advance(:days => diff).strftime("%Y-%m-%d")
      end

      def next_month(this)
        unless this.is_a?(Fixnum)
          this = this.to_i
        end
        nxt = this == 12 ? 1 : this + 1
        nxt.to_s.rjust(2, '0')
      end

      def next_month_name(this, language = 'English')
        unless this.is_a?(Fixnum)
          this = get_months(language).index(this)
        end
        nxt = this == 12 ? 1 : this + 1
        get_months(language)[nxt]
      end

      def prev_day(yr, mo, dy, diff = -1)
        diff = diff > 0 ? -diff : diff
        tdy  = DateTime.new(yr.to_i, mo.to_i, dy.to_i, 0, 0, 0)
        tdy.advance(:days => diff).strftime("%Y-%m-%d")
      end

      def prev_month(this)
        prev = this.to_i == 1 ? 12 : this.to_i - 1
        prev.to_s.rjust(2, '0')
      end

      def prev_month_name(this, language = 'English')
        unless this.is_a?(Fixnum)
          this = get_months(language).index(this)
        end
        prev = this == 1 ? 12 : this - 1
        get_months(language)[prev]
      end

      def get_mdyy(t = Time.now)
        "#{t.month}/#{t.day}/#{t.year}"
      end

      def get_month_name(this, language = 'English')
        unless this.is_a?(Fixnum)
          this = get_months(language).index(this)
        end
        get_months(language)[this]
      end

      def get_month_names(date = Date.today)
        this_month = date.month
        if this_month == 12
          next_month = 1
        else
          next_month = this_month + 1
        end
        if this_month == 1
          prev_month = 12
        else
          prev_month = this_month - 1
        end

        month_arr = Date::MONTHNAMES

        this_month_name = month_arr[this_month]
        next_month_name = month_arr[next_month]
        prev_month_name = month_arr[prev_month]

        arr = [date.year, date.day, this_month_name, next_month_name, prev_month_name]
        debug_to_log("#{__method__} #{nice_array(arr)}")
        arr

      end

      def get_months(language = 'English', abbrev = 0)
        case language
          when /english/i
            full_arr = Date::MONTHNAMES

          # TODO: commented words with diacriticals until we can fix encoding confusion with mac/safari
          when /french/i, /francais/i #, /français/i
            full_arr = [nil, 'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
                        'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre']
          # full_arr = [nil, 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          #             'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre']
          else
            failed_to_log(with_caller("Language #{language} not yet supported."))
            full_arr = nil
        end

        if abbrev > 0
          rtrn_arr = []
          full_arr.each do |m|
            if m
              rtrn_arr << m.slice(0, abbrev)
            else
              rtrn_arr << nil
            end
          end
        else
          rtrn_arr = full_arr
        end

        rtrn_arr
      rescue
        failed_to_log(unable_to(language))
      end

      def translate_month_name(name, to, from = 'English')
        get_months(from).index(name)
        get_months(to)[get_months(from).index(name)]
      end

      def get_timestamp(format = 'long', offset = nil, offset_unit = :years)
        t = DateTime.now
        if offset
          t = t.advance(offset_unit => offset)
        end
        case format
          when 'dateonly'
            t.strftime("%m/%d/%Y")
          when 'condensed'
            t.strftime("%Y%m%d%H%M")
          when 'condensed_seconds'
            t.strftime("%Y%m%d%H%M%S")
          when 'long'
            t.strftime("%m/%d/%Y %I:%M %p")
          when 'mdyy'
            get_mdyy(t)
          when 'm/d/y'
            get_mdyy(t)
          else
            Time.now.strftime("%m/%d/%Y %H:%M:%S")
        end
      end

      def tic(new = false)
        now = Time.now.utc
        if new
          @tic_tic = now
        else
          debug_to_log(with_caller("#{now.to_f - @tic_tic.to_f}", "#{get_call_array(2)[1]}"))
          @tic_tic = now
        end
      end

      def tic_m(msg = '')
        now = Time.now.utc
        debug_to_log(with_caller("#{now.to_f - @tic_tic.to_f}", "#{get_call_array(2)[1]}", msg))
        @tic_tic = now
      end

      def time_it(container, desc, timeout = 3, &block)
        start = Time.now.to_f
        begin
          Watir::Wait.until(timeout) { block.call(nil) }
        rescue => e
          if e.class.to_s =~ /TimeOutException/ or e.message =~ /timed out/
            debug_to_log("#{desc} '#{$!}'")
            return Time.now.to_f - start
          elsif not rescue_me(e, __method__, "#{block.to_s}", "#{container.class}")
            raise e
          end
        end
        duration = Time.now.to_f - start
        debug_to_report(with_caller(desc, duration.to_s))
        duration
      rescue
        failed_to_log(unable_to(desc))
      end

      def sec2hms(s)
        Time.at(s.to_i).gmtime.strftime('%H:%M:%S')
      end

      def pad_date(dt)
        if dt and dt.length > 0
          a, d1, b, d2, c = dt.split(/([\/\.-])/)
          a = a.rjust(2, '0') unless a and a.length > 1
          b = b.rjust(2, '0') unless b and b.length > 1
          c = c.rjust(2, '0') unless c and c.length > 1
          a + d1 + b + d2 + c
        else
          ''
        end
      end

      def convert_y_m_d_to_ymd(yrs, mos, dys, fmt_out = '%Y-%m-%d', alt_fmt = '%Y-%m')
        dys = [dys] unless dys.is_a?(Array)
        mos = [mos] unless mos.is_a?(Array)
        yrs = [yrs] unless yrs.is_a?(Array)
        arr = []
        if dys.size > 0
          dys.each do |dy|
            mo = mos[dys.index(dy)] ? mos[dys.index(dy)] : mos[0]
            yr = yrs[dys.index(dy)] ? yrs[dys.index(dy)] : yrs[0]
            arr << DateTime::parse("#{dy}/#{mo}/#{yr}").strftime(fmt_out).sub(/^0/, '')
          end
        else
          mos.each do |mo|
            yr = yrs[mos.index(mo)] ? yrs[mos.index(mo)] : yrs[0]
            arr << DateTime::parse("1/#{mo}/#{yr}").strftime(alt_fmt).sub(/^0/, '')
          end
        end
        arr
      rescue
        failed_to_log(unable_to("y:#{yrs}, m:#{mos}, d:#{dys}"))
      end

      def parse_mdy_to_datetime(mdy)
        if mdy and mdy.length > 0
          m, d1, d, d2, y = mdy.split(/([\/\.-])/)
          y = "20#{y}" unless y.length == 4
          ymd = "#{y}#{d1}#{m}#{d1}#{d}"
          DateTime.parse(ymd)
        end
      rescue
        failed_to_log(unable_to)
      end

      def diff_datetimes_in_days(beg_dt, end_dt)
        (end_dt - beg_dt).to_i
      end


    end
  end
end
