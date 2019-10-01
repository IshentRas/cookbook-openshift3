#
# Cookbook Name:: cookbook-openshift3
# Recipe:: ng_node_join
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
certificate_server = server_info.certificate_server
certificate_server_protocol = server_info.certificate_server_protocol

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

remote_file "Retrieve certificate from Master[#{certificate_server['fqdn']}]" do
  path "#{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc"
  source "#{certificate_server_protocol}://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/node/generated-configs/#{node['fqdn']}.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt node certificate tgz files]', :immediately
  notifies :run, 'execute[Extract certificate to Node folder]', :immediately
  notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
  notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
  retries 120
  retry_delay 5
end

execute 'Un-encrypt node certificate tgz files' do
  command "openssl enc -d -aes-256-cbc -in #{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc -out #{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
  action :nothing
end

execute 'Extract certificate to Node folder' do
  command "tar xzf #{node['fqdn']}.tgz && chown -R root:root ."
  cwd node['cookbook-openshift3']['openshift_node_config_dir']
  action :nothing
end
