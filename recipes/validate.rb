#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: validate
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
first_master = server_info.first_master
first_etcd = server_info.first_etcd
master_servers = server_info.master_servers
lb_servers = server_info.lb_servers
etcd_servers = server_info.etcd_servers
certificate_server = server_info.certificate_server
is_certificate_server = server_info.on_certificate_server?

if node['is_apaas_openshift_cookbook']['ose_version']
  if node['is_apaas_openshift_cookbook']['ose_version'].to_f.round(1) != node['is_apaas_openshift_cookbook']['ose_major_version'].to_f.round(1)
    Chef::Log.error("\"ose_version\" #{node['is_apaas_openshift_cookbook']['ose_version']} should be a subset of \"ose_major_version\" #{node['is_apaas_openshift_cookbook']['ose_major_version']}")
    node.run_state['issues_detected'] = true
  end
end

if node['is_apaas_openshift_cookbook']['use_wildcard_nodes'] && node['is_apaas_openshift_cookbook']['wildcard_domain'].empty?
  Chef::Log.error('"wildcard_domain" cannot be left empty when using "use_wildcard_nodes attribute"')
  node.run_state['issues_detected'] = true
end

if node['is_apaas_openshift_cookbook']['openshift_HA'] && node['is_apaas_openshift_cookbook']['openshift_cluster_name'].empty?
  Chef::Log.error('A Cluster Name must be defined via "openshift_cluster_name"')
  node.run_state['issues_detected'] = true
end

if !node['is_apaas_openshift_cookbook']['openshift_HA'] && node['is_apaas_openshift_cookbook']['certificate_server'] != {}
  Chef::Log.error('Separate certificate server and master standalone not supported.')
  node.run_state['issues_detected'] = true
end

if !node['is_apaas_openshift_cookbook']['openshift_HA'] && node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i > 6
  Chef::Log.error('Master standalone is not supported with 3.7+')
  node.run_state['issues_detected'] = true
end

if node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics']
  unless node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_types'].any? { |t| t.casecmp(node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type']).zero? }
    Chef::Log.error('Key openshift_metrics_cassandra_storage_types is not valid. Please refer to the documentation for supprted types')
    node.run_state['issues_detected'] = true
  end
end

if node['is_apaas_openshift_cookbook']['etcd_add_additional_nodes']
  unless node['is_apaas_openshift_cookbook']['etcd_add_additional_nodes'] && etcd_servers.any? { |key| key['new_node'] }
    Chef::Log.error('A key named "new_node" must be defined when adding new members to ETCD cluster')
    node.run_state['issues_detected'] = true
  end
end

%w(openshift_node_max_pod openshift_node_minimum_container_ttl_duration openshift_node_maximum_dead_containers_per_container openshift_node_maximum_dead_containers openshift_node_image_gc_high_threshold openshift_node_image_gc_low_threshold).each do |deprecated|
  unless node['is_apaas_openshift_cookbook'][deprecated].empty?
    Chef::Log.warn("The attributes #{deprecated} has been deprecated, please use \"openshift_node_kubelet_args_custom\",")
  end
end

if node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router']
  Chef::Log.warn("The custom router file \"#{node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file']}\" cannot be found") unless ::File.exist?(node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file'])
end

if node['is_apaas_openshift_cookbook']['openshift_logging_install_logging'] && node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_logging']
  Chef::Log.error("openshift_logging_es_cluster_size (#{node['is_apaas_openshift_cookbook']['openshift_logging_es_cluster_size']}) should be an odd number") if node['is_apaas_openshift_cookbook']['openshift_logging_es_cluster_size'].to_i.even?
  node.run_state['issues_detected'] = true if node['is_apaas_openshift_cookbook']['openshift_logging_es_cluster_size'].to_i.even?
end

unless master_servers.is_a?(Array)
  Chef::Log.error('master_servers not an array')
  node.run_state['issues_detected'] = true
end

unless lb_servers.is_a?(Array)
  Chef::Log.error('lb_servers not an array')
  node.run_state['issues_detected'] = true
end

unless etcd_servers.is_a?(Array)
  Chef::Log.error('etcd_servers not an array')
  node.run_state['issues_detected'] = true
end

if first_master.nil?
  Chef::Log.error('first_master not set')
  node.run_state['issues_detected'] = true
end

if node['is_apaas_openshift_cookbook']['openshift_HA']
  if first_etcd.nil?
    Chef::Log.error('first_etcd not set')
    node.run_state['issues_detected'] = true
  end
end

if certificate_server.nil?
  Chef::Log.error('certificate_server not set')
  node.run_state['issues_detected'] = true
end

if master_servers.empty?
  Chef::Log.error('No master_servers set')
  node.run_state['issues_detected'] = true
end

if is_certificate_server
  include_recipe 'is_apaas_openshift_cookbook::helper_migrate_certificate_server_cluster' if helper.check_certificate_server_cluster
  include_recipe 'is_apaas_openshift_cookbook::helper_migrate_certificate_server_etcd' if helper.check_certificate_server_etcd
end

unless node['is_apaas_openshift_cookbook']['upgrade'] && ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])
  include_recipe 'is_apaas_openshift_cookbook::adhoc_redeploy_certificates' if node['is_apaas_openshift_cookbook']['adhoc_redeploy_certificates']
  include_recipe 'is_apaas_openshift_cookbook::commons' unless node.run_state['issues_detected']
end
