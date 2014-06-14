class Site

  def initialize(config)
    @config = config

    @repos = { origin_github_path => SiteRepo.new(repo_path, origin_github_path) }

    @config.get_deep(:git, :forks).each do |fork_github_path|
      @repos[fork_github_path] = SiteRepo.new(repo_path, fork_github_path)      
    end
  end  

  #############################################################################
  # Swerve-level Site Actions
  #############################################################################

  def delete
    Swerve.log_part("Deleting #{name}'s repositories... ")
    FileUtils.rm_rf(repo_path)
    Swerve.log("done!")
  end

  def init
    exec_commands_in_active_repo(
      @config.get_deep(:commands, :init),
      pre_message: "Initializing #{name}'s active repository (#{active_repo.github_path})...",
      post_message: "#{name} initialization complete."
    )
  end

  def download
    FileUtils.mkdir_p(repo_path)
    run_on_repos(:download, false)
    set_active_repo(origin_repo) if !active_repo_set?  
  end

  def update(active_only = false)
    exec_commands_in_active_repo(
      @config.get_deep(:commands, :update),
      pre_message: "Updating #{name}'s active repository (#{active_repo.github_path})...",
      post_message: "#{name} update is complete."
    )
  end

  def start
    exec_commands_in_active_repo(
      @config.get_deep(:commands, :start),
      pre_message: "Starting #{name}'s active repository server (#{active_repo.github_path})...",
      fork: true
    )

    time_limit = 60
    time = 0
    sleep_duration = 1

    while time < time_limit do
      sleep(sleep_duration)
      break if up?
      time = time + sleep_duration
    end

    if up?
      Swerve.log("#{name} startup is complete, its server is active on guest port #{port}, host port #{port*10}")
    else
      Swerve.log("#{name}'s server didn't startup within #{time_limit} seconds.  If it is slow, it might still come up.  Check 'swerve status'.")
    end
  end

  def stop
    # http://stackoverflow.com/a/9346231/1664216
    if !up?
      Swerve.log("Can't stop #{name} because it isn't up.")
      return
    end

    system "kill $(lsof -t -i:#{port})"
    Swerve.log("#{name} was #{$?.success? ? '' : 'NOT'} stopped successfully.")
  end

  def restart
    stop if up?
    start
  end

  def dir
    active_link_path
  end

  #############################################################################
  # Helpers
  #############################################################################

  def exec_commands_in_active_repo(commands, options={})
    commands = [commands].compact if !commands.is_a?(Array)

    Swerve.log(options[:pre_message])

    if commands.empty?
      Swerve.log("Nothing to do.")
    else
      commands.each do |command|
        exec_command_in_active_repo(command, options.except(:pre_message, :post_message))
      end
    end

    Swerve.log(options[:post_message])
  end

  def exec_command_in_active_repo(command, options={})
    options[:errors_are_fatal] ||= false
    options[:verbose] ||= false

    Runner.run(active_link_path, command, options)
  end

  def run_on_repos(command, active_only)
    if active_only
      active_repo.send(command)
    else
      @repos.values.each {|repo| repo.send(command)}
    end
  end

  def named?(name)
    # Matches either the stated name or the git repo name
    @config[:name] == name || repo_name == name
  end

  def name
    @config[:name]
  end

  def unique_label
    @config[:unique_label]
  end

  def repo_name
    @config.get_deep(:git, :origin).split('/')[1]
  end

  def downloaded?
    File.exist?(repo_path) && File.exist?(active_link_path)
  end

  def repo_path
    File.expand_path("../repos/#{repo_name}")
  end

  def set_active_repo(repo_or_github_path)
    github_path = repo_or_github_path.is_a?(String) ? repo_or_github_path : repo_or_github_path.github_path
    FileUtils.rm(active_link_path) if active_repo_set?
    FileUtils.ln_s("#{repo_path}/#{github_path}", active_link_path)
  end

  def active_repo_set?
    File.exist?(active_link_path)
  end

  def origin_github_path
    @config.get_deep(:git, :origin)
  end

  def active_link_path
    "#{repo_path}/active"
  end

  def active_repo
    return nil if !active_repo_set?
    active_repo_github_path = File.readlink(active_link_path).split("#{repo_path}/")[1]
    @repos[active_repo_github_path]
  end

  def origin_repo
    @repos[origin_github_path]
  end

  def port
    @config[:port]
  end

  def up?
    Network.is_port_open?('localhost', port)
  end

  def repo_select_choices
    choices = []
    @repos.each_value{|repo| choices.push(display: "#{repo.github_path}#{' (origin)' if repo.github_path == origin_github_path}", shortcut: nil, value: repo)}
    choices
  end

end