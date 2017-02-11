#
# Cookbook Name:: cookbook-openshift3
# Recipe:: validate
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
if node['cookbook-openshift3']['ose_version']
  if node['cookbook-openshift3']['ose_version'].to_f.round(1) != node['cookbook-openshift3']['ose_major_version'].to_f.round(1)
    Chef::Application.fatal!("\"ose_version\" #{node['cookbook-openshift3']['ose_version']} should be a subset of \"ose_major_version\" #{node['cookbook-openshift3']['ose_major_version']}")
  end
end

if node['cookbook-openshift3']['use_wildcard_nodes'] && node['cookbook-openshift3']['wildcard_domain'].empty?
  Chef::Application.fatal!('"wildcard_domain" cannot be left empty when using "use_wildcard_nodes attribute"')
end

if node['cookbook-openshift3']['openshift_HA'] && node['cookbook-openshift3']['openshift_cluster_name'].nil?
  Chef::Application.fatal!('A Cluster Name must be defined via "openshift_cluster_name"')
end

if node['cookbook-openshift3']['openshift_hosted_cluster_metrics']
  unless node['cookbook-openshift3']['openshift_hosted_cluster_metrics'] && Hash[node['cookbook-openshift3']['openshift_hosted_metrics_parameters'].map { |k, v| [k.upcase, v] }].key?('HAWKULAR_METRICS_HOSTNAME')
    Chef::Application.fatal!('Key HAWKULAR_METRICS_HOSTNAME must be defined when deploying cluster metrics ("openshift_hosted_metrics_parameters")')
  end
end

if node['cookbook-openshift3']['etcd_add_additional_nodes']
  unless node['cookbook-openshift3']['etcd_add_additional_nodes'] && node['cookbook-openshift3']['etcd_servers'].any? { |key| key['new_node'] }
    Chef::Application.fatal!('A key named "new_node" must be defined when adding new members to ETCD cluster')
  end
end
