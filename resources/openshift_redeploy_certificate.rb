#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_redeploy_certificate
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_redeploy_certificate
resource_name :openshift_redeploy_certificate

actions :redeploy

default_action :redeploy
