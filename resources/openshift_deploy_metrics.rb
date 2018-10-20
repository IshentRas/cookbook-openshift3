#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_deploy_metrics
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_metrics
resource_name :openshift_deploy_metrics

actions %i[create delete]

default_action :create
