#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: ng_certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node['is_apaas_openshift_cookbook']['enabled_firewall_rules_certificate'].each do |rule|
  iptables_rule rule do
    action :enable
    notifies :restart, 'service[iptables]', :immediately
  end
end

include_recipe 'is_apaas_openshift_cookbook::etcd_certificates'
openshift_master_pkg 'Install OpenShift Master Client for Certificate Server'
include_recipe 'is_apaas_openshift_cookbook::ng_master_cluster_ca'
include_recipe 'is_apaas_openshift_cookbook::ng_master_cluster_certificates'
