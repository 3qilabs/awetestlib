require 'open-uri'
module Awetestlib
  class Runner
    def initialize(options = {})
      build_class = "Awetestlib::#{check_script_type(options[:script_type])}::Runner".constantize
      build_class.new(options).start
    end

    def check_script_type(script_type)
      case script_type
        when "Regression" ; "Regression" #Should this be regression? possible rename
        else              ; script_type
      end
    end
  end
end

