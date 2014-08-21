class SiteRepo

  attr_reader :github_path

  def initialize(clone_parent_dir, github_path)
    @clone_parent_dir = clone_parent_dir
    @github_path = github_path
  end

  def cloned?
    File.directory?(clone_dir) && !(Dir.entries(clone_dir) - %w{ . .. }).empty?
  end

  def download
    Swerve.log_part("Downloading #{@github_path}... ")    

    if !cloned?
      # When git cloning, try the ssh way first (will work if user 
      # ssh keys setup for accessing git).  If that doesn't work, catch
      # Git::GitExecuteError and try read-only https way next.

      Swerve.log_part("Cloning... ")
      begin
        g = Git.clone(git_ssh_url, @github_path, path: @clone_parent_dir)
        Swerve.log("(completed via SSH)")
      rescue Git::GitExecuteError => e
        g = Git.clone(git_https_url, @github_path, path: @clone_parent_dir)
        Swerve.log("(completed via HTTPS)")
      end
    else
      Swerve.log_part("Already cloned; pulling... ")
      git_object.pull
      Swerve.log("(completed)")
    end
  end

  # def refresh
  #   install! if !downloaded?
  # end

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
    git_object.branches.local.select{|b| b.current}.first
  end

  def branch_select_choices
    choices = git_object.branches.collect do |branch| 
      {display: branch.name, value: branch}
    end

    choices.reject{|choice| choice[:display] =~ / -> /}
  end

  def set_current_branch(branch)
    git_object.checkout(branch.name)
  end 

  def git_object
    Git.open(clone_dir)
  end

end