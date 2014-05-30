class Site

  def initialize(config)
    @config = config

    @repos = { origin_github_path => SiteRepo.new(repo_path, origin_github_path) }

    @config.get_deep(:git, :forks).each do |fork_github_path|
      @repos[fork_github_path] = SiteRepo.new(repo_path, fork_github_path)      
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

  # def refresh
  #   Swerve.log("Refreshing #{name}")

  #   FileUtils.mkdir_p(repo_path)
  #   @repos.values.each { |repo| repo.refresh }
  #   set_active_repo(origin_github_path) if !active_repo_set?
  # end

  def reset(active_only = false)
    # should only do for the active repo
    puts Rainbow("TBD").red
  end

  # def install(active_only = false)
  #   FileUtils.mkdir_p(repo_path)

  #   if active_repo.nil?
  #     origin_repo.install!
  #     set_active_repo(origin_repo)
  #   end

  #   if active_only
  #     active_repo.install!
  #   else
  #     @repos.each {|repo| repo.install!}
  #   end
  # end

  def download(active_only = false)
    FileUtils.mkdir_p(repo_path)

    if active_repo.nil?
      origin_repo.download
      set_active_repo(origin_repo)
    end

    if active_only
      active_repo.download
    else
      @repos.values.each {|repo| repo.download}
    end
  end

  def update(active_only = false)
    puts Rainbow("TBD").red
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

end