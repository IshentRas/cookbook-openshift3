#
# Cookbook Name:: cookbook-openshift3
# Recipe:: master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

master_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{node['cookbook-openshift3']['master_servers']}")).sort! : node['cookbook-openshift3']['master_servers']
etcd_servers = node['cookbook-openshift3']['use_params_roles'] && !Chef::Config[:solo] ? search(:node, %(role:"#{node['cookbook-openshift3']['etcd_servers']}")).sort! : node['cookbook-openshift3']['etcd_servers']

if node['cookbook-openshift3']['openshift_HA']
  case node['cookbook-openshift3']['openshift_HA_method']
  when 'native'
    if node['cookbook-openshift3']['openshift_cluster_name'].nil?
      Chef::Application.fatal!('A Cluster Name must be defined via \"openshift_cluster_name\"')
    end
  else
    if node['cookbook-openshift3']['openshift_cluster_name'].nil? && node['cookbook-openshift3']['openshift_master_cluster_vip'].nil?
      Chef::Application.fatal!('A Cluster Name and IP must be defined via \"openshift_cluster_name\" and \"openshift_master_cluster_vip\"')
    end
  end
end

if master_servers.find { |server_master| server_master['fqdn'] == node['fqdn'] }
  package node['cookbook-openshift3']['openshift_service_type'] do
    version node['cookbook-openshift3'] ['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
    not_if { node['cookbook-openshift3']['deploy_containerized'] }
  end

  package 'httpd' do
    notifies :run, 'ruby_block[Change HTTPD port xfer]', :immediately
    notifies :enable, 'service[httpd]', :immediately
  end

  node['cookbook-openshift3']['enabled_firewall_rules_master'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  directory node['cookbook-openshift3']['openshift_master_config_dir'] do
    recursive true
  end

  template node['cookbook-openshift3']['openshift_master_session_secrets_file'] do
    source 'session-secrets.yaml.erb'
    variables lazy {
      {
        secret_authentication: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip,
        secret_encryption: Mixlib::ShellOut.new('/usr/bin/openssl rand -base64 24').run_command.stdout.strip
      }
    }
    action :create_if_missing
  end

  remote_directory node['cookbook-openshift3']['openshift_common_examples_base'] do
    source 'openshift_examples/examples'
    owner 'root'
    group 'root'
    action :create
    recursive true
    only_if { node['cookbook-openshift3']['deploy_example'] }
  end

  if node['cookbook-openshift3']['openshift_HA']
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
    include_recipe 'cookbook-openshift3::master_cluster'
  else
    include_recipe 'cookbook-openshift3::master_standalone'
  end

  directory '/root/.kube' do
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end

  execute 'Copy the OpenShift admin client config' do
    command "cp #{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig /root/.kube/config && chmod 700 /root/.kube/config"
    creates '/root/.kube/config'
  end

  if master_servers.first['fqdn'] == node['fqdn']
    include_recipe 'cookbook-openshift3::nodes_certificates'
    include_recipe 'cookbook-openshift3::master_config_post'
  end
end

if etcd_servers.find { |server_etcd| server_etcd['fqdn'] == node['fqdn'] }
    include_recipe 'cookbook-openshift3::etcd_cluster'
end

