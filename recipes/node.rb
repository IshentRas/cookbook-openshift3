#
# Cookbook Name:: cookbook-openshift3
# Recipe:: node
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['master_servers']
node_servers = node['cookbook-openshift3']['node_servers']
path_certificate = node['cookbook-openshift3']['use_wildcard_nodes'] ? 'wildcard_nodes.tgz.enc' : "#{node['fqdn']}.tgz.enc"
certificate_server = node['cookbook-openshift3']['certificate_server'] == {} ? master_servers.first : node['cookbook-openshift3']['certificate_server']
default_interface = `/sbin/ip route get to 8.8.8.8`[/src.*/][/\d+\.\d+\.\d+\.\d+/]

ose_major_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']
origin_dns_upstream_ip = ose_major_version.split('.')[1].to_i >= 6 ? '127.0.0.1' : node['cookbook-openshift3']['openshift_common_first_svc_ip']

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = Chef::EncryptedDataBagItem.load(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

if node_servers.find { |server_node| server_node['fqdn'] == node['fqdn'] }
  file '/usr/local/etc/.firewall_node_additional.txt' do
    content node['cookbook-openshift3']['enabled_firewall_additional_rules_node'].join("\n")
    owner 'root'
    group 'root'
  end

  node['cookbook-openshift3']['enabled_firewall_rules_node'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  directory node['cookbook-openshift3']['openshift_node_config_dir'] do
    recursive true
  end

  if node['cookbook-openshift3']['deploy_containerized']
    execute 'Pull NODE docker image' do
      command "docker pull #{node['cookbook-openshift3']['openshift_docker_node_image']}:#{node['cookbook-openshift3']['openshift_docker_image_version']}"
      not_if "docker images  | grep #{node['cookbook-openshift3']['openshift_docker_node_image']}.*#{node['cookbook-openshift3']['openshift_docker_image_version']}"
    end

    execute 'Pull OVS docker image' do
      command "docker pull #{node['cookbook-openshift3']['openshift_docker_ovs_image']}:#{node['cookbook-openshift3']['openshift_docker_image_version']}"
      not_if "docker images  | grep #{node['cookbook-openshift3']['openshift_docker_ovs_image']}.*#{node['cookbook-openshift3']['openshift_docker_image_version']}"
    end

    template "/etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-node-dep.service" do
      source 'service_node-deps-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    template "/etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-node.service" do
      source 'service_node-containerized.service.erb'
      variables(
        origin_dns_upstream_ip: origin_dns_upstream_ip
      )
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    template '/etc/systemd/system/openvswitch.service' do
      source 'service_openvswitch-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    template '/etc/sysconfig/openvswitch' do
      source 'service_openvswitch.sysconfig.erb'
      notifies :restart, 'service[openvswitch]', :immediately
    end
  else
    template "/etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-node.service" do
      source 'service_node.service.erb'
      variables(
        origin_dns_upstream_ip: origin_dns_upstream_ip
      )
      notifies :run, 'execute[daemon-reload]', :immediately
    end
  end

  sysconfig_vars = {}

  if node['cookbook-openshift3']['openshift_cloud_provider'] == 'aws'
    if node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_name'] && node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_item_name']
      secret_file = node['cookbook-openshift3']['openshift_cloud_providers']['aws']['secret_file'] || nil
      aws_vars = Chef::EncryptedDataBagItem.load(node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_name'], node['cookbook-openshift3']['openshift_cloud_providers']['aws']['data_bag_item_name'], secret_file)

      sysconfig_vars['aws_access_key_id'] = aws_vars['access_key_id']
      sysconfig_vars['aws_secret_access_key'] = aws_vars['secret_access_key']
    end
  end

  template "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node" do
    source 'service_node.sysconfig.erb'
    variables(sysconfig_vars)
    notifies :run, 'ruby_block[Restart Node]', :immediately
  end

  package "#{node['cookbook-openshift3']['openshift_service_type']}-node" do
    action :install
    version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  package "#{node['cookbook-openshift3']['openshift_service_type']}-sdn-ovs" do
    action :install
    version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
    only_if { node['cookbook-openshift3']['openshift_common_use_openshift_sdn'] == true }
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  package 'conntrack-tools' do
    action :install
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  remote_file "Retrieve certificate from Master[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/node/generated-configs/#{path_certificate}"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt node certificate tgz files]', :immediately
    notifies :run, 'execute[Extract certificate to Node folder]', :immediately
    retries 12
    retry_delay 5
  end

  execute 'Un-encrypt node certificate tgz files' do
    command "openssl enc -d -aes-256-cbc -in #{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc -out #{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    action :nothing
  end

  execute 'Extract certificate to Node folder' do
    command "tar xzf #{node['fqdn']}.tgz && chown -R root:root ."
    cwd node['cookbook-openshift3']['openshift_node_config_dir']
    action :nothing
  end

  directory "Fix permissions on #{node['cookbook-openshift3']['openshift_node_config_dir']}" do
    path node['cookbook-openshift3']['openshift_node_config_dir']
    owner 'root'
    group 'root'
    mode '0755'
  end

  file "Fix permissions on #{node['cookbook-openshift3']['openshift_node_config_dir']}/ca.crt" do
    path ::File.join(node['cookbook-openshift3']['openshift_node_config_dir'], 'ca.crt')
    owner 'root'
    group 'root'
    mode '0644'
  end

  remote_file '/etc/pki/ca-trust/source/anchors/openshift-ca.crt' do
    source "file://#{node['cookbook-openshift3']['openshift_node_config_dir']}/ca.crt"
    notifies :run, 'ruby_block[Update ca trust]', :immediately
  end

  # Use ruby_block for copying OpenShift CA to system CA trust
  ruby_block 'Update ca trust' do
    block do
      Mixlib::ShellOut.new('update-ca-trust').run_command
    end
    notifies :restart, 'service[docker]', :immediately
    notifies :run, 'execute[Wait for 30 secondes for docker services to come up]', :immediately
    action :nothing
  end

  execute 'Wait for 30 secondes for docker services to come up' do
    command 'sleep 30'
    action :nothing
    only_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  if node['cookbook-openshift3']['deploy_dnsmasq']
    package 'NetworkManager'

    template '/etc/origin/node/node-dnsmasq.conf' do
      source 'node-dnsmasq.conf.erb'
      variables(
        origin_dns_upstream_ip: origin_dns_upstream_ip
      )
    end

    template '/etc/dnsmasq.d/origin-dns.conf' do
      source 'origin-dns.conf.erb'
      variables default_interface: default_interface
      notifies :restart, 'service[dnsmasq]', :immediately
    end

    # On some systems, NetworkManager does not exist, so ignore_failure.
    cookbook_file '/etc/NetworkManager/dispatcher.d/99-origin-dns.sh' do
      source '99-origin-dns.sh'
      owner 'root'
      group 'root'
      mode '0755'
      action :create
      ignore_failure true
      notifies :restart, 'service[NetworkManager]', :immediately
    end

    ruby_block 'Setup dnsmasq' do
      block do
        f = Chef::Util::FileEdit.new('/etc/dnsmasq.conf')
        f.insert_line_if_no_match(%r{^conf-dir=/etc/dnsmasq.d}, 'conf-dir=/etc/dnsmasq.d')
        f.write_file
      end
    end

    # ignore_failure in case this fails/is not necessary
    service 'dnsmasq' do
      action [:enable, :start]
      ignore_failure true
    end
  end

  template node['cookbook-openshift3']['openshift_node_config_file'] do
    source 'node.yaml.erb'
    variables(
      node_labels: node_servers.find { |server_node| server_node['fqdn'] == node['fqdn'] }['labels'].to_s.split(' '),
      ose_major_version: ose_major_version,
      kubelet_args: node['cookbook-openshift3']['openshift_node_kubelet_args_default'].merge(node['cookbook-openshift3']['openshift_node_kubelet_args_custom'])
    )
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :run, 'ruby_block[Restart Node]', :immediately
    notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
  end

  selinux_policy_boolean 'virt_use_nfs' do
    value true
  end

  service "#{node['cookbook-openshift3']['openshift_service_type']}-node" do
    retries 5
    retry_delay 2
    action :start
  end
end
