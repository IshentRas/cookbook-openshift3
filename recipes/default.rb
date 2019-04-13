#
# Cookbook Name:: cookbook-openshift3
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
should_be_configured = server_info.should_be_configured?
is_etcd_server = server_info.on_etcd_server?
is_master_server = server_info.on_master_server?
is_control_plane_server = server_info.on_control_plane_server?
is_node_server = server_info.on_node_server?
is_certificate_server = server_info.on_certificate_server?

include_recipe 'iptables::default'
include_recipe 'selinux_policy::default'

if should_be_configured
  if ::File.file?(node['cookbook-openshift3']['adhoc_uninstall_openshift3_cookbook'])
    Chef::Log.warn('adhoc_uninstall_openshift3_cookbook file found against Control Plane Server (Ignoring uninstall)') if is_control_plane_server
    Chef::Log.warn('adhoc_uninstall_openshift3_cookbook file found (Triggerring uninstall)') unless is_control_plane_server
    include_recipe 'cookbook-openshift3::services'
    include_recipe 'cookbook-openshift3::adhoc_uninstall' unless is_control_plane_server
    return
  end

  if node['cookbook-openshift3']['ose_major_version'].split('.')[1].to_i >= 10
    include_recipe 'cookbook-openshift3::ng_commons' if Chef::VERSION.to_f >= 14.0
    Chef::Log.error('For 3.10, CHEF client must be 14.0+') if Chef::VERSION.to_f < 14.0
    return
  end

  if ::File.file?(node['cookbook-openshift3']['adhoc_turn_off_openshift3_cookbook'])
    Chef::Log.warn('adhoc_turn_off_openshift3_cookbook file found: ' + node['cookbook-openshift3']['adhoc_turn_off_openshift3_cookbook'])
    return
  end

  include_recipe 'cookbook-openshift3::ca_bundle_fix'

  include_recipe 'cookbook-openshift3::services'

  if ::File.file?(node['cookbook-openshift3']['adhoc_reset_control_flag'])
    include_recipe 'cookbook-openshift3::adhoc_reset'
  end

  if node['cookbook-openshift3']['control_upgrade']
    begin
      include_recipe 'cookbook-openshift3::upgrade_certificate_server' if is_certificate_server && !is_master_server
      include_recipe "cookbook-openshift3::upgrade_control_plane#{node['cookbook-openshift3']['control_upgrade_version']}" if is_master_server || is_etcd_server
      include_recipe "cookbook-openshift3::upgrade_node#{node['cookbook-openshift3']['control_upgrade_version']}" if is_node_server && !is_master_server
    rescue Chef::Exceptions::RecipeNotFound
      Chef::Log.error("The variable control_upgrade_version \'#{node['cookbook-openshift3']['control_upgrade_version']}\' is not a valid target (14,15,36,37,39)")
    end
  end

  if node['cookbook-openshift3']['asynchronous_upgrade']
    include_recipe 'cookbook-openshift3::disable_excluder'
  end

  if is_control_plane_server && ::File.file?(node['cookbook-openshift3']['adhoc_migrate_etcd_flag'])
    include_recipe 'cookbook-openshift3::adhoc_migrate_etcd'
    return
  end

  include_recipe 'cookbook-openshift3::validate'
end
