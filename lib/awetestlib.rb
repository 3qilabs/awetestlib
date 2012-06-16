require 'yaml'
require 'active_support/core_ext/hash'

module Awetestlib
  ::USING_WINDOWS = !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM=~ /mswin|mingw/))
  ::USING_OSX     = RUBY_PLATFORM =~ /darwin/

  BROWSER_MAP = {
      'FF' => 'Firefox',
      'IE' => 'Internet Explorer',
      'S'  => 'Safari',
      'MS' => 'Mobile Safari',
      'C'  => 'Chrome'
  }

  BROWSER_ALTERNATES = {
      'OSX'     => { 'IE' => 'S' },
      'Windows' => { 'S' => 'IE' }
  }

  if USING_WINDOWS
    #require 'win32ole' <-- We'll load this later in Shamisen::AwetestLegacy::Runner. It has to be loaded after watir, see https://www.pivotaltracker.com/story/show/19249981
    require 'win32/screenshot'
  end
  #require 'active_support/inflector'
  #require 'active_support/core_ext/object'
  #require 'active_support/core_ext/hash'

  require 'andand'
  require 'regression/runner'


  if USING_OSX
    require 'appscript'
  end

  require 'roo'

end
