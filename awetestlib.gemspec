# -*- encoding: utf-8 -*-
puts "#{$0}"
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |s|

  s.name = %q{awetestlib}
  s.version = Awetestlib::VERSION
  s.date = Awetestlib::VERSION_DATE
  s.platform = Gem::Platform::RUBY

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors     = ["Patrick Neve", "Anthony Woo"]
  s.email = %q{patrick@3qilabs.com}
  s.summary = %q{Awetest DSL for automated testing desktop and mobile browser-based applications.}
  s.homepage = %q{http://3qilabs.com}
  s.description = %q{Includes Cucumber, Calabash, and Awetest DSL.}

  s.add_dependency('watir-webdriver')
  s.add_dependency('watir-nokogiri')
  s.add_dependency('activesupport', '~> 4.2.0')
  s.add_dependency('andand')
  s.add_dependency('roo')
  s.add_dependency('selenium-webdriver','2.45.0')
  s.add_dependency('nokogiri')
  s.add_dependency('i18n')
  s.add_dependency('appium_lib', '~> 6.0')
  s.add_dependency('pry')
  s.add_dependency('calabash-android')
  s.add_dependency('calabash-cucumber')
  s.add_dependency('sys-uname')

  s.require_paths = ["lib"]   #,"ext"]
  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

end

