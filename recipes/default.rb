#
# Cookbook Name:: cookbook-openshift3
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

service "#{node['cookbook-openshift3']['openshift_service_type']}-master"

service "#{node['cookbook-openshift3']['openshift_service_type']}-master-api" do
  retries 5
  retry_delay 5
end

service "#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers"

service 'daemon-reload'

service "#{node['cookbook-openshift3']['openshift_service_type']}-node" do
  retries 5
  retry_delay 5
end

service 'httpd' do
  action :enable
end

service 'etcd'

service 'docker'
