#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_router
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_deploy_router if defined? provides

def whyrun_supported?
  true
end

action :create do
  execute 'Annotate Hosted Router Project' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} annotate --overwrite namespace/${namespace_router} openshift.io/node-selector=${selector_router}"
    environment(
      'selector_router' => node['cookbook-openshift3']['openshift_hosted_router_selector'],
      'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
    )
    not_if "oc get namespace/${namespace_router} --template '{{ .metadata.annotations }}' | fgrep -q openshift.io/node-selector:${selector_router}"
    only_if 'oc get namespace/${namespace_router} --no-headers'
  end

  execute 'Create Hosted Router Certificate' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} create secret generic router-certs --from-file tls.crt=${certfile} --from-file tls.key=${keyfile} -n ${namespace_router}"
    environment(
      'certfile' => node['cookbook-openshift3']['openshift_hosted_router_certfile'],
      'keyfile' => node['cookbook-openshift3']['openshift_hosted_router_keyfile'],
      'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    only_if { ::File.file?(node['cookbook-openshift3']['openshift_hosted_router_certfile']) && ::File.file?(node['cookbook-openshift3']['openshift_hosted_router_keyfile']) }
    not_if 'oc get secret router-certs -n $namespace_router --no-headers'
  end

  deploy_options = %w(--selector=${selector_router} -n ${namespace_router}) + Array(new_resource.deployer_options)
  execute 'Deploy Hosted Router' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} adm router #{deploy_options.join(' ')} --config=admin.kubeconfig || true"
    environment(
      'selector_router' => node['cookbook-openshift3']['openshift_hosted_router_selector'],
      'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    only_if '[[ `oc get pod --selector=router=router --config=admin.kubeconfig | wc -l` -eq 0 ]]'
  end

  execute 'Auto Scale Router based on label' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} scale dc/router --replicas=${replica_number} -n ${namespace_router} --config=admin.kubeconfig"
    environment(
      'replica_number' => Mixlib::ShellOut.new("oc get node --no-headers --selector=#{node['cookbook-openshift3']['openshift_hosted_router_selector']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig | wc -l").run_command.stdout.strip,
      'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    not_if '[[ `oc get pod --selector=router=router --config=admin.kubeconfig --no-headers | wc -l` -eq ${replica_number} ]]'
  end

  new_resource.updated_by_last_action(true)
end
