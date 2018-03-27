#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: commons
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_first_master = server_info.on_first_master?

include_recipe 'is_apaas_openshift_cookbook::common'
include_recipe 'is_apaas_openshift_cookbook::master'
include_recipe 'is_apaas_openshift_cookbook::node'
include_recipe 'is_apaas_openshift_cookbook::master_config_post' if is_first_master
include_recipe 'is_apaas_openshift_cookbook::excluder'
