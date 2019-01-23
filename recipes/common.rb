#
# Cookbook Name:: cookbook-openshift3
# Recipe:: common
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
master_servers = server_info.master_servers
lb_servers = server_info.lb_servers
is_master_server = server_info.on_master_server?
is_node_server = server_info.on_node_server?
is_certificate_server = server_info.on_certificate_server?
is_remove_etcd_server = server_info.on_remove_etcd_server?

include_recipe 'cookbook-openshift3::packages'
include_recipe 'cookbook-openshift3::docker'
include_recipe 'iptables::default'
include_recipe 'selinux_policy::default'

service 'firewalld' do
  action %i[stop disable]
  notifies :run, 'execute[rebuild-iptables]', :immediately
end

iptables_rule 'firewall_jump_rule' do
  action :enable
end

if !lb_servers.nil? && lb_servers.find { |lb| lb['fqdn'] == node['fqdn'] }
  package 'haproxy' do
    retries 3
  end

  node['cookbook-openshift3']['enabled_firewall_rules_lb'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  directory '/etc/systemd/system/haproxy.service.d' do
    recursive true
  end

  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy.conf.erb'
    variables(
      lazy do
        {
          master_servers: master_servers,
          maxconn: node['cookbook-openshift3']['lb_default_maxconn'].nil? ? '20000' : node['cookbook-openshift3']['lb_default_maxconn']
        }
      end
    )
    notifies :restart, 'service[haproxy]', :immediately
  end

  template '/etc/systemd/system/haproxy.service.d/limits.conf' do
    source 'haproxy.service.erb'
    variables nofile: node['cookbook-openshift3']['lb_limit_nofile'].nil? ? '100000' : node['cookbook-openshift3']['lb_limit_nofile']
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :restart, 'service[haproxy]', :immediately
  end
end

package 'deltarpm' do
  retries 3
end

yum_package node['cookbook-openshift3']['core_packages'] do
  only_if { is_master_server || is_node_server }
end

package 'httpd' do
  notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
  notifies :enable, 'service[httpd]', :immediately
  retries 3
  only_if { is_certificate_server }
end

directory node['cookbook-openshift3']['openshift_data_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if { node['cookbook-openshift3']['deploy_containerized'] && (is_master_server || is_node_server) }
end

directory node['cookbook-openshift3']['openshift_common_base_dir'] do
  owner 'root'
  group 'root'
  mode '0750'
  only_if { is_master_server || is_node_server }
end

include_recipe 'cookbook-openshift3::certificate_server' if is_certificate_server
include_recipe 'cookbook-openshift3::etcd_removal' if is_remove_etcd_server
include_recipe 'cookbook-openshift3::cloud_provider'
