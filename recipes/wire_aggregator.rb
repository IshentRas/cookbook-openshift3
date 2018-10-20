#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: wire_aggregator
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

remote_file 'Retrieve the aggregator certs' do
  path "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/wire_aggregator-masters.tgz.enc"
  source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/master/generated_certs/wire_aggregator-masters.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt aggregator tgz files]', :immediately
  notifies :run, 'execute[Extract aggregator to Master folder]', :immediately
  retries 12
  retry_delay 5
end

execute 'Un-encrypt aggregator tgz files' do
  command "openssl enc -d -aes-256-cbc -in wire_aggregator-masters.tgz.enc -out wire_aggregator-masters.tgz -k '#{encrypted_file_password}'"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  action :nothing
end

execute 'Extract aggregator to Master folder' do
  command 'tar -xzf wire_aggregator-masters.tgz ./front-proxy-ca* ./aggregator-front-proxy*'
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  action :nothing
end

file "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-ansible-catalog-console.js" do
  content 'window.OPENSHIFT_CONSTANTS.TEMPLATE_SERVICE_BROKER_ENABLED=false'
  mode '0644'
  owner 'root'
  group 'root'
end
