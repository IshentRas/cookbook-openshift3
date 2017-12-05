#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_create_pv
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_create_pv if defined? provides

def whyrun_supported?
  true
end

action :create do
  new_resource.persistent_storage.each do |pv|
    execute "Create Persistent Storage : #{pv['name']}" do
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      command "eval echo \'\{\"apiVersion\":\"v1\",\"kind\":\"PersistentVolume\",\"metadata\":\{\"name\":\"${name_pv}\"\},\"spec\":\{\"capacity\":\{\"storage\":\"${capacity_pv}\"\},\"accessModes\":[\"${access_modes_pv}\"],\"nfs\":\{\"path\":\"${path_pv}\",\"server\":\"${server_pv}\"\},\"persistentVolumeReclaimPolicy\":\"${volume_policy}\"\}\}\' | oc create -f - --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
      environment(
        'name_pv' => "#{pv['name']}-volume",
        'capacity_pv' => pv['capacity'],
        'access_modes_pv' => pv['access_modes'],
        'path_pv' => pv['path'],
        'server_pv' => pv['server'],
        'volume_policy' => pv.key?('policy') ? pv['policy'] : 'Retain'
      )
      not_if "[[ `oc get pv/${name_pv} --no-headers --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig | wc -l` -eq 1 ]]"
    end

    next unless pv.key?('claim')
    execute "Create Persistent Claim: #{pv['name']}" do
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      command "eval echo \'\{\"apiVersion\":\"v1\",\"kind\":\"PersistentVolumeClaim\",\"metadata\":\{\"name\":\"${name_pvc}\"\},\"spec\":\{\"resources\":\{\"requests\":\{\"storage\":\"${capacity_pvc}\"\}\},\"accessModes\":[\"${access_modes_pvc}\"]\}\}\' | oc create -f - --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n ${namespace}"
      environment(
        'name_pvc' => "#{pv['name']}-claim",
        'capacity_pvc' => pv['capacity'],
        'access_modes_pvc' => pv['access_modes'],
        'namespace' => pv['claim']['namespace']
      )
      not_if "[[ `oc get pvc/${name_pvc} --no-headers --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n ${namespace} | wc -l` -eq 1 ]]"
    end
  end
  new_resource.updated_by_last_action(true)
end
