#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: ng_nodes_certificates
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
node_servers = server_info.node_servers

%W(/var/www/html/node #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}).each do |path|
  directory path do
    owner 'apache'
    group 'apache'
    mode '0755'
  end
end

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

execute 'Wait for API to become available' do
  command "[[ $(curl --silent --tlsv1.2 --max-time 2 #{node['is_apaas_openshift_cookbook']['openshift_master_api_url']}/healthz/ready --cacert #{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.crt --cacert #{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
  retries 150
  retry_delay 5
end

execute 'Create service account kubeconfig with csr rights' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} serviceaccounts create-kubeconfig ${openshift_master_csr_sa} -n ${openshift_master_csr_namespace} --config=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/admin.kubeconfig > #{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/bootstrap.kubeconfig"
  environment(
    'openshift_master_csr_sa' => node['is_apaas_openshift_cookbook']['openshift_master_csr_sa'],
    'openshift_master_csr_namespace' => node['is_apaas_openshift_cookbook']['openshift_master_csr_namespace']
  )
  not_if { ::File.exist?("#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/bootstrap.kubeconfig") }
end

node_servers.each do |node_server|
  execute "Generate certificate directory for #{node_server['fqdn']}" do
    command "mkdir -p #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']}"
    creates "#{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
  end

  remote_file "#{Chef::Config[:file_cache_path]}/#{node_server['fqdn']}/bootstrap.kubeconfig" do
    source "file://#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/bootstrap.kubeconfig"
    sensitive true
    not_if { ::File.exist?("#{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz") }
  end

  execute "Generate a tarball for #{node_server['fqdn']}" do
    command "tar --mode='0644' --owner=root --group=root -czvf #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz -C #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']} . --remove-files && chown apache:apache #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
    creates "#{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
  end

  execute "Encrypt node servers tgz files for #{node_server['fqdn']}" do
    command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz -out #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chown apache:apache #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc"
    creates "#{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc"
  end
end
