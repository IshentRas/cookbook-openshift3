#
# Cookbook Name:: cookbook-openshift3
# Recipe:: etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers
certificate_server = server_info.certificate_server
etcd_remove_servers = node['cookbook-openshift3']['etcd_remove_servers']
is_certificate_server = server_info.on_certificate_server?
is_etcd_server = server_info.on_etcd_server?

if node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'] && node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['cookbook-openshift3']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['cookbook-openshift3']['encrypted_file_password']['data_bag_name'], node['cookbook-openshift3']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['cookbook-openshift3']['encrypted_file_password']['default']
end

if is_certificate_server
  package 'httpd' do
    notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
    notifies :enable, 'service[httpd]', :immediately
    retries 3
  end

  directory node['cookbook-openshift3']['etcd_ca_dir'] do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
    recursive true
  end

  %w(certs crl fragments).each do |etcd_ca_sub_dir|
    directory "#{node['cookbook-openshift3']['etcd_ca_dir']}/#{etcd_ca_sub_dir}" do
      owner 'root'
      group 'root'
      mode '0700'
      action :create
      recursive true
    end
  end

  template node['cookbook-openshift3']['etcd_openssl_conf'] do
    source 'openssl.cnf.erb'
  end

  execute "ETCD Generate index.txt #{node['fqdn']}" do
    command 'touch index.txt'
    cwd node['cookbook-openshift3']['etcd_ca_dir']
    creates "#{node['cookbook-openshift3']['etcd_ca_dir']}/index.txt"
  end

  file "#{node['cookbook-openshift3']['etcd_ca_dir']}/serial" do
    content '01'
    action :create_if_missing
  end

  execute "ETCD Generate CA certificate for #{node['fqdn']}" do
    command "openssl req -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -newkey rsa:4096 -keyout ca.key -new -out ca.crt -x509 -extensions etcd_v3_ca_self -batch -nodes -days #{node['cookbook-openshift3']['etcd_default_days']} -subj /CN=etcd-signer@$(date +%s)"
    environment 'SAN' => ''
    cwd node['cookbook-openshift3']['etcd_ca_dir']
    creates "#{node['cookbook-openshift3']['etcd_ca_dir']}/ca.crt"
  end

  %W(/var/www/html/etcd #{node['cookbook-openshift3']['etcd_generated_certs_dir']} #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd).each do |path|
    directory path do
      mode '0755'
      owner 'apache'
      group 'apache'
    end
  end

  template "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/.htaccess" do
    owner 'apache'
    group 'apache'
    source 'access-htaccess.erb'
    notifies :run, 'ruby_block[Modify the AllowOverride options]', :immediately
    notifies :restart, 'service[httpd]', :immediately
    variables(servers: etcd_servers)
  end

  remote_file "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd/ca.crt" do
    source "file://#{node['cookbook-openshift3']['etcd_ca_dir']}/ca.crt"
    mode '0644'
    sensitive true
    action :create_if_missing
  end

  etcd_servers.each do |etcd_master|
    directory "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
    end

    %w(server peer).each do |etcd_certificates|
      execute "ETCD Create the #{etcd_certificates} csr for #{etcd_master['fqdn']}" do
        command "openssl req -new -keyout #{etcd_certificates}.key -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -out #{etcd_certificates}.csr -reqexts #{node['cookbook-openshift3']['etcd_req_ext']} -batch -nodes -subj /CN=#{etcd_master['fqdn']}"
        environment 'SAN' => "IP:#{etcd_master['ipaddress']}"
        cwd "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}"
        creates "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/#{etcd_certificates}.csr"
      end

      execute "ETCD Sign and create the #{etcd_certificates} crt for #{etcd_master['fqdn']}" do
        command "openssl ca -name #{node['cookbook-openshift3']['etcd_ca_name']} -config #{node['cookbook-openshift3']['etcd_openssl_conf']} -out #{etcd_certificates}.crt -in #{etcd_certificates}.csr -extensions #{node['cookbook-openshift3']["etcd_ca_exts_#{etcd_certificates}"]} -batch"
        environment 'SAN' => ''
        cwd "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}"
        creates "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/#{etcd_certificates}.crt"
      end
    end

    execute "Create a tarball of the etcd certs for #{etcd_master['fqdn']}" do
      command "tar czvf #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -C #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']} . && chown apache: #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
      creates "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
      notifies :run, 'execute[Encrypt etcd certificate tgz files]', :immediately
    end

    execute 'Encrypt etcd certificate tgz files' do
      command "openssl enc -aes-256-cbc -in #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -out #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz.enc -k '#{encrypted_file_password}'  && chmod -R  0755 #{node['cookbook-openshift3']['etcd_generated_certs_dir']} && chown -R apache: #{node['cookbook-openshift3']['etcd_generated_certs_dir']}"
      action :nothing
    end
  end

  openshift_add_etcd 'Add additional etcd nodes to cluster' do
    etcd_servers etcd_servers
    only_if { node['cookbook-openshift3']['etcd_add_additional_nodes'] }
  end

  openshift_add_etcd 'Remove additional etcd nodes to cluster' do
    etcd_servers etcd_servers
    etcd_servers_to_remove etcd_remove_servers
    not_if { etcd_remove_servers.empty? }
    action :remove_node
  end
end

if is_etcd_server || is_certificate_server
  yum_package 'etcd' do
    action :upgrade if node['cookbook-openshift3']['upgrade']
    version node['cookbook-openshift3']['etcd_version'] unless node['cookbook-openshift3']['etcd_version'].nil?
    retries 3
    notifies :restart, 'service[etcd-service]', :immediately if node['cookbook-openshift3']['upgrade'] && !etcd_servers.find { |etcd| etcd['fqdn'] == node['fqdn'] }.nil?
  end
end

if is_etcd_server
  node['cookbook-openshift3']['enabled_firewall_rules_etcd'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  if node['cookbook-openshift3']['deploy_containerized']
    docker_image node['cookbook-openshift3']['openshift_docker_etcd_image'] do
      action :pull_if_missing
    end

    template "/etc/systemd/system/#{node['cookbook-openshift3']['etcd_service_name']}.service" do
      source 'service_etcd-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
      notifies :restart, 'service[etcd-service]', :immediately if node['cookbook-openshift3']['upgrade']
    end

    systemd_unit 'etcd' do
      action :mask
    end
  end

  remote_file "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt" do
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/generated_certs/etcd/ca.crt"
    sensitive true
  end

  remote_file "Retrieve certificate from ETCD Master[#{certificate_server['fqdn']}]" do
    path "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt etcd certificate tgz files]', :immediately
    notifies :run, 'execute[Extract certificate to ETCD folder]', :immediately
    retries 12
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
    owner 'etcd'
    group 'etcd'
    mode '0600'
  end

  %w(cert peer).each do |certificate_type|
    file node['cookbook-openshift3']['etcd_' + certificate_type + '_file'.to_s] do
      owner 'etcd'
      group 'etcd'
      mode '0600'
    end

    file node['cookbook-openshift3']['etcd_' + certificate_type + '_key'.to_s] do
      owner 'etcd'
      group 'etcd'
      mode '0600'
    end
  end

  execute 'Fix ETCD directory permissions' do
    command "chmod 755 #{node['cookbook-openshift3']['etcd_conf_dir']}"
    only_if "[[ $(stat -c %a #{node['cookbook-openshift3']['etcd_conf_dir']}) -ne 755 ]]"
  end

  template "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf" do
    source 'etcd.conf.erb'
    notifies :restart, 'service[etcd-service]', :immediately
    notifies :enable, 'service[etcd-service]', :immediately
    variables(
      lazy do
        {
          etcd_servers: etcd_servers,
          initial_cluster_state: etcd_servers.find { |etcd_node| etcd_node['fqdn'] == node['fqdn'] }.key?('new_node') ? 'existing' : node['cookbook-openshift3']['etcd_initial_cluster_state']
        }
      end
    )
  end

  cookbook_file '/etc/profile.d/etcdctl.sh' do
    source 'etcdctl.sh'
    mode '0755'
  end
end
