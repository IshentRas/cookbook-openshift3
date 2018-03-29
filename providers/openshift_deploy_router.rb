#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_deploy_router
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_deploy_router if defined? provides

def whyrun_supported?
  true
end

action :create do
  converge_by 'Deploy Router' do
    execute 'Annotate Hosted Router Project' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} annotate --overwrite namespace/${namespace_router} openshift.io/node-selector=${selector_router}"
      environment(
        'selector_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector'],
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get namespace/${namespace_router} --template '{{ .metadata.annotations }}' | fgrep -q openshift.io/node-selector:${selector_router}"
      only_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get namespace/${namespace_router} --no-headers"
    end

    execute 'Create Hosted Router Certificate' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create secret generic router-certs --from-file tls.crt=${certfile} --from-file tls.key=${keyfile} -n ${namespace_router}"
      environment(
        'certfile' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_certfile'],
        'keyfile' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_keyfile'],
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      only_if { ::File.file?(node['is_apaas_openshift_cookbook']['openshift_hosted_router_certfile']) && ::File.file?(node['is_apaas_openshift_cookbook']['openshift_hosted_router_keyfile']) }
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get secret router-certs -n $namespace_router --no-headers"
    end

    deploy_options = %w(--selector=${selector_router} -n ${namespace_router}) + Array(new_resource.deployer_options)
    execute 'Deploy Hosted Router' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} adm router #{deploy_options.join(' ')} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig || true"
      environment(
        'selector_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector'],
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      only_if "[[ `#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get pod --selector=router=router --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | wc -l` -eq 0 ]]"
    end

    execute 'Auto Scale Router based on label' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale dc/router --replicas=${replica_number} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      environment(
        'replica_number' => Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get node --no-headers --selector=#{node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | wc -l").run_command.stdout.strip,
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      not_if "[[ `#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get pod --selector=router=router --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --no-headers | wc -l` -eq ${replica_number} ]]"
    end
  end
end
