#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
helper_certs = OpenShiftHelper::CertHelper.new
etcd_servers = server_info.etcd_servers
new_etcd_servers = server_info.new_etcd_servers
remove_etcd_servers = server_info.new_etcd_servers
certificate_server = server_info.certificate_server
is_etcd_server = server_info.on_etcd_server?
is_new_etcd_server = server_info.on_new_etcd_server?
is_master_server = server_info.on_master_server?
etcd_healthy = helper.checketcd_healthy?
docker_version = node['is_apaas_openshift_cookbook']['openshift_docker_etcd_version']

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_etcd_server || is_new_etcd_server
  include_recipe 'is_apaas_openshift_cookbook::etcd_packages'

  include_recipe 'is_apaas_openshift_cookbook::etcd_recovery' if ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_emergency'])
  include_recipe 'is_apaas_openshift_cookbook::etcd_recovery' if etcd_healthy && ::File.file?(node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_member'])

  file node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_emergency'] do
    action :delete
  end

  file node['is_apaas_openshift_cookbook']['adhoc_recovery_etcd_member'] do
    action :delete
  end

  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_etcd'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  if node['is_apaas_openshift_cookbook']['deploy_containerized']
    execute 'Pull ETCD Image' do
      command "docker pull #{node['is_apaas_openshift_cookbook']['openshift_docker_etcd_image']}:#{docker_version}"
    end

    template "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service" do
      source 'service_etcd-containerized.service.erb'
      variables(path_bin: node['is_apaas_openshift_cookbook']['openshift_docker_etcd_image'].include?('coreos') ? '/usr/local/bin/etcd' : '/usr/bin/etcd')
      notifies :run, 'execute[daemon-reload]', :immediately
      notifies :restart, 'service[etcd-service]', :immediately if node['is_apaas_openshift_cookbook']['upgrade']
    end

    service 'etcd' do
      action :mask
    end
  end

  if node['is_apaas_openshift_cookbook']['adhoc_redeploy_etcd_ca']
    Chef::Log.warn("The ETCD CA CERTS redeploy will be skipped for ETCD[#{node['fqdn']}]. Could not find the flag: #{node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag'])

    ruby_block "Redeploy ETCD CA certs for ETCD server: #{node['fqdn']}" do
      block do
        helper.remove_dir("#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca.crt")
        helper.remove_dir("#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz*")
      end
      only_if { ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']) }
    end
  end

  remote_file "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca.crt" do
    source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/ca.crt"
    retries ::Mixlib::ShellOut.new("systemctl is-enabled #{node['is_apaas_openshift_cookbook']['etcd_service_name']}").run_command.error? ? 180 : 60
    retry_delay 5
    sensitive true
    action :create_if_missing
  end

  remote_file "Retrieve ETCD certificates from Certificate Server[#{certificate_server['fqdn']}]" do
    path "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt etcd certificate tgz files]', :immediately
    notifies :run, 'execute[Extract certificate to ETCD folder]', :immediately
    retries 60
    retry_delay 5
  end

  execute 'Un-encrypt etcd certificate tgz files' do
    command "openssl enc -d -aes-256-cbc -in etcd-#{node['fqdn']}.tgz.enc -out etcd-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    cwd node['is_apaas_openshift_cookbook']['etcd_conf_dir']
    action :nothing
  end

  execute 'Extract certificate to ETCD folder' do
    command "tar xzf etcd-#{node['fqdn']}.tgz"
    cwd node['is_apaas_openshift_cookbook']['etcd_conf_dir']
    action :nothing
  end

  file node['is_apaas_openshift_cookbook']['etcd_ca_cert'] do
    owner 'etcd'
    group 'etcd'
    mode '0600'
  end

  %w[cert peer].each do |certificate_type|
    file node['is_apaas_openshift_cookbook']['etcd_' + certificate_type + '_file'.to_s] do
      owner 'etcd'
      group 'etcd'
      mode '0600'
    end

    file node['is_apaas_openshift_cookbook']['etcd_' + certificate_type + '_key'.to_s] do
      owner 'etcd'
      group 'etcd'
      mode '0600'
    end
  end

  directory node['is_apaas_openshift_cookbook']['etcd_conf_dir'] do
    owner 'etcd'
    group 'etcd'
    mode '0700'
  end

  template "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd.conf" do
    source 'etcd.conf.erb'
    notifies :restart, 'service[etcd-service]', :immediately unless is_new_etcd_server || remove_etcd_servers.any?
    notifies :enable, 'service[etcd-service]', :immediately unless is_new_etcd_server
    variables(
      lazy do
        {
          etcd_servers: is_etcd_server ? etcd_servers : new_etcd_servers,
          initial_cluster_state: node['is_apaas_openshift_cookbook']['etcd_initial_cluster_state']
        }
      end
    )
  end

  ruby_block 'Restart ETCD service if valid certificate (Upgrade ETCD CA)' do
    block do
    end
    notifies :restart, 'service[etcd-service]', :immediately if helper_certs.valid_certificate?(node['is_apaas_openshift_cookbook']['etcd_ca_cert'], node['is_apaas_openshift_cookbook']['etcd_cert_file'])
    notifies :delete, "file[#{node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']}]", :immediately unless is_master_server
    only_if { helper_certs.valid_certificate?(node['is_apaas_openshift_cookbook']['etcd_ca_cert'], node['is_apaas_openshift_cookbook']['etcd_cert_file']) && ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']) }
  end
end

include_recipe 'is_apaas_openshift_cookbook::etcd_scaleup' if is_new_etcd_server
