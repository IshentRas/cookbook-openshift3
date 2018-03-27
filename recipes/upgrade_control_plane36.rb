#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_control_plane36
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

Chef::Log.error("Upgrade will be skipped. Could not find the flag: #{node['is_apaas_openshift_cookbook']['control_upgrade_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])

if ::File.file?(node['is_apaas_openshift_cookbook']['control_upgrade_flag'])

  node.force_override['is_apaas_openshift_cookbook']['upgrade'] = true
  node.force_override['is_apaas_openshift_cookbook']['ose_major_version'] = node['is_apaas_openshift_cookbook']['upgrade_ose_major_version']
  node.force_override['is_apaas_openshift_cookbook']['ose_version'] = node['is_apaas_openshift_cookbook']['upgrade_ose_version']
  node.force_override['is_apaas_openshift_cookbook']['openshift_docker_image_version'] = node['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version']
  node.force_override['yum']['main']['exclude'] = 'docker-1.13*'

  server_info = OpenShiftHelper::NodeHelper.new(node)
  first_etcd = server_info.first_etcd
  is_etcd_server = server_info.on_etcd_server?
  is_master_server = server_info.on_master_server?
  is_node_server = server_info.on_node_server?
  is_first_master = server_info.on_first_master?

  if defined? node['is_apaas_openshift_cookbook']['upgrade_repos']
    node.force_override['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['upgrade_repos']
  end

  if is_master_server
    return unless ::Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 ls /migration/#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}/#{node['fqdn']}").run_command.error?
  end

  include_recipe 'yum::default'

  if is_master_server || is_node_server
    %w(excluder docker-excluder).each do |pkg|
      execute "Disable atomic-openshift-#{pkg}" do
        command "atomic-openshift-#{pkg} enable"
      end
    end
  end

  if is_etcd_server
    log 'Upgrade for ETCD [STARTED]' do
      level :info
    end

    execute 'Generate etcd backup before upgrade' do
      command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade36"
      not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade36") }
      notifies :run, 'execute[Copy etcd v3 data store (PRE)]', :immediately
    end

    execute 'Copy etcd v3 data store (PRE)' do
      command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-pre-upgrade36/member/snap/"
      only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
      action :nothing
    end

    include_recipe 'is_apaas_openshift_cookbook'
    include_recipe 'is_apaas_openshift_cookbook::common'
    include_recipe 'is_apaas_openshift_cookbook::etcd_cluster'

    execute 'Generate etcd backup after upgrade' do
      command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade36"
      not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade36") }
      notifies :run, 'execute[Copy etcd v3 data store (POST)]', :immediately
    end

    execute 'Copy etcd v3 data store (POST)' do
      command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-post-upgrade36/member/snap/"
      only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
      action :nothing
    end

    log 'Upgrade for ETCD [COMPLETED]' do
      level :info
    end
  end

  if is_master_server
    log 'Upgrade for MASTERS [STARTED]' do
      level :info
    end

    config_options = YAML.load_file("#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master/master-config.yaml")
    node.force_override['is_apaas_openshift_cookbook']['etcd_migrated'] = false unless config_options['kubernetesMasterConfig']['apiServerArguments'].key?('storage-backend')

    include_recipe 'is_apaas_openshift_cookbook::certificate_server' if node['is_apaas_openshift_cookbook']['deploy_containerized']

    if node['is_apaas_openshift_cookbook']['openshift_HA']
      include_recipe 'is_apaas_openshift_cookbook::master_cluster'
    else
      include_recipe 'is_apaas_openshift_cookbook::master_standalone'
    end

    include_recipe 'is_apaas_openshift_cookbook::node' if is_node_server

    include_recipe 'is_apaas_openshift_cookbook::excluder'

    log 'Restart Master & Node services' do
      level :info
      notifies :restart, 'service[atomic-openshift-master]', :immediately unless node['is_apaas_openshift_cookbook']['openshift_HA']
      notifies :restart, 'service[atomic-openshift-master-api]', :immediately if node['is_apaas_openshift_cookbook']['openshift_HA']
      notifies :restart, 'service[atomic-openshift-master-controllers]', :immediately if node['is_apaas_openshift_cookbook']['openshift_HA']
      notifies :restart, 'service[atomic-openshift-node]', :immediately if is_node_server
      notifies :restart, 'service[openvswitch]', :immediately if is_node_server
    end

    execute "Set upgrade markup for master : #{node['fqdn']}" do
      command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 set /migration/#{node['is_apaas_openshift_cookbook']['control_upgrade_version']}/#{node['fqdn']} ok"
    end

    log 'Upgrade for MASTERS [COMPLETED]' do
      level :info
    end
  end

  if is_master_server && is_first_master
    log 'Reconcile Cluster Roles & Cluster Role Bindings [STARTED]' do
      level :info
    end

    execute 'Wait for API to be ready' do
      command "[[ $(curl --silent #{node['is_apaas_openshift_cookbook']['openshift_master_api_url']}/healthz/ready --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca.crt --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
      retries 120
      retry_delay 1
    end

    execute 'Reconcile Cluster Roles' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-cluster-roles --additive-only=true --confirm"
    end

    execute 'Reconcile Cluster Role Bindings' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-cluster-role-bindings \
              --exclude-groups=system:authenticated \
              --exclude-groups=system:authenticated:oauth \
              --exclude-groups=system:unauthenticated \
              --exclude-users=system:anonymous \
              --additive-only=true --confirm"
    end

    execute 'Reconcile Jenkins Pipeline Role Bindings' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-cluster-role-bindings system:build-strategy-jenkinspipeline --confirm"
    end

    execute 'Reconcile Security Context Constraints' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-sccs --confirm --additive-only=true"
    end

    execute 'Remove shared-resource-viewer protection before upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              annotate role shared-resource-viewer openshift.io/reconcile-protect- -n openshift"
    end

    execute 'Migrate storage post policy reconciliation' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=* --confirm"
    end

    log 'Reconcile Cluster Roles & Cluster Role Bindings [COMPLETED]' do
      level :info
    end

    include_recipe 'is_apaas_openshift_cookbook::upgrade_managed_hosted'
  end
end
