#
# Cookbook Name:: cookbook-openshift3
# Recipe:: adhoc_migrate_etcd
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
first_etcd = server_info.first_etcd
is_etcd_server = server_info.on_etcd_server?
is_master_server = server_info.on_master_server?
is_first_master = server_info.on_first_master?
is_first_etcd = server_info.on_first_etcd?
certificate_server = server_info.certificate_server
is_certificate_server = server_info.on_certificate_server?
is_control_plane_server = server_info.on_control_plane_server?
etcd_servers = server_info.etcd_servers
certificate_server_protocol = server_info.certificate_server_protocol

include_recipe 'cookbook-openshift3::services'

if is_etcd_server
  return if ::File.file?("#{node['cookbook-openshift3']['etcd_data_dir']}/.migrated")

  if ::Dir.glob("#{node['cookbook-openshift3']['etcd_data_dir']}/member/snap/*.snap").empty?
    Chef::Log.error('Before the migration can proceed the etcd member must write down at least one snapshot under /var/lib/etcd/member/snap directory')
    return
  end
end

if is_master_server
  log 'Stop services on MASTERS' do
    level :info
    notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately unless node['cookbook-openshift3']['openshift_HA']
    notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately if node['cookbook-openshift3']['openshift_HA']
    notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately if node['cookbook-openshift3']['openshift_HA']
  end
end

if is_first_etcd
  execute 'Check cluster health' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 cluster-health | grep -w 'cluster is healthy'"
    notifies :run, 'execute[Check if there are any v3 data]', :immediately
  end

  execute 'Check if there are any v3 data' do
    command "[[ $(ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['cookbook-openshift3']['etcd_peer_file']} --key #{node['cookbook-openshift3']['etcd_peer_key']} --cacert #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 get '.' --from-key --keys-only -w simple | wc -l) -eq 0 ]]"
    notifies :run, 'execute[Starting ETCD Migration]', :immediately
    action :nothing
  end

  execute 'Starting ETCD Migration' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 set /migration/etcd pre"
    action :nothing
  end

  execute 'Checking flag for migration (ETCD)' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 get /migration/etcd | grep -w pre"
    retries 120
    retry_delay 5
    notifies :run, 'execute[Generate etcd backup before migration]', :immediately
  end

  directory "#{node['cookbook-openshift3']['etcd_data_dir']}/backup"

  execute 'Generate etcd backup before migration' do
    command "etcdctl backup --data-dir=#{node['cookbook-openshift3']['etcd_data_dir']} --backup-dir=#{node['cookbook-openshift3']['etcd_data_dir']}/backup/pre-migration-v3"
    action :nothing
    notifies :run, 'execute[Copy etcd v3 data store]', :immediately
  end

  execute 'Copy etcd v3 data store' do
    command "cp -a #{node['cookbook-openshift3']['etcd_data_dir']}/member/snap/db #{node['cookbook-openshift3']['etcd_data_dir']}/backup/pre-migration-v3/member/snap/"
    action :nothing
    notifies :write, 'log[Stop services on ETCD]', :immediately
  end

  log 'Stop services on ETCD' do
    level :info
    notifies :stop, 'service[etcd-service]', :immediately
    action :nothing
  end

  execute 'Migrate etcd data' do
    command "ETCDCTL_API=3 /usr/bin/etcdctl migrate --data-dir=#{node['cookbook-openshift3']['etcd_data_dir']} &> #{Chef::Config[:file_cache_path]}/etcd_migration1"
  end

  execute 'Check the etcd v2 data are correctly migrated' do
    command "cat #{Chef::Config[:file_cache_path]}/etcd_migration1 | grep 'finished transforming keys' && touch #{Chef::Config[:file_cache_path]}/etcd_migration2"
    only_if { ::File.exist?("#{Chef::Config[:file_cache_path]}/etcd_migration1") }
  end

  ruby_block 'Set ETCD_FORCE_NEW_CLUSTER=true on first etcd host' do
    block do
      f = Chef::Util::FileEdit.new("#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf")
      f.insert_line_if_no_match(/^ETCD_FORCE_NEW_CLUSTER/, 'ETCD_FORCE_NEW_CLUSTER=true')
      f.write_file
    end
    notifies :start, 'service[etcd-service]', :immediately
    only_if { ::File.exist?("#{Chef::Config[:file_cache_path]}/etcd_migration2") }
  end

  execute 'Check ETCD cluster health before doing anything' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 cluster-health | grep -w 'cluster is healthy'"
    retries 30
    retry_delay 1
    notifies :run, 'ruby_block[Unset ETCD_FORCE_NEW_CLUSTER=true]', :immediately
    only_if { ::File.exist?("#{Chef::Config[:file_cache_path]}/etcd_migration2") }
  end

  ruby_block 'Unset ETCD_FORCE_NEW_CLUSTER=true' do
    block do
      f = Chef::Util::FileEdit.new("#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf")
      f.search_file_delete_line(/^ETCD_FORCE_NEW_CLUSTER/)
      f.write_file
    end
    action :nothing
  end

  execute 'Wait for 10 seconds when containerised' do
    command 'sleep 10'
    only_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  execute 'Set ETCD ready' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 set /migration/${etcd_path} ok"
    only_if { etcd_servers.size > 1 }
    environment('etcd_path' => etcd_servers.size > 1 ? 'etcd-cluster' : 'etcd')
  end

  file "#{node['cookbook-openshift3']['etcd_data_dir']}/.migrated" do
    action :create_if_missing
  end
