#
# Cookbook Name:: cookbook-openshift3
# Recipe:: node
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['master_servers']
node_servers = node['cookbook-openshift3']['node_servers']
path_certificate = node['cookbook-openshift3']['use_wildcard_nodes'] ? 'wildcard_nodes.tgz' : "#{node['fqdn']}.tgz"
certificate_server = node['cookbook-openshift3']['certificate_server'] == {} ? master_servers.first : node['cookbook-openshift3']['certificate_server']

# Use ruby_block for copying OpenShift CA to system CA trust
ruby_block 'Update ca trust' do
  block do
    Mixlib::ShellOut.new('update-ca-trust').run_command
  end
  notifies :restart, 'service[docker]', :immediately
  action :nothing
end

if node_servers.find { |server_node| server_node['fqdn'] == node['fqdn'] }
  file '/usr/local/etc/.firewall_node_additional.txt' do
    content node['cookbook-openshift3']['enabled_firewall_additional_rules_node'].join('\n')
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

  remote_file "Retrieve certificate from Master[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_node_config_dir']}/#{node['fqdn']}.tgz"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/node/generated-configs/#{path_certificate}"
    action :create_if_missing
    notifies :run, 'execute[Extract certificate to Node folder]', :immediately
    retries 12
    retry_delay 5
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

  if node['cookbook-openshift3']['deploy_dnsmasq']
    template '/etc/dnsmasq.d/origin-dns.conf' do
      source 'origin-dns.conf.erb'
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

    # ignore_failure in case this fails/is not necessary
    service 'dnsmasq' do
      action [:enable, :start]
      ignore_failure true
    end
  end

  template node['cookbook-openshift3']['openshift_node_config_file'] do
    source 'node.yaml.erb'
    variables(
      ose_major_version: node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version'],
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
