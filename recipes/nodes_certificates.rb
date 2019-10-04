#
# Cookbook Name:: cookbook-openshift3
# Recipe:: nodes_certificates
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
node_servers = server_info.node_servers
ose_major_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']

%W[/var/www/html/node #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}].each do |path|
  directory path do
    owner 'apache'
    group 'apache'
    mode '0755'
  end
end

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

if node['cookbook-openshift3']['use_wildcard_nodes']
  execute 'Generate certificate directory for Wildcard node servers' do
    command "mkdir -p #{Chef::Config[:file_cache_path]}/wildcard_nodes"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz"
  end

  execute 'Generate certificate for Wildcard node servers' do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-api-client-config \
            --client-dir=#{Chef::Config[:file_cache_path]}/wildcard_nodes \
            --certificate-authority=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.crt \
            --signer-cert=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.crt --signer-key=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.key \
            --signer-serial=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.serial.txt --user='system:node:wildcard_nodes'\
            --groups=system:nodes --master=#{node['cookbook-openshift3']['openshift_master_api_url']}"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz"
  end

  execute 'Generate the node server certificate for Wildcard node servers' do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-server-cert --cert=server.crt --key=server.key --overwrite=true \
             --hostnames=#{node['cookbook-openshift3']['wildcard_domain'].downcase} --signer-cert=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.crt --signer-key=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.key \
             --signer-serial=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.serial.txt && mv server.{key,crt} #{Chef::Config[:file_cache_path]}/wildcard_nodes"
    cwd Chef::Config[:file_cache_path]
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz"
  end

  execute 'Generate a tarball for Wildcard node servers' do
    command "tar --mode='0644' --owner=root --group=root -czvf #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz \
              -C #{Chef::Config[:file_cache_path]}/wildcard_nodes . --remove-files && chown apache: #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz"
  end

  execute 'Encrypt Wildcard node servers tgz files' do
    command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tar.gz -out #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz.enc -k '#{encrypted_file_password}'  && chmod -R  0755 #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']} && chown -R apache: #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}"
    creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/wildcard_nodes.tgz.enc"
  end
else
  node_servers.each do |node_server|
    execute "Generate certificate directory for #{node_server['fqdn']}" do
      command "mkdir -p #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']}"
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
    end

    execute "Generate certificate for #{node_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-api-client-config \
							${legacy_certs} \
              --client-dir=#{Chef::Config[:file_cache_path]}/#{node_server['fqdn']} \
              --certificate-authority=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.crt \
              --signer-cert=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.crt --signer-key=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.key \
              --signer-serial=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.serial.txt --user='system:node:#{node_server['fqdn'].downcase}' \
              --groups=system:nodes --master=#{node['cookbook-openshift3']['openshift_master_api_url']} ${validity_certs}"
      environment(
        'validity_certs' => ose_major_version.split('.')[1].to_i < 5 ? '' : "--expire-days=#{node['cookbook-openshift3']['openshift_node_cert_expire_days']}",
        'legacy_certs' => File.file?(node['cookbook-openshift3']['redeploy_cluster_ca_certserver_control_flag']) ? "--certificate-authority=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}-legacy-ca/ca.crt" : ''
      )
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
    end

    execute "Generate the node server certificate for #{node_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-server-cert --cert=server.crt --key=server.key --overwrite=true \
							--hostnames=#{node_server['fqdn'].downcase + ',' + node_server['ipaddress']} --signer-cert=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.crt --signer-key=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.key \
              --signer-serial=#{node['cookbook-openshift3']['master_certs_generated_certs_dir']}/ca.serial.txt ${validity_certs} && mv server.{key,crt} #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']}"
      environment(
        'validity_certs' => ose_major_version.split('.')[1].to_i < 5 ? '' : "--expire-days=#{node['cookbook-openshift3']['openshift_node_cert_expire_days']}"
      )
      cwd Chef::Config[:file_cache_path]
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
    end

    execute "Generate a tarball for #{node_server['fqdn']}" do
      command "tar --mode='0644' --owner=root --group=root -czvf #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz -C #{Chef::Config[:file_cache_path]}/#{node_server['fqdn']} . --remove-files && chown apache:apache #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz"
    end
    execute "Encrypt node servers tgz files for #{node_server['fqdn']}" do
      command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tar.gz -out #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chown apache:apache #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc"
      creates "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/#{node_server['fqdn']}.tgz.enc"
    end
  end

  ruby_block 'Adjust permissions for node enc certificates' do
    block do
      run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
      Dir.glob("#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/*").grep(/\.(?:enc)$/).uniq.each do |enc|
        file = Chef::Resource::File.new(enc, run_context)
        file.mode '0644'
        file.run_action(:create)
      end
    end
  end

  # Add .htaccess for nodes if non-wildcard nodes are used
  template "#{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}/.htaccess" do
    owner 'apache'
    group 'apache'
    source 'access-htaccess.erb'
    notifies :run, 'ruby_block[Modify the AllowOverride options]', :immediately
    variables(servers: node_servers)
  end
end
