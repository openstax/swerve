name             "swerve"
maintainer       "OpenStax"
license          "MIT"
description      "Installs and configures swerve environment"
version          "1.7.1"

recipe "swerve", "Installs and configures swerve"

%w{ centos redhat fedora ubuntu debian amazon oracle}.each do |os|
  supports os
end

%w{ emacs ssh_known_hosts }.each do |cb|
  depends cb
end
