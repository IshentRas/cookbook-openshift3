#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: ng_etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers
docker_version = node['is_apaas_openshift_cookbook']['openshift_docker_etcd_version']
new_etcd_servers = server_info.new_etcd_servers
remove_etcd_servers = server_info.new_etcd_servers
certificate_server = server_info.certificate_server
is_etcd_server = server_info.on_etcd_server?
is_new_etcd_server = server_info.on_new_etcd_server?
is_master_server = server_info.on_master_server?
user_id =  node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod'] ? 'root' : 'etcd'
group_id = node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod'] ? 'root' : 'etcd'
etcd_ipaddress = etcd_servers.find { |etcd| etcd['fqdn'] == node['fqdn'] }['ipaddress']

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_etcd_server || is_new_etcd_server
  include_recipe 'is_apaas_openshift_cookbook::ng_etcd_packages' unless node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod']

  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_etcd'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  template '/etc/profile.d/etcdctl.sh' do
    source 'etcd/etcdctl.sh.erb'
    mode '0755'
    owner 'root'
    group 'root'
  end

  if is_master_server
    docker_image node['is_apaas_openshift_cookbook']['openshift_docker_etcd_image'] do
      tag docker_version
      action :pull_if_missing
      only_if { node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod'] }
    end

    %W(#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']} #{node['is_apaas_openshift_cookbook']['etcd_data_dir']}).each do |etcd_dir|
      directory etcd_dir do
        mode '0700'
      end
    end

    template '/etc/origin/node/pods/etcd.yaml' do
      source 'etcd/etcd.yaml.erb'
      variables(
        etcd_image: "#{node['is_apaas_openshift_cookbook']['openshift_docker_etcd_image']}:#{docker_version}",
        etcd_url: "#{etcd_ipaddress}:#{node['is_apaas_openshift_cookbook']['etcd_client_port']}"
      )
      mode '0600'
      owner user_id
      group group_id
      only_if { node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod'] }
    end
  end

  remote_file "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca.crt" do
    source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/ca.crt"
    retries 60
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
    owner user_id
    group group_id
    mode '0600'
  end

  %w(cert peer).each do |certificate_type|
    file node['is_apaas_openshift_cookbook']['etcd_' + certificate_type + '_file'.to_s] do
      owner user_id
      group group_id
      mode '0600'
    end

    file node['is_apaas_openshift_cookbook']['etcd_' + certificate_type + '_key'.to_s] do
      owner user_id
      group group_id
      mode '0600'
    end
  end

  directory node['is_apaas_openshift_cookbook']['etcd_conf_dir'] do
    owner user_id
    group group_id
    mode '0700'
  end

  template "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd.conf" do
    source 'etcd/etcd.conf.erb'
    notifies :restart, 'service[etcd]', :immediately unless (is_new_etcd_server || remove_etcd_servers.any?) || node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod']
    notifies :enable, 'service[etcd]', :immediately unless is_new_etcd_server || node['is_apaas_openshift_cookbook']['openshift_etcd_static_pod']
    variables(
      lazy do
        {
          etcd_servers: is_etcd_server ? etcd_servers : new_etcd_servers,
          initial_cluster_state: node['is_apaas_openshift_cookbook']['etcd_initial_cluster_state']
        }
      end
    )
  end
end
