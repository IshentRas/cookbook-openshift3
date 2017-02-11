#
# Cookbook Name:: cookbook-openshift3
# Recipe:: master_standalone
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

if node['cookbook-openshift3']['deploy_containerized']
  execute 'Pull CLI docker image' do
    command "docker pull #{node['cookbook-openshift3']['openshift_docker_cli_image']}:#{node['cookbook-openshift3']['openshift_docker_image_version']}"
    not_if "docker images  | grep #{node['cookbook-openshift3']['openshift_docker_cli_image']}.*#{node['cookbook-openshift3']['openshift_docker_image_version']}"
  end

  template '/usr/local/bin/openshift' do
    source 'openshift_cli.erb'
    mode '0755'
  end

  %w(oadm oc kubectl).each do |client_symlink|
    link "/usr/local/bin/#{client_symlink}" do
      to '/usr/local/bin/openshift'
      link_type :hard
    end
  end

  execute 'Pull MASTER docker image' do
    command "docker pull #{node['cookbook-openshift3']['openshift_docker_master_image']}:#{node['cookbook-openshift3']['openshift_docker_image_version']}"
    not_if "docker images  | grep #{node['cookbook-openshift3']['openshift_docker_master_image']}.*#{node['cookbook-openshift3']['openshift_docker_image_version']}"
  end
end

execute 'Create the master certificates' do
  command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-master-certs \
          --hostnames=#{node['cookbook-openshift3']['erb_corsAllowedOrigins'].join(',')} \
          --master=#{node['cookbook-openshift3']['openshift_master_api_url']} \
          --public-master=#{node['cookbook-openshift3']['openshift_master_public_api_url']} \
          --cert-dir=#{node['cookbook-openshift3']['openshift_master_config_dir']} --overwrite=false"
  creates "#{node['cookbook-openshift3']['openshift_master_config_dir']}/master.server.key"
end

package "#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  action :install
  version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
  notifies :run, 'execute[daemon-reload]', :immediately
  not_if { node['cookbook-openshift3']['deploy_containerized'] }
end

template "/etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master.service" do
  source 'service_master-containerized.service.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
  only_if { node['cookbook-openshift3']['deploy_containerized'] }
end

template "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  source 'service_master.sysconfig.erb'
end

execute 'Create the policy file' do
  command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} create-bootstrap-policy-file --filename=#{node['cookbook-openshift3']['openshift_master_policy']}"
  creates node['cookbook-openshift3']['openshift_master_policy']
  notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :delayed
end

template node['cookbook-openshift3']['openshift_master_scheduler_conf'] do
  source 'scheduler.json.erb'
  variables ose_major_version: node['cookbook-openshift3']['ose_major_version']
  notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :delayed
end

if node['cookbook-openshift3']['oauth_Identity'] == 'HTPasswdPasswordIdentityProvider'
  package 'httpd-tools'

  template node['cookbook-openshift3']['openshift_master_identity_provider'][node['cookbook-openshift3']['oauth_Identity']]['filename'] do
    source 'htpasswd.erb'
    mode '600'
  end
end

openshift_create_master 'Create master configuration file' do
  named_certificate node['cookbook-openshift3']['openshift_master_named_certificates']
  origins node['cookbook-openshift3']['erb_corsAllowedOrigins'].uniq
  standalone_registry node['cookbook-openshift3']['deploy_standalone_registry']
  master_file node['cookbook-openshift3']['openshift_master_config_file']
  openshift_service_type node['cookbook-openshift3']['openshift_service_type']
end

service "#{node['cookbook-openshift3']['openshift_service_type']}-master" do
  action [:start, :enable]
end
