class Site

  def initialize(config)
    @config = config

    # @origin_repo = SiteRepo.new(repo_path, origin_github_path, 'origin')

    @repos = { origin_github_path => SiteRepo.new(repo_path, origin_github_path) }

    # @repos = [@origin_repo]
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
    File.exist?(repo_path) && File.exist?(current_link_path)
  end

  def refresh
    FileUtils.mkdir_p(repo_path)

    @repos.values.each { |repo| repo.refresh }

    set_current_repo(origin_github_path) if !current_repo_set?
  end

  def repo_path
    File.expand_path("../repos/#{repo_name}")
  end

  def set_current_repo(github_path)
    FileUtils.ln_s("#{repo_path}/#{github_path}", current_link_path)
  end

  def current_repo_set?
    File.exist?(current_link_path)
  end

  def origin_github_path
    @config.get_deep(:git, :origin)
  end

  def current_link_path
    "#{repo_path}/current"
  end

  def current_repo
    return nil if !current_repo_set?
    current_repo_github_path = File.readlink(current_link_path).split("#{repo_path}/")[1]
    @repos[current_repo_github_path]
  end

  def port
    @config[:port]
  end

  def up?
    Network.is_port_open?('localhost', port)
  end

end