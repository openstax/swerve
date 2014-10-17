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
  config.vm.box = "trusty64"
  config.vm.box_url = "https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/1/providers/virtualbox.box"

  # Use NFS for shared folders for better performance
  # Required for NFS to work, pick any local IP
  config.vm.network :private_network, ip: '192.168.50.50'
  config.vm.synced_folder '.', '/vagrant', nfs: true

  # Alternative sync strategy
  #
  # config.vm.synced_folder ".", "/vagrant", type: "rsync"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.berkshelf.enabled = true
  config.ssh.forward_agent = true

  guest_to_host_ports = {
    2999 => 2999,
    3000 => 3000,
    3001 => 3001,
    3002 => 3002,
    3003 => 3003
  }

  guest_to_host_ports.each do |guest, host|
    config.vm.network :forwarded_port, guest: guest, host: host
  end

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
