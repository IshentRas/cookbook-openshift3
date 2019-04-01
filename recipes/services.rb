#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: services
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
helper = OpenShiftHelper::UtilHelper
etcd_servers = server_info.etcd_servers
master_servers = server_info.master_servers
certificate_server = server_info.certificate_server

service 'atomic-openshift-master'

service 'atomic-openshift-master-api' do
  retries 5
  retry_delay 5
end

service 'atomic-openshift-master-controllers' do
  retries 5
  retry_delay 5
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'httpd' do
  retries 5
  retry_delay 5
end

service 'docker'

service 'NetworkManager'

service 'openvswitch'

service 'haproxy'

service 'Restart Master' do
  service_name 'atomic-openshift-master'
  action :nothing
  only_if 'systemctl is-active atomic-openshift-master'
end

service 'Restart API' do
  service_name 'atomic-openshift-master-api'
  action :nothing
  only_if 'systemctl is-active atomic-openshift-master-api'
end

service 'Restart Controller' do
  service_name 'atomic-openshift-master-controllers'
  action :nothing
  only_if 'systemctl is-active atomic-openshift-master-controllers'
end

service 'Restart Node' do
  service_name 'atomic-openshift-node'
  action :nothing
  only_if 'systemctl is-enabled atomic-openshift-node'
  retries 4
  retry_delay 5
end

service 'atomic-openshift-node' do
  action :nothing
end

if node['is_apaas_openshift_cookbook']['deploy_containerized']
  service 'etcd-service' do
    service_name 'etcd_container'
    action :nothing
  end
else
  service 'etcd-service' do
    service_name 'etcd'
    action :nothing
    retries 3
    retry_delay 90
  end
end

ruby_block 'Change HTTPD port xfer' do
  block do
    http_addresses = [etcd_servers, master_servers, [certificate_server]].each_with_object([]) do |candidate_servers, memo|
      this_server = candidate_servers.find { |server_candidate| server_candidate['fqdn'] == node['fqdn'] }
      memo << this_server['ipaddress'] if this_server
    end.sort.uniq

    openshift_settings = helper.new('/etc/httpd/conf/httpd.conf')
    openshift_settings.search_file_replace_line(
      /(^Listen.*?\n)+/m,
      http_addresses.map { |addr| "Listen #{addr}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}\n" }.join
    )
    openshift_settings.write_file
  end
  action :nothing
  notifies :restart, 'service[httpd]', :immediately
end

ruby_block 'Modify the AllowOverride options' do
  block do
    openshift_settings = helper.new('/etc/httpd/conf/httpd.conf')
    openshift_settings.search_file_replace_line(
      /AllowOverride None/,
      'AllowOverride All'
    )
    openshift_settings.write_file
  end
  action :nothing
  notifies :reload, 'service[httpd]', :immediately
end

file node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag'] do
  action :nothing
end
