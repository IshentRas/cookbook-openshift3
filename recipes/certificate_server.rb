#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_certificate_server = server_info.on_certificate_server?
new_etcd_servers = server_info.new_etcd_servers
remove_etcd_servers = server_info.remove_etcd_servers
ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

if is_certificate_server
  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_certificate'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  openshift_master_pkg 'Install OpenShift Master Packages for Certificate Server'

  include_recipe 'is_apaas_openshift_cookbook::etcd_packages'
  include_recipe 'is_apaas_openshift_cookbook::etcd_certificates' if node['is_apaas_openshift_cookbook']['openshift_HA']
  include_recipe 'is_apaas_openshift_cookbook::etcd_recovery' if ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_certificate_server'])
  include_recipe 'is_apaas_openshift_cookbook::etcd_scaleup' unless new_etcd_servers.empty?
  include_recipe 'is_apaas_openshift_cookbook::etcd_removal' unless remove_etcd_servers.empty?
  include_recipe 'is_apaas_openshift_cookbook::master_cluster_ca'
  include_recipe 'is_apaas_openshift_cookbook::master_cluster_certificates' if node['is_apaas_openshift_cookbook']['openshift_HA']
  include_recipe 'is_apaas_openshift_cookbook::wire_aggregator_certificates' if ose_major_version.split('.')[1].to_i >= 7
  include_recipe 'is_apaas_openshift_cookbook::nodes_certificates'
end
