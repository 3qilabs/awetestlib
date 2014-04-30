require 'pry'
require 'watir-webdriver'

browser = Watir::Browser.new(:chrome)

browser.goto('http://www.entheosweb.com/website_design/pop_up_windows.asp')
browser.link(:text, 'Click here').when_present.click

popup = browser.window(:title, 'Preview Business Template 1')

    sleep(1)

browser.close
