#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: ng_docker
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

yum_package 'docker' do
  action :install
  version node['is_apaas_openshift_cookbook']['upgrade'] ? (node['is_apaas_openshift_cookbook']['upgrade_docker_version'] unless node['is_apaas_openshift_cookbook']['upgrade_docker_version'].nil?) : (node['is_apaas_openshift_cookbook']['docker_version'] unless node['is_apaas_openshift_cookbook']['docker_version'].nil?)
  retries 3
  options node['is_apaas_openshift_cookbook']['docker_yum_options'] unless node['is_apaas_openshift_cookbook']['docker_yum_options'].nil?
  notifies :restart, 'service[docker]', :immediately if node['is_apaas_openshift_cookbook']['upgrade']
  only_if do
    ::Mixlib::ShellOut.new('rpm -q docker').run_command.error? || node['is_apaas_openshift_cookbook']['upgrade']
  end
end

template '/etc/sysconfig/docker-storage-setup' do
  source 'docker-storage.erb'
end

template '/etc/sysconfig/docker-network' do
  source 'service_docker-network.sysconfig.erb'
  notifies :restart, 'service[docker]', :immediately unless ::Mixlib::ShellOut.new('systemctl is-enabled docker').run_command.error?
end

template '/etc/sysconfig/docker' do
  source 'service_docker.sysconfig.erb'
  notifies :restart, 'service[docker]', :immediately
  notifies :enable, 'service[docker]', :immediately
end
