property :etcd_action, String
property :target_version, String
property :docker_version, String

provides :openshift_upgrade

action :create_backup do
  directory "#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/backup"

  execute "Generate etcd backup #{new_resource.etcd_action.upcase} upgrade" do
    command "etcdctl backup --data-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']} --backup-dir=#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/backup/#{new_resource.etcd_action}-upgrade#{new_resource.target_version}"
    not_if { ::File.directory?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}-#{new_resource.etcd_action}/backup/upgrade#{new_resource.target_version}") }
    notifies :run, 'execute[Copy etcd v3 data store]', :immediately
  end

  execute 'Copy etcd v3 data store' do
    command "cp -a #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/backup/#{new_resource.etcd_action}-upgrade#{new_resource.target_version}/member/snap/"
    only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['etcd_data_dir']}/member/snap/db") }
    action :nothing
  end
end

action :set_mark_upgrade do
  server_info = OpenShiftHelper::NodeHelper.new(node)
  first_etcd = server_info.first_etcd

  if new_resource.target_version.to_i < 37
    execute "Set upgrade markup for master : #{node['fqdn']}" do
      command "/usr/bin/etcdctl --cert-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 set /migration/#{new_resource.target_version}/#{node['fqdn']} ok"
    end
  else
    execute "Set upgrade markup for master : #{node['fqdn']}" do
      command "ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 put /migration/#{new_resource.target_version}/#{node['fqdn']} ok"
    end
  end
end

action :reconcile_cluster_roles do
  execute 'Wait for API to be ready' do
    command "[[ $(curl --silent #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}/healthz/ready --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca.crt --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
    retries 120
    retry_delay 1
  end

  case new_resource.target_version.to_i
  when 14
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
  when 15
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

    execute 'Upgrade job storage' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=jobs --confirm"
    end
  when 36
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

    execute 'Upgrade clusterpolicies storage Post upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=clusterpolicies --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
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
              migrate storage --include=${resources} --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
      environment 'resources' => node['is_apaas_openshift_cookbook']['customised_storage'] ? node['is_apaas_openshift_cookbook']['customised_resources'] : '*'
      not_if { node['is_apaas_openshift_cookbook']['skip_migration_storage'] }
    end
  when 37
    execute 'Remove shared-resource-viewer protection before upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              annotate role shared-resource-viewer openshift.io/reconcile-protect- -n openshift"
    end

    execute 'Upgrade clusterpolicies storage Post upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=clusterpolicies --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
    end

    execute 'Reconcile Security Context Constraints' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-sccs --confirm --additive-only=true"
    end

    execute 'Migrate storage post policy reconciliation Post upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=${resources} --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
      environment 'resources' => node['is_apaas_openshift_cookbook']['customised_storage'] ? node['is_apaas_openshift_cookbook']['customised_resources'] : '*'
      not_if { node['is_apaas_openshift_cookbook']['skip_migration_storage'] }
    end
  when 38
    execute 'Upgrade clusterpolicies storage Post upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=clusterpolicies --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
    end

    execute 'Reconcile Security Context Constraints (3.8)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-sccs --confirm --additive-only=true"
    end

    execute 'Migrate storage post policy reconciliation Post upgrade (3.8)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=${resources} --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
      environment 'resources' => node['is_apaas_openshift_cookbook']['customised_storage'] ? node['is_apaas_openshift_cookbook']['customised_resources'] : '*'
      not_if { node['is_apaas_openshift_cookbook']['skip_migration_storage'] }
    end
  when 39
    execute 'Upgrade clusterpolicies storage Post upgrade' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=clusterpolicies --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
    end

    execute 'Reconcile Security Context Constraints (3.9)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              policy reconcile-sccs --confirm --additive-only=true"
    end

    execute 'Migrate storage post policy reconciliation Post upgrade (3.9)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              migrate storage --include=${resources} --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
      environment 'resources' => node['is_apaas_openshift_cookbook']['customised_storage'] ? node['is_apaas_openshift_cookbook']['customised_resources'] : '*'
      not_if { node['is_apaas_openshift_cookbook']['skip_migration_storage'] }
    end
  end
end
