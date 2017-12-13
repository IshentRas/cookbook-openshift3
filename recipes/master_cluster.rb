#
# Cookbook Name:: cookbook-openshift3
# Recipe:: master_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
first_master = server_info.first_master
is_first_master = server_info.on_first_master?
master_servers = server_info.master_servers
etcd_servers = server_info.etcd_servers
certificate_server = server_info.certificate_server
is_certificate_server = server_info.on_certificate_server?

ose_major_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']

node['cookbook-openshift3']['enabled_firewall_rules_master_cluster'].each do |rule|
  iptables_rule rule do
    action :enable
  end
end

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = Chef::EncryptedDataBagItem.load(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

if is_certificate_server
  %W(/var/www/html/master #{node['cookbook-openshift3']['master_generated_certs_dir']}).each do |path|
    directory path do
      mode '0755'
      owner 'apache'
      group 'apache'
    end
  end

  master_servers.each do |master_server|
    directory "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
    end

    execute "ETCD Create the CLIENT csr for #{master_server['fqdn']}" do
      command "openssl req -new -keyout #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.key -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -out #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.csr -reqexts #{node['cookbook-openshift3']['etcd_req_ext']} -batch -nodes -subj /CN=#{master_server['fqdn']}"
      environment 'SAN' => "IP:#{master_server['ipaddress']}"
      cwd "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.csr"
    end

    execute "ETCD Create the CLIENT csr for #{master_server['fqdn']}" do
      command "openssl req -new -keyout #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.key -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -out #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.csr -reqexts #{node['cookbook-openshift3']['etcd_req_ext']} -batch -nodes -subj /CN=#{master_server['fqdn']}"
      environment 'SAN' => "IP:#{master_server['ipaddress']}"
      cwd "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.csr"
    end

    execute "ETCD Sign and create the CLIENT crt for #{master_server['fqdn']}" do
      command "openssl ca -name #{node['cookbook-openshift3']['etcd_ca_name']} -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -out #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.crt -in #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.csr -batch"
      environment 'SAN' => ''
      cwd "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.crt"
    end

    remote_file "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}ca.crt" do
      source "file://#{node['cookbook-openshift3']['etcd_ca_dir']}/ca.crt"
    end

    execute "Create a tarball of the etcd master certs for #{master_server['fqdn']}" do
      command "tar czvf #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz -C #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']} . && chown -R apache:apache #{node['cookbook-openshift3']['master_generated_certs_dir']}"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz"
    end

    execute 'Encrypt etcd tgz files' do
      command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz  -out #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chmod -R  0755 #{node['cookbook-openshift3']['master_generated_certs_dir']} && chown -R apache: #{node['cookbook-openshift3']['master_generated_certs_dir']}"
    end
  end
end

# Download the certs
remote_file "Retrieve client certificate from Master[#{certificate_server['fqdn']}]" do
  path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz.enc"
  source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/openshift-master-#{node['fqdn']}.tgz.enc"
  action :create_if_missing
  notifies :run, 'execute[Un-encrypt master certificate tgz files]', :immediately
  notifies :run, 'execute[Extract certificate to Master folder]', :immediately
  retries 12
  retry_delay 5
end

execute 'Un-encrypt master certificate tgz files' do
  command "openssl enc -d -aes-256-cbc -in openshift-master-#{node['fqdn']}.tgz.enc -out openshift-master-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
  cwd node['cookbook-openshift3']['openshift_master_config_dir']
  action :nothing
end

execute 'Extract certificate to Master folder' do
  command "tar xzf openshift-master-#{node['fqdn']}.tgz"
  cwd node['cookbook-openshift3']['openshift_master_config_dir']
  action :nothing
end

%w(client.crt client.key ca.crt).each do |certificate_type|
  file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}#{certificate_type}" do
    owner 'root'
    group 'root'
    mode '0600'
  end
end

if is_certificate_server
  if node['cookbook-openshift3']['openshift_master_ca_certificate']['data_bag_name'] && node['cookbook-openshift3']['openshift_master_ca_certificate']['data_bag_item_name']
    secret_file = node['cookbook-openshift3']['openshift_master_ca_certificate']['secret_file'] || nil
    ca_vars = Chef::EncryptedDataBagItem.load(node['cookbook-openshift3']['openshift_master_ca_certificate']['data_bag_name'], node['cookbook-openshift3']['openshift_master_ca_certificate']['data_bag_item_name'], secret_file)

    file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.key" do
      content Base64.decode64(ca_vars['key_base64'])
      mode '0600'
      action :create_if_missing
    end

    file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt" do
      content Base64.decode64(ca_vars['cert_base64'])
      mode '0644'
      action :create_if_missing
    end

    file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.serial.txt" do
      content '00'
      mode '0644'
      action :create_if_missing
    end
  end

  execute "Create the master certificates for #{first_master['fqdn']}" do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-master-certs \
            --hostnames=#{(node['cookbook-openshift3']['erb_corsAllowedOrigins'] + [first_master['ipaddress'], first_master['fqdn'], node['cookbook-openshift3']['openshift_common_api_hostname']]).uniq.join(',')} \
            --master=#{node['cookbook-openshift3']['openshift_master_api_url']} \
            --public-master=#{node['cookbook-openshift3']['openshift_master_public_api_url']} \
            --cert-dir=#{node['cookbook-openshift3']['openshift_master_config_dir']} --overwrite=false"
    creates "#{node['cookbook-openshift3']['openshift_master_config_dir']}/master.server.key"
  end

  execute 'Create temp directory for loopback master client config' do
    command "mkdir -p #{Chef::Config[:file_cache_path]}/openshift_ca_loopback_tmpdir"
    not_if "grep \'#{node['cookbook-openshift3']['openshift_master_loopback_context_name']}\' #{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-master.kubeconfig"
    notifies :run, "execute[Generate the loopback master client config for #{first_master['fqdn']}]", :immediately
  end

  execute "Generate the loopback master client config for #{first_master['fqdn']}" do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-api-client-config \
            --certificate-authority=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt \
            --master=#{node['cookbook-openshift3']['openshift_master_loopback_api_url']} \
            --public-master=#{node['cookbook-openshift3']['openshift_master_loopback_api_url']} \
            --client-dir=#{Chef::Config[:file_cache_path]}/openshift_ca_loopback_tmpdir \
            --groups=system:masters,system:openshift-master \
            --signer-cert=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt \
            --signer-key=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.key \
            --signer-serial=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.serial.txt \
            --user=system:openshift-master --basename=openshift-master"
    action :nothing
  end

  %w(openshift-master.crt openshift-master.key openshift-master.kubeconfig).each do |loopback_master_client|
    remote_file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{loopback_master_client}" do
      source "file://#{Chef::Config[:file_cache_path]}/openshift_ca_loopback_tmpdir/#{loopback_master_client}"
      only_if { ::File.file?("#{Chef::Config[:file_cache_path]}/openshift_ca_loopback_tmpdir/#{loopback_master_client}") }
    end
  end

  directory 'Delete temp directory for loopback master client config' do
    path "#{Chef::Config[:file_cache_path]}/openshift_ca_loopback_tmpdir"
    recursive true
    action :delete
  end

  master_servers.each do |master_server|
    directory "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
      recursive true
    end

    execute "Create the master server certificates for #{master_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-server-cert \
              --hostnames=#{(node['cookbook-openshift3']['erb_corsAllowedOrigins'] + [master_server['ipaddress'], master_server['fqdn'], node['cookbook-openshift3']['openshift_common_api_hostname']]).uniq.join(',')} \
              --cert=#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/master.server.crt \
              --key=#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/master.server.key \
              --signer-cert=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt \
              --signer-key=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.key \
              --signer-serial=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.serial.txt \
              --overwrite=false"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/master.server.crt"
      not_if { is_first_master }
    end

    execute "Generate master client configuration for #{master_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-api-client-config \
              --certificate-authority=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt \
              --master=https://#{master_server['fqdn']}:#{node['cookbook-openshift3']['openshift_master_api_port']} \
              --public-master=https://#{master_server['fqdn']}:#{node['cookbook-openshift3']['openshift_master_api_port']} \
              --client-dir=#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']} \
              --groups=system:masters,system:openshift-master \
              --signer-cert=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt \
              --signer-key=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.key \
              --signer-serial=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.serial.txt \
              --user=system:openshift-master --basename=openshift-master"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/openshift-master.kubeconfig"
    end

    certs = case ose_major_version.split('.')[1].to_i
            when 3..4
              node['cookbook-openshift3']['openshift_master_certs'] + %w(openshift-registry.crt openshift-registry.key openshift-registry.kubeconfig openshift-router.crt openshift-router.key openshift-router.kubeconfig service-signer.crt service-signer.key)
            when 5..6
              node['cookbook-openshift3']['openshift_master_certs'] + %w(service-signer.crt service-signer.key)
            else
              node['cookbook-openshift3']['openshift_master_certs']
            end

    certs.uniq.each do |master_certificate|
      remote_file "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/#{master_certificate}" do
        source "file://#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{master_certificate}"
        only_if { ::File.file?("#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{master_certificate}") }
      end
    end

    %w(client.crt client.key).each do |remove_etcd_certificate|
      file "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}#{remove_etcd_certificate}" do
        action :delete
      end
    end

    execute "Create a tarball of the master certs for #{master_server['fqdn']}" do
      command "tar czvf #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz -C #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']} . "
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz"
    end

    execute 'Encrypt master master tgz files' do
      command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz  -out #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chmod -R  0755 #{node['cookbook-openshift3']['master_generated_certs_dir']} && chown -R apache: #{node['cookbook-openshift3']['master_generated_certs_dir']}"
    end
  end
end

unless is_certificate_server
  remote_file "Retrieve master certificate from Master[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/openshift-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt master certificate master tgz files]', :immediately
    notifies :run, 'execute[Extract master certificate to Master folder]', :immediately
    retries 12
    retry_delay 5
  end

  execute 'Un-encrypt master certificate master tgz files' do
    command "openssl enc -d -aes-256-cbc -in openshift-#{node['fqdn']}.tgz.enc -out openshift-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end

  execute 'Extract master certificate to Master folder' do
    command "tar xzf openshift-#{node['fqdn']}.tgz"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end
end

package "#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  action :install
  version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
  notifies :run, 'execute[daemon-reload]', :immediately
  not_if { node['cookbook-openshift3']['deploy_containerized'] }
  retries 3
end

execute 'Create the policy file' do
  command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-bootstrap-policy-file --filename=#{node['cookbook-openshift3']['openshift_master_policy']}"
  creates node['cookbook-openshift3']['openshift_master_policy']
end

template node['cookbook-openshift3']['openshift_master_scheduler_conf'] do
  source 'scheduler.json.erb'
  variables ose_major_version: ose_major_version
  notifies :restart, 'service[Restart API]', :immediately
end

if node['cookbook-openshift3']['oauth_Identities'].include? 'HTPasswdPasswordIdentityProvider'
  package 'httpd-tools' do
    retries 3
  end

  template node['cookbook-openshift3']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']['filename'] do
    source 'htpasswd.erb'
    mode '600'
  end
end

sysconfig_vars = {}

if node['cookbook-openshift3']['openshift_cloud_provider'] == 'aws'
  if node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_name'] && node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_item_name']
    secret_file = node['cookbook-openshift3']['openshift_cloud_providers']['aws']['secret_file'] || nil
    aws_vars = Chef::EncryptedDataBagItem.load(node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_name'], node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_item_name'], secret_file)

    sysconfig_vars['aws_access_key_id'] = aws_vars['access_key_id']
    sysconfig_vars['aws_secret_access_key'] = aws_vars['secret_access_key']
  end
