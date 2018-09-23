#
# Cookbook Name:: cookbook-openshift3
# Recipe:: ng_commons
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_node_server = server_info.on_node_server?
is_etcd_server = server_info.on_etcd_server?
is_master_server = server_info.on_master_server?
is_certificate_server = server_info.on_certificate_server?

include_recipe 'cookbook-openshift3::ng_services'
include_recipe 'cookbook-openshift3::packages'
include_recipe 'cookbook-openshift3::ng_docker' if is_node_server
include_recipe 'iptables::default'
include_recipe 'selinux_policy::default'

iptables_rule 'firewall_jump_rule' do
  action :enable
end

service 'firewalld' do
  action %i(stop disable)
end

package 'deltarpm' do
  retries 3
end

yum_package node['cookbook-openshift3']['core_packages']

yum_package 'httpd' do
  notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
  notifies :enable, 'service[httpd]', :immediately
  only_if { is_certificate_server }
end

include_recipe 'cookbook-openshift3::ng_certificate_server' if is_certificate_server
include_recipe 'cookbook-openshift3::ng_node' if is_node_server
include_recipe 'cookbook-openshift3::ng_etcd_cluster' if is_etcd_server
include_recipe 'cookbook-openshift3::ng_master' if is_master_server || is_certificate_server
include_recipe 'cookbook-openshift3::ng_node_join' if is_node_server
