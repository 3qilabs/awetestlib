begin_time = Time.now
require 'rubygems'
puts sprintf('%.4f', (Time.now - begin_time))
begin_time = Time.now

b = Watir::Browser.new
puts sprintf('%.4f', (Time.now - begin_time))
b.goto("www.google.com")
b.text_field(:name, "q").set("3qilabs")
sleep 5
b.button(:name, "btnG").click
b.text.include? "3QI Labs"
b.close
