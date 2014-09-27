require "thor"
require 'rainbow'
require 'command_line_reporter'
require 'debugger'
require 'fileutils'
require 'git'
require './utilities'
require './network'
require './runner'
require './ui'
require './site'
require './site_repo'


class Swerve < Thor

  include CommandLineReporter
  include Ui

  # Make the help list the program as 'swerve', not 'swerve.rb'
  $PROGRAM_NAME = "swerve"

  def self.site_labels_help(command)
    <<-DESC
    You can pass a list of site labels to bypass being prompted for which sites
    to #{command}.  The site labels should start with the "unique_names" specified in the
    site configurations.

    E.g. to #{command} the Accounts and Exchange sites, you could type

    $> swerve #{command} acc exch

    As a shortcut, you can also pass 'all' to #{command} all of the sites, e.g.

    $> swerve #{command} all
    DESC
  end

  CONFIG = {
    sites: [
      {
        name: "Tutor (Legacy)",
        unique_label: "ost",
        git: {
          origin: "lml/ost",
          forks: [
            "Dantemss/ost",
            "lakshmivyas/ost",
            "kjdav/ost"
          ]
        },
        port: 3000,
        commands: {
          init: [
            "bundle install --without production",
            "bundle exec rake db:drop",
            "bundle exec rake db:create",
            "bundle exec rake db:migrate",
            "bundle exec rake db:seed"
          ],
          update: [
            "bundle",
            "bundle exec rake db:migrate"
          ],
          start: [
            "bundle exec rails server"
          ]
        }
      },
      {
        name: "Exercises",
        unique_label: "exer",
        git: {
          origin: "openstax/exercises",
          forks: [
            "Dantemss/exercises",
            "jpslav/exercises"
          ]
        },
        port: 3002
      },
      {
        name: "Accounts",
        unique_label: "acc",
        git: {
          origin: "openstax/accounts",
          forks: [
            "Dantemss/accounts",
            "jpslav/accounts"
          ]
        },
        port: 2999
      },
      {
        name: "Exchange",
        unique_label: "exc",
        git: {
          origin: "openstax/exchange",
          forks: []
        },
        port: 3003
      },
      {
        name: "Tutor",
        unique_label: "tutor",
        git: {
          origin: "openstax/tutor",
          forks: []
        },
        port: 3001,
        commands: {
          init: [
            "bundle install --without production",
            "bundle exec rake db:drop",
            "bundle exec rake db:create",
            "bundle exec rake db:migrate",
            "bundle exec rake db:seed"
          ],
          update: [
            "bundle",
            "bundle exec rake db:migrate"
          ],
          start: [
            "bundle exec rails server"
          ]
        }
      }
    ]
  }

  @@sites = CONFIG[:sites].collect{|site_config| Site.new(site_config)}

  desc "tutorial", Rainbow("Run this to get read how to get started with swerve").green.bright
  def tutorial
say <<-TUTORIAL

The 'swerve' program lets you easily download and run the sites in the
OpenStax family.

To get started, you first need to download the sites.

#{prompt('swerve download')}

This will prompt you with a list of the sites, letting you choose which you want
to download.  Choose the one called #{@@sites[0].name}.  See the "Shortcut" column?  
Most of the commands in swerve let you specify shortcuts for sites on the command 
line.  For example you could have said

#{prompt('swerve download ' + @@sites[0].unique_label)}

to have just downloaded the #{@@sites[0].name} site without being prompted to choose.

  ----------------------
  Aside: For whichever sites are chosen for downloading, all of the code repositories
  for that site will be downloaded.  There is one main repository for each site 
  (called the "origin") and then each developer has their own copy of the code.  By 
  default, the "origin" repository is the active repository for each site.  Any 
  site-specific actions you take (like starting the web server) run on that site's 
  active repository.  Sometimes, you'll want to look at code in a different repository, 
  and possibly even on a different branch.  To do this, use the #{tut('swerve repo')} and 
  #{tut('swerve branch')} commands.
  ----------------------

After you have downloaded the #{@@sites[0].name} site, take a moment to look at swerve's
status:

