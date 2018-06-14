#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: adhoc_reset
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

openshift_reset_host node['fqdn']

file node['is_apaas_openshift_cookbook']['adhoc_reset_control_flag'] do
  action :delete
end
