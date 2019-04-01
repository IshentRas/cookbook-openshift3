#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_router
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_deploy_router if defined? provides

def whyrun_supported?
  true
end

action :create do
  converge_by "Deploy Router on #{node['fqdn']}" do
    oc_client = node['cookbook-openshift3']['ose_major_version'].split('.')[1].to_i >= 10 ? node['cookbook-openshift3']['openshift_client_binary'] : node['cookbook-openshift3']['openshift_common_client_binary']
    if node['cookbook-openshift3']['ose_major_version'].split('.')[1].to_i < 10
      execute 'Annotate Hosted Router Project' do
        command "#{oc_client} annotate --overwrite namespace/${namespace_router} openshift.io/node-selector=${selector_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
        environment(
          'selector_router' => node['cookbook-openshift3']['openshift_hosted_router_selector'],
          'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
        )
        not_if "#{oc_client} get namespace/${namespace_router} --template '{{ .metadata.annotations }}' --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | fgrep -q openshift.io/node-selector:${selector_router}"
        only_if "#{oc_client} get namespace/${namespace_router} --no-headers --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
      end

      if node['cookbook-openshift3']['openshift_hosted_router_deploy_shards']
        node['cookbook-openshift3']['openshift_hosted_router_shard'].each do |shard|
          execute "Annotate Hosted Router Project for sharding[#{shard['service_account']}]" do
            command "#{oc_client} annotate --overwrite namespace/${namespace_router} openshift.io/node-selector=${selector_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
            environment(
              'selector_router' => shard['selector'],
              'namespace_router' => shard['namespace']
            )
            not_if "#{oc_client} get namespace/${namespace_router} --template '{{ .metadata.annotations }}' --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | fgrep -q openshift.io/node-selector:${selector_router}"
            only_if "#{oc_client} get namespace/${namespace_router} --no-headers --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
          end
        end
      end
    end

    execute 'Create Hosted Router Certificate' do
      command "#{oc_client} create secret generic router-certs --from-file tls.crt=${certfile} --from-file tls.key=${keyfile} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
      environment(
        'certfile' => node['cookbook-openshift3']['openshift_hosted_router_certfile'],
        'keyfile' => node['cookbook-openshift3']['openshift_hosted_router_keyfile'],
        'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
      )
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      only_if { ::File.file?(node['cookbook-openshift3']['openshift_hosted_router_certfile']) && ::File.file?(node['cookbook-openshift3']['openshift_hosted_router_keyfile']) }
      not_if "#{oc_client} get secret router-certs -n $namespace_router --no-headers --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
    end

    deploy_options = %w[--selector=${selector_router} -n ${namespace_router}] + Array(new_resource.deployer_options)
    execute 'Deploy Hosted Router' do
      command "#{oc_client} adm router #{deploy_options.join(' ')} --images=#{node['cookbook-openshift3']['openshift_docker_hosted_router_image']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} || true"
      environment(
        'selector_router' => node['cookbook-openshift3']['openshift_hosted_router_selector'],
        'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
      )
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      only_if "[[ `#{oc_client} get pod --selector=router=router -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | wc -l` -eq 0 ]]"
    end

    if node['cookbook-openshift3']['openshift_hosted_router_deploy_shards']
      node['cookbook-openshift3']['openshift_hosted_router_shard'].each do |shard|
        execute "Deploy Hosted Router for sharding[#{shard['service_account']}]" do
          command "#{oc_client} adm router router-#{shard['service_account']} --images=#{node['cookbook-openshift3']['openshift_docker_hosted_router_image']} --selector=${selector_router} --service-account=#{shard['service_account']} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} || true"
          environment(
            'selector_router' => shard['selector'],
            'namespace_router' => shard['namespace']
          )
          cwd node['cookbook-openshift3']['openshift_master_config_dir']
          only_if "[[ `#{oc_client} get pod --selector=router=router-#{shard['service_account']} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | wc -l` -eq 0 ]]"
        end
      end
    end

    execute 'Auto Scale Router based on label' do
      command "#{oc_client} scale dc/router --replicas=${replica_number} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
      environment(
        'replica_number' => Mixlib::ShellOut.new("#{oc_client} get node --no-headers --selector=#{node['cookbook-openshift3']['openshift_hosted_router_selector']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | wc -l").run_command.stdout.strip,
        'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
      )
      cwd node['cookbook-openshift3']['openshift_master_config_dir']
      not_if "[[ `#{oc_client} get pod --selector=router=router --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} --no-headers | wc -l` -eq ${replica_number} ]]"
    end

    if node['cookbook-openshift3']['openshift_hosted_router_deploy_shards']
      node['cookbook-openshift3']['openshift_hosted_router_shard'].each do |shard|
        execute "Auto Scale Router based on label for sharding[#{shard['service_account']}]" do
          command "#{oc_client} scale dc/router-#{shard['service_account']} --replicas=${replica_number} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
          environment(
            'replica_number' => Mixlib::ShellOut.new("#{oc_client} get node --no-headers --selector=#{shard['selector']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | wc -l").run_command.stdout.strip,
            'selector_router' => shard['selector'],
            'namespace_router' => shard['namespace']
          )
          cwd node['cookbook-openshift3']['openshift_master_config_dir']
          not_if "[[ `#{oc_client} get pod --selector=router=router-#{shard['service_account']} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} --no-headers | wc -l` -eq ${replica_number} ]]"
        end
      end
    end

    unless node['cookbook-openshift3']['openshift_hosted_deploy_env_router'].empty?
      node['cookbook-openshift3']['openshift_hosted_deploy_env_router'].each do |env|
        execute "Set ENV \"#{env.upcase}\" for Hosted Router" do
          command "#{oc_client} set env dc/router #{env} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
          environment(
            'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
          )
          cwd node['cookbook-openshift3']['openshift_master_config_dir']
          not_if "[[ `#{oc_client} env dc/router --list -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}` =~ \"#{env}\" ]]"
        end
      end
    end

    if node['cookbook-openshift3']['openshift_hosted_router_deploy_shards']
      node['cookbook-openshift3']['openshift_hosted_router_shard'].each do |shard|
        shard['env'].each do |env|
          execute "Set Sharding ENV #{env} for Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} set env dc/router-#{shard['service_account']} #{env} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
            environment(
              'selector_router' => shard['selector'],
              'namespace_router' => shard['namespace']
            )
            cwd node['cookbook-openshift3']['openshift_master_config_dir']
            not_if "[[ `#{oc_client} env dc/router-#{shard['service_account']} --list -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}` =~ \"#{env}\" ]]"
          end
        end
      end
    end

    if node['cookbook-openshift3']['openshift_hosted_deploy_custom_router'] && ::File.exist?(node['cookbook-openshift3']['openshift_hosted_deploy_custom_router_file'])
      execute 'Create ConfigMap of the customised Hosted Router' do
        command "#{oc_client} create configmap customrouter --from-file=haproxy-config.template=#{node['cookbook-openshift3']['openshift_hosted_deploy_custom_router_file']} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
        environment(
          'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
        )
        cwd node['cookbook-openshift3']['openshift_master_config_dir']
        not_if "#{oc_client} get configmap customrouter -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
      end

      execute 'Set ENV TEMPLATE_FILE for customised Hosted Router' do
        command "#{oc_client} set env dc/router TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
        environment(
          'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
        )
        cwd node['cookbook-openshift3']['openshift_master_config_dir']
        not_if "[[ `#{oc_client} env dc/router --list -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}` =~ \"TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template\" ]]"
      end

      execute 'Set Volume for customised Hosted Router' do
        command "#{oc_client} volume dc/router --add --name=#{node['cookbook-openshift3']['openshift_hosted_deploy_custom_name']} --mount-path=/var/lib/haproxy/conf/custom --type=configmap --configmap-name=customrouter -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
        environment(
          'namespace_router' => node['cookbook-openshift3']['openshift_hosted_router_namespace']
        )
        cwd node['cookbook-openshift3']['openshift_master_config_dir']
        not_if "#{oc_client} volume dc/router -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | grep /var/lib/haproxy/conf/custom"
      end

      if node['cookbook-openshift3']['openshift_hosted_router_deploy_shards']
        node['cookbook-openshift3']['openshift_hosted_router_shard'].each do |shard|
          next unless shard.key?('custom_router')
          execute "Create ConfigMap of the customised Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} create configmap customrouter --from-file=haproxy-config.template=${custom_router_file} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
            environment(
              'namespace_router' => shard['namespace'],
              'custom_router_file' => shard.key?('custom_router_file') ? shard['custom_router_file'] : node['cookbook-openshift3']['openshift_hosted_deploy_custom_router_file']
            )
            cwd node['cookbook-openshift3']['openshift_master_config_dir']
            not_if "#{oc_client} get configmap customrouter -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
          end

          execute "Set ENV TEMPLATE_FILE for customised Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} set env dc/router-#{shard['service_account']} TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
            environment(
              'namespace_router' => shard['namespace']
            )
            cwd node['cookbook-openshift3']['openshift_master_config_dir']
            not_if "[[ `#{oc_client} env dc/router-#{shard['service_account']} --list -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}` =~ \"TEMPLATE_FILE=/var/lib/haproxy/conf/custom/haproxy-config.template\" ]]"
          end

          execute "Set Volume for customised Hosted Router sharding[#{shard['service_account']}]" do
            command "#{oc_client} volume dc/router-#{shard['service_account']} --add --name=#{node['cookbook-openshift3']['openshift_hosted_deploy_custom_name']} --mount-path=/var/lib/haproxy/conf/custom --type=configmap --configmap-name=customrouter -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']}"
            environment(
              'namespace_router' => shard['namespace']
            )
            cwd node['cookbook-openshift3']['openshift_master_config_dir']
            not_if "#{oc_client} volume dc/router-#{shard['service_account']} -n ${namespace_router} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['cookbook-openshift3']['openshift_master_loopback_api_url']} | grep /var/lib/haproxy/conf/custom"
          end
        end
      end
    end
  end
end
