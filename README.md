swerve
======

**S**oft**W**are **E**nvironment **R**eproduced in a **V**agrant **E**nvironment

OpenStax is a collection of educational web sites that work in concert to improve student learning.  Doing development work on one site normally means interacting with the others.  Setting up development instances of all the sites (with the particular dependencies and connections) can be a pain.  Swerve is a vagrant environment with tools for easily setting up all of the sites, starting/stopping servers, checking on the status of the servers, tailing logs, etc.

Installation
---------------

There are just a few steps to prepare your computer for using Swerve.

1. Install Vagrant -- go to [vagrantup.com](vagrantup.com) and install the appropriate package for your OS.
2. Clone the Swerve repository (e.g. `git clone https://github.com/openstax/swerve.git`)
3. At the command line, go into the cloned directory (e.g. `cd swerve`) and run `bundle install`.  This will install "Berkshelf" a tool for grabbing and running Chef cookbook dependencies as needed.
4. Install the `vagrant-berkshelf` plugin, by running `vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1` at the command line.
5. Start up the Vagrant virtual machine by running `vagrant up` inside the cloned swerve directory.