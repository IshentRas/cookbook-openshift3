#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: excluder
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_node_server = server_info.on_node_server?
is_master_server = server_info.on_master_server?

ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

if is_node_server || node['is_apaas_openshift_cookbook']['deploy_containerized']
  yum_package 'atomic-openshift-docker-excluder' do
    action :upgrade if node['is_apaas_openshift_cookbook']['upgrade']
    version node['is_apaas_openshift_cookbook']['excluder_version'] unless node['is_apaas_openshift_cookbook']['excluder_version'].nil?
    not_if { ose_major_version.split('.')[1].to_i < 5 && node['is_apaas_openshift_cookbook']['openshift_deployment_type'] != 'enterprise' }
  end

  execute 'Enable atomic-openshift-docker-excluder' do
    command 'atomic-openshift-docker-excluder disable'
    not_if { ose_major_version.split('.')[1].to_i < 5 && node['is_apaas_openshift_cookbook']['openshift_deployment_type'] != 'enterprise' }
  end
end

if is_master_server || is_node_server
  yum_package 'atomic-openshift-excluder' do
    action :upgrade if node['is_apaas_openshift_cookbook']['upgrade']
    version node['is_apaas_openshift_cookbook']['excluder_version'] unless node['is_apaas_openshift_cookbook']['excluder_version'].nil?
    not_if { ose_major_version.split('.')[1].to_i < 5 && node['is_apaas_openshift_cookbook']['openshift_deployment_type'] != 'enterprise' }
  end

  execute 'Enable atomic-openshift-excluder' do
    command 'atomic-openshift-excluder disable'
    not_if { ose_major_version.split('.')[1].to_i < 5 && node['is_apaas_openshift_cookbook']['openshift_deployment_type'] != 'enterprise' }
  end
end
