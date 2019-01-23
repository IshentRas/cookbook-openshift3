#
# Cookbook Name:: cookbook-openshift3
# Recipe:: certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_certificate_server = server_info.on_certificate_server?
new_etcd_servers = server_info.new_etcd_servers
remove_etcd_servers = server_info.remove_etcd_servers
ose_major_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']

if is_certificate_server
  node['cookbook-openshift3']['enabled_firewall_rules_certificate'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  openshift_master_pkg 'Install OpenShift Master Packages for Certificate Server'

  include_recipe 'cookbook-openshift3::etcd_packages'
  include_recipe 'cookbook-openshift3::etcd_certificates' if node['cookbook-openshift3']['openshift_HA']
  include_recipe 'cookbook-openshift3::etcd_recovery' if ::File.file?(node['cookbook-openshift3']['adhoc_recovery_etcd_certificate_server'])
  include_recipe 'cookbook-openshift3::etcd_scaleup' unless new_etcd_servers.empty?
  include_recipe 'cookbook-openshift3::etcd_removal' unless remove_etcd_servers.empty?
  include_recipe 'cookbook-openshift3::master_cluster_ca'
  include_recipe 'cookbook-openshift3::master_cluster_certificates' if node['cookbook-openshift3']['openshift_HA']
  include_recipe 'cookbook-openshift3::wire_aggregator_certificates' if ose_major_version.split('.')[1].to_i >= 7
  include_recipe 'cookbook-openshift3::nodes_certificates'
end
