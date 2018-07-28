#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_certificate_server = server_info.on_certificate_server?
new_etcd_servers = server_info.new_etcd_servers
remove_etcd_servers = server_info.remove_etcd_servers

if is_certificate_server
  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_certificate'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  include_recipe 'is_apaas_openshift_cookbook::master_packages'
  include_recipe 'is_apaas_openshift_cookbook::etcd_packages'
  include_recipe 'is_apaas_openshift_cookbook::etcd_certificates' if node['is_apaas_openshift_cookbook']['openshift_HA']
  include_recipe 'is_apaas_openshift_cookbook::etcd_scaleup' unless new_etcd_servers.empty?
  include_recipe 'is_apaas_openshift_cookbook::etcd_removal' unless remove_etcd_servers.empty?
  include_recipe 'is_apaas_openshift_cookbook::master_cluster_ca'
  include_recipe 'is_apaas_openshift_cookbook::master_cluster_certificates' if node['is_apaas_openshift_cookbook']['openshift_HA']
  include_recipe 'is_apaas_openshift_cookbook::nodes_certificates'
end