#{prompt('swerve status')}

This will print a table showing the status of the sites available in swerve.  Along with
the name of the site, the table shows the active repository, the active branch, and the port
of the site's server if it is online (saying '(offline)' if it is offline).  Downloaded
sites show up in green, non-downloaded ones in red.

Before a particular site can be run, it must be initialized.  To do that for the one we 
downloaded:

#{prompt('swerve init ' + @@sites[0].unique_label)}

You'll likely only want to initialize every so often.  Initialization does things like
deleting and resetting your sites' development databases.  Then to start the server:

#{prompt('swerve start ' + @@sites[0].unique_label)}

In the status table, you'll now see two ports listed for #{@@sites[0].name}.  The first is
the port used inside the swerve virtual machine.  The second is the port that is available
outside of the virtual machine.  Say this second port was 30000.  Then on your computer you
could point a browser to #{tut("http://localhost:30000")} and voila you'd see the site for
#{@@sites[0].name}.

To stop or restart the server, use the following, respectively:

#{prompt('swerve stop')}
#{prompt('swerve restart')}

If someone has developed some new code and you want to make it available to your installation
of swerve, you can do

#{prompt('swerve update')}

At any time you can say:

#{prompt('swerve help')}

to get a summary of the available commands.  Passing a command to #{tut('swerve help')} will
give you detailed help on that command, e.g.:

#{prompt('swerve help start')}

