#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: upgrade_control_plane38_part1
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# This must be run before any upgrade takes place.
# It creates the service signer certs (and any others) if they were not in
# existence previously.

server_info = OpenShiftHelper::NodeHelper.new(node)
first_etcd = server_info.first_etcd
is_master_server = server_info.on_master_server?
is_node_server = server_info.on_node_server?
is_first_master = server_info.on_first_master?

if is_first_master
  log 'Pre master upgrade - Upgrade all storage (3.8)' do
    level :info
  end

  execute 'Migrate storage post policy reconciliation Pre upgrade (3.8)' do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
             --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
             migrate storage --include=* --confirm"
  end

  execute 'Create key for upgrade all storage (3.8)' do
    command "ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 put /migration/37_38/storage ok"
  end
end

if is_master_server && !is_first_master
  execute 'Wait for First master to upgrade all storage (3.8)' do
    command "ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/37_38/storage -w simple | grep -w ok"
    retries 120
    retry_delay 5
  end
end

if is_master_server

  log 'Upgrade for MASTERS [STARTED] (3.8)' do
    level :info
  end

  openshift_master_pkg 'Upgrade Master to 3.8' do
    options '-x *atomic-openshift*3.9*'
    version '3.8.0-1.el7.git.0.dd1558c'
  end

  include_recipe 'is_apaas_openshift_cookbook::excluder' unless is_node_server

  log 'Restart Master services (3.8)' do
    level :info
    notifies :restart, 'service[atomic-openshift-master-api]', :immediately
    notifies :restart, 'service[atomic-openshift-master-controllers]', :immediately
  end

  log 'Upgrade for MASTERS [COMPLETED] (3.8)' do
    level :info
  end
end

if is_master_server && !is_first_master
  execute 'Wait for First master to reconcile all roles (3.8)' do
    command "[[ $(ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/storage -w simple | wc -l) -eq 0 ]]"
    retries 120
    retry_delay 5
  end
end

if is_master_server && is_first_master

  execute 'Wait for API to be ready (3.8)' do
    command "[[ $(curl --silent --tlsv1.2 --max-time 2 #{node['is_apaas_openshift_cookbook']['openshift_master_api_url']}/healthz/ready --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca.crt --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt) =~ \"ok\" ]]"
    retries 120
    retry_delay 1
  end

  log 'Reconcile Cluster Roles & Cluster Role Bindings [STARTED] (3.8)' do
    level :info
  end

  execute 'Reconcile Security Context Constraints (3.8)' do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
            --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
            policy reconcile-sccs --confirm --additive-only=true"
  end

  execute 'Migrate storage post policy reconciliation Post upgrade (3.8)' do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} \
            --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
            migrate storage --include=* --confirm --server #{node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']}"
  end

  execute 'Delete key for upgrade all storage (3.8)' do
    command "ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 del /migration/storage"
  end
end

if is_master_server
  log 'Cycle all controller services to force new leader election mode (3.8)' do
    level :info
    notifies :restart, 'service[atomic-openshift-master-controllers]', :immediately
  end

  log 'Reconcile Cluster Roles & Cluster Role Bindings [COMPLETED] (3.8)' do
    level :info
  end
end
