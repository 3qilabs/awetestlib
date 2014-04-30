# -*- encoding: utf-8 -*-
require "lib/version"

Gem::Specification.new do |s|

  s.name = %q{awetestlib}
  s.version = Awetestlib::VERSION
  s.date = Awetestlib::VERSION_DATE
  s.platform = Gem::Platform::CURRENT

  #s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Patrick Neve", "Anthony Woo"]
  s.email = %q{patrick@3qilabs.com}
  s.summary = %q{Tools for automated testing of browser-based and mobile applications.}
  s.homepage = %q{http://3qilabs.com}
  s.description = %q{Includes Cucumber, Calabash, and Awetest DSL.}

  s.add_dependency('nokogiri')
  s.add_dependency('watir-webdriver')
  #s.add_dependency('selenium-webdriver') # installed by watir-webdriver
  s.add_dependency('activesupport')
  s.add_dependency('i18n')
  s.add_dependency('andand')
  s.add_dependency('win32-process')
  s.add_dependency('win32screenshot')
  #s.add_dependency('mini_magick') # installed by win32screenshot
  s.add_dependency('roo')
  #s.add_dependency('spreadsheet')  # installed by roo
  s.add_dependency('google-spreadsheet-ruby')
  s.add_dependency('pry')
  #s.add_dependency('rdoc') # installed with Ruby 2.0.0
  s.add_dependency('calabash-android')
  #s.add_dependency('cucumber') # installed by calabash-android
  s.add_dependency('sys-uname')

  s.require_paths = ["lib"]
  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

end

