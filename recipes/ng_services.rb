#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: ng_services
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
helper = OpenShiftHelper::UtilHelper
etcd_servers = server_info.etcd_servers
master_servers = server_info.master_servers
certificate_server = server_info.certificate_server

service 'httpd'
service 'docker'
service 'NetworkManager'
service 'etcd'

service 'atomic-openshift-node' do
  retries 5
  retry_delay 5
end

execute 'Restart API' do
  command '/usr/local/bin/master-restart api'
  action :nothing
  only_if "[[ $(systemctl show -p SubState atomic-openshift-node | cut -d'=' -f2) == 'running' ]]"
end

execute 'Restart Controller' do
  command '/usr/local/bin/master-restart controllers'
  action :nothing
  only_if "[[ $(systemctl show -p SubState atomic-openshift-node | cut -d'=' -f2) == 'running' ]]"
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
