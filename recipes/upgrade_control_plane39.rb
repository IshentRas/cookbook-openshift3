#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_control_plane39
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

Chef::Log.error("Upgrade will be skipped. Could not find the flag: #{node['is_apaas_openshift_cookbook']['control_upgrade_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])

if ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])

  node.force_override['is_apaas_openshift_cookbook']['upgrade'] = true
  node.force_override['is_apaas_openshift_cookbook']['openshift_docker_image_version'] = node['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version']
  node.force_override['is_apaas_openshift_cookbook']['ose_major_version'] = node['is_apaas_openshift_cookbook']['upgrade_ose_major_version']
  node.force_override['is_apaas_openshift_cookbook']['ose_version'] = node['is_apaas_openshift_cookbook']['upgrade_ose_version']

  node.force_override['yum']['main']['exclude'] = node['is_apaas_openshift_cookbook']['custom_pkgs_excluder'] unless node['is_apaas_openshift_cookbook']['custom_pkgs_excluder'].nil?

  server_info = OpenShiftHelper::NodeHelper.new(node)
  first_etcd = server_info.first_etcd
  is_etcd_server = server_info.on_etcd_server?
  is_master_server = server_info.on_master_server?
  is_node_server = server_info.on_node_server?

  if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
    node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
  end

  if is_master_server
    return unless ::Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 ls /migration/#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}/#{node['fqdn']}").run_command.error?
  end

  include_recipe 'yum::default'
  include_recipe 'is_apaas_openshift_cookbook::packages'
  include_recipe 'is_apaas_openshift_cookbook::disable_excluder'

  if is_master_server || is_node_server
    %w(excluder docker-excluder).each do |pkg|
      execute "Disable atomic-openshift-#{pkg} for Control Plane" do
        command "atomic-openshift-#{pkg} enable"
      end
    end
  end

  if is_etcd_server
    log 'Upgrade for ETCD [STARTED]' do
      level :info
    end

    execute 'Generate etcd backup before upgrade' do
      command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade39"
      not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade39") }
      notifies :run, 'execute[Copy etcd v3 data store (PRE)]', :immediately
    end

    execute 'Copy etcd v3 data store (PRE)' do
      command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade39/member/snap/"
      only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
      action :nothing
    end

    include_recipe 'is_apaas_openshift_cookbook'
    include_recipe 'is_apaas_openshift_cookbook::etcd_cluster'

    execute 'Generate etcd backup after upgrade' do
      command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade39"
      not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade39") }
      notifies :run, 'execute[Copy etcd v3 data store (POST)]', :immediately
    end

    execute 'Copy etcd v3 data store (POST)' do
      command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade39/member/snap/"
      only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
      action :nothing
    end

    file node['is_apaas_openshift_cookbook']['control_upgrade_flag'] do
      action :delete
      only_if { is_etcd_server && !is_master_server }
    end

    log 'Upgrade for ETCD [COMPLETED]' do
      level :info
    end
  end

  include_recipe 'is_apaas_openshift_cookbook::upgrade_control_plane38_part1'
  include_recipe 'is_apaas_openshift_cookbook::upgrade_control_plane39_part1'
end
