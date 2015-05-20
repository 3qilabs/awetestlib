# -*- encoding: utf-8 -*-
puts "#{$0}"
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |s|

  s.name        = %q{awetestlib}
  s.version     = Awetestlib::VERSION
  s.date        = Awetestlib::VERSION_DATE
  s.platform    = Gem::Platform::CURRENT

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors     = ["Patrick Neve", "Anthony Woo"]
  s.email       = %q{patrick@3qilabs.com}
  s.summary     = %q{Awetest DSL for automated testing desktop and mobile browser-based applications.}
  s.homepage    = %q{http://3qilabs.com}
  s.description = %q{Features robust and flexible reporting.}

  s.add_dependency('watir-webdriver', '~> 0')
  s.add_dependency('watir-nokogiri', '~> 0')
  s.add_dependency('activesupport', '~> 4.2', '>= 4.2.0')
  s.add_dependency('andand', '~> 0')
  s.add_dependency('roo', '~> 0')
  s.add_dependency('selenium-webdriver', '~> 0')
  s.add_dependency('nokogiri', '~> 0')
  s.add_dependency('i18n', '~> 0')
  s.add_dependency('appium_lib', '~> 6.0')
  s.add_dependency('pry', '~> 0')
  s.add_dependency('sys-uname', '~> 0')

  s.require_paths = ["lib"]
  s.files       = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

end
