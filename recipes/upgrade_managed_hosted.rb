#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_managed_hosted
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

hosted_upgrade_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : 'v' + node['is_apaas_openshift_cookbook']['ose_version'].to_s.split('-')[0]

log 'Update hosted deployment(s) to current version [STARTED]' do
  level :info
end

template "#{Chef::Config[:file_cache_path]}/router-patch" do
  source 'patch-router.json.erb'
  variables(
    lazy do
      {
        router_image: Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get dc/router -n #{node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']} -o jsonpath='{.spec.template.spec.containers[0].image}' --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}").run_command.stdout.strip.gsub(/:v.+/, ":#{hosted_upgrade_version}")
      }
    end
  )
end

if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
  node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
    template "#{Chef::Config[:file_cache_path]}/router-patch-#{shard['service_account']}" do
      source 'patch-router.json.erb'
      variables(
        lazy do
          {
            router_image: Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get dc/router -n #{node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']} -o jsonpath='{.spec.template.spec.containers[0].image}' --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}").run_command.stdout.strip.gsub(/:v.+/, ":#{hosted_upgrade_version}")
          }
        end
      )
    end
  end
end

if node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router'] && ::File.exist?(node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file'])
  execute 'Update ConfigMap of the customised Hosted Router' do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create configmap customrouter --from-file=haproxy-config.template=#{node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file']} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']} --dry-run -o yaml | #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} replace -f - -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
    environment(
      'namespace_router' => node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']
    )
    cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  end

  if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
    node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
      execute "Update ConfigMap of the customised Hosted Router sharding[#{shard['service_account']}]" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create configmap customrouter --from-file=haproxy-config.template=${custom_router_file} -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']} --dry-run -o yaml | #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} replace -f - -n ${namespace_router} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
        environment(
          'namespace_router' => shard['namespace'],
          'custom_router_file' => shard.key?('custom_router_file') ? shard['custom_router_file'] : node['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file']
        )
        cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      end
    end
  end
end

execute "Update router image to current version \"#{hosted_upgrade_version}\"" do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} \
    --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
    patch dc/router -n #{node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']} -p \"$(cat #{Chef::Config[:file_cache_path]}/router-patch)\""
  only_if do
    node['is_apaas_openshift_cookbook']['openshift_hosted_manage_router']
  end
end

if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
  node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
    execute "Update router image to current version \"#{hosted_upgrade_version}\" for #{shard['service_account']}" do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} \
        --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
        patch dc/router-#{shard['service_account']} -n #{shard['namespace']} -p \"$(cat #{Chef::Config[:file_cache_path]}/router-patch-#{shard['service_account']})\""
      only_if do
        node['is_apaas_openshift_cookbook']['openshift_hosted_manage_router']
      end
    end
  end
end

template "#{Chef::Config[:file_cache_path]}/registry-patch" do
  source 'patch-registry.json.erb'
  variables(
    lazy do
      {
        registry_image: Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get dc/docker-registry -n #{node['is_apaas_openshift_cookbook']['openshift_hosted_registry_namespace']} -o jsonpath='{.spec.template.spec.containers[0].image}'").run_command.stdout.strip.gsub(/:v.+/, ":#{hosted_upgrade_version}")
      }
    end
  )
end

execute "Update registry image to current version \"#{hosted_upgrade_version}\"" do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} \
    --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
    patch dc/docker-registry -n #{node['is_apaas_openshift_cookbook']['openshift_hosted_registry_namespace']} -p \"$(cat #{Chef::Config[:file_cache_path]}/registry-patch)\""
  only_if do
    node['is_apaas_openshift_cookbook']['openshift_hosted_manage_registry']
  end
end

log 'Update hosted deployment(s) to current version [COMPLETED]' do
  level :info
end
