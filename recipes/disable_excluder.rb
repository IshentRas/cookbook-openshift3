#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: disable_excluder
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_master_server = server_info.on_master_server?
is_node_server = server_info.on_node_server?

if is_master_server || is_node_server
  %w[excluder docker-excluder].each do |pkg|
    execute "Disable atomic-openshift-#{pkg} (Best effort < 3.5)" do
      command "atomic-openshift-#{pkg} enable"
      only_if "rpm -q atomic-openshift-#{pkg}"
    end
  end
end
