#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: services
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

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

service 'httpd'

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
  only_if 'systemctl is-active atomic-openshift-node'
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
  end
end
