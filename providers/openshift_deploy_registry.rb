#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_registry
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_deploy_registry if defined? provides

def whyrun_supported?
  true
end

action :create do
  execute 'Annotate Hosted Registry Project' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} annotate --overwrite namespace/${namespace_registry} openshift.io/node-selector=${selector_registry}"
    environment(
      'selector_registry' => node['cookbook-openshift3']['openshift_hosted_registry_selector'],
      'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
    )
    not_if "oc get namespace/${namespace_registry} --template '{{ .metadata.annotations }}' | fgrep -q openshift.io/node-selector:${selector_registry}"
    only_if 'oc get namespace/${namespace_registry} --no-headers'
  end

  execute 'Deploy Hosted Registry' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} adm registry --selector=${selector_registry} -n ${namespace_registry} --config=admin.kubeconfig"
    environment(
      'selector_registry' => node['cookbook-openshift3']['openshift_hosted_registry_selector'],
      'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    only_if '[[ `oc get pod --selector=docker-registry=default --no-headers --config=admin.kubeconfig | wc -l` -eq 0 ]]'
  end

  execute 'Generate certificates for Hosted Registry' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} adm ca create-server-cert --signer-cert=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt --signer-key=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.key --signer-serial=#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.serial.txt --hostnames=\"$(#{node['cookbook-openshift3']['openshift_common_client_binary']} get service docker-registry -o jsonpath='{.spec.clusterIP}' --config=admin.kubeconfig -n #{node['cookbook-openshift3']['openshift_hosted_registry_namespace']}),docker-registry.#{node['cookbook-openshift3']['openshift_hosted_registry_namespace']}.svc.cluster.local,${docker_registry_route_hostname}\" --cert=#{node['cookbook-openshift3']['openshift_master_config_dir']}/registry.crt --key=#{node['cookbook-openshift3']['openshift_master_config_dir']}/registry.key --config=admin.kubeconfig"
    environment lazy {
      {
        'registry_svc_ip' => `#{node['cookbook-openshift3']['openshift_common_client_binary']} get service docker-registry -o jsonpath='{.spec.clusterIP}' --config=admin.kubeconfig -n #{node['cookbook-openshift3']['openshift_hosted_registry_namespace']}`,
        'docker_registry_route_hostname' => "docker-registry-#{node['cookbook-openshift3']['openshift_hosted_registry_namespace']}-#{node['cookbook-openshift3']['openshift_master_router_subdomain']}",
      }
    }
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    not_if "[[ -f #{node['cookbook-openshift3']['openshift_master_config_dir']}/registry.crt && -f #{node['cookbook-openshift3']['openshift_master_config_dir']}/registry.key ]]"
  end

  execute 'Create secret for certificates' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} secrets new registry-certificates #{node['cookbook-openshift3']['openshift_master_config_dir']}/registry.crt #{node['cookbook-openshift3']['openshift_master_config_dir']}/registry.key -n ${namespace_registry} --config=admin.kubeconfig"
    environment lazy {
      {
        'registry_svc_ip' => `#{node['cookbook-openshift3']['openshift_common_client_binary']} get service docker-registry -o jsonpath='{.spec.clusterIP}' --config=admin.kubeconfig -n #{node['cookbook-openshift3']['openshift_hosted_registry_namespace']}`,
        'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace'],
        'docker_registry_route_hostname' => "docker-registry-#{node['cookbook-openshift3']['openshift_hosted_registry_namespace']}-#{node['cookbook-openshift3']['openshift_master_router_subdomain']}",
      }
    }
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    only_if '[[ `oc get secret registry-certificates -n ${namespace_registry} --no-headers --config=admin.kubeconfig | wc -l` -eq 0 ]]'
  end

  %w(default registry).each do |service_account|
    execute "Add secret to registry's pod service accounts (#{service_account})" do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} secrets add ${sa} registry-certificates -n ${namespace_registry} --config=admin.kubeconfig"
      environment(
        'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace'],
        'sa' => service_account
      )
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      not_if '[[ `oc get -o template sa/${sa} --template={{.secrets}} -n ${namespace_registry} --config=admin.kubeconfig` =~ "registry-certificates" ]]'
    end
  end

  execute 'Attach registry-certificates secret volume' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} volume dc/docker-registry --add --type=secret --secret-name=registry-certificates -m /etc/secrets -n ${namespace_registry} --config=admin.kubeconfig"
    environment(
      'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    not_if '[[ `oc get dc/docker-registry -o jsonpath=\'{.spec.template.spec.volumes[*].secret.secretName}\' -n ${namespace_registry} --no-headers --config=admin.kubeconfig` =~ registry-certificate ]]'
  end

  execute 'Configure certificates in registry deplomentConfig' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} env dc/docker-registry REGISTRY_HTTP_TLS_CERTIFICATE=/etc/secrets/registry.crt REGISTRY_HTTP_TLS_KEY=/etc/secrets/registry.key -n ${namespace_registry} --config=admin.kubeconfig"
    environment(
      'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    not_if '[[ `oc env dc/docker-registry --list -n ${namespace_registry} --config=admin.kubeconfig` =~ "REGISTRY_HTTP_TLS_CERTIFICATE=/etc/secrets/registry.crt" && `oc env dc/docker-registry --list -n ${namespace_registry} --config=admin.kubeconfig` =~ "REGISTRY_HTTP_TLS_KEY=/etc/secrets/registry.key" ]]'
  end

  execute 'Update registry liveness probe from HTTP to HTTPS' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} patch dc/docker-registry -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"registry\",\"livenessProbe\":{\"httpGet\":{\"scheme\":\"HTTPS\"}}}]}}}}' -n ${namespace_registry} --config=admin.kubeconfig"
    environment(
      'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    not_if '[[ `oc get dc/docker-registry -o jsonpath=\'{.spec.template.spec.containers[*].livenessProbe.httpGet.scheme}\' -n ${namespace_registry} --no-headers --config=admin.kubeconfig` =~ "HTTPS" ]]'
  end

  execute 'Update registry readiness probe from HTTP to HTTPS' do
    command "#{node['cookbook-openshift3']['openshift_common_client_binary']} patch dc/docker-registry -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"registry\",\"readinessProbe\":{\"httpGet\":{\"scheme\":\"HTTPS\"}}}]}}}}' -n ${namespace_registry} --config=admin.kubeconfig"
    environment(
      'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
    )
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    not_if '[[ `oc get dc/docker-registry -o jsonpath=\'{.spec.template.spec.containers[*].readinessProbe.httpGet.scheme}\' -n ${namespace_registry} --no-headers --config=admin.kubeconfig` =~ "HTTPS" ]]'
  end

  if new_resource.persistent_registry
    execute 'Add volume to Hosted Registry' do
      command 'oc volume dc/docker-registry --add --overwrite -t persistentVolumeClaim --claim-name=${registry_claim} --name=registry-storage -n ${namespace_registry} --config=admin.kubeconfig'
      environment(
        'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace'],
        'registry_claim' => new_resource.persistent_volume_claim_name
      )
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      not_if '[[ `oc get -o template dc/docker-registry --template={{.spec.template.spec.volumes}} -n ${namespace_registry} --config=admin.kubeconfig` =~ "${registry_claim}" ]]'
    end
    execute 'Auto Scale Registry based on label' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} scale dc/docker-registry --replicas=${replica_number} -n ${namespace_registry} --config=admin.kubeconfig"
      environment(
        'replica_number' => Mixlib::ShellOut.new("oc get node --no-headers --selector=#{node['cookbook-openshift3']['openshift_hosted_registry_selector']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig | wc -l").run_command.stdout.strip,
        'namespace_registry' => node['cookbook-openshift3']['openshift_hosted_registry_namespace']
      )
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      not_if '[[ `oc get pod --selector=docker-registry=default --config=admin.kubeconfig --no-headers | wc -l` -eq ${replica_number} ]]'
    end
  end
  new_resource.updated_by_last_action(true)
end
