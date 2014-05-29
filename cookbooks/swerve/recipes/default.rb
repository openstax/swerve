rbenv_ruby "1.9.3-p194"
rbenv_ruby "1.9.3-p545"

rbenv_gem "bundler" do
  ruby_version "1.9.3-p194"
  ruby_version "1.9.3-p545"
end

include_recipe "emacs"

required_packages = [
  "sqlite3", 
  "libsqlite3-dev",
  # To use passwords in user_account blocks
  "libshadow-ruby1.8",
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

remote_file "/usr/bin/prompt.pl" do
  source "https://raw.githubusercontent.com/kevinburleigh75/ost_bash_prompt/master/prompt.pl"
  mode 0755
end

template "/home/vagrant/.bashrc" do
  source "bashrc.erb"
end