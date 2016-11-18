#
# Cookbook Name:: cookbook-openshift3
# Recipe:: etcd_cluster
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

etcd_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{etcd_servers}")).sort! : node['cookbook-openshift3']['etcd_servers']
master_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{node['cookbook-openshift3']['master_servers']}")).sort! : node['cookbook-openshift3']['master_servers']

if etcd_servers.size.odd? && etcd_servers.size >= 1
  if etcd_servers.first['fqdn'] == node['fqdn']
    package 'httpd' do
      notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
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

    etcd_servers.each do |etcd_master|
      directory '/var/www/html/etcd' do
        mode '0755'
        owner 'apache'
        group 'apache'
      end
      directory '/var/www/html/etcd/generated_certs' do
        mode '0755'
        owner 'apache'
        group 'apache'
      end
      directory "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}" do
        mode '0755'
        owner 'apache'
        group 'apache'
        recursive true
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

      link "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}/ca.crt" do
        to "#{node['cookbook-openshift3']['etcd_ca_dir']}/ca.crt"
        link_type :hard
      end

      execute "Create a tarball of the etcd certs for #{etcd_master['fqdn']}" do
        command "tar czvf #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -C #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']} . && chown apache: #{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
        creates "#{node['cookbook-openshift3']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
      end
    end
  end
else
  Chef::Application.fatal!("ETCD Servers should has length of 2n + 1 and nor \"#{etcd_servers.length}\"")
end

node['cookbook-openshift3']['enabled_firewall_rules_etcd'].each do |rule|
  iptables_rule rule do
    action :enable
  end
end

package 'etcd'

remote_file "Retrieve certificate from ETCD Master[#{etcd_servers.first['fqdn']}]" do
  path "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz"
  source "http://#{master_servers.first['ipaddress']}:#{node['cookbook-openshift3']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}.tgz"
  action :create_if_missing
  notifies :run, 'execute[Extract certificate to ETCD folder]', :immediately
  retries 12
  retry_delay 5
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

execute 'Fix ETCD directiory permissions' do
  command "chmod 755 #{node['cookbook-openshift3']['etcd_conf_dir']}"
  only_if "[[ $(stat -c %a #{node['cookbook-openshift3']['etcd_conf_dir']}) -ne 755 ]]"
end

template "#{node['cookbook-openshift3']['etcd_conf_dir']}/etcd.conf" do
  source 'etcd.conf.erb'
  notifies :restart, 'service[etcd]', :immediately
  variables etcd_servers: etcd_servers
end

service 'etcd' do
  action [:start, :enable]
end