end

template "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  source 'service_master.sysconfig.erb'
  variables(sysconfig_vars)
  notifies :restart, 'service[Restart API]', :immediately
  notifies :restart, 'service[Restart Controller]', :immediately
end

template node['cookbook-openshift3']['openshift_master_api_systemd'] do
  source node['cookbook-openshift3']['deploy_containerized'] == true ? 'service_master-api-containerized.service.erb' : 'service_master-api.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
end

template node['cookbook-openshift3']['openshift_master_controllers_systemd'] do
  source node['cookbook-openshift3']['deploy_containerized'] == true ? 'service_master-controllers-containerized.service.erb' : 'service_master-controllers.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
end

template node['cookbook-openshift3']['openshift_master_api_sysconfig'] do
  source 'service_master-api.sysconfig.erb'
  variables(sysconfig_vars)
  notifies :restart, 'service[Restart API]', :immediately
end

template node['cookbook-openshift3']['openshift_master_controllers_sysconfig'] do
  source 'service_master-controllers.sysconfig.erb'
  variables(sysconfig_vars)
  notifies :restart, 'service[Restart Controller]', :immediately
end

openshift_create_master 'Create master configuration file' do
  named_certificate node['cookbook-openshift3']['openshift_master_named_certificates']
  origins node['cookbook-openshift3']['erb_corsAllowedOrigins'].uniq
  master_file node['cookbook-openshift3']['openshift_master_config_file']
  etcd_servers etcd_servers
  masters_size master_servers.size
  openshift_service_type node['cookbook-openshift3']['openshift_service_type']
  standalone_registry node['cookbook-openshift3']['deploy_standalone_registry']
  cluster true
