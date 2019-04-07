#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: docker
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
is_node_server = server_info.on_node_server?

if is_node_server || node['is_apaas_openshift_cookbook']['deploy_containerized']
  yum_package 'docker' do
    action :install
    version node['is_apaas_openshift_cookbook']['upgrade'] ? (helper.get_nodevar('upgrade_docker_version') unless helper.get_nodevar('upgrade_docker_version').nil?) : (helper.get_nodevar('docker_version') unless helper.get_nodevar('docker_version').nil?)
    retries 3
    options node['is_apaas_openshift_cookbook']['docker_yum_options'] unless node['is_apaas_openshift_cookbook']['docker_yum_options'].nil?
    notifies :restart, 'service[docker]', :immediately if node['is_apaas_openshift_cookbook']['upgrade']
    flush_cache(before: true)
    only_if do
      ::Mixlib::ShellOut.new('rpm -q docker').run_command.error? || node['is_apaas_openshift_cookbook']['upgrade'] || ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_reset_control_flag'])
    end
  end

  bash "Configure Docker to use the default FS type for #{node['fqdn']}" do
    code <<-BASH
      correct_fs=$(df -T /var | egrep -o 'xfs|ext4')
      sed -i "s/xfs/$correct_fs/" /usr/bin/docker-storage-setup
    BASH
    not_if "grep $(df -T /var | egrep -o 'xfs|ext4') /usr/bin/docker-storage-setup"
    timeout 60
  end

  template '/etc/sysconfig/docker-storage-setup' do
    source 'docker-storage.erb'
  end

  template '/etc/sysconfig/docker-network' do
    source 'service_docker-network.sysconfig.erb'
    notifies :restart, 'service[docker]', :immediately unless ::Mixlib::ShellOut.new('systemctl is-enabled docker').run_command.error?
  end

  execute 'Trigger Docker from previous deployment' do
    command 'docker-storage-setup --reset'
    action :nothing
  end

  template '/etc/sysconfig/docker' do
    source 'service_docker.sysconfig.erb'
    notifies :run, 'execute[Trigger Docker from previous deployment]', :immediately if ::Mixlib::ShellOut.new('systemctl is-enabled docker').run_command.error?
    notifies :restart, 'service[docker]', :immediately
    notifies :enable, 'service[docker]', :immediately
  end

  if node['is_apaas_openshift_cookbook']['openshift_docker_secure']
    node['is_apaas_openshift_cookbook']['openshift_docker_add_registry_arg'].each do |registry|
      directory "/etc/docker/certs.d/#{registry}" do
        owner 'root'
        group 'root'
        mode '0755'
        action :create
        recursive true
      end

      ruby_block "Update Docker trusted certificates for #{node['fqdn']}" do
        block do
          fqdn, port = registry.split(':')
          uri = port.nil? ? "#{fqdn}:443" : "#{fqdn}:#{port}"
          crt = Mixlib::ShellOut.new("echo | timeout 5 openssl s_client -servername #{fqdn} -connect #{uri} 2>/dev/null | openssl x509").run_command.stdout.strip
          open("/etc/docker/certs.d/#{registry}/registry.crt", 'w') { |f| f << crt.to_s } unless crt.empty?
        end
        not_if { ::File.file?("/etc/docker/certs.d/#{registry}/registry.crt") }
      end
    end
  end
end
