Awetestlib
==========

Automate testing of browser-based applications in Windows or Mac.

After completing this guide you will be able to run tests locally from command line or from an IDE.

------------

## Prerequisites

You need to have Ruby 1.8.7 installed using RubyInstaller. You can download the RubyInstaller for 1.8.7
[here](http://rubyinstaller.org/downloads/).  Choose the most recent 1.8.7.  Make sure you tell the installer to put Ruby in the PATH environment variable.

You can check your Ruby version using:

    ruby -v

Additionally, for Windows, you will need to install the RubyInstaller DevKit to compile a few dependent gems. You can download DevKit
[here](http://rubyinstaller.org/downloads/)
and the installation directions can be found
[here](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit). Choose the one for Ruby 1.8.7.

## Install

In a terminal or command prompt, install the awetestlib gem:

    gem install awetestlib --no-ri --no-rdoc

Note: This could take up to 5 minutes for first time installs.  You may need to use 'sudo' on OSX



## Setup Regression Module

Run the following command and verify the step

    awetestlib regression_setup

## Usage

Run the following command to see the different usages

    awetestlib

## Setup Browsers

### Setup Safari (Mac OS X only)

To setup support for Safari browser, please follow the instructions at [SafariDriver](http://code.google.com/p/selenium/wiki/SafariDriver)

It is important to start a selenium-server-standalone process in a terminal session before running Safari scripts, else you will get a 'waiting for connection' error.

When using raw Watir-webdriver for Safari, open the browser with

    browser = Watir::Browser.new(:remote, :desired_capabilities=>:'safari')

### Setup Chrome
To setup support for Google Chrome browser, please download the latest Chromedriver version from [here](http://code.google.com/p/chromedriver/downloads/list)

Then move the executables in your PATH. To find your PATH, type the command below in your terminal/command prompt:

For Mac OSX:

    echo $PATH

For Windows:

    PATH

We suggest putting both drivers in Ruby187\bin as it will already be in your path.

### Setup Internet Explorer
To setup support for Internet Explorer, please download the latest IEDriverServer version from [here](http://code.google.com/p/selenium/downloads/list)
and move the executable into your PATH.


### Setup IDEs (Rubymine, Netbeans)

To setup the awetestlib gem with Rubymine use:

    awetestlib rubymine_setup <ProjectName>

To setup awetestlib with Netbeans use:

    awetestlib netbeans_setup <ProjectName>

You can now start your scripts within the IDE. Use the Run Configuration button.

For additional information on IDE setup, refer to the links below:

  - [Netbeans IDE setup](https://github.com/3qilabs/awetestlib/blob/develop/netbeans_setup.md)

  - [Rubymine IDE setup](https://github.com/3qilabs/awetestlib/blob/develop/rubymine_setup.md)

3. If you prefer to run your tests from command line, you can use the following command
  - `awetestlib <script_file> [parameters]`

  For example: To run a script named demo.rb in Firefox, your command will look like.
  - `awetestlib demo.rb -b FF`

The full list of parameters for the command line currently are:

    Usage: awetestlib <script_file> [parameters]
        -b, --browser BROWSER            Specify a browser (IE, FF, S, C)
        -r, --root_path ROOT_PATH        Specify the root path (default is current path)
        -l, --library LIBRARY            Specify a library to be loaded
        -x, --excel EXCEL_FILE           Specify an excel file containing variables to be loaded
        -v, --version VERSION            Specify a browser version
        -e, --environment_url URL        Specify the environment URL
        -f, --environment_nodename NODE  Specify the environment node name
        -n, --environment_name NAME      Specify the environment name
        -u, --selenium_remote_url URL    Specify the device's remote url and port
        -s, --screencap_path PATH        Specify the path where screenshots will be saved
        -o, --output_to_log              Write to log file
            --log_path_subdir SUBDIR     Specify log path relative to root_path
		-p, --pry						 Require Pry for debugging
		-c, --classic_watir				 Use Classic Watir for IE instead of Watir-webdriver
            --report_all_test_refs       Include list of all error/test case reference ids actually validated

To start writing your own script, refer to the [Scripting Guide/Wiki](https://github.com/3qilabs/awetestlib/wiki/Getting-Started---Scripting) wiki.

For the latest documentation of the Awetest DSL go to [Rubydoc](http://rubydoc.info/gems/awetestlib) and look in Awetestlib::Regression.

### Cucumber Support

One of the technologies that the Awetest framework supports is [Cucumber](http://cukes.info/). To get setup with cucumber, you can run the following command:

`awetestlib cucumber_setup <ProjectName>`

That will create the standard cucumber folder structure in the ProjectName directory.

Visit our [wiki](https://github.com/3qilabs/awetestlib/wiki/Predefined-Cucumber-Web-Steps) to see the list of predefined steps provided by awetestlib


