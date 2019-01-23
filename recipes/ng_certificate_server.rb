#
# Cookbook Name:: cookbook-openshift3
# Recipe:: ng_certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node['cookbook-openshift3']['enabled_firewall_rules_certificate'].each do |rule|
  iptables_rule rule do
    action :enable
    notifies :restart, 'service[iptables]', :immediately
  end
end

include_recipe 'cookbook-openshift3::etcd_certificates'
openshift_master_pkg 'Install OpenShift Master Client for Certificate Server'
include_recipe 'cookbook-openshift3::ng_master_cluster_ca'
include_recipe 'cookbook-openshift3::ng_master_cluster_certificates'
