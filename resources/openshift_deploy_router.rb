#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_deploy_router
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_router
resource_name :openshift_deploy_router

actions :create

default_action :create

attribute :deployer_options, kind_of: [String, Array], default: []
