#
# Cookbook Name:: cookbook-openshift3
# Recipe:: upgrade_node14
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

node.force_override['cookbook-openshift3']['upgrade'] = true
node.force_override['cookbook-openshift3']['ose_major_version'] = '1.4'
node.force_override['cookbook-openshift3']['ose_version'] = '1.4.1-1.el7'
node.force_override['cookbook-openshift3']['openshift_docker_image_version'] = 'v1.4.1'
node.force_override['cookbook-openshift3']['docker_version'] = '1.12.6-71.git3e8e77d.el7'

server_info = OpenShiftHelper::NodeHelper.new(node)
is_node_server = server_info.on_node_server?

if defined? node['cookbook-openshift3']['upgrade_repos']
  node.force_override['cookbook-openshift3']['yum_repositories'] = node['cookbook-openshift3']['upgrade_repos']
end

if is_node_server
  log 'Upgrade for NODE [STARTED]' do
    level :info
  end

  include_recipe 'cookbook-openshift3'
  include_recipe 'cookbook-openshift3::common'
  include_recipe 'cookbook-openshift3::node'

  log 'Node services' do
    level :info
    notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
    notifies :restart, 'service[openvswitch]', :immediately
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  log 'Upgrade for NODE [COMPLETED]' do
    level :info
  end
end