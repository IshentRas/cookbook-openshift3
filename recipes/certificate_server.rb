#
# Cookbook Name:: cookbook-openshift3
# Recipe:: certificate_server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['master_servers']
certificate_server = node['cookbook-openshift3']['certificate_server'] == {} ? node['cookbook-openshift3']['master_servers'] : master_servers + [node['cookbook-openshift3']['certificate_server']]

if certificate_server.find { |server_master| server_master['fqdn'] == node['fqdn'] }
  if node['cookbook-openshift3']['deploy_containerized']
    execute 'Pull CLI docker image' do
      command "docker pull #{node['cookbook-openshift3']['openshift_docker_cli_image']}:#{node['cookbook-openshift3']['openshift_docker_image_version']}"
      not_if "docker images  | grep #{node['cookbook-openshift3']['openshift_docker_cli_image']}.*#{node['cookbook-openshift3']['openshift_docker_image_version']}"
    end

    bash 'Add CLI to master(s)' do
      code <<-EOH
        docker create --name temp-cli ${DOCKER_IMAGE}:${DOCKER_TAG}
        docker cp temp-cli:/usr/bin/openshift /usr/local/bin/openshift
        docker rm temp-cli
        EOH
      environment(
        'DOCKER_IMAGE' => node['cookbook-openshift3']['openshift_docker_master_image'],
        'DOCKER_TAG' => node['cookbook-openshift3']['openshift_docker_image_version']
      )
      not_if { ::File.exist?('/usr/local/bin/openshift') }
    end

    %w(oadm oc kubectl).each do |client_symlink|
      link "/usr/local/bin/#{client_symlink}" do
        to '/usr/local/bin/openshift'
        link_type :hard
      end
    end

    execute 'Add bash completion for oc' do
      command '/usr/local/bin/oc completion bash > /etc/bash_completion.d/oc'
      not_if { ::File.exist?('/etc/bash_completion.d/oc') || node['cookbook-openshift3']['openshift_docker_image_version'] =~ /v1.2/i }
    end

    execute 'Pull MASTER docker image' do
      command "docker pull #{node['cookbook-openshift3']['openshift_docker_master_image']}:#{node['cookbook-openshift3']['openshift_docker_image_version']}"
      not_if "docker images  | grep #{node['cookbook-openshift3']['openshift_docker_master_image']}.*#{node['cookbook-openshift3']['openshift_docker_image_version']}"
    end
  end

  package node['cookbook-openshift3']['openshift_service_type'] do
    version node['cookbook-openshift3'] ['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end
end
