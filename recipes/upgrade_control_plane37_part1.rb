#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_control_plane37_part1
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_etcd_server = server_info.on_etcd_server?
is_master_server = server_info.on_master_server?

if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
  node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
end

include_recipe 'yum::default'
include_recipe 'is_apaas_openshift_cookbook::packages'
include_recipe 'is_apaas_openshift_cookbook::disable_excluder'

if is_etcd_server
  log 'Upgrade for ETCD [STARTED]' do
    level :info
  end

  openshift_upgrade 'Generate etcd backup before upgrade' do
    action :create_backup
    etcd_action 'pre'
    target_version node['is_apaas_openshift_cookbook']['control_upgrade_version']
  end

  include_recipe 'is_apaas_openshift_cookbook'
  include_recipe 'is_apaas_openshift_cookbook::etcd_cluster'

  openshift_upgrade 'Generate etcd backup after upgrade' do
    action :create_backup
    etcd_action 'post'
    target_version node['is_apaas_openshift_cookbook']['control_upgrade_version']
  end

  log 'Upgrade for ETCD [COMPLETED]' do
    level :info
  end

  file node['is_apaas_openshift_cookbook']['control_upgrade_flag'] do
    action :delete
    only_if { is_etcd_server && !is_master_server }
  end
end

include_recipe 'is_apaas_openshift_cookbook::upgrade_control_plane37_part2'
