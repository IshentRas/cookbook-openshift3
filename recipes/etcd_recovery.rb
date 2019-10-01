#
# Cookbook Name:: cookbook-openshift3
# Recipe:: etcd_recovery
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
first_etcd = server_info.first_etcd
is_etcd_server = server_info.on_etcd_server?
certificate_server = server_info.certificate_server
is_certificate_server = server_info.on_certificate_server?
etcd_servers = server_info.etcd_servers
etcd_healthy = helper.checketcd_healthy?
certificate_server_protocol = server_info.certificate_server_protocol

if is_certificate_server && etcd_healthy && ::File.file?(node['cookbook-openshift3']['adhoc_recovery_etcd_certificate_server'])
  file node['cookbook-openshift3']['adhoc_recovery_etcd_certificate_server'] do
    action :delete
  end
end

if is_certificate_server && ::File.file?(node['cookbook-openshift3']['adhoc_clean_etcd_flag'])
  ruby_block 'Force wiping recovery directory' do
    block do
      helper.remove_dir("#{node['cookbook-openshift3']['etcd_generated_recovery_dir']}/*")
    end
  end
end

if is_certificate_server && !etcd_healthy
  directory node['cookbook-openshift3']['etcd_generated_recovery_dir'] do
    mode '0755'
    owner 'apache'
    group 'apache'
    recursive true
  end

  etcd_servers.each do |etcd|
    execute "Remove unhealthy member #{etcd['fqdn']} from the cluster" do
      command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} member remove $(/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | awk '/unreachable/ { print $2 }')"
      retries 2
      retry_delay 2
      only_if { !Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | grep \"is unreachable.*#{etcd['ipaddress']}\"").run_command.error? }
    end

    execute "Add #{etcd['fqdn']} to the cluster" do
      command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} member add #{etcd['fqdn']} https://#{etcd['ipaddress']}:2380 | grep ^ETCD | tr --delete '\"' | tee #{node['cookbook-openshift3']['etcd_generated_recovery_dir']}/etcd-#{etcd['fqdn']} && chmod 644 #{node['cookbook-openshift3']['etcd_generated_recovery_dir']}/etcd-#{etcd['fqdn']}"
      creates "#{node['cookbook-openshift3']['etcd_generated_recovery_dir']}/etcd-#{etcd['fqdn']}"
      notifies :run, "execute[Check #{etcd['fqdn']} has successfully registered]", :immediately
      notifies :start, 'service[httpd]', :before
      not_if { Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} member list").run_command.stdout.strip.include?(etcd['fqdn']) }
    end

    execute "Check #{etcd['fqdn']} has successfully registered" do
      command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | grep -w 'got healthy result from https://#{etcd['ipaddress']}:2379'"
      retries 120
      retry_delay 5
      notifies :run, "execute[Wait for 10 seconds for cluster to sync with #{etcd['fqdn']}]", :immediately
      action :nothing
    end

    execute "Wait for 10 seconds for cluster to sync with #{etcd['fqdn']}" do
      command 'sleep 10'
      action :nothing
    end
  end

  file node['cookbook-openshift3']['adhoc_recovery_etcd_certificate_server'] do
    action :delete
  end

  ruby_block 'Wipe recovery directory' do
    block do
      helper.remove_dir("#{node['cookbook-openshift3']['etcd_generated_recovery_dir']}/*")
    end
  end
end

if is_etcd_server && ::File.file?(node['cookbook-openshift3']['adhoc_recovery_etcd_member'])
  directory "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d" do
    action :create
  end

  template "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d/override.conf" do
    source 'etcd-override.conf.erb'
    variables(path_bin: node['cookbook-openshift3']['openshift_docker_etcd_image'].include?('coreos') ? '/usr/local/bin/etcd' : '/usr/bin/etcd')
  end

  remote_file "Retrieve ETCD SystemD Drop-in from Certificate Server[#{certificate_server['fqdn']}]" do
    path "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d/etcd-dropin"
    source "#{certificate_server_protocol}://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/recovery/etcd-#{node['fqdn']}"
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :delete, "directory[#{node['cookbook-openshift3']['etcd_data_dir']}/member]", :immediately
    retries 120
    retry_delay 5
  end

  directory "#{node['cookbook-openshift3']['etcd_data_dir']}/member" do
    recursive true
    action :nothing
    notifies :start, 'service[etcd-service]', :immediately
  end

  execute 'Check cluster health' do
    command "[[ $(/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} -C https://`hostname -i`:2379 cluster-health | grep -c 'got healthy') -eq #{etcd_servers.size} ]]"
    retries 60
    notifies :delete, "directory[/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d]", :immediately
    retry_delay 5
  end

  directory "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d" do
    recursive true
    action :nothing
    notifies :run, 'execute[daemon-reload]', :immediately
  end
end

if is_etcd_server && ::File.file?(node['cookbook-openshift3']['adhoc_recovery_etcd_emergency'])
  ruby_block 'Set ETCD_FORCE_NEW_CLUSTER=true on etcd host (Emergency)' do
    block do
      f = Chef::Util::FileEdit.new("#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf")
      f.insert_line_if_no_match(/^ETCD_FORCE_NEW_CLUSTER/, 'ETCD_FORCE_NEW_CLUSTER=true')
      f.write_file
    end
    notifies :restart, 'service[etcd-service]', :immediately
  end

  execute 'Check ETCD cluster health before removing node in Emergency mode' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} -C https://`hostname -i`:2379 cluster-health | grep -w 'cluster is healthy'"
    retries 30
    retry_delay 1
    notifies :run, 'ruby_block[Unset ETCD_FORCE_NEW_CLUSTER=true (Emergency)]', :immediately
  end

  ruby_block 'Unset ETCD_FORCE_NEW_CLUSTER=true (Emergency)' do
    block do
      f = Chef::Util::FileEdit.new("#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf")
      f.search_file_delete_line(/^ETCD_FORCE_NEW_CLUSTER/)
      f.write_file
    end
    action :nothing
  end
end
