#
# Cookbook Name:: cookbook-openshift3
# Recipe:: nodes_certificates
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node_servers = node['cookbook-openshift3']['node_servers']

%W(/var/www/html/node #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}).each do |path|
  directory path do
    owner 'apache'
    group 'apache'
    mode '0755'
  end
end

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = Chef::EncryptedDataBagItem.load(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

if node['cookbook-openshift3']['use_wildcard_nodes']
  execute 'Generate certificate directory for Wildcard node servers' do
    command "mkdir -p #{Chef::Config[:file_cache_path]}/wildcard_nodes"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz"
  end

  execute 'Generate certificate for Wildcard node servers' do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-api-client-config \
            --client-dir=#{Chef::Config[:file_cache_path]}/wildcard_nodes \
            --certificate-authority=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt \
            --signer-cert=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt --signer-key=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.key \
            --signer-serial=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.serial.txt --user='system:node:wildcard_nodes'\
            --groups=system:nodes --master=#{node['cookbook-openshift3']['openshift_master_api_url']}"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz"
  end

  execute 'Generate the node server certificate for Wildcard node servers' do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-server-cert --cert=server.crt --key=server.key --overwrite=true \
             --hostnames=#{node['cookbook-openshift3']['wildcard_domain']} --signer-cert=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt --signer-key=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.key \
             --signer-serial=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.serial.txt && mv server.{key,crt} #{Chef::Config[:file_cache_path]}/wildcard_nodes"
    cwd Chef::Config[:file_cache_path]
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz"
  end

  execute 'Generate a tarball for Wildcard node servers' do
    command "tar czvf #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz \
              -C #{Chef::Config[:file_cache_path]}/wildcard_nodes . --remove-files && chown apache: #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz"
  end

  execute 'Encrypt Wildcard node servers tgz files' do
    command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz -out #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz.enc -k '#{encrypted_file_password}'  && chmod -R  0755 #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']} && chown -R apache: #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}"
  end
else
  node_servers.each do |node_server|
    execute "Generate certificate directory for #{node_server['fqdn']}" do
      command "mkdir -p #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']}"
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz"
    end

    execute "Generate certificate for #{node_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-api-client-config \
              --client-dir=#{Chef::Config[:file_cache_path]}/#{node_server['fqdn']} \
              --certificate-authority=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt \
              --signer-cert=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt --signer-key=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.key \
              --signer-serial=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.serial.txt --user='system:node:#{node_server['fqdn']}' \
              --groups=system:nodes --master=#{node['cookbook-openshift3']['openshift_master_api_url']}"
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz"
    end

    execute "Generate the node server certificate for #{node_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-server-cert --cert=server.crt --key=server.key --overwrite=true \
              --hostnames=#{node_server['fqdn'] + ',' + node_server['ipaddress']} --signer-cert=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt --signer-key=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.key \
              --signer-serial=#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.serial.txt && mv server.{key,crt} #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']}"
      cwd Chef::Config[:file_cache_path]
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz"
    end

    execute "Generate a tarball for #{node_server['fqdn']}" do
      command "tar czvf #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz \
               -C #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']} . --remove-files && chown apache: #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz"
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz"
    end
    execute 'Encrypt Wildcard node servers tgz files' do
      command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz -out #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chmod -R  0755 #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']} && chown -R apache: #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}"
    end
  end
end
