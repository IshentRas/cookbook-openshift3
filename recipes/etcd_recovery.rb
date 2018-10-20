#
# Cookbook Name:: is_apaas_openshift_cookbook
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

if is_certificate_server && etcd_healthy && ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_member'])
  file node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_member'] do
    action :delete
  end
end

if is_certificate_server && !etcd_healthy
  directory node['is_apaas_openshift_cookbook']['etcd_generated_recovery_dir'] do
    mode '0755'
    owner 'apache'
    group 'apache'
    recursive true
  end

  etcd_servers.each do |etcd|
    execute "Remove unhealthy member #{etcd['fqdn']} from the cluster" do
      command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} member remove $(/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | awk '/unreachable/ { print $2 }')"
      retries 2
      retry_delay 2
      only_if { !Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | grep \"is unreachable.*#{etcd['ipaddress']}\"").run_command.error? }
    end

    execute "Add #{etcd['fqdn']} to the cluster" do
      command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} member add #{etcd['fqdn']} https://#{etcd['ipaddress']}:2380 | grep ^ETCD | tr --delete '\"' | tee #{node['is_apaas_openshift_cookbook']['etcd_generated_recovery_dir']}/etcd-#{etcd['fqdn']}"
      creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_recovery_dir']}/etcd-#{etcd['fqdn']}"
      notifies :run, "execute[Check #{etcd['fqdn']} has successfully registered]", :immediately
      not_if { Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} member list").run_command.stdout.strip.include?(etcd['fqdn']) }
    end

    execute "Check #{etcd['fqdn']} has successfully registered" do
      command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt --endpoints #{etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')} cluster-health | grep -w 'got healthy result from https://#{etcd['ipaddress']}:2379'"
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

  file node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_member'] do
    action :delete
  end

  ruby_block 'Wipe recovery directory' do
    block do
      helper.remove_dir("#{node['is_apaas_openshift_cookbook']['etcd_generated_recovery_dir']}/*")
    end
  end
end

if is_etcd_server && ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_member'])
  directory "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d" do
    action :create
  end

  template "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d/override.conf" do
    source 'etcd-override.conf.erb'
    variables(path_bin: node['is_apaas_openshift_cookbook']['openshift_docker_etcd_image'].include?('coreos') ? '/usr/local/bin/etcd' : '/usr/bin/etcd')
  end

  remote_file "Retrieve ETCD SystemD Drop-in from Certificate Server[#{certificate_server['fqdn']}]" do
    path "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d/etcd-dropin"
    source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/recovery/etcd-#{node['fqdn']}"
    action :create_if_missing
    notifies :run, 'execute[daemon-reload]', :immediately
    retries 120
    retry_delay 5
  end

  directory "#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member" do
    recursive true
    action :delete
    notifies :start, 'service[etcd-service]', :immediately
  end

  directory "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d" do
    recursive true
    action :delete
    notifies :run, 'execute[daemon-reload]', :immediately
  end
end

if is_etcd_server && ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_emergency'])
  ruby_block 'Set ETCD_FORCE_NEW_CLUSTER=true on etcd host (Emergency)' do
    block do
      f = Chef::Util::FileEdit.new("#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd.conf")
      f.insert_line_if_no_match(/^ETCD_FORCE_NEW_CLUSTER/, 'ETCD_FORCE_NEW_CLUSTER=true')
      f.write_file
    end
    notifies :restart, 'service[etcd-service]', :immediately
  end

  execute 'Check ETCD cluster health before removing node in Emergency mode' do
    command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_peer_file']} --key-file #{node['is_apaas_openshift_cookbook']['etcd_peer_key']} --ca-file #{node['is_apaas_openshift_cookbook']['etcd_ca_cert']} -C https://`hostname`:2379 cluster-health | grep -w 'cluster is healthy'"
    retries 30
    retry_delay 1
    notifies :run, 'ruby_block[Unset ETCD_FORCE_NEW_CLUSTER=true (Emergency)]', :immediately
  end

  ruby_block 'Unset ETCD_FORCE_NEW_CLUSTER=true (Emergency)' do
    block do
      f = Chef::Util::FileEdit.new("#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd.conf")
      f.search_file_delete_line(/^ETCD_FORCE_NEW_CLUSTER/)
      f.write_file
    end
    action :nothing
  end
end
