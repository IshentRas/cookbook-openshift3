#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: web_console
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
master_servers = server_info.master_servers

FOLDER = Chef::Config['file_cache_path'] + '/web_console'

oc_project 'openshift-web-console'

oc_serviceaccount 'openshift-web-console' do
  namespace 'openshift-web-console'
end

directory FOLDER.to_s do
  recursive true
end

remote_file "#{FOLDER}/admin.kubeconfig" do
  source "file://#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
  sensitive true
end

cookbook_file "#{FOLDER}/console-template.yaml" do
  source 'web_console/console-template.yaml'
  mode '0644'
end

template 'Generate the web console config to temp directory' do
  path "#{FOLDER}/console-config.yaml"
  source 'web_console/console-config.yaml.erb'
  mode '0644'
  sensitive true
end

execute 'Generate web console ConfigMap' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create configmap webconsole-config --from-file=webconsole-config.yaml=#{FOLDER}/console-config.yaml --dry-run -o yaml --config=#{FOLDER}/admin.kubeconfig | #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} apply --config=#{FOLDER}/admin.kubeconfig -f - -n openshift-web-console"
end

execute 'Generate the Deployment' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} process -f #{FOLDER}/console-template.yaml --param IMAGE=#{node['is_apaas_openshift_cookbook']['openshift_web_console_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']} --param REPLICA_COUNT=#{master_servers.size} --config=#{FOLDER}/admin.kubeconfig | #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} apply --config=#{FOLDER}/admin.kubeconfig -f - -n openshift-web-console"
end
