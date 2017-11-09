#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_registry
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_registry
resource_name :openshift_deploy_registry

actions :create

default_action :create

attribute :persistent_registry, kind_of: [TrueClass, FalseClass], required: true
attribute :persistent_volume_claim_name, kind_of: [String], default: ''
