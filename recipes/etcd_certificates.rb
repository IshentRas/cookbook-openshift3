#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: etcd_certificates
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
etcd_servers = server_info.etcd_servers + server_info.new_etcd_servers
is_certificate_server = server_info.on_certificate_server?

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_certificate_server
  directory node['is_apaas_openshift_cookbook']['etcd_ca_dir'] do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
    recursive true
  end

  directory node['is_apaas_openshift_cookbook']['etcd_certificate_dir'] do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end

  %w[certs crl fragments].each do |etcd_ca_sub_dir|
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

  file 'Initialise ETCD CA Serial' do
    path "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/serial"
    content '01'
    not_if { ::File.exist?("#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/serial") }
  end

  execute "ETCD Generate CA certificate for #{node['fqdn']}" do
    command "openssl req -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -newkey rsa:4096 -keyout ca.key -new -out ca.crt -x509 -extensions etcd_v3_ca_self -batch -nodes -days #{node['is_apaas_openshift_cookbook']['etcd_default_days']} -subj /CN=etcd-signer@$(date +%s)"
    environment 'SAN' => ''
    cwd node['is_apaas_openshift_cookbook']['etcd_ca_dir']
    creates "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/ca.crt"
  end

  %W[/var/www/html/etcd #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}].each do |path|
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
    variables(servers: etcd_servers)
  end

  remote_file '/var/www/html/etcd/ca.crt' do
    owner 'apache'
    group 'apache'
    source "file://#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/ca.crt"
    mode '0644'
    sensitive true
  end

  etcd_servers.each do |etcd_master|
    directory "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
    end

    %w[server peer].each do |etcd_certificates|
      execute "ETCD Create the #{etcd_certificates} csr for #{etcd_master['fqdn']}" do
        command "openssl req -new -keyout #{etcd_certificates}.key -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{etcd_certificates}.csr -reqexts #{node['is_apaas_openshift_cookbook']['etcd_req_ext']} -batch -nodes -subj /CN=#{etcd_master['fqdn']}"
        environment 'SAN' => "IP:#{etcd_master['ipaddress']}, DNS:#{etcd_master['fqdn']}"
        cwd "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/#{etcd_certificates}.csr"
      end

      execute "ETCD Sign and create the #{etcd_certificates} crt for #{etcd_master['fqdn']}" do
        command "openssl ca -name #{node['is_apaas_openshift_cookbook']['etcd_ca_name']} -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{etcd_certificates}.crt -in #{etcd_certificates}.csr -extensions #{node['is_apaas_openshift_cookbook']["etcd_ca_exts_#{etcd_certificates}"]} -batch"
        environment 'SAN' => "IP:#{etcd_master['ipaddress']}"
        cwd "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/#{etcd_certificates}.crt"
      end
    end

    execute "Create a tarball of the etcd certs for #{etcd_master['fqdn']}" do
      command "tar --mode='0644' --owner=root --group=root -czvf #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -C #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']} . && chown apache:apache #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
      creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
    end

    execute "Encrypt etcd certificate tgz files for #{etcd_master['fqdn']}" do
      command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -out #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chown -R apache:apache #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz.enc"
      creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz.enc"
    end
  end

  remote_file "#{node['is_apaas_openshift_cookbook']['etcd_certificate_dir']}/ca.crt" do
    owner 'root'
    group 'root'
    source "file://#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/ca.crt"
    mode '0644'
    sensitive true
  end

  remote_file "#{node['is_apaas_openshift_cookbook']['etcd_certificate_dir']}/peer.key" do
    owner 'root'
    group 'root'
    source "file://#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_servers.first['fqdn']}/peer.key"
    mode '0644'
    sensitive true
  end

  remote_file "#{node['is_apaas_openshift_cookbook']['etcd_certificate_dir']}/peer.crt" do
    owner 'root'
    group 'root'
    source "file://#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_servers.first['fqdn']}/peer.crt"
    mode '0644'
    sensitive true
  end
end
