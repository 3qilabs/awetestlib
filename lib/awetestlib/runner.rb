require 'open-uri'  #; load_time

module Awetestlib
  # TODO replace this with regression/runner.  Only one script type.
  # Parent class. Each script type will have a Runner that inherits from this class.
  class Runner
    def initialize(options = {})
      build_class = "Awetestlib::#{check_script_type(options[:script_type])}::Runner".constantize
      build_class.new(options).start
    end

    def check_script_type(script_type)
      case script_type
        when 'Regression', 'Awetest', 'AwetestDSL', 'Awetestlib'
          'Regression'
        else
          script_type
      end
    end
  end
end

