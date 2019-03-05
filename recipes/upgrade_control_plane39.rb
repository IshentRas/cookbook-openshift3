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
  is_etcd_server = server_info.on_etcd_server?
  is_master_server = server_info.on_master_server?
  is_node_server = server_info.on_node_server?

  if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
    node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
  end

  if is_master_server
    return unless server_info.check_master_upgrade?(server_info.first_etcd, node['is_apaas_openshift_cookbook']['control_upgrade_version'])
  end

  include_recipe 'yum::default'
  include_recipe 'is_apaas_openshift_cookbook::packages'
  include_recipe 'is_apaas_openshift_cookbook::disable_excluder'

  if is_master_server || is_node_server
    %w[excluder docker-excluder].each do |pkg|
      execute "Disable atomic-openshift-#{pkg} for Control Plane" do
        command "atomic-openshift-#{pkg} enable"
      end
    end
  end

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
