Feature:
	I want to test cucumber

Scenario:
	When I open a new browser
	Then I go to the url "http://mail.yahoo.com"
	Then I should see "Sign in to Yahoo!"
	When I fill in "Yahoo! ID" with "automationtester88"
	Then I fill in "Password" with "password1"
	Then I click the button "Sign In"
	Then I should see "Invalid ID or password."
