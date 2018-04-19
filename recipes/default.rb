#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_etcd_server = server_info.on_etcd_server?
is_master_server = server_info.on_master_server?
is_node_server = server_info.on_node_server?
is_certificate_server = server_info.on_certificate_server?

if ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_uninstall_control_flag'])
  include_recipe 'is_apaas_openshift_cookbook::adhoc_uninstall'
end

include_recipe 'is_apaas_openshift_cookbook::services'

if node['is_apaas_openshift_cookbook']['control_upgrade']
  begin
    include_recipe 'is_apaas_openshift_cookbook::upgrade_certificate_server' if is_certificate_server && !is_master_server
    include_recipe "is_apaas_openshift_cookbook::upgrade_control_plane#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}" if is_master_server || is_etcd_server
    include_recipe "is_apaas_openshift_cookbook::upgrade_node#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}" if is_node_server && !is_master_server
  rescue Chef::Exceptions::RecipeNotFound
    Chef::Log.error("The variable control_upgrade_version \'#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}\' is not a valid target (14,15,36,37)")
  end
end

include_recipe 'is_apaas_openshift_cookbook::validate'
