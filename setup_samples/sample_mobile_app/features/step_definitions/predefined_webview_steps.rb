Then /^let me debug$/ do
  binding.pry
end

Then /^I swipe "(.*?)" from the "(.*?)" label$/ do |dir, ele| #Then I swipe "up" from the "Locations" label
  query("view:'UILabel' marked:'#{ele}' first", "swipeInDirection:", dir)
end

Then /^I use the keyboard to fill in the textfield marked "(.*?)" with "(.*?)"$/ do |text_field_mark, text_to_type|
  query( "view marked:'#{text_field_mark}'", 'setText:', text_to_type )
end

Then /^I touch the switch with index "(.*?)"$/ do |idx| #Then I touch the switch with index "1"
  touch("view:'UISwitch' index:#{idx}")
end

And /I wait (\d+) seconds?/ do |seconds|  #Then I wait 3 seconds
  sleep(seconds.to_i)
end

Then /^I type "(.*?)" in the text field with id "(.*?)"$/ do |txt, id|
  set_text("webView css:'input' id:'#{id}'", txt)
end


Then /^I touch the WebView text "(.*?)"$/ do |txt|
  sleep 1
  wait_for(10){element_exists("webView css:'a' textContent:'#{txt}'")}
  touch("webView css:'a' textContent:'#{txt}'")
end

Then /^I touch the WebView button "(.*?)"$/ do |txt|
  sleep 1
  wait_for(10){element_exists("webView css:'input' textContent:'#{txt}'")}
  touch("webView css:'input' textContent:'#{txt}'")
end

Then /^I should see the WebView text "(.*?)"$/ do |txt|
  sleep 1
  if !query("webView textContent:'#{txt}'").empty?
    true
  else
    fail("Did not find WebView text '#{txt}")
  end
end

Then /^I should not see the WebView text "(.*?)"$/ do |txt|
  sleep 1
  if query("webView textContent:'#{txt}'").empty?
    true
  else
    fail("Found WebView text '#{txt}'")
  end
end

Then /^I touch the WebView button with value "(.*?)"$/ do |val|
  wait_for(10){element_exists("webView css:'input' value:'#{val}'")}
  touch("webView css:'input' value:'#{val}'")
end

When /^I touch the WebView link with index "(.*?)"$/ do |idx|
  wait_for(10){element_exists("webView css:'a' index:#{idx}")}
  touch("webView css:'a' index:#{idx}")
end

def send_command ( command )
  %x{osascript<<APPLESCRIPT
tell application "System Events"
  tell application "iPhone Simulator" to activate
  keystroke "#{command}"
  delay 1
  key code 36
end tell
APPLESCRIPT}
end

When /^I send the command "([^\\"]*)"$/ do |cmd|
  send_command(cmd)
end

