#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: master_packages
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_certificate_server = server_info.on_certificate_server?
first_master = server_info.first_master
docker_version = node['is_apaas_openshift_cookbook']['openshift_docker_image_version']

if node['is_apaas_openshift_cookbook']['deploy_containerized']
  execute 'Pull Master Image' do
    command "docker pull #{node['is_apaas_openshift_cookbook']['openshift_docker_master_image']}:#{docker_version}"
  end

  bash 'Add CLI to master(s)' do
    code <<-BASH
      docker create --name temp-cli ${DOCKER_IMAGE}:${DOCKER_TAG}
      docker cp temp-cli:/usr/bin/openshift /usr/local/bin/openshift
      docker rm temp-cli
      BASH
    environment(
      'DOCKER_IMAGE' => node['is_apaas_openshift_cookbook']['openshift_docker_master_image'],
      'DOCKER_TAG' => node['is_apaas_openshift_cookbook']['openshift_docker_image_version']
    )
    not_if { ::File.exist?('/usr/local/bin/openshift') && !node['is_apaas_openshift_cookbook']['upgrade'] }
  end

  %w[oadm oc kubectl].each do |client_symlink|
    link "/usr/local/bin/#{client_symlink}" do
      to '/usr/local/bin/openshift'
      link_type :hard
    end
  end

  execute 'Add bash completion for oc' do
    command '/usr/local/bin/oc completion bash > /etc/bash_completion.d/oc'
    not_if { ::File.exist?('/etc/bash_completion.d/oc') && !node['is_apaas_openshift_cookbook']['upgrade'] }
  end
end

package 'atomic-openshift-master' do
  action :install
  version node['is_apaas_openshift_cookbook']['ose_version'] unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
  options node['is_apaas_openshift_cookbook']['yum_options'] unless node['is_apaas_openshift_cookbook']['yum_options'].nil?
  notifies :run, 'execute[daemon-reload]', :immediately
  not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] || (is_certificate_server && node['fqdn'] != first_master['fqdn']) }
  retries 3
end

package 'atomic-openshift-clients' do
  action :install
  version node['is_apaas_openshift_cookbook']['ose_version'] unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
  options node['is_apaas_openshift_cookbook']['yum_options'] unless node['is_apaas_openshift_cookbook']['yum_options'].nil?
  not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
  retries 3
end
