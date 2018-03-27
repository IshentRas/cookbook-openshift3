#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers
certificate_server = server_info.certificate_server
etcd_remove_servers = node['is_apaas_openshift_cookbook']['etcd_remove_servers']
is_certificate_server = server_info.on_certificate_server?
is_etcd_server = server_info.on_etcd_server?

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_certificate_server
  package 'httpd' do
    notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
    notifies :enable, 'service[httpd]', :immediately
    retries 3
  end

  directory node['is_apaas_openshift_cookbook']['etcd_ca_dir'] do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
    recursive true
  end

  %w(certs crl fragments).each do |etcd_ca_sub_dir|
    directory "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/#{etcd_ca_sub_dir}" do
      owner 'root'
      group 'root'
      mode '0700'
      action :create
      recursive true
    end
  end

  template node['is_apaas_openshift_cookbook']['etcd_openssl_conf'] do
    source 'openssl.cnf.erb'
  end

  execute "ETCD Generate index.txt #{node['fqdn']}" do
    command 'touch index.txt'
    cwd node['is_apaas_openshift_cookbook']['etcd_ca_dir']
    creates "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/index.txt"
  end

  file "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/serial" do
    content '01'
    action :create_if_missing
  end

  execute "ETCD Generate CA certificate for #{node['fqdn']}" do
    command "openssl req -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -newkey rsa:4096 -keyout ca.key -new -out ca.crt -x509 -extensions etcd_v3_ca_self -batch -nodes -days #{node['is_apaas_openshift_cookbook']['etcd_default_days']} -subj /CN=etcd-signer@$(date +%s)"
    environment 'SAN' => ''
    cwd node['is_apaas_openshift_cookbook']['etcd_ca_dir']
    creates "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/ca.crt"
  end

  %W(/var/www/html/etcd #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']} #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd).each do |path|
    directory path do
      mode '0755'
      owner 'apache'
      group 'apache'
    end
  end

  template "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/.htaccess" do
    owner 'apache'
    group 'apache'
    source 'access-htaccess.erb'
    notifies :run, 'ruby_block[Modify the AllowOverride options]', :immediately
    notifies :restart, 'service[httpd]', :immediately
    variables(servers: etcd_servers)
  end

  %w(ca.crt ca.key).each do |etcd_export_certificate|
    remote_file "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd/#{etcd_export_certificate}" do
      source "file://#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/#{etcd_export_certificate}"
      mode '0644'
      sensitive true
    end
  end

  etcd_servers.each do |etcd_master|
    directory "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
    end

    %w(server peer).each do |etcd_certificates|
      execute "ETCD Create the #{etcd_certificates} csr for #{etcd_master['fqdn']}" do
        command "openssl req -new -keyout #{etcd_certificates}.key -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{etcd_certificates}.csr -reqexts #{node['is_apaas_openshift_cookbook']['etcd_req_ext']} -batch -nodes -subj /CN=#{etcd_master['fqdn']}"
        environment 'SAN' => "IP:#{etcd_master['ipaddress']}"
        cwd "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/#{etcd_certificates}.csr"
      end

      execute "ETCD Sign and create the #{etcd_certificates} crt for #{etcd_master['fqdn']}" do
        command "openssl ca -name #{node['is_apaas_openshift_cookbook']['etcd_ca_name']} -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{etcd_certificates}.crt -in #{etcd_certificates}.csr -extensions #{node['is_apaas_openshift_cookbook']["etcd_ca_exts_#{etcd_certificates}"]} -batch"
        environment 'SAN' => ''
        cwd "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/#{etcd_certificates}.crt"
      end
    end

    remote_file "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/ca.crt" do
      source "file://#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/ca.crt"
      sensitive true
    end

    execute "Create a tarball of the etcd certs for #{etcd_master['fqdn']}" do
      command "tar czvf #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -C #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']} . && chown apache: #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
      creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
    end

    execute 'Encrypt etcd certificate tgz files' do
      command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -out #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz.enc -k '#{encrypted_file_password}'  && chmod -R  0755 #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']} && chown -R apache: #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}"
    end
  end

  openshift_add_etcd 'Add additional etcd nodes to cluster' do
    etcd_servers etcd_servers
    only_if { node['is_apaas_openshift_cookbook']['etcd_add_additional_nodes'] }
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
    action :upgrade if node['is_apaas_openshift_cookbook']['upgrade']
    version node['is_apaas_openshift_cookbook']['etcd_version'] unless node['is_apaas_openshift_cookbook']['etcd_version'].nil?
    retries 3
    notifies :restart, 'service[etcd-service]', :immediately if node['is_apaas_openshift_cookbook']['upgrade'] && !etcd_servers.find { |etcd| etcd['fqdn'] == node['fqdn'] }.nil?
  end
end

if is_etcd_server
  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_etcd'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  if node['is_apaas_openshift_cookbook']['deploy_containerized']
    docker_image node['is_apaas_openshift_cookbook']['openshift_docker_etcd_image'] do
      action :pull_if_missing
    end

    template "/etc/systemd/system/#{node['is_apaas_openshift_cookbook']['etcd_service_name']}.service" do
      source 'service_etcd-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
      notifies :restart, 'service[etcd-service]', :immediately if node['is_apaas_openshift_cookbook']['upgrade']
    end

    ruby_block 'Mask ETCD service' do
      block do
        Mixlib::ShellOut.new('systemctl mask etcd').run_command
      end
      action :nothing
    end
  end

  remote_file "Retrieve certificate from ETCD Master[#{certificate_server['fqdn']}]" do
    path "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}.tgz.enc"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt etcd certificate tgz files]', :immediately
    notifies :run, 'execute[Extract certificate to ETCD folder]', :immediately
    retries 12
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

  %w(cert peer).each do |certificate_type|
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

  execute 'Fix ETCD directory permissions' do
    command "chmod 755 #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}"
    only_if "[[ $(stat -c %a #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}) -ne 755 ]]"
  end

  template "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd.conf" do
    source 'etcd.conf.erb'
    notifies :restart, 'service[etcd-service]', :immediately
    notifies :enable, 'service[etcd-service]', :immediately
    variables(
      lazy do
        {
          etcd_servers: etcd_servers,
          initial_cluster_state: etcd_servers.find { |etcd_node| etcd_node['fqdn'] == node['fqdn'] }.key?('new_node') ? 'existing' : node['is_apaas_openshift_cookbook']['etcd_initial_cluster_state']
        }
      end
    )
  end

  cookbook_file '/etc/profile.d/etcdctl.sh' do
    source 'etcdctl.sh'
    mode '0755'
  end
end
