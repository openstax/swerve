require "thor"
require 'rainbow'
require 'command_line_reporter'
require 'debugger'
require 'fileutils'
require 'git'

class Hash
  def get_deep(*fields)
    fields.inject(self) {|acc,e| acc[e] if acc}
  end
end

class Site

  def initialize(config)
    @config = config
  end

  def named?(name)
    # Matches either the stated name or the git repo name
    @config[:name] == name || repo_name == name
  end

  def name
    @config[:name]
  end

  def repo_name
    @config.get_deep(:git, :origin).split('/')[1]
  end

  def installed?
    File.exist?(repo_path) && File.exist?("#{repo_path}/current")
  end

  def refresh
    debugger
    FileUtils.mkdir_p(repo_path)
    FileUtils.mkdir_p(repo_path + "/forks")

    # only clone if not there.
    begin
      g = Git.clone(git_ssh_url(@config.get_deep(:git, :origin)), 'origin', path: repo_path)
    rescue Git::GitExecuteError => e
      g = Git.clone(git_https_url(@config.get_deep(:git, :origin)), 'origin', path: repo_path)
    end
  end

  def repo_path
    File.expand_path("../repos/#{repo_name}")
  end

  def git_ssh_url(repo)
    "git@github.com:#{repo}.git"
  end

  def git_https_url(repo)
    "https://github.com/#{repo}"
  end

end

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
        name: "OpenStax Tutor",
        git: {
          origin: "lml/ost",
          forks: [
            "klb/ost",
            "kjd/ost"
          ]
        },
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
        }
      }

    ]
  }

  @@sites = CONFIG[:sites].collect{|site_config| Site.new(site_config)}

  desc "refresh", "Makes sure all sites are installed and have up-to-date code"
  def refresh
    puts Rainbow("TBD").red
  end

  desc "status", "Lists the status of the sites"
  def status
    debugger
    get_site("ost").refresh
    table :border => false do
      row :header => true, :color => 'blue'  do
        column 'Site', :width => 20, :align => 'left'
        column 'Fork', width: 20, align: 'left'
        column 'Branch', width: 20, align: 'left'
        column 'Up?', :width => 10
      end

      @@sites.each do |site|
        row color: (site.installed? ? 'black' : 'white_on_black') do
          column site.name
          column '---'
          column '---'
          column '---'
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