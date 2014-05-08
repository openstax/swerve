source 'https://api.berkshelf.com'

local_cookbook_path = ENV['SWERVE_COOKBOOKS_PATH']
local_cookbook_path = local_cookbook_path.blank? ? 'cookbooks' : local_cookbook_path

%w(rbenv swerve).each do |cookbook_name|
  # if local_cookbook_path.blank?
  #   cookbook cookbook_name, git: "https://github.com/openstax/openstax_cookbooks.git", rel: cookbook_name 
  # else
    cookbook cookbook_name, path: "#{local_cookbook_path}/#{cookbook_name}"
  # end
end