#
# Cookbook Name:: cookbook-openshift3
# Recipe:: ng_master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
certificate_server = server_info.certificate_server
is_master_server = server_info.on_master_server?
is_first_master = server_info.on_first_master?
is_certificate_server = server_info.on_certificate_server?
docker_version = node['cookbook-openshift3']['openshift_docker_image_version']
service_accounts = node['cookbook-openshift3']['openshift_common_service_accounts_additional'].any? ? node['cookbook-openshift3']['openshift_common_service_accounts'] + node['cookbook-openshift3']['openshift_common_service_accounts_additional'] : node['cookbook-openshift3']['openshift_common_service_accounts']

if is_master_server
  node['cookbook-openshift3']['enabled_firewall_rules_master_cluster'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
    secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
    encrypted_file_password = data_bag_item(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
  else
    encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
  end

  file '/usr/local/etc/.firewall_master_additional.txt' do
    content node['cookbook-openshift3']['enabled_firewall_additional_rules_master'].join("\n")
    owner 'root'
    group 'root'
  end

  directory node['cookbook-openshift3']['openshift_master_config_dir'] do
    recursive true
    owner 'root'
    group 'root'
    mode '0700'
  end

  directory "#{node['cookbook-openshift3']['openshift_common_base_dir']}/service-catalog" do
    recursive true
    owner 'root'
    group 'root'
    mode '0755'
  end

  remote_file "Retrieve ETCD client certificate from Certificate Server[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/openshift-master-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt etcd certificates tgz files]', :immediately
    notifies :run, 'execute[Extract etcd certificates to Master folder]', :immediately
    retries 60
    retry_delay 5
    sensitive true
  end

  execute 'Un-encrypt etcd certificates tgz files' do
    command "openssl enc -d -aes-256-cbc -in openshift-master-#{node['fqdn']}.tgz.enc -out openshift-master-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end

  execute 'Extract etcd certificates to Master folder' do
    command "tar -xzf openshift-master-#{node['fqdn']}.tgz ./master.etcd-client.crt ./master.etcd-client.key"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end

  remote_file "Retrieve ETCD CA cert from Certificate Server[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/#{node['cookbook-openshift3']['master_etcd_cert_prefix']}ca.crt"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/ca.crt"
    owner 'root'
    group 'root'
    mode '0600'
    retries 60
    retry_delay 5
    sensitive true
    action :create_if_missing
  end

  remote_file "Retrieve master certificates from Certificate Server[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/master/generated_certs/openshift-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt master certificates master tgz files]', :immediately
    notifies :run, 'execute[Extract master certificates to Master folder]', :immediately
    retries 60
    retry_delay 5
    sensitive true
  end

  execute 'Un-encrypt master certificates master tgz files' do
    command "openssl enc -d -aes-256-cbc -in openshift-#{node['fqdn']}.tgz.enc -out openshift-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end

  execute 'Extract master certificates to Master folder' do
    command "tar -xzf openshift-#{node['fqdn']}.tgz"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    action :nothing
  end

  ruby_block 'Adjust permissions for certificate and key files on Master servers' do
    block do
      run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
      Dir.glob("#{node['cookbook-openshift3']['openshift_master_config_dir']}/*").grep(/\.(?:key)$/).uniq.each do |key|
        file = Chef::Resource::File.new(key, run_context)
        file.owner 'root'
        file.group 'root'
        file.mode '0600'
        file.run_action(:create)
      end

      Dir.glob("#{node['cookbook-openshift3']['openshift_master_config_dir']}/*").grep(/\.(?:crt|json)$/).uniq.each do |key|
        file = Chef::Resource::File.new(key, run_context)
        file.owner 'root'
        file.group 'root'
        file.mode '0640'
        file.run_action(:create)
      end
    end
  end

  remote_directory node['cookbook-openshift3']['openshift_common_examples_base'] do
    source "openshift_control_plane/examples/#{docker_version.split('.')[0..1].join('.')}"
    owner 'root'
    group 'root'
    action :create
    recursive true
    purge true
    only_if { node['cookbook-openshift3']['deploy_example'] }
  end

  remote_file '/etc/origin/node/node-config.yaml' do
    source 'file:///etc/origin/node/node-config.yaml'
    sensitive true
    action :create_if_missing
  end

  docker_image node['cookbook-openshift3']['openshift_docker_control-plane_image'] do
    tag docker_version
    action :pull_if_missing
  end

  remote_directory '/usr/local/bin' do
    source 'openshift_control_plane/docker'
    files_mode '0755'
    owner 'root'
    group 'root'
    action :create
  end

  directory node['cookbook-openshift3']['openshift_master_config_dir'] do
    recursive true
    owner 'root'
    group 'root'
    mode '0700'
  end

  directory '/usr/libexec/kubernetes/kubelet-plugins/volume/exec' do
    recursive true
    owner 'root'
    group 'root'
    mode '0755'
  end

  execute 'Create the policy file' do
    command "#{node['cookbook-openshift3']['openshift_client_binary']} adm create-bootstrap-policy-file --filename=#{node['cookbook-openshift3']['openshift_master_policy']}"
    creates node['cookbook-openshift3']['openshift_master_policy']
  end

  template node['cookbook-openshift3']['openshift_master_scheduler_conf'] do
    source 'openshift_control_plane/scheduler.json.erb'
  end

  template node['cookbook-openshift3']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']['filename'] do
    source 'htpasswd.erb'
    mode '600'
    only_if { node['cookbook-openshift3']['oauth_Identities'].include? 'HTPasswdPasswordIdentityProvider' }
  end

  template node['cookbook-openshift3']['openshift_master_session_secrets_file'] do
    source 'session-secrets.yaml.erb'
    variables(
      lazy do
        {
          secret_authentication: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip,
          secret_encryption: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip
        }
      end
    )
    action :create_if_missing
  end

  openshift_create_master 'Create master configuration file' do
    action :create_ng
    named_certificate node['cookbook-openshift3']['openshift_master_named_certificates']
    origins node['cookbook-openshift3']['erb_corsAllowedOrigins'].uniq
    master_file node['cookbook-openshift3']['openshift_master_config_file']
    openshift_service_type node['cookbook-openshift3']['openshift_service_type']
  end

  template '/etc/origin/master/master.env' do
    source 'openshift_control_plane/master.env.erb'
  end

  template '/etc/origin/node/pods/apiserver.yaml' do
    source 'openshift_control_plane/apiserver.yaml.erb'
    variables(
      api_image: "#{node['cookbook-openshift3']['openshift_docker_control-plane_image']}:#{docker_version}"
    )
    mode '0600'
    owner 'root'
    group 'root'
  end

  template '/etc/origin/node/pods/controller.yaml' do
    source 'openshift_control_plane/controller.yaml.erb'
    variables(
      controller_image: "#{node['cookbook-openshift3']['openshift_docker_control-plane_image']}:#{docker_version}"
    )
    mode '0600'
    owner 'root'
    group 'root'
  end

  %w[bootstrap.kubeconfig node.kubeconfig].each do |bootstrap|
    remote_file "/etc/origin/node/#{bootstrap}" do
      source 'file:///etc/origin/master/admin.kubeconfig'
      owner 'root'
      group 'root'
      mode '0600'
      sensitive true
      action :create
      notifies :enable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
      notifies :start, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately if bootstrap == 'node.kubeconfig'
    end
  end

  directory '/root/.kube' do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end

  execute 'Copy the OpenShift admin client config' do
    command "cp #{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig /root/.kube/config && chmod 700 /root/.kube/config"
    creates '/root/.kube/config'
  end

  ruby_block 'Update OpenShift admin client config' do
    block do
      require 'fileutils'
      FileUtils.cp("#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig", '/root/.kube/config')
    end
    not_if { FileUtils.compare_file("#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig", '/root/.kube/config') }
  end

  %w[api controllers etcd].each do |item|
    next if item == 'etcd' && !node['cookbook-openshift3']['openshift_etcd_static_pod']

    execute "Wait for control plane #{item} pod to appear" do
      command "#{node['cookbook-openshift3']['openshift_client_binary']} get pod ${pod} -n kube-system -o jsonpath=\"{range .status.conditions[*]}{@.type}={@.status};{end}\" | grep -w \"Ready=True\""
      environment(
        'pod' => "master-#{item}-#{node['fqdn'].downcase}"
      )
      retries 120
      retry_delay 1
    end
  end

  node['cookbook-openshift3']['openshift_core_api_list'].each do |api|
    execute "Wait for or APIs (#{api}) to become available" do
      command "#{node['cookbook-openshift3']['openshift_client_binary']} get --raw /apis/#{api}/v1"
      retries 60
      retry_delay 2
    end
  end

  ruby_block 'Remove oc cache to refresh a list of APIs' do
    block do
      helper.remove_dir('/root/.kube/cache')
    end
    only_if { File.directory?('/root/.kube/cache') }
  end
end

include_recipe 'cookbook-openshift3::ng_nodes_certificates' if is_certificate_server

if is_first_master
  service_accounts.each do |serviceaccount|
    execute "Creation of namespace \"#{serviceaccount['namespace']}\"" do
      command "#{node['cookbook-openshift3']['openshift_client_binary']} adm new-project ${namespace} ${selector} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
      environment(
        'namespace' => serviceaccount['namespace'],
        'selector' => serviceaccount.key?('selector') ? "--node-selector=#{serviceaccount['selector']}" : ''
      )
      not_if "#{node['cookbook-openshift3']['openshift_client_binary']} get project #{serviceaccount['namespace']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute "Creation service account: \"#{serviceaccount['name']}\" ; Namespace: \"#{serviceaccount['namespace']}\"" do
      command "#{node['cookbook-openshift3']['openshift_client_binary']} create sa ${serviceaccount} -n ${namespace} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
      environment(
        'serviceaccount' => serviceaccount['name'],
        'namespace' => serviceaccount['namespace']
      )
      not_if "#{node['cookbook-openshift3']['openshift_client_binary']} get sa #{serviceaccount['name']} -n #{serviceaccount['namespace']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    if node['cookbook-openshift3']['openshift_hosted_router_deploy_shards']
      node['cookbook-openshift3']['openshift_hosted_router_shard'].each do |shard|
        execute "Add cluster-reader for router sharing service account: \"#{shard['service_account']}\"" do
          command "#{node['cookbook-openshift3']['openshift_client_binary']} adm policy add-cluster-role-to-user cluster-reader ${serviceaccount} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
          environment(
            'serviceaccount' => "system:serviceaccount:#{shard['namespace']}:#{shard['service_account']}"
          )
          not_if "#{node['cookbook-openshift3']['openshift_client_binary']} get clusterrolebinding/cluster-readers -o yaml --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig | grep ${serviceaccount}"
        end
      end
    end

    next unless serviceaccount.key?('scc')

    sccs = serviceaccount['scc'].is_a?(Array) ? serviceaccount['scc'] : serviceaccount['scc'].split(' ') # Backport old logic

    sccs.each do |scc|
      execute "Add SCC [#{scc}] to service account: \"#{serviceaccount['name']}\" ; Namespace: \"#{serviceaccount['namespace']}\"" do
        command "#{node['cookbook-openshift3']['openshift_client_binary']} adm policy add-scc-to-user #{scc} -z #{serviceaccount['name']} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n #{serviceaccount['namespace']}"
        not_if "#{node['cookbook-openshift3']['openshift_client_binary']} get scc/#{scc} -n #{serviceaccount['namespace']} -o yaml --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig | grep system:serviceaccount:#{serviceaccount['namespace']}:#{serviceaccount['name']}"
      end
    end
  end

  openshift_create_node_config 'Setup the node group config maps' do
    action :create_node_groups
  end

  openshift_create_node_config 'Node config reconcilation' do
    action :create_sync
    only_if { helper.check_pod_not_ready?('openshift-node', 'component=network', 1) }
  end

  openshift_create_node_config 'Node config bootstrap auto approver' do
    action :create_bootstrap_controller
    only_if { helper.check_pod_not_ready?('openshift-infra', 'app=bootstrap-autoapprover', 1) }
  end

  openshift_create_node_config 'Node config SDN' do
    action :create_sdn
    only_if { helper.check_pod_not_ready?('openshift-sdn', 'component=network', 2) }
  end

  node['cookbook-openshift3']['image_streams'].each do |imagestream|
    execute "Import Openshift Examples Base image-streams #{imagestream.split('.')[0]}" do
      command "#{node['cookbook-openshift3']['openshift_client_binary']} apply -f #{node['cookbook-openshift3']['openshift_common_examples_base']}/image-streams/#{imagestream} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
      only_if { node['cookbook-openshift3']['deploy_example'] && node['cookbook-openshift3']['deploy_example_image-streams'] }
    end
  end

  execute 'Import Openshift db templates' do
    command "#{node['cookbook-openshift3']['openshift_client_binary']} apply -f #{node['cookbook-openshift3']['openshift_common_examples_base']}/db-templates --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
    only_if { node['cookbook-openshift3']['deploy_example'] && node['cookbook-openshift3']['deploy_example_db_templates'] }
  end

  execute 'Import Openshift Examples quickstart-templates' do
    command "#{node['cookbook-openshift3']['openshift_client_binary']} apply -f #{node['cookbook-openshift3']['openshift_common_examples_base']}/quickstart-templates --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
    only_if { node['cookbook-openshift3']['deploy_example'] && node['cookbook-openshift3']['deploy_example_quickstart-templates'] }
  end

  execute 'Import Openshift Examples xpaas-streams' do
    command "#{node['cookbook-openshift3']['openshift_client_binary']} apply -f #{node['cookbook-openshift3']['openshift_common_examples_base']}/xpaas-streams --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
    only_if { node['cookbook-openshift3']['deploy_example'] && node['cookbook-openshift3']['deploy_example_xpaas-streams'] }
  end

  execute 'Import Openshift Examples xpaas-templates' do
    command "#{node['cookbook-openshift3']['openshift_client_binary']} apply -f #{node['cookbook-openshift3']['openshift_common_examples_base']}/xpaas-templates --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n openshift"
    only_if { node['cookbook-openshift3']['deploy_example'] && node['cookbook-openshift3']['deploy_example_xpaas-templates'] }
  end

  openshift_deploy_router 'Deploy Router' do
    deployer_options node['cookbook-openshift3']['openshift_hosted_router_options']
    only_if do
      node['cookbook-openshift3']['openshift_hosted_manage_router']
    end
  end

  openshift_deploy_registry 'Deploy Registry' do
    persistent_registry node['cookbook-openshift3']['registry_persistent_volume'].empty? ? false : true
    persistent_volume_claim_name "#{node['cookbook-openshift3']['registry_persistent_volume']}-claim"
    only_if do
      node['cookbook-openshift3']['openshift_hosted_manage_registry']
    end
  end

  openshift_create_node_config 'Deploy Service Catalog' do
    action :create_kube_service_catalog
  end

  openshift_create_node_config 'Deploy Template Service Broker' do
    action :create_template_service_broker
    only_if { helper.check_pod_not_ready?('openshift-template-service-broker', 'apiserver=true', 1) }
  end

  include_recipe 'cookbook-openshift3::web_console'

  openshift_deploy_metrics 'Remove Cluster Metrics' do
    action :delete
    only_if do
      node['cookbook-openshift3']['openshift_hosted_cluster_metrics'] &&
        !node['cookbook-openshift3']['openshift_metrics_install_metrics']
    end
  end

  openshift_deploy_metrics 'Deploy Cluster Metrics' do
    only_if do
      node['cookbook-openshift3']['openshift_hosted_cluster_metrics'] &&
        node['cookbook-openshift3']['openshift_metrics_install_metrics']
    end
  end

  openshift_deploy_logging 'Remove Cluster Logging' do
    action :delete
    only_if do
      node['cookbook-openshift3']['openshift_hosted_cluster_logging'] &&
        !node['cookbook-openshift3']['openshift_logging_install_logging']
    end
  end

  openshift_deploy_logging 'Deploy Cluster Logging' do
    only_if do
      node['cookbook-openshift3']['openshift_hosted_cluster_logging'] &&
        node['cookbook-openshift3']['openshift_logging_install_logging']
    end
  end
end
