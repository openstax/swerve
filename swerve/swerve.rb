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

  desc "refresh", "Makes sure all sites are installed and have up-to-date code"
  def refresh
    puts Rainbow("TBD").red
  end

  desc "status", "Lists the status of the sites"
  def status
    debugger
    get_site_config("ost")
    table :border => false do
      row :header => true, :color => 'blue'  do
        column 'Site', :width => 20, :align => 'left', padding: 2
        column 'Fork', width: 20, align: 'left'
        column 'Branch', width: 20, align: 'left'
        column 'Up?', :width => 10
      end

      CONFIG[:sites].each do |site|
        row color: 'black' do
          column site[:name], padding: 2
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

  def get_site_config(site_name)
    # gets site by either its name or its git repo name
    CONFIG[:sites].select{|site| site[:name] == site_name}[0] ||
    CONFIG[:sites].select{|site| String(site.get_deep(:git, :origin)).match(/\/#{site_name}\.git$/)}[0]
  end




end

Swerve.start(ARGV)