require 'rubygems'
require 'watir-webdriver'

b=Watir::Browser.new(:remote, :desired_capabilities=>:'safari')
b.goto("www.google.com")
b.text_field(:name ,"q").set("3qilabs")
b.button(:name,"btnG").click