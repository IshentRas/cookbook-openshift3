#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_node14
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
  is_node_server = server_info.on_node_server?

  if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
    node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
  end

  include_recipe 'yum::default'
  include_recipe 'is_apaas_openshift_cookbook::packages'
  include_recipe 'is_apaas_openshift_cookbook::disable_excluder'

  if is_node_server
    log 'Upgrade for NODE [STARTED]' do
      level :info
    end

    include_recipe 'is_apaas_openshift_cookbook::services'
    include_recipe 'is_apaas_openshift_cookbook::node'
    include_recipe 'is_apaas_openshift_cookbook::docker'
    include_recipe 'is_apaas_openshift_cookbook::excluder'

    file 'Remove obsolete docker-sdn-ovs.conf' do
      path '/etc/systemd/system/docker.service.d/docker-sdn-ovs.conf'
      action :delete
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    log 'Node services' do
      level :info
      notifies :restart, 'service[openvswitch]', :immediately
      not_if { ::File.file?("/usr/local/share/info/.upgrade-#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}") }
    end

    file "/usr/local/share/info/.upgrade-#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}" do
      action :create_if_missing
    end

    log 'Upgrade for NODE [COMPLETED]' do
      level :info
    end
  end
end
