#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_certificate_server
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

  if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
    node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
  end

  log 'Upgrade for CERTIFICATE SERVER [STARTED]' do
    level :info
  end

  %w[excluder docker-excluder].each do |pkg|
    execute "Disable atomic-openshift-#{pkg}" do
      command "atomic-openshift-#{pkg} enable"
      only_if "rpm -q atomic-openshift-#{pkg}"
    end
  end

  include_recipe 'is_apaas_openshift_cookbook::packages'
  openshift_master_pkg 'Upgrade OpenShift Master Packages for Certificate Server'
  include_recipe 'is_apaas_openshift_cookbook::etcd_packages'
  include_recipe 'is_apaas_openshift_cookbook::excluder'

  include_recipe 'is_apaas_openshift_cookbook::wire_aggregator_certificates' if ose_major_version.split('.')[1].to_i == 7 && node['is_apaas_openshift_cookbook']['upgrade']

  log 'Upgrade for CERTIFICATE SERVER [COMPLETED]' do
    level :info
  end
end
