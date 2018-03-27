#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_create_master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_add_etcd
resource_name :openshift_add_etcd

actions %i(add_node remove_node)

default_action :add_node

attribute :etcd_servers, kind_of: Array, regex: /.*/, required: true, default: []
attribute :etcd_servers_to_remove, kind_of: Array, regex: /.*/, required: false, default: []
