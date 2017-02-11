#
# Cookbook Name:: cookbook-openshift3
# Recipe:: master_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['master_servers']
etcd_servers = node['cookbook-openshift3']['etcd_servers']
master_peers = master_servers.reject { |h| h['fqdn'] == master_servers[0]['fqdn'] }

node['cookbook-openshift3']['enabled_firewall_rules_master_cluster'].each do |rule|
  iptables_rule rule do
    action :enable
  end
end

if etcd_servers.first['fqdn'] != master_servers.first['fqdn']
  directory node['cookbook-openshift3']['etcd_ca_dir'] do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
    recursive true
  end

  template node['cookbook-openshift3']['etcd_openssl_conf'] do
    source 'openssl.cnf.erb'
  end

  %w(certs crl fragments).each do |etcd_ca_sub_dir|
    directory "#{node['cookbook-openshift3']['etcd_ca_dir']}/#{etcd_ca_sub_dir}" do
      owner 'root'
      group 'root'
      mode '0700'
      action :create
      recursive true
    end
  end

  execute "ETCD Generate index.txt #{node['fqdn']}" do
    command 'touch index.txt'
    cwd node['cookbook-openshift3']['etcd_ca_dir']
    creates "#{node['cookbook-openshift3']['etcd_ca_dir']}/index.txt"
  end

  file "#{node['cookbook-openshift3']['etcd_ca_dir']}/serial" do
    content '01'
    action :create_if_missing
  end

  %w(ca.crt ca.key).each do |etcd_crt|
    remote_file "Retrieve CA certificates #{etcd_crt} from ETCD Master[#{etcd_servers.first['fqdn']}]" do
      path "#{node['cookbook-openshift3']['etcd_ca_dir']}/#{etcd_crt}"
      source "http://#{etcd_servers.first['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/generated_certs/etcd/#{etcd_crt}"
      action :create_if_missing
      retries 10
      retry_delay 5
    end
  end
end

if master_servers.first['fqdn'] == node['fqdn']
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

    execute "ETCD Sign and create the CLIENT crt for #{master_server['fqdn']}" do
      command "openssl ca -name #{node['cookbook-openshift3']['etcd_ca_name']} -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -out #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.crt -in #{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.csr -batch"
      environment 'SAN' => ''
      cwd "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}client.crt"
    end

    link "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}ca.crt" do
      to "#{node['cookbook-openshift3']['etcd_ca_dir']}/ca.crt"
      link_type :hard
    end

    execute "Create a tarball of the etcd master certs for #{master_server['fqdn']}" do
      command "tar czvf #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz -C #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']} . "
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz"
    end
  end
end

remote_file "Retrieve client certificate from Master[#{master_servers.first['fqdn']}]" do
  path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz"
  source "http://#{master_servers.first['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/openshift-master-#{node['fqdn']}.tgz"
  action :create_if_missing
  notifies :run, 'execute[Extract certificate to Master folder]', :immediately
  retries 12
  retry_delay 5
end

execute 'Extract certificate to Master folder' do
  command "tar xzf openshift-master-#{node['fqdn']}.tgz"
  cwd node['cookbook-openshift3']['openshift_master_config_dir']
  action :nothing
end

%w(client.crt client.key ca.cert).each do |certificate_type|
  file "#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}#{certificate_type}" do
    owner 'root'
    group 'root'
    mode '0600'
  end
end