end

if certificate_server['fqdn'] == first_master['fqdn'] || !is_certificate_server
  execute 'Activate services for Master API on first master' do
    command 'echo nothing to do specific'
    notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
    notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
    only_if { first_master['fqdn'] == node['fqdn'] }
  end

  execute 'Wait for master api service to start on first master' do
    command 'sleep 15'
    action :run
    not_if "systemctl is-active #{node['cookbook-openshift3']['openshift_service_type']}-master-api"
  end

  execute 'Activate services for Master API on all masters' do
    command 'echo nothing to do specific'
    notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
    notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
    only_if { first_master['fqdn'] != node['fqdn'] }
  end

  execute 'Wait for API to become available' do
    command "[[ $(curl --silent #{node['cookbook-openshift3']['openshift_master_api_url']}/healthz/ready --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
    retries 120
    retry_delay 1
  end

  execute 'Activate services for Master CONTROLLERS on first master' do
    command 'echo nothing to do specific'
    notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
    notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
    only_if { first_master['fqdn'] == node['fqdn'] }
  end

  execute 'Wait for master controller service to start on first master' do
    command 'sleep 15'
    action :run
    not_if "systemctl is-active #{node['cookbook-openshift3']['openshift_service_type']}-master-controllers"
  end

  execute 'Activate services for Master CONTROLLERS on all masters' do
    command 'echo nothing to do specific'
    notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
    notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
    only_if { first_master['fqdn'] != node['fqdn'] }
  end

  execute 'Disable Master service on masters' do
    command 'echo nothing to do specific'
    notifies :disable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately
    notifies :run, "ruby_block[Mask #{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately
  end
end

# Use ruby_block as systemd service provider does not support 'mask' action
# https://tickets.opscode.com/browse/CHEF-3369
ruby_block "Mask #{node['cookbook-openshift3']['openshift_service_type']}-master" do
  block do
    Mixlib::ShellOut.new("systemctl mask #{node['cookbook-openshift3']['openshift_service_type']}-master").run_command
  end
  action :nothing
end
