Awetestlib
==========

Run automated regression and mobile tests

After completing this guide you will be able to run tests locally from command line or from an IDE

------------

## Prerequisites

You need to have Ruby 1.8.7 installed. You can download Ruby 1.8.7 
[here](http://rubyinstaller.org/downloads/)

You can check your Ruby version using:

    ruby -v

Additionally, you will need to install DevKit to compile a few dependent gems. You can download DevKit
[here](http://rubyinstaller.org/downloads/)
and the installation directions can be found
[here](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit)

## Install

In a terminal or command prompt, install the awetestlib gem

    gem install awetestlib --no-ri --no-rdoc

Note: This could take up to 5 minutes for first time installs and you may need to use 'sudo'


## Setup Regression Module

To setup the regression module, run the following command and verify the step
  
    awetestlib regression_setup

## Usage

Run the following command to see the different usages

    awetestlib

## Setup Browsers

### Setup Safari (Mac OS X only)

To setup support for Safari browser, please follow the instructions at [SafariDriver](http://code.google.com/p/selenium/wiki/SafariDriver) 

### Setup Chrome
To setup support for Google Chrome browser, please download the latest Chromedriver version from [here](http://code.google.com/p/chromedriver/downloads/list) 

Then move the executables in your PATH. To find your PATHs, type the command below in your terminal/command prompt

For Mac OSX:

    echo $PATH

For Windows:

    PATH
    
### Setup Internet Explorer
To setup support for Internet Explorer, please download the latest IEDriver version from [here](http://code.google.com/p/selenium/downloads/list) 
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

    Usage: awetestlib <script_file> [parameters] [options]
        -b, --browser BROWSER            Specify a browser (IE, FF, S, C)
        -l, --library LIBRARY            Specify a library to be loaded
        -r, --root_path ROOT_PATH        Specify the root path
        -x, --excel EXCEL_FILE           Specify an excel file containing variables to be loaded
        -v, --version VERSION            Specify a browser version

To start writing your own script, refer to the [Scripting Guide/Wiki](https://github.com/3qilabs/awetestlib/wiki/Getting-Started---Scripting) wiki

### Cucumber Support 

One of the technologies that the Awetest framework supports is [Cucumber](http://cukes.info/). To get setup with cucumber, you can run the following command: `awetestlib cucumber_setup` which will create your typical cucumber folder structure.

Visit our [wiki](https://github.com/3qilabs/awetestlib/wiki/Predefined-Cucumber-Web-Steps) to see the list of predefined steps provided by awetestlib


