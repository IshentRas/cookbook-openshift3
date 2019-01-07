#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: master_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
helper_certs = OpenShiftHelper::CertHelper.new
first_master = server_info.first_master
master_servers = server_info.master_servers
etcd_servers = server_info.etcd_servers
certificate_server = server_info.certificate_server

ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

node['is_apaas_openshift_cookbook']['enabled_firewall_rules_master_cluster'].each do |rule|
  iptables_rule rule do
    action :enable
  end
end

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if node['is_apaas_openshift_cookbook']['adhoc_redeploy_etcd_ca']
  Chef::Log.warn("The ETCD CA CERTS redeploy will be skipped for Master[#{node['fqdn']}]. Could not find the flag: #{node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag'])

  ruby_block "Redeploy ETCD CA certs for Master server: #{node['fqdn']}" do
    block do
      helper.remove_dir("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}ca.crt")
      helper.remove_dir("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz*")
    end
    only_if { ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']) }
  end
end

if node['is_apaas_openshift_cookbook']['adhoc_redeploy_cluster_ca']
  Chef::Log.warn("The CLUSTER CA CERTS redeploy will be skipped for Master[#{node['fqdn']}]. Could not find the flag: #{node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag'])

  ruby_block "Redeploy CA certs for Master server: #{node['fqdn']}" do
    block do
      helper.remove_dir("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-#{node['fqdn']}.tgz*")
    end
    only_if { ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag']) }
    notifies :delete, "file[#{node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag']}]", :immediately
    notifies :restart, 'service[Restart API]', :delayed if ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag'])
    notifies :restart, 'service[Restart Controller]', :delayed if ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag'])
  end

  file node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag'] do
    action :nothing
  end
end

remote_file "Retrieve ETCD client certificate from Certificate Server[#{certificate_server['fqdn']}]" do
  path "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz.enc"
  source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/master/generated_certs/openshift-master-#{node['fqdn']}.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt etcd certificates tgz files]', :immediately
  notifies :run, 'execute[Extract etcd certificates to Master folder]', :immediately
  retries 60
  retry_delay 5
  sensitive true
end

execute 'Un-encrypt etcd certificates tgz files' do
  command "openssl enc -d -aes-256-cbc -in openshift-master-#{node['fqdn']}.tgz.enc -out openshift-master-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  action :nothing
end

execute 'Extract etcd certificates to Master folder' do
  command "tar -xzf openshift-master-#{node['fqdn']}.tgz ./master.etcd-client.crt ./master.etcd-client.key"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  action :nothing
end

remote_file "Retrieve ETCD CA cert from Certificate Server[#{certificate_server['fqdn']}]" do
  path "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}ca.crt"
  source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/ca.crt"
  owner 'root'
  group 'root'
  mode '0600'
  retries 60
  retry_delay 5
  sensitive true
  action :create_if_missing
end

remote_file "Retrieve master certificates from Certificate Server[#{certificate_server['fqdn']}]" do
  path "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-#{node['fqdn']}.tgz.enc"
  source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/master/generated_certs/openshift-#{node['fqdn']}.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt master certificates master tgz files]', :immediately
  notifies :run, 'execute[Extract master certificates to Master folder]', :immediately
  retries 60
  retry_delay 5
  sensitive true
end

execute 'Un-encrypt master certificates master tgz files' do
  command "openssl enc -d -aes-256-cbc -in openshift-#{node['fqdn']}.tgz.enc -out openshift-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  action :nothing
end

execute 'Extract master certificates to Master folder' do
  command "tar -xzf openshift-#{node['fqdn']}.tgz"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  action :nothing
end

execute 'Create the policy file' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} create-bootstrap-policy-file --filename=#{node['is_apaas_openshift_cookbook']['openshift_master_policy']}"
  creates node['is_apaas_openshift_cookbook']['openshift_master_policy']
end

template node['is_apaas_openshift_cookbook']['openshift_master_scheduler_conf'] do
  source 'scheduler.json.erb'
  variables ose_major_version: ose_major_version
  notifies :restart, 'service[Restart API]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
end

if node['is_apaas_openshift_cookbook']['oauth_Identities'].include? 'HTPasswdPasswordIdentityProvider'
  package 'httpd-tools' do
    retries 3
  end

  template node['is_apaas_openshift_cookbook']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']['filename'] do
    source 'htpasswd.erb'
    mode '600'
  end
end

sysconfig_vars = {}

if node['is_apaas_openshift_cookbook']['openshift_cloud_provider'] == 'aws'
  if node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_name'] && node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_item_name']
    secret_file = node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['secret_file'] || nil
    aws_vars = data_bag_item(node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_name'], node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_item_name'], secret_file)

    sysconfig_vars['aws_access_key_id'] = aws_vars['access_key_id']
    sysconfig_vars['aws_secret_access_key'] = aws_vars['secret_access_key']
  end
end

template '/etc/sysconfig/atomic-openshift-master' do
  source 'service_master.sysconfig.erb'
  variables(sysconfig_vars)
  notifies :restart, 'service[Restart API]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
  notifies :restart, 'service[Restart Controller]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
end

template node['is_apaas_openshift_cookbook']['openshift_master_api_systemd'] do
  source node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? 'service_master-api-containerized.service.erb' : 'service_master-api.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
end

template node['is_apaas_openshift_cookbook']['openshift_master_controllers_systemd'] do
  source node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? 'service_master-controllers-containerized.service.erb' : 'service_master-controllers.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
end

template node['is_apaas_openshift_cookbook']['openshift_master_api_sysconfig'] do
  source 'service_master-api.sysconfig.erb'
  variables(sysconfig_vars)
  notifies :restart, 'service[Restart API]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
end

template node['is_apaas_openshift_cookbook']['openshift_master_controllers_sysconfig'] do
  source 'service_master-controllers.sysconfig.erb'
  variables(sysconfig_vars)
  notifies :restart, 'service[Restart Controller]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
end

include_recipe 'is_apaas_openshift_cookbook::wire_aggregator' if ose_major_version.split('.')[1].to_i >= 7

openshift_create_master 'Create master configuration file' do
  named_certificate node['is_apaas_openshift_cookbook']['openshift_master_named_certificates']
  origins node['is_apaas_openshift_cookbook']['erb_corsAllowedOrigins'].uniq
  master_file node['is_apaas_openshift_cookbook']['openshift_master_config_file']
  etcd_servers etcd_servers
  masters_size master_servers.size
  openshift_service_type 'atomic-openshift'
  standalone_registry node['is_apaas_openshift_cookbook']['deploy_standalone_registry']
end

package 'etcd' do
  not_if 'rpm -q etcd'
end

execute 'Check ETCD cluster health before doing anything' do
  command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_peer_file']} --cert-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt -C #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | grep -w 'cluster is healthy'"
  retries 120
  retry_delay 1
end

execute 'Activate services for Master API on first master' do
  command 'echo nothing to do specific'
  notifies :start, 'service[atomic-openshift-master-api]', :immediately
  notifies :enable, 'service[atomic-openshift-master-api]', :immediately
  only_if { first_master['fqdn'] == node['fqdn'] }
end

execute 'Wait for master api service to start on first master' do
  command node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? 'sleep 15' : 'sleep 5'
  action :run
  not_if 'systemctl is-active atomic-openshift-master-api'
end

execute 'Activate services for Master API on all masters' do
  command 'echo nothing to do specific'
  notifies :start, 'service[atomic-openshift-master-api]', :immediately
  notifies :enable, 'service[atomic-openshift-master-api]', :immediately
  only_if { first_master['fqdn'] != node['fqdn'] }
end

execute 'Wait for API to become available' do
  command "[[ $(curl --silent --tlsv1.2 --max-time 2 #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}/healthz/ready --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca.crt --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
  environment 'no_proxy' => 'localhost'
  retries 120
  retry_delay 1
end

execute 'Activate services for Master CONTROLLERS on first master' do
  command 'echo nothing to do specific'
  notifies :start, 'service[atomic-openshift-master-controllers]', :immediately
  notifies :enable, 'service[atomic-openshift-master-controllers]', :immediately
  only_if { first_master['fqdn'] == node['fqdn'] }
end

execute 'Wait for master controller service to start on first master' do
  command node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? 'sleep 15' : 'sleep 5'
  action :run
  not_if 'systemctl is-active atomic-openshift-master-controllers'
end

execute 'Activate services for Master CONTROLLERS on all masters' do
  command 'echo nothing to do specific'
  notifies :start, 'service[atomic-openshift-master-controllers]', :immediately
  notifies :enable, 'service[atomic-openshift-master-controllers]', :immediately
  only_if { first_master['fqdn'] != node['fqdn'] }
end

service 'atomic-openshift-master' do
  action %i[disable mask]
end

ruby_block 'Adjust permissions for certificate and key files on Master servers' do
  block do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Dir.glob("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/*").grep(/\.(?:key)$/).uniq.each do |key|
      file = Chef::Resource::File.new(key, run_context)
      file.owner 'root'
      file.group 'root'
      file.mode '0600'
      file.run_action(:create)
    end

    Dir.glob("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/*").grep(/\.(?:crt|json)$/).uniq.each do |key|
      file = Chef::Resource::File.new(key, run_context)
      file.owner 'root'
      file.group 'root'
      file.mode '0640'
      file.run_action(:create)
    end
  end
end

ruby_block 'Restart Master services if valid certificate (Upgrade ETCD CA)' do
  block do
  end
  notifies :delete, "file[#{node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']}]", :immediately
  notifies :restart, 'service[atomic-openshift-master-api]', :immediately
  notifies :restart, 'service[atomic-openshift-master-controllers]', :immediately
  only_if { helper_certs.valid_certificate?("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}ca.crt", "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.crt") && ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']) }
end
