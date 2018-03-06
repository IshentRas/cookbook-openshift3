#
# Cookbook Name:: cookbook-openshift3
# Recipe:: adhoc_migrate_etcd
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node.force_override['cookbook-openshift3']['upgrade'] = true
node.force_override['cookbook-openshift3']['ose_major_version'] = '3.6'
node.force_override['cookbook-openshift3']['ose_version'] = '3.6.1-1.0.008f2d5'

hosted_upgrade_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : 'v' + node['cookbook-openshift3']['ose_version'].to_s.split('-')[0]

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers
is_certificate_server = server_info.on_certificate_server?
is_etcd_server = server_info.on_etcd_server?
is_master_server = server_info.on_master_server?
is_first_master = server_info.on_first_master?
is_first_etcd = server_info.on_first_etcd?

include_recipe 'cookbook-openshift3'

if is_first_etcd
  log 'Check if there is at least one v2 snapshot [Abort if not found]' do
    level :info
  end

  return unless Dir["#{node['cookbook-openshift3']['etcd_data_dir']}/member/snap/*.snap"].any?
end

if is_master_server
  log 'Stop services on MASTERS' do
    level :info
  notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately unless node['cookbook-openshift3']['openshift_HA']
  notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately if node['cookbook-openshift3']['openshift_HA']
  notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately if node['cookbook-openshift3']['openshift_HA']
  end
end

if is_etcd_server
  execute 'Generate etcd backup before migration' do
    command "etcdctl backup --data-dir=#{node['cookbook-openshift3']['etcd_data_dir']} --backup-dir=#{node['cookbook-openshift3']['etcd_data_dir']}-pre-migration-v3"
    not_if { ::File.directory?("#{node['cookbook-openshift3']['etcd_data_dir']}-pre-upgrade36") }
    notifies :run, 'execute[Copy etcd v3 data store]', :immediately
  end

  execute 'Copy etcd v3 data store' do
    command "cp -a #{node['cookbook-openshift3']['etcd_data_dir']}/member/snap/db #{node['cookbook-openshift3']['etcd_data_dir']}-pre-migration-v3/member/snap/"
    only_if { ::File.file?("#{node['cookbook-openshift3']['etcd_data_dir']}/member/snap/db") }
    action :nothing
  end

  log 'Stop services on ETCD' do
    level :info
  notifies :stop, 'service[etcd-service]', :immediately
  end
end

if is_first_etcd
  execute 'Migrate etcd data' do
    command "ETCDCTL_API=3 /usr/bin/etcdctl migrate --data-dir=#{node['cookbook-openshift3']['etcd_data_dir']} > #{Chef::Config[:file_cache_path]}/etcd_migration1"
  end

  execute 'Check the etcd v2 data are correctly migrated' do
    command "cat #{Chef::Config[:file_cache_path]}/etcd_migration1 | grep 'finished transforming keys' && touch #{Chef::Config[:file_cache_path]}/etcd_migration2"
  only_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/etcd_migration1") }
  end

  ruby_block 'Set ETCD_FORCE_NEW_CLUSTER=true on first etcd host' do
    block do
      f = Chef::Util::FileEdit.new("#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf")
      f.insert_line_if_no_match(%r{^ETCD_FORCE_NEW_CLUSTER}, 'ETCD_FORCE_NEW_CLUSTER=true')
      f.write_file
    notifies :start, 'service[etcd-service]', :immediately
    end
  only_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/etcd_migration2") }
  end
end