TUTORIAL
  end

  desc "status", "Lists the status of the sites"
  def status

    table :border => false do
      row :header => true, :color => 'blue'  do
        column 'Site', :width => 20, :align => 'left'
        column 'Active Repo', width: 20, align: 'left'
        column 'Active Branch', width: 20, align: 'left'
        column 'Port (Swerve => Host)', :width => 21
      end

      @@sites.each do |site|
        repo = site.active_repo
        row color: (site.downloaded? ? 'green' : 'red') do
          column site.name
          column repo ? repo.github_path : '---'
          column repo ? repo.current_branch.to_s : '---'
          column site.up? ? "#{site.port} => #{site.port}" : '(offline)'
        end
      end

    end
  end

  desc "delete [<SITELABEL>...]", "Deletes the specified sites"
  long_desc <<-LONGDESC
    Deletes the specified sites.  If you don't have any unpushed work in the sites,
    deleting them is no biggie -- you can just redownload them.  

    Note that when you destroy the Swerve virtual machine (via "vagrant destroy") the
    sites in swerve are not deleted.  This is because they are actually stored in the
    "swerve" directory you checked out from Github.  So if you want to delete them,
    you have to either call this "swerve delete" command or you have to manually delete
    them from the "swerve" directory on your machine.

    #{site_labels_help('install')}

  LONGDESC
  def delete(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to delete?",
                   inputs: site_labels)

    if yes?("Are you sure you want to delete all repositories for these sites?: #{sites.collect{|site| site.name}.join(', ')}")
      sites.each {|site| site.delete }
    else
      say "Delete canceled."
    end
  end

  desc "download [<SITELABEL>...]", "Makes sure the code is up-to-date for the specified sites"
  long_desc <<-LONGDESC
    Makes sure the code is up-to-date for all of the specified sites' repositories.  If 
    there is not yet a active repository, this command will make the origin repository
    the active one.

    #{site_labels_help('install')}

  LONGDESC
  def download(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to download?",
                   inputs: site_labels)
    sites.each {|site| site.download }
  end

  desc "init [<SITELABEL>...]", "Runs site-specific initialization actions for the specified sites' active repositories."
  long_desc <<-LONGDESC
    Runs site-specific initialization actions for the specified sites' active repositories.  These actions
    normally include things like #{Rainbow('deleting').red} and re-initialize the active database.

    #{site_labels_help('init')}

  LONGDESC
  def init(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to initialize?",
                   inputs: site_labels)

    if yes?("Are you sure you want to init the active repositories for these sites?: #{sites.collect{|site| site.name}.join(', ')}")
      sites.each {|site| site.init }
    else
      say "Init canceled."
    end
  end

  desc "update [<SITELABEL>...]", "Runs site-specific update actions for the specified sites' active repositories."
  def update(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to update?",
                   inputs: site_labels)
    sites.each {|site| site.update(true) }
  end

  desc "start [<SITELABEL>...]", "Starts the servers for the specified sites."
  long_desc <<-LONGDESC
    Starts the servers for the specified sites' active repositories.  Make sure
    you have run "swerve init" for these servers before calling "start".

    #{site_labels_help('reset')}

  LONGDESC
  def start(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to start?",
                   inputs: site_labels)
    sites.each {|site| site.start }
  end

  desc "stop [<SITELABEL>...]", "Stops the servers for the specified sites."
  long_desc <<-LONGDESC
    Stops the servers for the specified sites' active repositories.

    #{site_labels_help('reset')}

  LONGDESC
  def stop(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to stop?",
                   inputs: site_labels)
    sites.each {|site| site.stop }
  end

  desc "restart [<SITELABEL>...]", "Restarts the servers for the specified sites."
  long_desc <<-LONGDESC
    Stops and starts the servers for the specified sites' active repositories.

    #{site_labels_help('reset')}

  LONGDESC
  def restart(*site_labels)
    sites = select(site_select_choices,
                   question: "Which site(s) do you want to restart?",
                   inputs: site_labels)
    sites.each {|site| site.restart }
  end

  desc "repo [<SITELABEL>]", "Set the active repository for a site"
  long_desc <<-LONGDESC
    Sets the active repository for a site.  The user is first asked which site they
    are interested in changing, then the repository to make active.

    #{site_labels_help('repo')}

  LONGDESC
  def repo(*site_labels)
    sites = select(site_select_choices,
                   question: "For which site do you want to select the active repository?",
                   inputs: site_labels,
                   select_one: true)

    site = sites.first

    repos = select(site.repo_select_choices,
                   question: "Which repository do you want to be active? ('#{site.active_repo.github_path}' is active now)",
                   select_one: true,
                   hide_all_choice: true)

    site.set_active_repo(repos.first)

    say "#{site.active_repo.github_path} is the active repository for #{site.name}."
  end

  desc "branch [SITELABEL]", "Set the active branch for a site's active repository"
  long_desc <<-LONGDESC
    Sets the active branch for a site.  The user is first prompted for which site
    they are interested in, then the branch to change to.

    #{site_labels_help('branch')}

  LONGDESC
  def branch(*site_labels)
    sites = select(site_select_choices,
                   question: "For which site do you want to select the active branch?",
                   inputs: site_labels,
                   select_one: true)

    site = sites.first
    repo = site.active_repo

    branches = select(repo.branch_select_choices,
                      question: "Which branch do you want to be active? ('#{repo.current_branch.to_s}' is active now)",
                      select_one: true,
                      hide_all_choice: true)

    branch = branches.first

    repo.set_current_branch(branch)

    say "#{branch.name} is the active branch for #{site.name}."
  end

  desc "dir [SITELABEL]", "Get the active repository's local directory for the given site"
  long_desc <<-LONGDESC
    Get the active repository's local directory for the given site.  Useful for easily 
    changing into a site's directory with:

    #{Display.prompt('cd `swerve dir ost`')}
  LONGDESC
  def dir(*site_labels)
    sites = select(site_select_choices,
                   question: "For which site do set the current directory?",
                   inputs: site_labels,
                   select_one: true)
    say sites.first.dir
  end

protected

  def site_select_choices
    @@sites.collect{|site| {display: site.name, shortcut: site.unique_label, value: site}}
  end

  def get_site(site_name)
    @@sites.select{|site| site.named?(site_name)}[0]
  end

  def self.log(message)
    puts message if !message.nil?
  end

  def self.log_part(message)
    $stdout.sync = true
    print message if !message.nil?
  end

  def tut(message)
    Display.tut(message)
  end

  def prompt(message)
    Display.prompt(message)
  end

end

###############################################################################
# Run it!
###############################################################################

begin
  Swerve.start(ARGV)
rescue SystemExit, Interrupt
  puts "\nExited swerve."
end