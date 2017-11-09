#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_router
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_router
resource_name :openshift_deploy_router

actions :create

default_action :create

attribute :deployer_options, kind_of: [String, Array], default: []
