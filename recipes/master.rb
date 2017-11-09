#
# Cookbook Name:: cookbook-openshift3
# Recipe:: master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['master_servers']
version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'][1..-1].sub(/^3/, '1').to_f.round(1) : node['cookbook-openshift3']['ose_major_version'].sub(/^3/, '1').to_f.round(1)
certificate_server = node['cookbook-openshift3']['certificate_server'] == {} ? master_servers.first : node['cookbook-openshift3']['certificate_server']

include_recipe 'cookbook-openshift3::etcd_cluster' if node['cookbook-openshift3']['etcd_servers'].any?

if certificate_server['fqdn'] == node['fqdn']
  package 'httpd' do
    notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
    notifies :enable, 'service[httpd]', :immediately
  end
  node['cookbook-openshift3']['enabled_firewall_rules_master'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end
end

if master_servers.find { |server_master| server_master['fqdn'] == node['fqdn'] } || certificate_server['fqdn'] == node['fqdn']
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
        secret_encryption: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip,
      }
    }
    action :create_if_missing
  end

  remote_directory node['cookbook-openshift3']['openshift_common_examples_base'] do
    source "openshift_examples/v#{version}"
    owner 'root'
    group 'root'
    action :create
    recursive true
    only_if { node['cookbook-openshift3']['deploy_example'] }
  end

  remote_directory node['cookbook-openshift3']['openshift_common_hosted_base'] do
    source "openshift_hosted_templates/v#{version}/#{node['cookbook-openshift3']['openshift_hosted_type']}"
    owner 'root'
    group 'root'
    action :create
    recursive true
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
end

if certificate_server['fqdn'] == node['fqdn']
  include_recipe 'cookbook-openshift3::nodes_certificates'
end
