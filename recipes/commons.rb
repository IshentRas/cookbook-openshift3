#
# Cookbook Name:: cookbook-openshift3
# Recipe:: commons
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_first_master = server_info.on_first_master?

include_recipe 'cookbook-openshift3::validate'
include_recipe 'cookbook-openshift3::common'
include_recipe 'cookbook-openshift3::master'
include_recipe 'cookbook-openshift3::node'
include_recipe 'cookbook-openshift3::master_config_post' if is_first_master
