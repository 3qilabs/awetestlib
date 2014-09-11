# -*- encoding: utf-8 -*-
puts "#{$0}"
# require "lib/version"
require File.expand_path('../lib/version', __FILE__)

#hack for debugging
# `wellsproxy`
#end hack

Gem::Specification.new do |s|

  s.name = %q{awetestlib}
  s.version = Awetestlib::VERSION
  s.date = Awetestlib::VERSION_DATE
  s.platform = Gem::Platform::RUBY

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Anthony Woo", "Patrick Neve"]
  s.email = %q{patrick@3qilabs.com}
  s.summary = %q{Awetest DSL for automated testing of browser-based applications.}
  s.homepage = %q{http://3qilabs.com}
  s.description = %q{Awetest DSL for automated testing of browser-based applications.}

  s.add_dependency('watir-webdriver')
  s.add_dependency('activesupport', '~> 3.2.17')
  s.add_dependency('andand')
  s.add_dependency('spreadsheet', '0.6.8')
  s.add_dependency('google-spreadsheet-ruby', '0.1.6')
  s.add_dependency('roo', '1.10.1')
  s.add_dependency('multipart-post', '2.0.0')
  s.add_dependency('selenium-webdriver')
  s.add_dependency('nokogiri')
  s.add_dependency('i18n')
  #s.add_dependency('rb-appscript')
  s.add_dependency('pry')
  s.add_dependency('cucumber')
  s.add_dependency('calabash-cucumber')
  s.add_dependency('sys-uname')
  s.require_paths = ["lib"]   #,"ext"]
  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  #This line tells rubygems to look for an extension to install
  #s.extensions = ["ext\\mkrf_conf.rb"]

end

