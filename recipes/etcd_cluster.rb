#
# Cookbook Name:: cookbook-openshift3
# Recipe:: etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

etcd_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{etcd_servers}")).sort! : node['cookbook-openshift3']['etcd_servers']

node['cookbook-openshift3']['enabled_firewall_rules_etcd'].each do |rule|
  iptables_rule rule do
    action :enable
  end
end

package 'etcd'

remote_file "Retrieve certificate from ETCD Master[#{etcd_servers.first['fqdn']}]" do
  path "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz"
  source "http://#{etcd_servers.first['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}.tgz"
  action :create_if_missing
  notifies :run, 'execute[Extract certificate to ETCD folder]', :immediately
  retries 12
  retry_delay 5
end

execute 'Extract certificate to ETCD folder' do
  command "tar xzf etcd-#{node['fqdn']}.tgz"
  cwd node['cookbook-openshift3']['etcd_conf_dir']
  action :nothing
end

file node['cookbook-openshift3']['etcd_ca_cert'] do
  owner 'etcd'
  group 'etcd'
  mode '0600'
end

%w(cert peer).each do |certificate_type|
  file node['cookbook-openshift3']['etcd_' + certificate_type + '_file'.to_s] do
    owner 'etcd'
    group 'etcd'
    mode '0600'
  end

  file node['cookbook-openshift3']['etcd_' + certificate_type + '_key'.to_s] do
    owner 'etcd'
    group 'etcd'
    mode '0600'
  end
end

execute 'Fix ETCD directiory permissions' do
  command "chmod 755 #{node['cookbook-openshift3']['etcd_conf_dir']}"
  only_if "[[ $(stat -c %a #{node['cookbook-openshift3']['etcd_conf_dir']}) -ne 755 ]]"
end

template "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf" do
  source 'etcd.conf.erb'
  notifies :restart, 'service[etcd]', :immediately
  variables etcd_servers: etcd_servers
end

service 'etcd' do
  action [:start, :enable]
end
