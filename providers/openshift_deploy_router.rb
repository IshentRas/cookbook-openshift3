#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_deploy_router
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_router if defined? provides

def whyrun_supported?
  true
end

action :create do
  converge_by "Deploy Router on #{node['fqdn']}" do
    oc_client = node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i >= 10 ? node['is_apaas_openshift_cookbook']['openshift_client_binary'] : node['is_apaas_openshift_cookbook']['openshift_common_client_binary']
    if node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i < 10
      execute 'Annotate Hosted Router Project' do
        command "#{oc_client} annotate --overwrite namespace/${namespace_router} openshift.io/node-selector=${selector_router}"
        environment(
          'selector_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector'],
          'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
        )
        not_if "#{oc_client} get namespace/${namespace_router} --template '{{ .metadata.annotations }}' | fgrep -q openshift.io/node-selector:${selector_router}"
        only_if "#{oc_client} get namespace/${namespace_router} --no-headers"
      end

      if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
        node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
          execute "Annotate Hosted Router Project for sharding[#{shard['service_account']}]" do
            command "#{oc_client} annotate --overwrite namespace/${namespace_router} openshift.io/node-selector=${selector_router}"
            environment(
              'selector_router' => shard['selector'],
              'namespace_router' => shard['namespace']
            )
            not_if "#{oc_client} get namespace/${namespace_router} --template '{{ .metadata.annotations }}' | fgrep -q openshift.io/node-selector:${selector_router}"
            only_if "#{oc_client} get namespace/${namespace_router} --no-headers"
          end
        end
      end
    end

    execute 'Create Hosted Router Certificate' do
      command "#{oc_client} create secret generic router-certs --from-file tls.crt=${certfile} --from-file tls.key=${keyfile} -n ${namespace_router}"
      environment(
        'certfile' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_certfile'],
        'keyfile' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_keyfile'],
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      only_if { ::File.file?(node['is_apaas_openshift_cookbook']['openshift_hosted_router_certfile']) && ::File.file?(node['is_apaas_openshift_cookbook']['openshift_hosted_router_keyfile']) }
      not_if "#{oc_client} get secret router-certs -n $namespace_router --no-headers"
    end

    deploy_options = %w[--selector=${selector_router} -n ${namespace_router}] + Array(new_resource.deployer_options)
    execute 'Deploy Hosted Router' do
      command "#{oc_client} adm router #{deploy_options.join(' ')} --images=#{node['is_apaas_openshift_cookbook']['openshift_docker_hosted_router_image']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig || true"
      environment(
        'selector_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector'],
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      only_if "[[ `#{oc_client} get pod --selector=router=router -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | wc -l` -eq 0 ]]"
    end

    if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
      node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
        execute "Deploy Hosted Router for sharding[#{shard['service_account']}]" do
          command "#{oc_client} adm router router-#{shard['service_account']} --images=#{node['is_apaas_openshift_cookbook']['openshift_docker_hosted_router_image']} --selector=${selector_router} --service-account=#{shard['service_account']} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig || true"
          environment(
            'selector_router' => shard['selector'],
            'namespace_router' => shard['namespace']
          )
          cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
          only_if "[[ `#{oc_client} get pod --selector=router=router-#{shard['service_account']} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | wc -l` -eq 0 ]]"
        end
      end
    end

    execute 'Auto Scale Router based on label' do
      command "#{oc_client} scale dc/router --replicas=${replica_number} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      environment(
        'replica_number' => Mixlib::ShellOut.new("#{oc_client} get node --no-headers --selector=#{node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | wc -l").run_command.stdout.strip,
        'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
      )
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      not_if "[[ `#{oc_client} get pod --selector=router=router --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --no-headers | wc -l` -eq ${replica_number} ]]"
    end

    if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
      node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
        execute "Auto Scale Router based on label for sharding[#{shard['service_account']}]" do
          command "#{oc_client} scale dc/router-#{shard['service_account']} --replicas=${replica_number} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
          environment(
            'replica_number' => Mixlib::ShellOut.new("#{oc_client} get node --no-headers --selector=#{shard['selector']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | wc -l").run_command.stdout.strip,
            'selector_router' => shard['selector'],
            'namespace_router' => shard['namespace']
          )
          cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
          not_if "[[ `#{oc_client} get pod --selector=router=router-#{shard['service_account']} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --no-headers | wc -l` -eq ${replica_number} ]]"
        end
      end
    end

    unless node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_env_router'].empty?
      node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_env_router'].each do |env|
        execute "Set ENV \"#{env.upcase}\" for Hosted Router" do
          command "#{oc_client} set env dc/router #{env} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
          environment(
            'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
          )
          cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
          not_if "[[ `#{oc_client} env dc/router --list -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig` =~ \"#{env}\" ]]"
        end
      end
    end

    if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
      node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
        shard['env'].each do |env|
          execute "Set Sharding ENV #{env} for Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} set env dc/router-#{shard['service_account']} #{env} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
            environment(
              'selector_router' => shard['selector'],
              'namespace_router' => shard['namespace']
            )
            cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
            not_if "[[ `#{oc_client} env dc/router-#{shard['service_account']} --list -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig` =~ \"#{env}\" ]]"
          end
        end
      end
    end

    if node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router'] && ::File.exist?(node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file'])
      execute 'Create ConfigMap of the customised Hosted Router' do
        command "#{oc_client} create configmap customrouter --from-file=haproxy-config.template=#{node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file']} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
        environment(
          'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
        )
        cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
        not_if "#{oc_client} get configmap customrouter -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      end

      execute 'Set ENV TEMPLATE_FILE for customised Hosted Router' do
        command "#{oc_client} set env dc/router TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
        environment(
          'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
        )
        cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
        not_if "[[ `#{oc_client} env dc/router --list -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig` =~ \"TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template\" ]]"
      end

      execute 'Set Volume for customised Hosted Router' do
        command "#{oc_client} volume dc/router --add --name=#{node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_name']} --mount-path=/var/lib/haproxy/conf/custom --type=configmap --configmap-name=customrouter -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
        environment(
          'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
        )
        cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
        not_if "#{oc_client} volume dc/router -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | grep /var/lib/haproxy/conf/custom"
      end

      if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
        node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
          execute "Create ConfigMap of the customised Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} create configmap customrouter --from-file=haproxy-config.template=${custom_router_file} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
            environment(
              'namespace_router' => shard['namespace'],
              'custom_router_file' => shard.key?('custom_router_file') ? shard['custom_router_file'] : node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file']
            )
            cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
            not_if "#{oc_client} get configmap customrouter -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
          end

          execute "Set ENV TEMPLATE_FILE for customised Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} set env dc/router-#{shard['service_account']} TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
            environment(
              'namespace_router' => shard['namespace']
            )
            cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
            not_if "[[ `#{oc_client} env dc/router-#{shard['service_account']} --list -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig` =~ \"TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template\" ]]"
          end

          execute "Set Volume for customised Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} volume dc/router-#{shard['service_account']} --add --name=#{node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_name']} --mount-path=/var/lib/haproxy/conf/custom --type=configmap --configmap-name=customrouter -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
            environment(
              'namespace_router' => shard['namespace']
            )
            cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
            not_if "#{oc_client} volume dc/router-#{shard['service_account']} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | grep /var/lib/haproxy/conf/custom"
          end
        end
      end
    end
  end
end
