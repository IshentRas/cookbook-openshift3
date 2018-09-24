#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_create_master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_create_master
resource_name :openshift_create_master

actions %i(create create_ng)

default_action :create

attribute :named_certificate, kind_of: Array, regex: /.*/, required: true, default: []
attribute :origins, kind_of: Array, regex: /.*/, required: true, default: []
attribute :standalone_registry, kind_of: [TrueClass, FalseClass], required: false, default: false
attribute :master_file, kind_of: String, regex: /.*/, required: true, default: nil
attribute :etcd_servers, kind_of: Array, regex: /.*/, required: false, default: []
attribute :masters_size, kind_of: [String, Integer], regex: /.*/, required: false, default: nil
attribute :openshift_service_type, kind_of: [String, Integer], regex: /.*/, required: true, default: nil
attribute :cluster_name, kind_of: String, regex: /.*/, required: false, default: nil
