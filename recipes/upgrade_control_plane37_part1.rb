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
is_node_server = server_info.on_node_server?

if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
  node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
end

include_recipe 'yum::default'

if is_master_server || is_node_server
  %w(excluder docker-excluder).each do |pkg|
    execute "Disable atomic-openshift-#{pkg}" do
      command "atomic-openshift-#{pkg} enable"
    end
  end
end

if is_etcd_server
  log 'Upgrade for ETCD [STARTED]' do
    level :info
  end

  execute 'Generate etcd backup before upgrade' do
    command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade37"
    not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade37") }
    notifies :run, 'execute[Copy etcd v3 data store (PRE)]', :immediately
  end

  execute 'Copy etcd v3 data store (PRE)' do
    command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade37/member/snap/"
    only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
    action :nothing
  end

  include_recipe 'is_apaas_openshift_cookbook'
  include_recipe 'is_apaas_openshift_cookbook::common'
  include_recipe 'is_apaas_openshift_cookbook::etcd_cluster'

  execute 'Generate etcd backup after upgrade' do
    command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade37"
    not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade37") }
    notifies :run, 'execute[Copy etcd v3 data store (POST)]', :immediately
  end

  execute 'Copy etcd v3 data store (POST)' do
    command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade37/member/snap/"
    only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
    action :nothing
  end

  log 'Upgrade for ETCD [COMPLETED]' do
    level :info
  end
end

include_recipe 'is_apaas_openshift_cookbook::upgrade_control_plane37_part2'
