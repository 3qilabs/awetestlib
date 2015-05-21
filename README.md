Awetestlib
==========

Automate testing of browser-based applications in Windows, Android, OSX, and iOS.

After completing this guide you will be able to run tests locally from command line or from an IDE.

------------
## Prerequisites: Ruby 2.x and RubyInstaller Devkit (Windows) or Xcode (Mac)

### Windows
#### Ruby 2.x
You need to have Ruby 2.x installed using the RubyInstaller package.

You can download the RubyInstaller
[here](http://rubyinstaller.org/downloads/).  

Awetestlib 2.0.x is tested with Ruby 2.0.0 but should work with more recent 2.x versions.

**Install in a directory without spaces, like C:\Ruby187. Don't install in Program Files.**

**Make sure you tell the installer to put Ruby in the PATH environment variable.**

You can check your Ruby version using:

    ruby -v


#### RubyInstaller Devkit (Windows only)
Additionally, for Windows, you will need to install the RubyInstaller DevKit to compile a few dependent gems.

Download DevKit
[from here](http://rubyinstaller.org/downloads/)
and the installation directions can also be found
[here](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit).

Choose the one for your Ruby and development platform (OS and 32/64 bit)

Create directory C:\devkit and unzip the devkit package into that directory.

Open a command window and change to C:\devkit.

Then execute

	ruby dk.rb init

And do

	ruby dk.rb review 

And make sure you see C:\Ruby2xx at the end of the output.  Now

	ruby dk.rb install

If you have difficulties with the above in Windows 7 and/or behind a firewall, you may have to set the http_proxy and/or run the installers as administrator. (see below)

### Mac
#### Ruby
(Ruby 1.8.7 is installed by default in OSX. Mountain Lion has 1.8.7 p358 which should be fine.)

#### Xcode
Follow Mac instructions for installing/upgrading Xcode to latest version.

## Install Awetestlib

**Start** by opening a command window or terminal

----------

#### NOTE: If you are behind a firewall:

1. You will need to set the http_proxy environment variable
2. You may have to change the HOMEDRIVE environment variable to C: in Windows at least temporarily
3. You may need to run the Windows 7 command window as administrator.

In Windows

	set http_proxy=http://myproxy.mycompany.com:80
	set HOMEDRIVE=C:

In OSX

	export HTTP_PROXY=http://myproxy.mycompany.com:80


----------
#### Temporary but necessary (13may2013)

In the command window:

	gem install nokogiri -v 1.5.9 --no-ri --no-rdoc

And

	gem install mini_magick -v 3.5.0 --no-ri --no-rdoc

**Then**, in the command window, install the awetestlib gem.

Note: This could take up to 5 minutes for first time installs.  You may need to use 'sudo' on OSX

    gem install awetestlib --no-ri --no-rdoc

**Then** run the following command and verify the step

    awetestlib regression_setup

### Usage

Run the following command to see the different usages

    awetestlib

## Setup Browsers
### Safari (OSX only)
To setup support for Safari browser, download the Selenium Safari Standalone Server from [Selenium downloads](https://code.google.com/p/selenium/downloads/list).  
Select selenium-server-standalone-x.xx.xx.jar.  (The version is 2.33.0 as of this writing.)  Download it and copy it into /Library/Java/Extensions.
You will need to start this process in a terminal session before running Safari scripts, else you will get a 'waiting for connection' error. 
Start it with this command in a terminal session:

	nohup java -jar /Library/Java/Extensions/selenium-server-standalone-2.33.0.jar & 

When using raw Watir-webdriver for Safari, open the browser with

    browser = Watir::Browser.new(:remote, :desired_capabilities=>:'safari')

A Caveat: The Selenium SafariDriver currently cannot handle modal alerts/windows, except to dismiss them (invisibly) whenever they exist. ([Issue 3862](https://code.google.com/p/selenium/issues/detail?id=3862))  
This means that any modal, expected or not, will not be visible when the selenium-server-standalone is running.  Expected alerts ('Are you sure?') also do not appear, even when manually clicking link or button that should produce alert. 

### Firefox

Firefox support is built into the selenium-webdriver gem (required by the watir-webdriver gem) for both Windows and OSX.  

### Chrome
To setup support for Google Chrome browser, please download the latest Chromedriver version for your platform from [here](http://code.google.com/p/chromedriver/downloads/list)

Then move the executables into your PATH. To find your PATH, type the command below in your terminal/command prompt:

For Mac OSX:

    echo $PATH

For Windows:

    PATH

### Internet Explorer (Windows only)
To setup support for Internet Explorer, please download the latest IEDriverServer version from [here](http://code.google.com/p/selenium/downloads/list)
and move the executable into your PATH.

We suggest putting the Chrome and IE drivers in C:\Ruby2xx\bin (in Windows) as it should already be in your path.

## Setup IDEs (Rubymine, Netbeans)

To setup the awetestlib gem with Rubymine use:

    awetestlib rubymine_setup <ProjectName>

To setup awetestlib with Netbeans use:

    awetestlib netbeans_setup <ProjectName>

You can now start your scripts within the IDE. Follow the instructions in each IDE for creating and executing run/debug configurations.

For additional information on IDE setup, refer to the links below:

  - [Netbeans IDE setup](https://github.com/3qilabs/awetestlib/blob/develop/netbeans_setup.md)

  - [Rubymine IDE setup](https://github.com/3qilabs/awetestlib/blob/develop/rubymine_setup.md)

## Command Line Execution
If you prefer to run your tests from command line, you can use the following command

  `awetestlib <script_file> [parameters]`

  For example: To run a script named demo.rb in Firefox, your command will look like:

  `awetestlib demo.rb -b FF`

Here is the full list of the currently available command line parameters:

    "-b", "--browser BROWSER",                            "Specify a browser by abbreviation (IE, FF, S, C) Required.")
    "-d", "--debug",                                      "Turn on dsl debug messaging")
    "-e", "--environment_url ENVIRONMENT_URL",            "Specify the environment URL")environment_url
    "-f", "--environment_node_name ENVIRONMENT_NODENAME", "Specify the environment node name")
    "-l", "--library LIBRARY",                            "Specify a library to be loaded")
    "-m", "--run_mode RUN_MODE",                          "Specify the run mode: local, local_zip, remote_zip")
    "-n", "--environment_name ENVIRONMENT_NAME",          "Specify the environment name")
    "-o", "--output_to_log",                              "Write all output to log file")
    "-p", "--pry",                                        "Require Pry for debugging")
    "-r", "--root_path ROOT_PATH",                        "Specify the root path.  Defaults to current directory")
    "-s", "--screencap-path SCREENCAP_PATH",              "Specify the path where screenshots will be saved")
    "-t", "--locate_timeout LOCATE_TIMEOUT",              "Set timeout for locating DOM elements.")
    "-u", "--selenium_remote_url SELENIUM_REMOTE_URL",    "Specify the device's remote url and port")
    "-v", "--version VERSION",                            "Specify an expected browser version")
    "-x", "--excel EXCEL_FILE",                           "Specify an excel file containing test data to be loaded")
    "-E", "--emulator EMULATOR",                          "Mobile emulator image (avd)")
    "-T", "--device_type DEVICE_TYPE",                    "Mobile device type (ipad, iphone, phone, tablet)")
    "-I", "--device_id DEVICE_ID",                        "Mobile device identifier 'UDID' or serial number")
    "-K", "--sdk SDK",                                    "Mobile native sdk. Optional for Android")
    "-P", "--platform PLATFORM",                          "Mobile or desktop platform: Android, iOS, Windows, or OSX")
    "-S", "--log_path_subdir LOG_PATH_SUBDIR",            "Specify log path relative to root_path.")
    "-R", "--report_all_test_refs",                       "Include report of all error/test case reference ids actually validated.")
    "-D", "--global_debug",                               "Set all global debug variables to true. ($DEBUG, $debug, $Debug")
    "-L", "--capture_load_times",                         "Capture load time for gem requires.")
      
To start writing your own script, refer to the [Scripting Guide/Wiki](https://github.com/3qilabs/awetestlib/wiki/Getting-Started---Scripting) wiki.

For the latest documentation of the Awetest DSL go to [Rubydoc](http://rubydoc.info/gems/awetestlib) and look in Awetestlib::Regression.

### Cucumber, Calabash, and Classic Watir Support (discontinued)

Awetestlib 2.x no longer supports Cucumber, Calabash, or Classic Watir.

3qiLabs' flagship product Awetest Server and the worker software Shamisen support Cucumber, Calabash, Awetestlib and a number of other technologies.
See 3qilabs.com for details.
