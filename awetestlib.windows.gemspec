# -*- encoding: utf-8 -*-
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |s|

  s.name = %q{awetestlib}
  s.version = Awetestlib::VERSION
  s.date = Awetestlib::VERSION_DATE
  s.platform = Gem::Platform::CURRENT

  #s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Anthony Woo", "Patrick Neve"]
  s.email = %q{patrick@3qilabs.com}
  s.summary = %q{Awetest DSL for automated testing of browser-based applications.}
  s.homepage = %q{http://3qilabs.com}
  s.description = %q{Awetest DSL for automated testing of browser-based applications.}

  s.add_dependency('watir-webdriver')
  s.add_dependency('watir', '1.8.1')
  s.add_dependency('commonwatir', '1.8.1')
  s.add_dependency('firewatir', '1.8.1')
  s.add_dependency('activesupport', '~> 3.0.0')
  s.add_dependency('i18n')
  s.add_dependency('andand')
  s.add_dependency('watirloo')
  s.add_dependency('win32-process', '0.6.6')
  s.add_dependency('win32screenshot')
  s.add_dependency('spreadsheet', '0.6.8')
  s.add_dependency('google-spreadsheet-ruby', '0.1.6')
  s.add_dependency('roo', '1.10.1')
  s.add_dependency('selenium-webdriver')
  s.add_dependency('pry')
  s.add_dependency('rdoc', '~> 3.11')
  s.add_dependency('cucumber')
  s.add_dependency('calabash-android')
  s.add_dependency('sys-uname')
  s.require_paths = ["lib"]
  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

end

