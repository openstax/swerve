swerve
======

**S**oft**W**are **E**nvironment **R**eproduced in a **V**agrant **E**nvironment

OpenStax is a collection of educational web sites that work in concert to improve student learning.  Doing development work on one site normally means interacting with the others.  Setting up development instances of all the sites (with the particular dependencies and connections) can be a pain.  Swerve is a vagrant environment with tools for easily setting up all of the sites, starting/stopping servers, checking on the status of the servers, etc.

Installation
---------------

There are just a few steps to prepare your computer for using Swerve.

1. Install Vagrant -- go to [vagrantup.com](http://www.vagrantup.com) and install the appropriate package for your operating system.
2. Install the `vagrant-berkshelf` plugin, by running `vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1` at the command line. If you run into weird errors about `dep_selector`, and you are on OS X, make sure your XCode installation and its command-line tools are up-to-date.
3. Install VirtualBox -- go to [virtualbox.org/](http://www.virtualbox.org) and install the appropriate package for your operating system.
4. Clone the Swerve repository (e.g. `git clone https://github.com/openstax/swerve.git`)
5. Start up the Vagrant virtual machine by running `vagrant up` inside the cloned swerve directory. It will take a while to boot up the virtual machine (as it is not only booting up, but also installing required software).
6. After the virtual machine is up and running (verifiable with `vagrant status`), get into it with a call to `vagrant ssh`.  
7. This will drop you at a command prompt running inside the virtual machine. From here type `swerve tutorial` to learn how to use swerve.
8. The following steps vary depending on what site you are trying to use. Replace <sitename> with the short name of the site in question. For example, use ost for OpenStax Tutor (Legacy).
  a. `swerve download <sitename>` will download the site.
  b. `swerve init <sitename>` will install the required libraries and initialize the database.
  c. `swerve start <sitename>` will start the server for the site.
