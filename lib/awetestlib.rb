#require 'yaml'    #Couldn't find use anywhere
require 'active_support/core_ext/hash'

module Awetestlib
  ::USING_WINDOWS = !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM=~ /mswin|mingw/))
  ::USING_OSX     = RUBY_PLATFORM =~ /darwin/

  # @private
  BROWSER_MAP = {
      'FF' => 'Firefox',
      'IE' => 'Internet Explorer',
      'S'  => 'Safari',
      'MS' => 'Mobile Safari',
      'C'  => 'Chrome'
  }

  # @private
  BROWSER_ALTERNATES = {
      'OSX'     => { 'IE' => 'S' },
      'Windows' => { 'S' => 'IE' }
  }

  if USING_WINDOWS
    #require 'win32ole' <-- We'll load this later in Shamisen::AwetestLegacy::Runner. It has to be loaded after watir, see https://www.pivotaltracker.com/story/show/19249981
    #require 'win32/screenshot'  # triggering segmentation fault 10sep2012 pmn
  end
  #require 'active_support/inflector'
  #require 'active_support/core_ext/object'
  #require 'active_support/core_ext/hash'
  require 'awetestlib/runner'  #; load_time
  require 'andand'  #; load_time
  require 'awetestlib/regression/runner'  #; load_time
  require 'pry'  #; load_time

  if USING_OSX
    require 'appscript'  #; load_time
  end

  #require 'roo' #moved to awetestlib runner

end
