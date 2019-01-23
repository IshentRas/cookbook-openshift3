#
# Cookbook Name:: cookbook-openshift3
# Recipe:: ng_etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers
docker_version = node['cookbook-openshift3']['openshift_docker_etcd_version']
new_etcd_servers = server_info.new_etcd_servers
remove_etcd_servers = server_info.new_etcd_servers
certificate_server = server_info.certificate_server
is_etcd_server = server_info.on_etcd_server?
is_new_etcd_server = server_info.on_new_etcd_server?
is_master_server = server_info.on_master_server?
user_id =  node['cookbook-openshift3']['openshift_etcd_static_pod'] ? 'root' : 'etcd'
group_id = node['cookbook-openshift3']['openshift_etcd_static_pod'] ? 'root' : 'etcd'
etcd_ipaddress = etcd_servers.find { |etcd| etcd['fqdn'] == node['fqdn'] }['ipaddress']

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

if is_etcd_server || is_new_etcd_server
  include_recipe 'cookbook-openshift3::ng_etcd_packages' unless node['cookbook-openshift3']['openshift_etcd_static_pod']

  node['cookbook-openshift3']['enabled_firewall_rules_etcd'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  template '/etc/profile.d/etcdctl.sh' do
    source 'etcd/etcdctl.sh.erb'
    mode '0755'
    owner 'root'
    group 'root'
  end

  if is_master_server
    docker_image node['cookbook-openshift3']['openshift_docker_etcd_image'] do
      tag docker_version
      action :pull_if_missing
      only_if { node['cookbook-openshift3']['openshift_etcd_static_pod'] }
    end

    %W[#{node['cookbook-openshift3']['etcd_conf_dir']} #{node['cookbook-openshift3']['etcd_data_dir']}].each do |etcd_dir|
      directory etcd_dir do
        mode '0700'
      end
    end

    template '/etc/origin/node/pods/etcd.yaml' do
      source 'etcd/etcd.yaml.erb'
      variables(
        etcd_image: "#{node['cookbook-openshift3']['openshift_docker_etcd_image']}:#{docker_version}",
        etcd_url: "https://#{etcd_ipaddress}:#{node['cookbook-openshift3']['etcd_client_port']}"
      )
      mode '0600'
      owner user_id
      group group_id
      only_if { node['cookbook-openshift3']['openshift_etcd_static_pod'] }
    end
  end

  remote_file "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt" do
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/ca.crt"
    retries 60
    retry_delay 5
    sensitive true
    action :create_if_missing
  end

  remote_file "Retrieve ETCD certificates from Certificate Server[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt etcd certificate tgz files]', :immediately
    notifies :run, 'execute[Extract certificate to ETCD folder]', :immediately
    retries 60
    retry_delay 5
  end

  execute 'Un-encrypt etcd certificate tgz files' do
    command "openssl enc -d -aes-256-cbc -in etcd-#{node['fqdn']}.tgz.enc -out etcd-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    cwd node['cookbook-openshift3']['etcd_conf_dir']
    action :nothing
  end

  execute 'Extract certificate to ETCD folder' do
    command "tar xzf etcd-#{node['fqdn']}.tgz"
    cwd node['cookbook-openshift3']['etcd_conf_dir']
    action :nothing
  end

  file node['cookbook-openshift3']['etcd_ca_cert'] do
    owner user_id
    group group_id
    mode '0600'
  end

  %w[cert peer].each do |certificate_type|
    file node['cookbook-openshift3']['etcd_' + certificate_type + '_file'.to_s] do
      owner user_id
      group group_id
      mode '0600'
    end

    file node['cookbook-openshift3']['etcd_' + certificate_type + '_key'.to_s] do
      owner user_id
      group group_id
      mode '0600'
    end
  end

  directory node['cookbook-openshift3']['etcd_conf_dir'] do
    owner user_id
    group group_id
    mode '0700'
  end

  template "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf" do
    source 'etcd/etcd.conf.erb'
    notifies :restart, 'service[etcd]', :immediately unless (is_new_etcd_server || remove_etcd_servers.any?) || node['cookbook-openshift3']['openshift_etcd_static_pod']
    notifies :enable, 'service[etcd]', :immediately unless is_new_etcd_server || node['cookbook-openshift3']['openshift_etcd_static_pod']
    variables(
      lazy do
        {
          etcd_servers: is_etcd_server ? etcd_servers : new_etcd_servers,
          initial_cluster_state: node['cookbook-openshift3']['etcd_initial_cluster_state']
        }
      end
    )
  end
end
