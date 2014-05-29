class SiteRepo

  attr_reader :github_path

  def initialize(clone_parent_dir, github_path)
    @clone_parent_dir = clone_parent_dir
    @github_path = github_path
  end

  def installed?
    File.directory?(clone_dir) && !(Dir.entries(clone_dir) - %w{ . .. }).empty?
  end

  def install!
    begin
      g = Git.clone(git_ssh_url, @github_path, path: @clone_parent_dir)
      puts "Cloned SSH version of #{@github_path}"
    rescue Git::GitExecuteError => e
      g = Git.clone(git_https_url, @github_path, path: @clone_parent_dir)
      puts "Cloned SSH version of #{@github_path}"
    end
  end

  def refresh
    install! if !installed?
  end

  def clone_dir
    "#{@clone_parent_dir}/#{@github_path}"
  end

  def git_ssh_url
    "git@github.com:#{@github_path}.git"
  end

  def git_https_url
    "https://github.com/#{@github_path}"
  end

  def current_branch
    Git.open(clone_dir).branches.local.select{|b| b.current}.first
  end

end