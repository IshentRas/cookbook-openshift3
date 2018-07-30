#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: oc_sa
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :oc_serviceaccount
property :service_accountname, String, required: true, name_property: true
property :namespace, String, required: true

action :create do
  execute "Create ServiceAccount [#{new_resource.service_accountname}]" do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create serviceaccount #{new_resource.service_accountname} -n #{new_resource.namespace} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get serviceaccount/#{new_resource.service_accountname} --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n #{new_resource.namespace}"
  end
end
