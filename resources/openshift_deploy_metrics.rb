#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_registry
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_metrics
resource_name :openshift_deploy_metrics

actions [:create, :delete]

default_action :create
