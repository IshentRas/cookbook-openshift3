#
# Cookbook Name:: cookbook-openshift3
# Recipe:: upgrade_x2_x3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.
include_recipe 'cookbook-openshift3::adhoc_redeploy_certificates'
