When /^I open a new browser$/ do
	if @params
	  case @params["browser"]
		  when "FF"; @browser = Watir::Browser.new :firefox
		  when "IE"; @browser = Watir::Browser.new :ie
		  when "C", "GC"; @browser = Watir::Browser.new :chrome	
	  end
	else
		@browser = Watir::Browser.new
	end
end

Given /^I open a firefox browser$/ do
  @browser = Watir::Browser.new :firefox
end

Given /^I open a chrome browser$/ do
  @browser = Watir::Browser.new :chrome	
end

Given /^I open an internet explorer browser$/ do
  @browser = Watir::Browser.new :ie
end

Then /^I navigate to the environment url$/ do
  url = @params['environment']['url']
  @browser.goto url
end

Then /^I go to the url "(.*?)"$/ do |url|
  @browser.goto url
end

Then /^I click "(.*?)"$/ do |element_text|
	sleep 1
  @browser.element(:text, element_text).click
end

Then /^I click the button "(.*?)"$/ do |element_text|
	sleep 1
  @browser.button(:text, element_text).click
end

Then /^I click the element with "(.*?)" "(.*?)"$/ do |arg1, arg2|
  @browser.element(arg1.to_sym, arg2)
end

Then /^I should see "(.*?)"$/ do |text|
	sleep 1
  stm = @browser.text.include? text
  if stm
    true
  else
    fail("Did not find text #{text}")
  end
end

Then /^I should not see "(.*?)"$/ do |text|
  stm = @browser.text.include? text
  if stm
    fail("Found text #{text}")
  else
    true
  end
end

Then /^I fill in "(.*?)" with "(.*?)"$/ do |field, value| #assumes u have label
  associated_label = @browser.label(:text, field).attribute_value("for")
  #associated_label = @browser.element(:xpath, '//label[contains(text(),"#{arg1}")]').attribute_value("for"))
  @browser.text_field(:id, associated_label).set value
end


When /^I wait (\d+) seconds?$/ do |seconds|
  sleep seconds.to_i
end
