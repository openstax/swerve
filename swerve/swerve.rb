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
            "klb/ost",
            "kjd/ost"
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
      }

    ]
  }

  @@sites = CONFIG[:sites].collect{|site_config| Site.new(site_config)}

  desc "refresh", "Makes sure all sites are installed and have up-to-date code"
  def refresh
    puts Rainbow("TBD").red
    get_site("ost").refresh
  end

  desc "status", "Lists the status of the sites"
  def status
    # debugger
    # get_site("ost").refresh
    table :border => false do
      row :header => true, :color => 'blue'  do
        column 'Site', :width => 20, :align => 'left'
        column 'Repo', width: 20, align: 'left'
        column 'Branch', width: 20, align: 'left'
        column 'Up?', :width => 10
      end

      @@sites.each do |site|
        repo = site.current_repo
        row color: (site.installed? ? 'black' : 'white_on_black') do
          column site.name
          column repo ? repo.github_path : '---'
          column repo ? repo.current_branch.to_s : '---'
          column site.up? ? 'Yes' : 'No'
        end
      end

    end
  end

protected

  def installed?(site_name)

  end

  def get_site(site_name)
    @@sites.select{|site| site.named?(site_name)}[0]
  end

end

Swerve.start(ARGV)