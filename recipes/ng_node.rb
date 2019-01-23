#
# Cookbook Name:: cookbook-openshift3
# Recipe:: ng_node
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

helper = OpenShiftHelper::NodeHelper.new(node)
openshift_node_group_name = helper.openshift_node_groups
docker_version = node['cookbook-openshift3']['openshift_docker_image_version']

ruby_block 'Turn off SWAP for nodes' do
  block do
    helper.turn_off_swap
  end
  not_if { ::File.readlines('/etc/fstab').grep(/(^[^#].*swap.*)\n/).none? }
  only_if { node['cookbook-openshift3']['openshift_node_disable_swap_on_host'] }
end

file '/usr/local/etc/.firewall_node_additional.txt' do
  content node['cookbook-openshift3']['enabled_firewall_additional_rules_node'].join("\n")
  owner 'root'
  group 'root'
end

node['cookbook-openshift3']['enabled_firewall_rules_node'].each do |rule|
  iptables_rule rule do
    action :enable
    notifies :restart, 'service[iptables]', :immediately
  end
end

yum_package %w[NetworkManager dnsmasq]

ruby_block 'Enforce running NM_CONTROLLED on host' do
  block do
    f = Chef::Util::FileEdit.new("/etc/sysconfig/network-scripts/ifcfg-#{node['network']['default_interface']}")
    f.search_file_delete_line(/^NM_CONTROLLED/)
    f.write_file
  end
  notifies :restart, 'service[NetworkManager]', :immediately
  only_if { ::File.exist?("/etc/sysconfig/network-scripts/ifcfg-#{node['network']['default_interface']}") && ::File.foreach("/etc/sysconfig/network-scripts/ifcfg-#{node['network']['default_interface']}").grep(/^NM_CONTROLLED/).any? }
end

directory node['cookbook-openshift3']['openshift_node_config_dir'] do
  recursive true
  owner 'root'
  group 'root'
  mode '0700'
end

template '/etc/dnsmasq.d/origin-dns.conf' do
  source 'openshift_node/origin-dns.conf.erb'
  notifies :restart, 'service[dnsmasq]', :immediately
end

directory '/etc/systemd/system/dnsmasq.service.d'

cookbook_file '/etc/systemd/system/dnsmasq.service.d/override.conf' do
  source 'openshift_node/override.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[dnsmasq]', :immediately
end

service 'dnsmasq' do
  action %i[enable start]
end

if helper.get_nodevar('custom_origin-dns')
  remote_file 'Retrieve custom file for 99-origin-dns.sh' do
    path '/etc/NetworkManager/dispatcher.d/99-origin-dns.sh'
    source "file://#{helper.get_nodevar('custom_origin_location')}"
    owner 'root'
    group 'root'
    mode '0755'
    notifies :restart, 'service[NetworkManager]', :immediately
  end
else
  cookbook_file '/etc/NetworkManager/dispatcher.d/99-origin-dns.sh' do
    source 'openshift_node/99-origin-dns.sh'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    notifies :restart, 'service[NetworkManager]', :immediately
  end
end

yum_package "#{node['cookbook-openshift3']['openshift_service_type']}-node" do
  action :install
  version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
  options node['cookbook-openshift3']['openshift_yum_options'] unless node['cookbook-openshift3']['openshift_yum_options'].nil?
end

yum_package "#{node['cookbook-openshift3']['openshift_service_type']}-clients" do
  action :install
  version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
  options node['cookbook-openshift3']['openshift_yum_options'] unless node['cookbook-openshift3']['openshift_yum_options'].nil?
end

yum_package 'conntrack-tools'

sysctl 'net.ipv4.ip_forward' do
  value 1
end

selinux_policy_boolean 'container_manage_cgroup' do
  value true
end

docker_image node['cookbook-openshift3']['openshift_docker_node_image'] do
  tag docker_version
  action :pull_if_missing
end

cookbook_file '/usr/local/bin/openshift-node' do
  source 'openshift_node/openshift-node'
  owner 'root'
  group 'root'
  mode '0500'
end

systemd_unit "#{node['cookbook-openshift3']['openshift_service_type']}-node.service" do
  content(Unit: {
            Description: 'OpenShift Node',
            After: ['docker.service', 'chronyd.service', 'ntpd.service', 'dnsmasq.service'],
            Wants: ['docker.service', 'dnsmasq.service'],
            Documentation: 'https://github.com/openshift/origin'
          },
          Service: {
            Type: 'notify',
            EnvironmentFile: "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node",
            ExecStart: '/usr/local/bin/openshift-node',
            LimitNOFILE: '65536',
            LimitCORE: 'infinity',
            WorkingDirectory: '/var/lib/origin/',
            SyslogIdentifier: "#{node['cookbook-openshift3']['openshift_service_type']}-node",
            Restart: 'always',
            RestartSec: '5s',
            TimeoutStartSec: '300',
            OOMScoreAdjust: '-999'
          },
          Install: {
            WantedBy: 'multi-user.target'
          })
  action :create
  triggers_reload true
end

ruby_block 'Configure Node settings' do
  block do
    node_settings = Chef::Util::FileEdit.new("/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node")
    node_settings.search_file_replace_line(/^OPTIONS=/, "OPTIONS=#{node['cookbook-openshift3']['openshift_node_start_options']}")
    node_settings.search_file_replace_line(/^DEBUG_LOGLEVEL=/, "DEBUG_LOGLEVEL=#{node['cookbook-openshift3']['openshift_node_debug_level']}")
    node_settings.search_file_replace_line(/^IMAGE_VERSION=/, "IMAGE_VERSION=#{docker_version}")
    node_settings.write_file
    node_settings = Chef::Util::FileEdit.new("/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node")
    node_settings.insert_line_if_no_match(/^OPTIONS=/, "OPTIONS=#{node['cookbook-openshift3']['openshift_node_start_options']}")
    node_settings.insert_line_if_no_match(/^DEBUG_LOGLEVEL=/, "DEBUG_LOGLEVEL=#{node['cookbook-openshift3']['openshift_node_debug_level']}")
    node_settings.insert_line_if_no_match(/^IMAGE_VERSION=/, "IMAGE_VERSION=#{docker_version}")
    node_settings.write_file
  end
end

openshift_create_node_config 'Create node configuration file' do
  node_file "#{node['cookbook-openshift3']['openshift_node_config_dir']}/node-config.yaml"
end

ruby_block 'Configure Node Environment Variables' do
  block do
    node_env_settings = Chef::Util::FileEdit.new("/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node")
    node['cookbook-openshift3']['openshift_node_env_vars'].each_pair do |k, v|
      node_env_settings.insert_line_if_no_match(/^#{k}/, "#{k}=#{v}")
    end
    node_env_settings.write_file
  end
  not_if { node['cookbook-openshift3']['openshift_node_env_vars'].empty? }
end

yum_package %w[nfs-utils glusterfs-fuse ceph-common iscsi-initiator-utils device-mapper-multipath]

%w[virt_use_nfs virt_sandbox_use_nfs virt_use_fusefs virt_sandbox_use_fusefs].each do |selinux_activate|
  selinux_policy_boolean selinux_activate do
    value true
  end
end

ruby_block 'Update the sysconfig to have necessary variables' do
  block do
    node_settings = Chef::Util::FileEdit.new("/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node")
    node_settings.insert_line_if_no_match(/^KUBECONFIG=/, "KUBECONFIG=#{node['cookbook-openshift3']['openshift_node_config_dir']}/bootstrap.kubeconfig")
    node_settings.write_file
  end
end

%w[/root/openshift_bootstrap /var/lib/origin/openshift.local.config /var/lib/origin/openshift.local.config/node /etc/docker/certs.d/docker-registry.default.svc:5000].each do |bootstrapping_dir|
  directory bootstrapping_dir
end

link '/etc/docker/certs.d/docker-registry.default.svc:5000/node-client-ca.crt' do
  to "#{node['cookbook-openshift3']['openshift_node_config_dir']}/client-ca.crt"
end

%W[#{node['cookbook-openshift3']['openshift_node_config_dir']}/pods #{node['cookbook-openshift3']['openshift_node_config_dir']}/certificates].each do |required_dir|
  directory required_dir do
    owner 'root'
    group 'root'
    mode '0700'
  end
end

ruby_block "Update the sysconfig to group #{openshift_node_group_name}" do
  block do
    node_settings = Chef::Util::FileEdit.new("/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node")
    node_settings.insert_line_if_no_match(/^BOOTSTRAP_CONFIG_NAME=.*/, "BOOTSTRAP_CONFIG_NAME=#{openshift_node_group_name}")
    node_settings.write_file
  end
end
