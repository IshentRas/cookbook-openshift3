#
# Cookbook Name:: cookbook-openshift3
# Recipe:: etcd_packages
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_master_server = server_info.on_master_server?
is_etcd_server = server_info.on_etcd_server?
is_new_etcd_server = server_info.on_new_etcd_server?
is_certificate_server = server_info.on_certificate_server?
etcd_servers = server_info.etcd_servers

if is_etcd_server || is_new_etcd_server
  yum_package 'Install ETCD for ETCD servers' do
    package_name 'etcd'
    action :install
    version node['cookbook-openshift3']['upgrade'] ? (node['cookbook-openshift3']['upgrade_etcd_version'] unless node['cookbook-openshift3']['upgrade_etcd_version'].nil?) : (node['cookbook-openshift3']['etcd_version'] unless node['cookbook-openshift3']['etcd_version'].nil?)
    retries 3
    notifies :restart, 'service[etcd-service]', :immediately if node['cookbook-openshift3']['upgrade'] && !etcd_servers.find { |etcd| etcd['fqdn'] == node['fqdn'] }.nil?
  end
end

if is_certificate_server || (is_master_server && !is_etcd_server)
  yum_package 'Install ETCD for certificate/master servers' do
    package_name 'etcd'
    version node['cookbook-openshift3']['upgrade'] ? (node['cookbook-openshift3']['upgrade_etcd_version'] unless node['cookbook-openshift3']['upgrade_etcd_version'].nil?) : (node['cookbook-openshift3']['etcd_version'] unless node['cookbook-openshift3']['etcd_version'].nil?)
  end
end

if is_certificate_server
  template '/usr/local/bin/etcdcheck' do
    source 'etcdctl.sh.erb'
    mode '0755'
    variables(
      etcd_endpoint: etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(','),
      etcd_crt: "#{node['cookbook-openshift3']['etcd_certificate_dir']}/peer.crt",
      etcd_key: "#{node['cookbook-openshift3']['etcd_certificate_dir']}/peer.key",
      etcd_ca: "#{node['cookbook-openshift3']['etcd_certificate_dir']}/ca.crt",
      ose_major_version: node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']
    )
  end
end

cookbook_file '/etc/profile.d/etcdctl.sh' do
  source 'etcdctl.sh'
  mode '0755'
end
