#
# Cookbook Name:: is_apaas_openshift_cookbook
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

unless new_etcd_servers.empty?
  if is_certificate_server

    directory node['is_apaas_openshift_cookbook']['etcd_generated_scaleup_dir'] do
      mode '0755'
      owner 'apache'
      group 'apache'
      recursive true
    end

    new_etcd_servers.each do |etcd|
      execute "Add #{etcd['fqdn']} to the cluster" do
        command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt -C #{etcds} member add #{etcd['fqdn']} https://#{etcd['ipaddress']}:2380 | grep ^ETCD | tr --delete '\"' | tee #{node['is_apaas_openshift_cookbook']['etcd_generated_scaleup_dir']}/etcd-#{etcd['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_scaleup_dir']}/etcd-#{etcd['fqdn']}"
        notifies :run, "execute[Check #{etcd['fqdn']} has successfully registered]", :immediately
      end

      execute "Check #{etcd['fqdn']} has successfully registered" do
        command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['is_apaas_openshift_cookbook']['etcd_generated_ca_dir']}/ca.crt -C #{etcds} cluster-health | grep -w 'got healthy result from https://#{etcd['ipaddress']}:2379'"
        retries 60
        retry_delay 5
        action :nothing
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

    directory "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d" do
      action :create
    end

    unless ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/.joined")
      template "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d/override.conf" do
        source 'etcd-override.conf.erb'
      end

      remote_file "Retrieve ETCD SystemD Drop-in from Certificate Server[#{certificate_server['fqdn']}]" do
        path "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d/etcd-dropin"
        source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/scaleup/etcd-#{node['fqdn']}"
        action :create_if_missing
        notifies :run, 'execute[daemon-reload]', :immediately
        notifies :start, 'service[etcd-service]', :immediately
        retries 60
        retry_delay 5
      end

      execute 'Check cluster health' do
        command "[[ $(/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['etcd_peer_file']} --key-file #{node['is_apaas_openshift_cookbook']['etcd_peer_key']} --ca-file #{node['is_apaas_openshift_cookbook']['etcd_ca_cert']} -C https://`hostname`:2379 cluster-health | grep -c 'got healthy') -eq #{new_etcd_size} ]]"
        retries 60
        retry_delay 5
      end

      directory "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service.d" do
        recursive true
        action :delete
        notifies :run, 'execute[daemon-reload]', :immediately
      end

      file "#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/.joined" do
        action :create_if_missing
      end
    end
  end
end