end

unless etcd_servers.size == 1
  if is_certificate_server

    directory node['cookbook-openshift3']['etcd_generated_migrated_dir'] do
      mode '0755'
      owner 'apache'
      group 'apache'
      recursive true
    end

    execute 'Checking flag for migration (Certificate Server)' do
      command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/etcd-cluster | grep -w ok"
      retries 120
      retry_delay 5
    end

    etcd_servers.reject { |etcdservers| etcdservers['fqdn'] == first_etcd['fqdn'] }.each do |etcd|
      execute "Add #{etcd['fqdn']} to the cluster" do
        command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 member add #{etcd['fqdn']} https://#{etcd['ipaddress']}:2380 | grep ^ETCD | tr --delete '\"' | tee #{node['cookbook-openshift3']['etcd_generated_migrated_dir']}/etcd-#{etcd['fqdn']} && chmod 644 #{node['cookbook-openshift3']['etcd_generated_migrated_dir']}/etcd-#{etcd['fqdn']}"
      end

      execute "Check #{etcd['fqdn']} has successfully registered" do
        command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.crt --key-file #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{first_etcd['fqdn']}/peer.key --ca-file #{node['cookbook-openshift3']['etcd_generated_ca_dir']}/ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 cluster-health | grep -w 'got healthy result from https://#{etcd['ipaddress']}:2379'"
        retries 120
        retry_delay 5
        notifies :run, 'execute[Wait for 10 seconds for cluster to sync]', :immediately unless etcd == etcd_servers.last
      end

      execute 'Wait for 10 seconds for cluster to sync' do
        command 'sleep 10'
        action :nothing
      end
    end
  end

  if is_etcd_server && !is_first_etcd
    directory "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d" do
      action :create
    end

    template "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d/override.conf" do
      source 'etcd-override.conf.erb'
      variables(path_bin: node['cookbook-openshift3']['openshift_docker_etcd_image'].include?('coreos') ? '/usr/local/bin/etcd' : '/usr/bin/etcd')
    end

    remote_file "Retrieve ETCD SystemD Drop-in from Certificate Server[#{certificate_server['fqdn']}]" do
      path "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d/etcd-dropin"
      source "#{certificate_server_protocol}://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/migration/etcd-#{node['fqdn']}"
      headers(node['cookbook-openshift3']['cert_server_headers'] || node.run_state['openshift3_cert_server_headers']) if node['cookbook-openshift3']['cert_server_headers'] || node.run_state['openshift3_cert_server_headers']
      notifies :run, 'execute[daemon-reload]', :immediately
      retries 120
      retry_delay 5
    end

    directory "#{node['cookbook-openshift3']['etcd_data_dir']}/member" do
      recursive true
      action :delete
      notifies :stop, 'service[etcd-service]', :before
      notifies :start, 'service[etcd-service]', :immediately
    end

    execute 'Check cluster health (Node has successfully joined)' do
      command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 cluster-health | grep -w 'got healthy result from https://#{node['ipaddress']}:2379'"
      retries 120
      retry_delay 5
    end

    directory "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service.d" do
      recursive true
      action :delete
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    file "#{node['cookbook-openshift3']['etcd_data_dir']}/.migrated" do
      action :create_if_missing
    end
  end

  if is_first_etcd
    execute 'Check cluster health. All members are back online' do
      command "[[ $(/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 cluster-health | grep -c 'got healthy') -eq #{etcd_servers.size} ]]"
      notifies :run, 'execute[Set Migration ready for Masters]', :immediately
      retries 120
      retry_delay 5
    end

    execute 'Set Migration ready for Masters' do
      command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['etcd_peer_file']} --key-file #{node['cookbook-openshift3']['etcd_peer_key']} --ca-file #{node['cookbook-openshift3']['etcd_ca_cert']} --endpoints https://`hostname -i`:2379 set /migration/${etcd_path} ready"
      environment('etcd_path' => etcd_servers.size > 1 ? 'etcd-cluster' : 'etcd')
      action :nothing
    end

    file "#{node['cookbook-openshift3']['etcd_data_dir']}/.migrated" do
      action :create_if_missing
    end
  end
