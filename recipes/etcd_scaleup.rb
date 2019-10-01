#
# Cookbook Name:: cookbook-openshift3
# Recipe:: etcd_scaleup
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
first_etcd = server_info.first_etcd
etcd_servers = server_info.etcd_servers
new_etcd_servers = server_info.new_etcd_servers
certificate_server = server_info.certificate_server
is_new_etcd_server = server_info.on_new_etcd_server?
is_certificate_server = server_info.on_certificate_server?
etcds = etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(',')
path_bin = node['cookbook-openshift3']['openshift_docker_etcd_image'].include?('coreos') ? '/usr/local/bin/etcd' : '/usr/bin/etcd'
certificate_server_protocol = server_info.certificate_server_protocol

unless new_etcd_servers.empty?
  if is_certificate_server

    directory node['cookbook-openshift3']['etcd_generated_scaleup_dir'] do
      mode '0755'
      owner 'apache'
      group 'apache'
      recursive true
    end

    new_etcd_servers.each do |etcd|
      execute "Add #{etcd['fqdn']} to the cluster" do
        command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt -C #{etcds} member add #{etcd['fqdn']} https://#{etcd['ipaddress']}:2380 | grep ^ETCD | tr --delete '\"' | tee #{node['cookbook-openshift3']['etcd_generated_scaleup_dir']}/etcd-#{etcd['fqdn']} && chmod 644 #{node['cookbook-openshift3']['etcd_generated_scaleup_dir']}/etcd-#{etcd['fqdn']}"
        creates "#{node['cookbook-openshift3']['etcd_generated_scaleup_dir']}/etcd-#{etcd['fqdn']}"
      end

      execute "Check #{etcd['fqdn']} has successfully registered" do
        command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt -C #{etcds} cluster-health | grep -w 'got healthy result from https://#{etcd['ipaddress']}:2379'"
        retries 60
        retry_delay 5
        notifies :run, "execute[Wait for 10 seconds for cluster to sync with #{etcd['fqdn']}]", :immediately
      end

      execute "Wait for 10 seconds for cluster to sync with #{etcd['fqdn']}" do
        command 'sleep 10'
        action :nothing
      end
    end
  end

  if is_new_etcd_server

    new_etcd_size = etcd_servers.size + new_etcd_servers.index { |etcd| etcd['fqdn'] == node['fqdn'] } + 1

    directory "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d" do
      action :create
    end

    unless ::File.file?("#{node['cookbook-openshift3']['etcd_data_dir']}/.joined")
      template "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d/override.conf" do
        source 'etcd-override.conf.erb'
        variables(path_bin: path_bin)
      end

      remote_file "Retrieve ETCD SystemD Drop-in from Certificate Server[#{certificate_server['fqdn']}]" do
        path "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d/etcd-dropin"
        source "#{certificate_server_protocol}://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/scaleup/etcd-#{node['fqdn']}"
        action :create_if_missing
        notifies :run, 'execute[daemon-reload]', :immediately
        notifies :start, 'service[etcd-service]', :immediately
        notifies :enable, 'service[etcd-service]', :immediately
        retries 60
        retry_delay 5
      end

      execute 'Check cluster health' do
        command "[[ $(/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} -C https://`hostname -i`:2379 cluster-health | grep -c 'got healthy') -eq #{new_etcd_size} ]]"
        retries 60
        retry_delay 5
      end

      directory "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d" do
        recursive true
        action :delete
        notifies :run, 'execute[daemon-reload]', :immediately
      end

      file "#{node['cookbook-openshift3']['etcd_data_dir']}/.joined" do
        action :create_if_missing
      end
    end
  end
end
