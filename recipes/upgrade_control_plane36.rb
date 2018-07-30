#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_control_plane36
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

Chef::Log.error("Upgrade will be skipped. Could not find the flag: #{node['is_apaas_openshift_cookbook']['control_upgrade_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])

if ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])

  node.force_override['is_apaas_openshift_cookbook']['upgrade'] = true
  node.force_override['is_apaas_openshift_cookbook']['ose_major_version'] = node['is_apaas_openshift_cookbook']['upgrade_ose_major_version']
  node.force_override['is_apaas_openshift_cookbook']['ose_version'] = node['is_apaas_openshift_cookbook']['upgrade_ose_version']
  node.force_override['is_apaas_openshift_cookbook']['openshift_docker_image_version'] = node['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version']
  node.force_override['yum']['main']['exclude'] = node['is_apaas_openshift_cookbook']['custom_pkgs_excluder'] unless node['is_apaas_openshift_cookbook']['custom_pkgs_excluder'].nil?

  server_info = OpenShiftHelper::NodeHelper.new(node)
  first_etcd = server_info.first_etcd
  is_etcd_server = server_info.on_etcd_server?
  is_master_server = server_info.on_master_server?
  is_node_server = server_info.on_node_server?
  is_first_master = server_info.on_first_master?

  if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
    node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
  end

  if is_master_server
    return unless server_info.check_master_upgrade?(server_info.first_etcd, node['is_apaas_openshift_cookbook']['control_upgrade_version'])
  end

  include_recipe 'yum::default'
  include_recipe 'is_apaas_openshift_cookbook::packages'
  include_recipe 'is_apaas_openshift_cookbook::disable_excluder'

  if is_etcd_server
    log 'Upgrade for ETCD [STARTED]' do
      level :info
    end

    openshift_upgrade 'Generate etcd backup before upgrade' do
      action :create_backup
      etcd_action 'pre'
      target_version node['is_apaas_openshift_cookbook']['control_upgrade_version']
    end

    include_recipe 'is_apaas_openshift_cookbook'
    include_recipe 'is_apaas_openshift_cookbook::etcd_cluster'

    openshift_upgrade 'Generate etcd backup after upgrade' do
      action :create_backup
      etcd_action 'post'
      target_version node['is_apaas_openshift_cookbook']['control_upgrade_version']
    end

    log 'Upgrade for ETCD [COMPLETED]' do
      level :info
    end

    file node['is_apaas_openshift_cookbook']['control_upgrade_flag'] do
      action :delete
      only_if { is_etcd_server && !is_master_server }
    end
  end

  if is_master_server
    log 'Upgrade for MASTERS [STARTED]' do
      level :info
    end

    config_options = YAML.load_file("#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master/master-config.yaml")
    node.force_override['is_apaas_openshift_cookbook']['etcd_migrated'] = false unless config_options['kubernetesMasterConfig']['apiServerArguments'].key?('storage-backend')

    include_recipe 'is_apaas_openshift_cookbook::master'
    include_recipe 'is_apaas_openshift_cookbook::excluder' unless is_node_server

    log 'Restart Master services' do
      level :info
      notifies :restart, 'service[atomic-openshift-master]', :immediately unless node['is_apaas_openshift_cookbook']['openshift_HA']
      notifies :restart, 'service[atomic-openshift-master-api]', :immediately if node['is_apaas_openshift_cookbook']['openshift_HA']
      notifies :restart, 'service[atomic-openshift-master-controllers]', :immediately if node['is_apaas_openshift_cookbook']['openshift_HA']
    end

    execute "Set upgrade markup for master : #{node['fqdn']}" do
      command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 set /migration/#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}/#{node['fqdn']} ok"
    end

    log 'Upgrade for MASTERS [COMPLETED]' do
      level :info
    end
  end

  if is_first_master
    log 'Reconcile Cluster Roles & Cluster Role Bindings [STARTED]' do
      level :info
    end

    openshift_upgrade 'Reconcile Cluster Roles & Cluster Role Bindings' do
      action :reconcile_cluster_roles
      target_version node['is_apaas_openshift_cookbook']['control_upgrade_version']
    end

    log 'Reconcile Cluster Roles & Cluster Role Bindings [COMPLETED]' do
      level :info
    end

    log 'Update the registry certificate for push-dns [STARTED]' do
      level :info
    end

    openshift_deploy_registry 'Redeploy Registry certificate' do
      action :redeploy_certificate
      only_if do
        node['is_apaas_openshift_cookbook']['openshift_hosted_manage_registry']
      end
    end

    log 'Update the registry certificate for push-dns [COMPLETED]' do
      level :info
    end

    include_recipe 'is_apaas_openshift_cookbook::upgrade_managed_hosted'
  end
  include_recipe 'is_apaas_openshift_cookbook::upgrade_node36' if is_node_server
end