if master_servers.first['fqdn'] == node['fqdn']
  execute 'Create the master certificates' do
    command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-master-certs \
            --hostnames=#{node['cookbook-openshift3']['erb_corsAllowedOrigins'].uniq.join(',')} \
            --master=#{node['cookbook-openshift3']['openshift_master_api_url']} \
            --public-master=#{node['cookbook-openshift3']['openshift_master_public_api_url']} \
            --cert-dir=#{node['cookbook-openshift3']['openshift_master_config_dir']} --overwrite=false"
    creates "#{node['cookbook-openshift3']['openshift_master_config_dir']}/master.server.key"
  end

  master_peers.each do |peer_server|
    directory "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
      recursive true
    end

    %w(ca.crt ca.key ca.serial.txt admin.crt admin.key admin.kubeconfig master.kubelet-client.crt master.kubelet-client.key openshift-master.crt openshift-master.key openshift-master.kubeconfig openshift-registry.crt openshift-registry.key openshift-registry.kubeconfig openshift-router.crt master.proxy-client.crt master.proxy-client.key openshift-router.key openshift-router.kubeconfig serviceaccounts.private.key serviceaccounts.public.key).each do |master_certificate|
      link "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']}/#{master_certificate}" do
        to "#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{master_certificate}"
        link_type :hard
      end
    end

    execute "Create the master peer certificates for #{peer_server['fqdn']}" do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-master-certs \
              --hostnames=#{node['cookbook-openshift3']['erb_corsAllowedOrigins'].uniq.join(',').gsub(master_servers.first['ipaddress'], peer_server['ipaddress'])} \
              --master=#{node['cookbook-openshift3']['openshift_master_api_url']} \
              --public-master=#{node['cookbook-openshift3']['openshift_master_public_api_url']} \
              --cert-dir=#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']} --overwrite=false"
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']}/master.server.crt"
    end

    %w(client.crt client.key).each do |remove_etcd_certificate|
      file "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}#{remove_etcd_certificate}" do
        action :delete
      end
    end

    execute "Create a tarball of the peer master certs for #{peer_server['fqdn']}" do
      command "tar czvf #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']}.tgz -C #{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']} . "
      creates "#{node['cookbook-openshift3']['master_generated_certs_dir']}/openshift-#{peer_server['fqdn']}.tgz"
    end
  end
end

if master_servers.first['fqdn'] != node['fqdn']
  remote_file "Retrieve peer certificate from Master[#{master_servers.first['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-#{node['fqdn']}.tgz"
    source "http://#{master_servers.first['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/openshift-#{node['fqdn']}.tgz"
    action :create_if_missing
    notifies :run, 'execute[Extract peer certificate to Master folder]', :immediately
    retries 12
    retry_delay 5
  end

  execute 'Extract peer certificate to Master folder' do
    command "tar xzf openshift-#{node['fqdn']}.tgz"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end

  package node['cookbook-openshift3']['openshift_service_type']
end

package "#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  action :install
  version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
  notifies :run, 'execute[daemon-reload]', :immediately
end

execute 'Create the policy file' do
  command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-bootstrap-policy-file --filename=#{node['cookbook-openshift3']['openshift_master_policy']}"
  creates node['cookbook-openshift3']['openshift_master_policy']
end

template node['cookbook-openshift3']['openshift_master_scheduler_conf'] do
  source 'scheduler.json.erb'
  variables ose_major_version: node['cookbook-openshift3']['ose_major_version']
  notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :delayed
end

if node['cookbook-openshift3']['oauth_Identity'] == 'HTPasswdPasswordIdentityProvider'
  package 'httpd-tools'

  template node['cookbook-openshift3']['openshift_master_identity_provider'][node['cookbook-openshift3']['oauth_Identity']]['filename'] do
    source 'htpasswd.erb'
    mode '600'
  end
end

template "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  source 'service_master.sysconfig.erb'
end

template node['cookbook-openshift3']['openshift_master_api_systemd'] do
  source 'service_master-api.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
end

template node['cookbook-openshift3']['openshift_master_controllers_systemd'] do
  source 'service_master-controllers.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
end

template node['cookbook-openshift3']['openshift_master_api_sysconfig'] do
  source 'service_master-api.sysconfig.erb'
  notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
end

template node['cookbook-openshift3']['openshift_master_controllers_sysconfig'] do
  source 'service_master-controllers.sysconfig.erb'
  notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
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

execute 'Activate services for Master API and Controllers' do
  command 'echo nothing to do specific'
  notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
  notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
  notifies :disable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately
  notifies :run, "ruby_block[Mask #{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately
end

# Use ruby_block as systemd service provider does not support 'mask' action
# https://tickets.opscode.com/browse/CHEF-3369
ruby_block "Mask #{node['cookbook-openshift3']['openshift_service_type']}-master" do
  block do
    Mixlib::ShellOut.new("systemctl mask #{node['cookbook-openshift3']['openshift_service_type']}-master").run_command
  end
  action :nothing
end

execute 'Wait for API to become available' do
  command "echo | openssl s_client -connect #{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']} -servername #{node['cookbook-openshift3']['openshift_common_public_hostname']}"
  retries 15
  retry_delay 2
  notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
end
