property :image_name, String, required: true, name_property: true
property :tag, String, default: 'latest'
default_action :pull_if_missing

provides :docker_image

action :pull_if_missing do
  execute "Pulling Container Image #{new_resource.image_name}" do
    command "docker pull #{new_resource.image_name}:#{new_resource.tag}"
  end
end
