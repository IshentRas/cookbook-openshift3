#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_create_pv
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_create_pv
resource_name :openshift_create_pv

actions :create

default_action :create

attribute :persistent_storage, kind_of: Array, regex: /.*/, required: true
