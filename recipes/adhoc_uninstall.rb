#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: adhoc_uninstall
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

openshift_delete_host node['fqdn']
