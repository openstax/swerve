# -*- mode: ruby -*-
# vi: set ft=ruby :



#
#######################################################################################
#
# Setup some developer specific environment stuff.  Do using a dot file so that
# the developer doesn't need to remember to set these in each terminal where vagrant
# is run
#
# Example .vagrant_setup.json:
#
#    {
#      "environment_variables": {
#        "ENV_NAME": "env_value"
#      }  
#    }
#

setup_file = ::File.join(::File.dirname(__FILE__), '.vagrant_setup.json')
if ::File.exists?(setup_file)
  json = JSON.parse(File.read(setup_file))
  json["environment_variables"].each do |name, value|
    ENV[name] = value
  end
end

#
#######################################################################################
#
# The "normal" Vagrant configuration
#

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.berkshelf.enabled = true

  # config.vm.network :forwarded_port, guest: 3000, host: 3000
  # config.vm.network :forwarded_port, guest: 80, host: 8080
  # config.vm.network :forwarded_port, guest: 443, host: 8081

  config.vm.provision :shell, :inline => <<-cmds 
    apt-get -y update;
    apt-get install -y build-essential;
    apt-get install -y python-software-properties;
    apt-add-repository -y ppa:brightbox/ruby-ng;
    apt-get -y update;
    apt-get install -y ruby1.9.3;
    gem install chef;
    gem install bundler --no-rdoc --no-ri --conservative;
  cmds

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe('rbenv::default')
    chef.add_recipe('rbenv::ruby_build')
    chef.add_recipe('swerve::default')
    chef.log_level = :debug
  end

  
end
