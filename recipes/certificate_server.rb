#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_certificate_server = server_info.on_certificate_server?
is_master_server = server_info.on_master_server?
docker_version = node['is_apaas_openshift_cookbook']['openshift_docker_image_version']

if is_certificate_server || is_master_server
  if node['is_apaas_openshift_cookbook']['deploy_containerized']

    docker_image node['is_apaas_openshift_cookbook']['openshift_docker_master_image'] do
      tag docker_version
      action :pull_if_missing
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

    %w(oadm oc kubectl).each do |client_symlink|
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

  package 'atomic-openshift' do
    action :install
    version node['is_apaas_openshift_cookbook']['ose_version'] unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
    options node['is_apaas_openshift_cookbook']['yum_options'] unless node['is_apaas_openshift_cookbook']['yum_options'].nil?
    not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
    retries 3
  end
end
