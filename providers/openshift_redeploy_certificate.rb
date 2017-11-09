#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_redeploy_certificate
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_redeploy_certificate if defined? provides

def whyrun_supported?
  true
end

action :redeploy do
  execute 'Backup etcd stuff' do
    command "tar czvf etcd-backup-$(date +%s).tar.gz -C #{node['cookbook-openshift3']['etcd_conf_dir']}/ca #{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt /var/www/html/etcd --ignore-failed-read --remove-files || true"
    cwd node['cookbook-openshift3']['etcd_conf_dir']
    only_if "[ -a #{node['cookbook-openshift3']['etcd_conf_dir']} ]"
  end
  execute 'Delete etcd Peer/Server certs' do
    command "rm -rf peer* server* etcd-#{node['fqdn']}.tgz etcd-#{node['fqdn']}.tgz.enc || true"
    cwd node['cookbook-openshift3']['etcd_conf_dir']
    only_if "[ -a #{node['cookbook-openshift3']['etcd_conf_dir']} ]"
  end
  execute 'Backup master stuff' do
    command "tar czvf master-backup-$(date +%s).tar.gz #{node['cookbook-openshift3']['openshift_master_config_dir']} /var/www/html/master --ignore-failed-read && rm -rf /var/www/html/master"
    cwd node['cookbook-openshift3']['openshift_common_base_dir']
    only_if "[ -a #{node['cookbook-openshift3']['openshift_master_config_dir']} ]"
  end
  execute 'Backup node stuff' do
    command "tar czvf node-backup-$(date +%s).tar.gz #{node['cookbook-openshift3']['openshift_node_config_dir']} /var/www/html/node --ignore-failed-read --remove-files"
    cwd node['cookbook-openshift3']['openshift_common_base_dir']
    only_if "[ -a #{node['cookbook-openshift3']['openshift_node_config_dir']} ]"
  end
  execute 'Delete old certs' do
    command 'rm -f $(ls -I serviceaccounts\* -I registry\*)'
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    only_if "[ -a #{node['cookbook-openshift3']['openshift_master_config_dir']} ]"
  end
  execute 'Remove root kubeconfig' do
    command 'rm -f config'
    cwd '/root/.kube'
    only_if '[ -a /root/.kube ]'
  end
  execute 'Remove node certs' do
    command "rm -rf #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']}"
    cwd node['cookbook-openshift3']['openshift_master_config_dir']
    only_if "[ -a #{node['cookbook-openshift3']['openshift_node_generated_configs_dir']} ]"
  end
  include_recipe 'cookbook-openshift3::default'
  new_resource.updated_by_last_action(true)
end
