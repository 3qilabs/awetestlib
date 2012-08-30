Awetestlib
==========

Run automated regression and mobile tests

After completing this guide you will be able to run tests locally from command line or from an IDE

------------

### Prerequisites

You need to have Ruby 1.8.7 installed. You can download Ruby 1.8.7 
[here](http://rubyinstaller.org/downloads/)

Additionally, you will need to install DevKit to compile a few dependent gems. You can download DevKit
[here](http://rubyinstaller.org/downloads/)

### Install

1. In a terminal or command prompt, install the awetestlib gem
  - `gem install awetestlib --no-ri --no-rdoc`


2. To setup the regression module, run the following command and verify the step
  - `awetestlib regression_setup`

### Usage

1. Run the following command to see the different usages
  - `awetestlib`

2. To setup the awetestlib gem with Netbeans or Rubymine, run either of the commands
  - `awetestlib rubymine_setup`

  or 
  - `awetestlib netbeans_setup`

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


