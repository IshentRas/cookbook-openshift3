#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: excluder
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

%w(excluder docker-excluder).each do |pkg|
  yum_package "atomic-openshift-#{pkg}" do
    action :upgrade if node['is_apaas_openshift_cookbook']['upgrade']
    version node['is_apaas_openshift_cookbook']['excluder_version'] unless node['is_apaas_openshift_cookbook']['excluder_version'].nil?
    not_if { ose_major_version.split('.')[1].to_i < 5 && node['is_apaas_openshift_cookbook']['openshift_deployment_type'] != 'enterprise' }
  end

  execute "Enable atomic-openshift-#{pkg}" do
    command "atomic-openshift-#{pkg} disable"
    not_if { ose_major_version.split('.')[1].to_i < 5 && node['is_apaas_openshift_cookbook']['openshift_deployment_type'] != 'enterprise' }
    not_if { node['is_apaas_openshift_cookbook']['upgrade'] }
  end
end
