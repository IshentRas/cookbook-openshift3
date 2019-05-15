#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: adhoc_uninstall
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'iptables::default'
include_recipe 'is_apaas_openshift_cookbook::services'
openshift_delete_host node['fqdn']
