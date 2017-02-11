#
# Cookbook Name:: cookbook-openshift3
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
master_servers = node['cookbook-openshift3']['master_servers']

service "#{node['cookbook-openshift3']['openshift_service_type']}-master"

service "#{node['cookbook-openshift3']['openshift_service_type']}-master-api" do
  retries 5
  retry_delay 5
end

service "#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers" do
  retries 5
  retry_delay 5
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'httpd'

service 'etcd'

service 'docker'

service 'NetworkManager'

service 'openvswitch'

include_recipe 'cookbook-openshift3::validate'
include_recipe 'cookbook-openshift3::common'
include_recipe 'cookbook-openshift3::master'
include_recipe 'cookbook-openshift3::node'

if master_servers.find { |server_master| server_master['fqdn'] == node['fqdn'] }
  if master_servers.first['fqdn'] == node['fqdn']
    include_recipe 'cookbook-openshift3::master_config_post'
  end
end
