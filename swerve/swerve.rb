require "thor"
require 'rainbow'
require 'command_line_reporter'
require 'debugger'
require 'fileutils'

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
    @config[:name] == name || @config.get_deep(:git, :origin).match(/\/#{name}\.git$/)
  end

  def name
    @config[:name]
  end

  def repo_name
    match_data = @config.get_deep(:git, :origin).match(/\/(.*)\.git$/)
    raise IllegalState if match_data.nil?
    match_data[1]
  end

  def installed?
    File.exist?(File.expand_path("../repos/#{repo_name}")) &&
    File.exist?(File.expand_path("../repos/#{repo_name}/current"))
  end

end

class Swerve < Thor

  include CommandLineReporter

  CONFIG = {
    sites: [
      {
        name: "OpenStax Tutor",
        git: {
          origin: "git@github.com:lml/ost.git",
          forks: [
            "git@github.com:klb/ost.git",
            "git@github.com:kjd/ost.git"
          ]
        },
        commands: []
      },
      {
        name: "Exercises",
        git: {
          origin: "git@github.com:openstax/exercises.git",
          forks: [
            "git@github.com:Dantemss/exercises.git",
            "git@github.com:jpslav/exercises.git"
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
    get_site("ost")
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