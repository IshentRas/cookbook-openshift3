#
# Cookbook Name:: cookbook-openshift3
# Recipe:: cloud_provider
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

if node['cookbook-openshift3']['openshift_cloud_provider']
  is_master_server = node['cookbook-openshift3']['master_servers'].find { |server_master| server_master['fqdn'] == node['fqdn'] }
  is_node_server = node['cookbook-openshift3']['node_servers'].find { |server_node| server_node['fqdn'] == node['fqdn'] }

  if is_master_server || is_node_server
    directory node['cookbook-openshift3']['openshift_cloud_provider_config_dir'] do
      recursive true
    end

    config_vars = {
      'aws' => {},
    }

    case node['cookbook-openshift3']['openshift_cloud_provider']
    when 'aws'
      config_vars['aws']['zone'] = Chef::HTTP.new('http://169.254.169.254/latest/meta-data/placement/availability-zone').get('/')
    end

    config_file = "#{node['cookbook-openshift3']['openshift_cloud_provider_config_dir']}/#{node['cookbook-openshift3']['openshift_cloud_provider']}.conf"

    template config_file do
      source 'cloud_provider.conf.erb'
      variables(config_vars)
      notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :delayed if is_master_server && !node['cookbook-openshift3']['openshift_HA']
      notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :delayed if is_master_server && node['cookbook-openshift3']['openshift_HA']
      notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :delayed if is_master_server && node['cookbook-openshift3']['openshift_HA']
      notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :delayed if is_node_server
    end
  end
end