end

if is_first_master
  execute 'Checking flag for migration (Master)' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/${etcd_path} | grep -w ready"
    environment('etcd_path' => etcd_servers.size > 1 ? 'etcd-cluster' : 'etcd')
    retries 120
    retry_delay 5
    notifies :run, 'bash[Add TTLs on the first master]', :immediately
  end

  bash 'Add TTLs on the first master' do
    code <<-BASH
      ETCDCTL_API=3 #{node['cookbook-openshift3']['openshift_common_admin_binary']} migrate etcd-ttl --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --etcd-address https://#{first_etcd['ipaddress']}:2379 --ttl-keys-prefix /kubernetes.io/events --lease-duration 1h

      ETCDCTL_API=3 #{node['cookbook-openshift3']['openshift_common_admin_binary']} migrate etcd-ttl --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --etcd-address https://#{first_etcd['ipaddress']}:2379 --ttl-keys-prefix /kubernetes.io/masterleases --lease-duration 10s

      ETCDCTL_API=3 #{node['cookbook-openshift3']['openshift_common_admin_binary']} migrate etcd-ttl --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --etcd-address https://#{first_etcd['ipaddress']}:2379 --ttl-keys-prefix /openshift.io/oauth/accesstokens --lease-duration 86400s

      ETCDCTL_API=3 #{node['cookbook-openshift3']['openshift_common_admin_binary']} migrate etcd-ttl --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --etcd-address https://#{first_etcd['ipaddress']}:2379 --ttl-keys-prefix /openshift.io/oauth/authorizetokens --lease-duration 500s

      ETCDCTL_API=3 #{node['cookbook-openshift3']['openshift_common_admin_binary']} migrate etcd-ttl --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --etcd-address https://#{first_etcd['ipaddress']}:2379 --ttl-keys-prefix /openshift.io/leases/controllers --lease-duration 30s
    BASH
    action :nothing
    notifies :run, 'execute[Clearing migration flag]', :immediately
  end

  execute 'Clearing migration flag' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 set /migration/${etcd_path} final"
    environment('etcd_path' => etcd_servers.size > 1 ? 'etcd-cluster' : 'etcd')
    action :nothing
  end
end

if is_master_server
  execute 'Checking flag for clearing migration (Master)' do
    command "/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/${etcd_path} | grep -w final"
    environment('etcd_path' => etcd_servers.size > 1 ? 'etcd-cluster' : 'etcd')
    retries 240
    retry_delay 10
  end

  config_options = YAML.load_file("#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/master-config.yaml")
  config_options['kubernetesMasterConfig']['apiServerArguments'].store('storage-backend', %w[etcd3])
  config_options['kubernetesMasterConfig']['apiServerArguments'].store('storage-media-type', %w[application/vnd.kubernetes.protobuf])

  file "#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/master-config.yaml" do
    content config_options.to_yaml
    notifies :write, 'log[Start services on MASTERS]', :immediately
  end

  log 'Start services on MASTERS' do
    level :info
    action :nothing
    notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
    notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
  end

  log 'ETCD migration [COMPLETED]' do
    level :info
  end
end

if is_control_plane_server
  file node['cookbook-openshift3']['adhoc_migrate_etcd_flag'] do
    action :delete
  end
end
