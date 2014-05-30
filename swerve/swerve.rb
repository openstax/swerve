require "thor"
require 'rainbow'
require 'command_line_reporter'
require 'debugger'
require 'fileutils'
require 'git'
require './utilities'
require './network'
require './runner'
require './site'
require './site_repo'


class Swerve < Thor

  include CommandLineReporter

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
      }

    ]
  }

  @@sites = CONFIG[:sites].collect{|site_config| Site.new(site_config)}

  desc "status", "Lists the status of the sites"
  def status

    table :border => false do
      row :header => true, :color => 'blue'  do
        column 'Site', :width => 20, :align => 'left'
        column 'Active Repo', width: 20, align: 'left'
        column 'Current Branch', width: 20, align: 'left'
        column 'Port (Swerve => Host)', :width => 21
      end

      @@sites.each do |site|
        repo = site.active_repo
        row color: (site.downloaded? ? 'green' : 'red') do
          column site.name
          column repo ? repo.github_path : '---'
          column repo ? repo.current_branch.to_s : '---'
          column site.up? ? "#{site.port} => #{site.port * 10}" : '(offline)'
        end
      end

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
    sites = select_sites(site_labels, "Which site(s) do you want to download?")
    sites.each {|site| site.download }
  end

  desc "init [<SITELABEL>...]", "Runs site-specific initialization actions for the specified sites' active repositories."
  long_desc <<-LONGDESC
    Runs site-specific initialization actions for the specified sites' active repositories.  These actions
    normally include things like #{Rainbow('deleting').red} and re-initialize the active database.

    #{site_labels_help('init')}

  LONGDESC
  def init(*site_labels)
    sites = select_sites(site_labels, "Which site(s) do you want to reset?")

    if yes?("Are you sure you want to init the active repositories for these sites?: #{sites.collect{|site| site.name}.join(', ')}")
      sites.each {|site| site.init }
    else
      say "Init canceled."
    end
  end

  desc "update [<SITELABEL>...]", "Runs site-specific update actions for the specified sites' active repositories."
  def update(*site_labels)
    sites = select_sites(site_labels, "Which site(s) do you want to update?")
    sites.each {|site| site.update(true) }
  end

  desc "start [<SITELABEL>...]", "Starts the servers for the specified sites."
  long_desc <<-LONGDESC
    Starts the servers for the specified sites' active repositories.  Make sure
    you have run "swerve init" for these servers before calling "start".

    #{site_labels_help('reset')}

  LONGDESC
  def start(*site_labels)
    sites = select_sites(site_labels, "Which site(s) do you want to start?")
    sites.each {|site| site.start }
  end

  desc "stop [<SITELABEL>...]", "Stops the servers for the specified sites."
  long_desc <<-LONGDESC
    Stops the servers for the specified sites' active repositories.

    #{site_labels_help('reset')}

  LONGDESC
  def stop(*site_labels)
    sites = select_sites(site_labels, "Which site(s) do you want to stop?")
    sites.each {|site| site.stop }
  end

  desc "restart [<SITELABEL>...]", "Restarts the servers for the specified sites."
  long_desc <<-LONGDESC
    Stops and starts the servers for the specified sites' active repositories.

    #{site_labels_help('reset')}

  LONGDESC
  def restart(*site_labels)
    sites = select_sites(site_labels, "Which site(s) do you want to restart?")
    sites.each {|site| site.restart }
  end


protected


  # Either uses the user input in site_labels to retrieve an array of Sites,
  # or shows the user a list of Sites and asks them to select some (then returns
  # those)
  def select_sites(site_labels, question, options={})

    options[:hide_choices] ||= false
    selected_sites = []

    if site_labels.empty?
      choices = @@sites.collect{|site| [site.name, [site]]}
      choices.push(['All', @@sites])

      if !options[:hide_choices]
        table :border => false do
          choices.each_with_index do |choice, index|
            row do
              column "(#{index})", align: 'right', width: 4
              column choice[0], width: 40
            end
          end
        end
      end

      selected_indices = ask(question).split(" ")

      if selected_indices.all? {|si| si.is_i? }
        selected_sites = selected_indices.collect{|si| choices[si.to_i][1]}.flatten
      else
        say Rainbow("Please enter a number or numbers separated by spaces! (or CTRL + C to exit)").red
        selected_sites = select_sites(label, question, hide_choices: true)
      end
    else
      

      if site_labels.any?{|site_label| site_label =~ /all/i}
        selected_sites = @@sites 
      else
        selected_sites = @@sites.select{|site| site_labels.any?{|site_label| site_label.downcase.starts_with?(site.unique_label.downcase)}}
      end
    end

    say Rainbow("The input '#{site_labels.join(' ')}' did not match any sites.").red if selected_sites.empty?
    return selected_sites
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

end

Swerve.start(ARGV)