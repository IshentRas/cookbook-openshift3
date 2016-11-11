#
# Cookbook Name:: cookbook-openshift3
# Recipe:: master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{node['cookbook-openshift3']['master_servers']}")).sort! : node['cookbook-openshift3']['master_servers']
etcd_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{node['cookbook-openshift3']['etcd_servers']}")).sort! : node['cookbook-openshift3']['etcd_servers']

if node['cookbook-openshift3']['openshift_HA']
  case node['cookbook-openshift3']['openshift_HA_method']
  when 'native'
    if node['cookbook-openshift3']['openshift_cluster_name'].nil?
      Chef::Application.fatal!('A Cluster Name must be defined via \"openshift_cluster_name\"')
    end
  else
    if node['cookbook-openshift3']['openshift_cluster_name'].nil? && node['cookbook-openshift3']['openshift_master_cluster_vip'].nil?
      Chef::Application.fatal!('A Cluster Name and IP must be defined via \"openshift_cluster_name\" and \"openshift_master_cluster_vip\"')
    end
  end
end

if master_servers.find { |server_master| server_master['fqdn'] == node['fqdn'] }
  package node['cookbook-openshift3']['openshift_service_type'] do
    version node['cookbook-openshift3'] ['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  package 'httpd' do
    notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
    notifies :enable, 'service[httpd]', :immediately
  end

  node['cookbook-openshift3']['enabled_firewall_rules_master'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  directory node['cookbook-openshift3']['openshift_master_config_dir'] do
    recursive true
  end

  template node['cookbook-openshift3']['openshift_master_session_secrets_file'] do
    source 'session-secrets.yaml.erb'
    variables lazy {
      {
        secret_authentication: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip,
        secret_encryption: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip
      }
    }
    action :create_if_missing
  end

  remote_directory node['cookbook-openshift3']['openshift_common_examples_base'] do
    source 'openshift_examples/examples'
    owner 'root'
    group 'root'
    action :create
    recursive true
    only_if { node['cookbook-openshift3']['deploy_example'] }
  end

  if node['cookbook-openshift3']['openshift_HA']
    include_recipe 'cookbook-openshift3::master_cluster'
  else
    include_recipe 'cookbook-openshift3::master_standalone'
  end

  directory '/root/.kube' do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end

  execute 'Copy the OpenShift admin client config' do
    command "cp #{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig /root/.kube/config && chmod 700 /root/.kube/config"
    creates '/root/.kube/config'
  end

  if master_servers.first['fqdn'] == node['fqdn']
    include_recipe 'cookbook-openshift3::nodes_certificates'
    include_recipe 'cookbook-openshift3::master_config_post'
  end
end

if etcd_servers.find { |server_etcd| server_etcd['fqdn'] == node['fqdn'] }
    include_recipe 'cookbook-openshift3::etcd_cluster'
end
