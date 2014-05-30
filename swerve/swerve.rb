require "thor"
require 'rainbow'
require 'command_line_reporter'
require 'debugger'
require 'fileutils'
require 'git'
require './utilities'
require './network'
require './site'
require './site_repo'



class Swerve < Thor

  include CommandLineReporter

  # Instead of storing the "git@github...." path, store each repo
  # as a string like 'lml/ost'

  # Then when git clone, try the ssh way first (will work if user has 
  # copied ssh public and private keys into /home/vagrant/.ssh), catch
  # Git::GitExecuteError and try read-only https way next.

  CONFIG = {
    sites: [
      {
        name: "Tutor (Legacy)",
        git: {
          origin: "lml/ost",
          forks: [
            "Dantemss/ost",
            "lakshmivyas/ost",
            "kjdav/ost"
          ]
        },
        port: 3000,
        commands: []
      },
      {
        name: "Exercises",
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
        git: {
          origin: "openstax/exchange",
          forks: []
        },
        port: 3003
      }

    ]
  }

  @@sites = CONFIG[:sites].collect{|site_config| Site.new(site_config)}

  desc "refresh", "Makes sure all sites are installed and have up-to-date code"
  def refresh
    @@sites.each{ |site| site.refresh }
  end

  # desc "test", "blah"
  # def test
  #   puts "enter a char: "
  #   str = STDIN.getc
  #   puts str
  # end

  desc "status", "Lists the status of the sites"
  def status

    table :border => false do
      row :header => true, :color => 'blue'  do
        column 'Site', :width => 20, :align => 'left'
        column 'Repo', width: 20, align: 'left'
        column 'Branch', width: 20, align: 'left'
        column 'Port', :width => 10
      end

      @@sites.each do |site|
        repo = site.current_repo
        row color: (site.installed? ? 'green' : 'red') do
          column site.name
          column repo ? repo.github_path : '---'
          column repo ? repo.current_branch.to_s : '---'
          column site.up? ? site.port : '(offline)'
        end
      end

    end
  end

  # todo, maybe 'install', 'setup', 'update' methods?
  # install gets the latest versions of repos (clones/pulls)
  # update runs bundle install, rake db:migrate (or whatever the commands are in the config)

protected

  def get_site(site_name)
    @@sites.select{|site| site.named?(site_name)}[0]
  end

  def self.log(message)
    puts message
  end

  def self.log_part(message)
    $stdout.sync = true
    print message
  end

end

Swerve.start(ARGV)