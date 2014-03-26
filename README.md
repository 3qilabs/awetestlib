Awetestlib
==========

Automate testing of browser-based applications in Windows or Mac.

After completing this guide you will be able to run tests locally from command line or from an IDE.

------------
## Prerequisites: Ruby 1.8.7 and RubyInstaller Devkit (Windows) or Xcode (Mac)

### Windows
#### Ruby 1.8.7
You need to have Ruby 1.8.7 installed using the RubyInstaller package.

You can download the RubyInstaller for 1.8.7
[here](http://rubyinstaller.org/downloads/).  Choose the most recent 1.8.7.

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

Choose the one for Ruby 1.8.7 and download the package.

Create directory C:\devkit and unzip the devkit package into that directory.

Open a command window and change to C:\devkit.

Then execute

	ruby dk.rb init

And do

	ruby dk.rb review 

And make sure you see C:\Ruby187 at the end of the output.  Now

	ruby dk.rb install

If you have difficulties with the above in Windows 7 and/or behind a firewall, you may have to set the http_proxy and/or run the installers as administrator. (see below)

### Mac
#### Ruby
Ruby 1.8.7 is installed by default in OSX. Mountain Lion has 1.8.7 p358 which should be fine.

#### Xcode
Follow Mac instructions for installing/upgrading Xcode to latest version.

## Install Awetestlib

**Start** by opening a command window or terminal

----------

#### NOTE: If you are behind a firewall:

1. You will need to set the http_proxy environment variable
2. You may have to change the HOMEDRIVE environment variable to C: in Windows
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

We suggest putting the Chrome and IE drivers in C:\Ruby187\bin (in Windows) as it should already be in your path.

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
            --log_path_subdir SUBDIR     Specify log path relative to root_path. Defaults to (root_path)/log if -o is specified.
		-p, --pry						 Require Pry for debugging
		-c, --classic_watir				 Use Classic Watir for IE instead of Watir-webdriver
            --report_all_test_refs       Include list of all error/test case reference ids actually validated

To start writing your own script, refer to the [Scripting Guide/Wiki](https://github.com/3qilabs/awetestlib/wiki/Getting-Started---Scripting) wiki.

For the latest documentation of the Awetest DSL go to [Rubydoc](http://rubydoc.info/gems/awetestlib) and look in Awetestlib::Regression.

### Cucumber Support

One of the technologies that the Awetest framework supports is [Cucumber](http://cukes.info/). To get setup with cucumber, you can run the following command:

`awetestlib cucumber_setup <ProjectName>`

That will create the standard cucumber folder structure in the ProjectName directory.

Visit our [wiki](https://github.com/3qilabs/awetestlib/wiki/Predefined-Cucumber-Web-Steps) to see the list of predefined steps provided by awetestlib.
