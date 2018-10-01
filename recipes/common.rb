#
# Cookbook Name:: is_apaas_openshift_cookbook
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

include_recipe 'is_apaas_openshift_cookbook::packages'
include_recipe 'is_apaas_openshift_cookbook::docker'
include_recipe 'iptables::default'
include_recipe 'selinux_policy::default'

service 'firewalld' do
  action %i(stop disable)
  notifies :run, 'execute[rebuild-iptables]', :immediately
end

iptables_rule 'firewall_jump_rule' do
  action :enable
end

if !lb_servers.nil? && lb_servers.find { |lb| lb['fqdn'] == node['fqdn'] }
  package 'haproxy' do
    retries 3
  end

  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_lb'].each do |rule|
    iptables_rule rule do
      action :enable
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
          maxconn: node['is_apaas_openshift_cookbook']['lb_default_maxconn'].nil? ? '20000' : node['is_apaas_openshift_cookbook']['lb_default_maxconn']
        }
      end
    )
    notifies :restart, 'service[haproxy]', :immediately
  end

  template '/etc/systemd/system/haproxy.service.d/limits.conf' do
    source 'haproxy.service.erb'
    variables nofile: node['is_apaas_openshift_cookbook']['lb_limit_nofile'].nil? ? '100000' : node['is_apaas_openshift_cookbook']['lb_limit_nofile']
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :restart, 'service[haproxy]', :immediately
  end
end

package 'deltarpm' do
  retries 3
end

yum_package node['is_apaas_openshift_cookbook']['core_packages']

package 'httpd' do
  notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
  notifies :enable, 'service[httpd]', :immediately
  retries 3
  only_if { is_certificate_server }
end

directory node['is_apaas_openshift_cookbook']['openshift_data_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] && (is_master_server || is_node_server) }
end

directory node['is_apaas_openshift_cookbook']['openshift_common_base_dir'] do
  owner 'root'
  group 'root'
  mode '0750'
  only_if { is_master_server || is_node_server }
end

include_recipe 'is_apaas_openshift_cookbook::certificate_server' if is_certificate_server
include_recipe 'is_apaas_openshift_cookbook::etcd_removal' if is_remove_etcd_server
include_recipe 'is_apaas_openshift_cookbook::cloud_provider'
