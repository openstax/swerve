rbenv_ruby "1.9.3-p547"
rbenv_ruby "2.1.3"

rbenv_gem "bundler" do
  ruby_version "1.9.3-p547"
end

rbenv_gem "bundler" do
  ruby_version "2.1.3"
end

include_recipe "emacs"
include_recipe "ssh_known_hosts"

required_packages = [
  "sqlite3", 
  "libsqlite3-dev",
  # To use passwords in user_account blocks
  # "libshadow-ruby1.8",   # removed when updated to Trusty
  "libxml2",
  "libxml2-dev",
  "libxslt1-dev"
]

required_packages.each do |required_package|
  package required_package do
    action [:upgrade]
  end
end

template "/usr/bin/swerve" do
  source "swerve.erb"
  mode 0755
end

# From https://raw.githubusercontent.com/kevinburleigh75/ost_bash_prompt/master/prompt.pl
template "/usr/bin/prompt.pl" do
  source "prompt.pl"
  mode 0755
end

# template "/home/vagrant/.bash_profile" do
#   source "bash_profile.erb"
# end

template "/home/vagrant/.bashrc" do
  source "bashrc.erb"
end

template "/home/vagrant/.gitconfig" do
  source "gitconfig.erb"
end

execute 'bundle install' do
  cwd '/vagrant/swerve'
end

ssh_known_hosts_entry 'github.com'