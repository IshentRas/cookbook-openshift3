#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: ng_node_join
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
certificate_server = server_info.certificate_server

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

remote_file "Retrieve certificate from Master[#{certificate_server['fqdn']}]" do
  path "#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc"
  source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/node/generated-configs/#{node['fqdn']}.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt node certificate tgz files]', :immediately
  notifies :run, 'execute[Extract certificate to Node folder]', :immediately
  notifies :enable, 'service[atomic-openshift-node]', :immediately
  notifies :restart, 'service[atomic-openshift-node]', :immediately
  retries 120
  retry_delay 5
end

execute 'Un-encrypt node certificate tgz files' do
  command "openssl enc -d -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc -out #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
  action :nothing
end

execute 'Extract certificate to Node folder' do
  command "tar xzf #{node['fqdn']}.tgz && chown -R root:root ."
  cwd node['is_apaas_openshift_cookbook']['openshift_node_config_dir']
  action :nothing
end
