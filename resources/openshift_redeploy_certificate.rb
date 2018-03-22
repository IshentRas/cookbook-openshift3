#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_redeploy_certificate
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_redeploy_certificate
resource_name :openshift_redeploy_certificate

actions :redeploy

default_action :redeploy
