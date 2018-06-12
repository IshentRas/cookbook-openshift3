#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: master_config_post
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
master_servers = server_info.master_servers
node_servers = server_info.node_servers

service_accounts = node['is_apaas_openshift_cookbook']['openshift_common_service_accounts_additional'].any? ? node['is_apaas_openshift_cookbook']['openshift_common_service_accounts'] + node['is_apaas_openshift_cookbook']['openshift_common_service_accounts_additional'] : node['is_apaas_openshift_cookbook']['openshift_common_service_accounts']

execute 'Check Master API' do
  command "[[ $(curl --silent #{node['is_apaas_openshift_cookbook']['openshift_master_api_url']}/healthz/ready --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca.crt --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
  retries 120
  retry_delay 1
end

service_accounts.each do |serviceaccount|
  execute "Creation of namespace \"#{serviceaccount['namespace']}\"" do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} adm new-project ${namespace} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    environment(
      'namespace' => serviceaccount['namespace']
    )
    cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
    not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get project #{serviceaccount['namespace']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
  end

  execute "Creation service account: \"#{serviceaccount['name']}\" ; Namespace: \"#{serviceaccount['namespace']}\"" do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create sa ${serviceaccount} -n ${namespace} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    environment(
      'serviceaccount' => serviceaccount['name'],
      'namespace' => serviceaccount['namespace']
    )
    cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
    not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get sa #{serviceaccount['name']} -n #{serviceaccount['namespace']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
  end

  if node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']
    node['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'].each do |shard|
      execute "Add cluster-reader for router sharing service account: \"#{shard['service_account']}\"" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} adm policy add-cluster-role-to-user cluster-reader ${serviceaccount} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
        environment(
          'serviceaccount' => "system:serviceaccount:#{shard['namespace']}:#{shard['service_account']}"
        )
        cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
        not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get clusterrolebinding/cluster-readers -o yaml --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | grep ${serviceaccount}"
      end
    end
  end

  next unless serviceaccount.key?('scc')

  sccs = serviceaccount['scc'].is_a?(Array) ? serviceaccount['scc'] : serviceaccount['scc'].split(' ') # Backport old logic

  sccs.each do |scc|
    execute "Add SCC [#{scc}] to service account: \"#{serviceaccount['name']}\" ; Namespace: \"#{serviceaccount['namespace']}\"" do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} policy add-scc-to-user #{scc} -z #{serviceaccount['name']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n #{serviceaccount['namespace']}"
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get scc/#{scc} -n #{serviceaccount['namespace']} -o yaml --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | grep system:serviceaccount:#{serviceaccount['namespace']}:#{serviceaccount['name']}"
    end
  end
end

execute 'Import Openshift Hosted Examples' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create -f #{node['is_apaas_openshift_cookbook']['openshift_common_hosted_base']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift || #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} replace -f #{node['is_apaas_openshift_cookbook']['openshift_common_hosted_base']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  ignore_failure true
end

execute 'Import Openshift db templates' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/db-templates --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift || #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} replace -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/db-templates --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  only_if { node['is_apaas_openshift_cookbook']['deploy_example'] && node['is_apaas_openshift_cookbook']['deploy_example_db_templates'] }
  ignore_failure true
end

execute 'Import Openshift Examples Base image-streams' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/image-streams/#{node['is_apaas_openshift_cookbook']['openshift_base_images']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift || #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} replace -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/image-streams/#{node['is_apaas_openshift_cookbook']['openshift_base_images']} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  only_if { node['is_apaas_openshift_cookbook']['deploy_example'] && node['is_apaas_openshift_cookbook']['deploy_example_image-streams'] }
  ignore_failure true
end

execute 'Import Openshift Examples quickstart-templates' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/quickstart-templates --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  only_if { node['is_apaas_openshift_cookbook']['deploy_example'] && node['is_apaas_openshift_cookbook']['deploy_example_quickstart-templates'] }
  ignore_failure true
end

execute 'Import Openshift Examples xpaas-streams' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/xpaas-streams --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  only_if { node['is_apaas_openshift_cookbook']['deploy_example'] && node['is_apaas_openshift_cookbook']['deploy_example_xpaas-streams'] }
  ignore_failure true
end

execute 'Import Openshift Examples xpaas-templates' do
  command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} create -f #{node['is_apaas_openshift_cookbook']['openshift_common_examples_base']}/xpaas-templates --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
  cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
  only_if { node['is_apaas_openshift_cookbook']['deploy_example'] && node['is_apaas_openshift_cookbook']['deploy_example_xpaas-templates'] }
  ignore_failure true
end

openshift_create_pv 'Create Persistent Storage' do
  persistent_storage node['is_apaas_openshift_cookbook']['persistent_storage']
  not_if { node['is_apaas_openshift_cookbook']['persistent_storage'].empty? }
end

node_servers.reject { |h| h.key?('skip_run') }.each do |nodes|
  execute "Set schedulability for Master node : #{nodes['fqdn']}" do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} manage-node #{nodes['fqdn']} --schedulable=${schedulability} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    environment(
      'schedulability' => !nodes.key?(:schedulable) && master_servers.find { |server_node| server_node['fqdn'] == nodes['fqdn'] } ? 'False' : nodes['schedulable'].to_s
    )
    cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
    only_if do
      master_servers.find { |server_node| server_node['fqdn'] == nodes['fqdn'] } &&
        !Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get node | grep #{nodes['fqdn']}").run_command.error?
    end
  end

  execute "Set schedulability for node : #{nodes['fqdn']}" do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} manage-node #{nodes['fqdn']} --schedulable=${schedulability} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    environment(
      'schedulability' => !nodes.key?(:schedulable) && node_servers.find { |server_node| server_node['fqdn'] == nodes['fqdn'] } ? 'True' : nodes['schedulable'].to_s
    )
    cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
    not_if do
      master_servers.find { |server_node| server_node['fqdn'] == nodes['fqdn'] } ||
        Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get node | grep #{nodes['fqdn']}").run_command.error?
    end
  end

  execute "Set Labels for node : #{nodes['fqdn']}" do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} label node #{nodes['fqdn']} ${labels} --overwrite --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    environment(
      'labels' => nodes['labels'].to_s
    )
    cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
    only_if do
      nodes.key?('labels') &&
        !Mixlib::ShellOut.new("#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get node | grep #{nodes['fqdn']}").run_command.error?
    end
  end
end

openshift_deploy_router 'Deploy Router' do
  deployer_options node['is_apaas_openshift_cookbook']['openshift_hosted_router_options']
  only_if do
    node['is_apaas_openshift_cookbook']['openshift_hosted_manage_router']
  end
end

openshift_deploy_registry 'Deploy Registry' do
  persistent_registry node['is_apaas_openshift_cookbook']['registry_persistent_volume'].empty? ? false : true
  persistent_volume_claim_name "#{node['is_apaas_openshift_cookbook']['registry_persistent_volume']}-claim"
  only_if do
    node['is_apaas_openshift_cookbook']['openshift_hosted_manage_registry']
  end
end

openshift_deploy_metrics 'Remove Cluster Metrics' do
  action :delete
  only_if do
    node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics'] &&
      !node['is_apaas_openshift_cookbook']['openshift_metrics_install_metrics']
  end
end

openshift_deploy_metrics 'Deploy Cluster Metrics' do
  only_if do
    node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics'] &&
      node['is_apaas_openshift_cookbook']['openshift_metrics_install_metrics']
  end
end
