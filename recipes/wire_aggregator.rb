#
# Cookbook Name:: cookbook-openshift3
# Recipe:: wire_aggregator
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

remote_file 'Retrieve the aggregator certs' do
  path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/wire_aggregator-masters.tgz.enc"
  source "#{certificate_server_protocol}://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/wire_aggregator-masters.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt aggregator tgz files]', :immediately
  notifies :run, 'execute[Extract aggregator to Master folder]', :immediately
  retries 12
  retry_delay 5
end

execute 'Un-encrypt aggregator tgz files' do
  command "openssl enc -d -aes-256-cbc -in wire_aggregator-masters.tgz.enc -out wire_aggregator-masters.tgz -k '#{encrypted_file_password}'"
  cwd node['cookbook-openshift3']['openshift_master_config_dir']
  action :nothing
end

execute 'Extract aggregator to Master folder' do
  command 'tar -xzf wire_aggregator-masters.tgz ./front-proxy-ca* ./aggregator-front-proxy*'
  cwd node['cookbook-openshift3']['openshift_master_config_dir']
  action :nothing
end

file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-ansible-catalog-console.js" do
  content 'window.OPENSHIFT_CONSTANTS.TEMPLATE_SERVICE_BROKER_ENABLED=false'
  mode '0644'
  owner 'root'
  group 'root'
end
