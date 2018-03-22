#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers
is_certificate_server = server_info.on_certificate_server?
is_master_server = server_info.on_master_server?

version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'][1..-1].sub(/^3/, '1').to_f.round(1) : node['is_apaas_openshift_cookbook']['ose_major_version'].sub(/^3/, '1').to_f.round(1)

include_recipe 'is_apaas_openshift_cookbook::etcd_cluster' if etcd_servers.any?

if is_certificate_server
  package 'httpd' do
    notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
    notifies :enable, 'service[httpd]', :immediately
    retries 3
  end
  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_master'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end
  # Do this immediately, so clients can connect (iptables cookbook delays).
  execute '/usr/sbin/rebuild-iptables'
end

if is_master_server || is_certificate_server
  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_master'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  directory node['is_apaas_openshift_cookbook']['openshift_master_config_dir'] do
    recursive true
    owner 'root'
    group 'root'
    mode '0700'
  end

  template node['is_apaas_openshift_cookbook']['openshift_master_session_secrets_file'] do
    source 'session-secrets.yaml.erb'
    variables(
      lazy do
        {
          secret_authentication: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip,
          secret_encryption: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip
        }
      end
    )
    action :create_if_missing
  end

  remote_directory node['is_apaas_openshift_cookbook']['openshift_common_examples_base'] do
    source "openshift_examples/v#{version}"
    owner 'root'
    group 'root'
    action :create
    recursive true
    only_if { node['is_apaas_openshift_cookbook']['deploy_example'] }
  end

  remote_directory node['is_apaas_openshift_cookbook']['openshift_common_hosted_base'] do
    source "openshift_hosted_templates/v#{version}/#{node['is_apaas_openshift_cookbook']['openshift_hosted_type']}"
    owner 'root'
    group 'root'
    action :create
    recursive true
  end

  if node['is_apaas_openshift_cookbook']['openshift_HA']
    include_recipe 'is_apaas_openshift_cookbook::master_cluster'
  else
    include_recipe 'is_apaas_openshift_cookbook::master_standalone'
  end

  directory '/root/.kube' do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end

  execute 'Copy the OpenShift admin client config' do
    command "cp #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig /root/.kube/config && chmod 700 /root/.kube/config"
    creates '/root/.kube/config'
  end
end

if is_certificate_server
  include_recipe 'is_apaas_openshift_cookbook::nodes_certificates' unless node['is_apaas_openshift_cookbook']['upgrade']
end
