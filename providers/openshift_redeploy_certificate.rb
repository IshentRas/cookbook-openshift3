#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_redeploy_certificate
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_redeploy_certificate if defined? provides

def whyrun_supported?
  true
end

action :redeploy do
  converge_by 'Redeploy certificates' do
    execute 'Backup etcd stuff' do
      command "tar czvf etcd-backup-$(date +%s).tar.gz -C #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca.crt /var/www/html/etcd --ignore-failed-read --remove-files || true"
      cwd node['is_apaas_openshift_cookbook']['etcd_conf_dir']
      only_if "[ -a #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']} ]"
    end
    execute 'Delete etcd Peer/Server certs' do
      command "$ACTION peer* server* etcd-#{node['fqdn']}.tgz etcd-#{node['fqdn']}.tgz.enc || true"
      cwd node['is_apaas_openshift_cookbook']['etcd_conf_dir']
      only_if "[ -a #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']} ]"
      environment 'ACTION' => 'rm -rf'
    end
    execute 'Backup master stuff' do
      command "tar czvf master-backup-$(date +%s).tar.gz #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']} /var/www/html/master --ignore-failed-read && $ACTION /var/www/html/master"
      cwd node['is_apaas_openshift_cookbook']['openshift_common_base_dir']
      only_if "[ -a #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']} ]"
      environment 'ACTION' => 'rm -rf'
    end
    execute 'Backup node stuff' do
      command "tar czvf node-backup-$(date +%s).tar.gz #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']} /var/www/html/node --ignore-failed-read --remove-files"
      cwd node['is_apaas_openshift_cookbook']['openshift_common_base_dir']
      only_if "[ -a #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']} ]"
    end
    execute 'Delete old certs' do
      command '$ACTION $(ls -I serviceaccounts\* -I registry\*)'
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      only_if "[ -a #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']} ]"
      environment 'ACTION' => 'rm -rf'
    end
    execute 'Remove root kubeconfig' do
      command '$ACTION config'
      cwd '/root/.kube'
      only_if '[ -a /root/.kube ]'
      environment 'ACTION' => 'rm -rf'
    end
    execute 'Remove node certs' do
      command "$ACTION #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']}"
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      only_if "[ -a #{node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']} ]"
      environment 'ACTION' => 'rm -rf'
    end
    include_recipe 'is_apaas_openshift_cookbook::default'
  end
end
