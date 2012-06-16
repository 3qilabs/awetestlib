require 'rubygems/dependency_installer.rb'
using_windows = !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM=~ /mswin|mingw/))
#using_jruby = defined?(JRUBY_VERSION)
using_osx = RUBY_PLATFORM =~ /darwin/
installer = Gem::DependencyInstaller.new
begin
  puts "#{RUBY_PLATFORM}"
  if using_windows
    installer.install "watirloo", ">=0"
    installer.install "win32-process", ">=0"
    installer.install "win32-screenshot", ">=0"
    installer.install "commonwatir", "=1.8.1"
    installer.install "watir", "=1.8.1"
    installer.install "firewatir", "=1.8.1"
  elsif using_osx
    installer.install "rb_appscript", ">=0"
    installer.install "safariwatir", ">=0"
  end

rescue
  puts "#{$!}"
  exit(1)
end

f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write("task :default\n")
f.close
