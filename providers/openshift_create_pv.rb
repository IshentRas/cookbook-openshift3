#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_create_pv
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_create_pv if defined? provides

def whyrun_supported?
  true
end

action :create do
  converge_by 'Create PV' do
    directory "#{Chef::Config['file_cache_path']}/pv"

    template "#{Chef::Config[:file_cache_path]}/pv_template.yaml" do
      source 'pv_template.yaml.erb'
    end

    template "#{Chef::Config[:file_cache_path]}/pvc_template.yaml" do
      source 'pvc_template.yaml.erb'
    end

    new_resource.persistent_storage.each do |pv|
      ruby_block "Setup Persistent Storage : #{pv['name']}" do
        block do
          pv_template = YAML.load_file("#{Chef::Config[:file_cache_path]}/pv_template.yaml")
          pv_template['metadata']['name'] = "#{pv['name']}-volume"
          pv_template['spec']['capacity']['storage'] = pv['capacity']
          pv_template['spec']['accessModes'] = [pv['access_modes']]
          pv_template['spec']['nfs']['path'] = pv['path']
          pv_template['spec']['nfs']['server'] = pv['server']
          pv_template['spec']['persistentVolumeReclaimPolicy'] = pv.key?('policy') ? pv['policy'] : 'Retain'

          file "#{Chef::Config[:file_cache_path]}/pv/#{pv['name']}-volume.yaml" do
            content pv_template.to_yaml
          end
        end
      end

      next unless pv.key?('claim')

      ruby_block "Create Persistent Claim: #{pv['name']}-claim" do
        block do
          pvc_template = YAML.load_file("#{Chef::Config[:file_cache_path]}/pvc_template.yaml")
          pvc_template['metadata']['name'] = "#{pv['name']}-claim"
          pvc_template['metadata']['namespace'] = pv['claim']['namespace']
          pvc_template['spec']['accessModes'] = [pv['access_modes']]
          pvc_template['spec']['resources']['requests']['storage'] = pv['capacity']
          pvc_template['spec']['volumeName'] = "#{pv['name']}-volume"

          file "#{Chef::Config[:file_cache_path]}/pv/#{pv['name']}-claim.yaml" do
            content pvc_template.to_yaml
          end
        end
      end
    end

    execute 'Apply Persistent Storage' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} apply -f #{Chef::Config[:file_cache_path]}/pv --recursive"
    end
  end
end
