#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: adhoc_redeploy_etcd_certs
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

Chef::Log.error("The ETCD CERTS redeploy will be skipped. Could not find the flag: #{node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag'])

if ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag'])

  if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
    secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
    encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
  else
    encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
  end

  server_info = OpenShiftHelper::NodeHelper.new(node)
  helper = OpenShiftHelper::NodeHelper.new(node)
  certificate_server = server_info.certificate_server
  etcd_servers = server_info.etcd_servers
  master_servers = server_info.master_servers
  is_certificate_server = server_info.on_certificate_server?
  is_etcd_server = server_info.on_etcd_server?
  is_master_server = server_info.on_master_server?

  if is_certificate_server
    etcd_servers.each do |etcd_master|
      ruby_block "Remove old certs for #{etcd_master['fqdn']}" do
        block do
          helper.remove_dir("#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}*")
        end
      end

      directory "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}" do
        mode '0755'
        owner 'apache'
        group 'apache'
      end

      %w[server peer].each do |etcd_certificates|
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

      execute "Create a tarball of the etcd certs for #{etcd_master['fqdn']}" do
        command "tar czvf #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -C #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']} . && chown apache: #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz"
      end

      execute 'Encrypt etcd certificate tgz files' do
        command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}.tgz -out #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}-new.tgz.enc -k '#{encrypted_file_password}'  && chmod -R  0755 #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']} && chown -R apache: #{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}"
        creates "#{node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']}/etcd-#{etcd_master['fqdn']}-new.tgz.enc"
      end
    end

    master_servers.each do |master_server|
      ruby_block "Remove old certs for #{master_server['fqdn']}" do
        block do
          helper.remove_dir("#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}*")
        end
      end

      directory "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}" do
        mode '0755'
        owner 'apache'
        group 'apache'
      end

      execute "ETCD Create the CLIENT csr for #{master_server['fqdn']}" do
        command "openssl req -new -keyout #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.key -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.csr -reqexts #{node['is_apaas_openshift_cookbook']['etcd_req_ext']} -batch -nodes -subj /CN=#{master_server['fqdn']}"
        environment 'SAN' => "IP:#{master_server['ipaddress']}"
        cwd "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.csr"
      end

      execute "ETCD Create the CLIENT csr for #{master_server['fqdn']}" do
        command "openssl req -new -keyout #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.key -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.csr -reqexts #{node['is_apaas_openshift_cookbook']['etcd_req_ext']} -batch -nodes -subj /CN=#{master_server['fqdn']}"
        environment 'SAN' => "IP:#{master_server['ipaddress']}"
        cwd "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.csr"
      end

      execute "ETCD Sign and create the CLIENT crt for #{master_server['fqdn']}" do
        command "openssl ca -name #{node['is_apaas_openshift_cookbook']['etcd_ca_name']} -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.crt -in #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.csr -batch"
        environment 'SAN' => ''
        cwd "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
        creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.crt"
      end

      execute "Create a tarball of the etcd master certs for #{master_server['fqdn']}" do
        command "tar czvf #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz -C #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']} . && chown -R apache:apache #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}"
        creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz"
      end

      execute 'Encrypt etcd tgz files' do
        command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz  -out #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}-new.tgz.enc -k '#{encrypted_file_password}' && chmod -R  0755 #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']} && chown -R apache: #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}"
      end
    end
  end

  if is_etcd_server
    ruby_block 'Remove old cert tarball' do
      block do
        helper.remove_dir("#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz*")
      end
    end

    remote_file "Retrieve certificate from ETCD Master[#{certificate_server['fqdn']}]" do
      path "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/etcd-#{node['fqdn']}.tgz.enc"
      source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/generated_certs/etcd-#{node['fqdn']}-new.tgz.enc"
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

    execute 'Fix ETCD directory permissions' do
      command "chmod 755 #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}"
      only_if "[[ $(stat -c %a #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}) -ne 755 ]]"
    end

    ruby_block 'Restart ETCD service if valid certificate' do
      block do
      end
      notifies :restart, 'service[etcd-service]', :immediately if helper.valid_certificate?(node['is_apaas_openshift_cookbook']['etcd_ca_cert'], node['is_apaas_openshift_cookbook']['etcd_cert_file'])
      only_if { helper.valid_certificate?(node['is_apaas_openshift_cookbook']['etcd_ca_cert'], node['is_apaas_openshift_cookbook']['etcd_cert_file']) }
    end
  end

  if is_master_server
    ruby_block 'Remove old cert tarball' do
      block do
        helper.remove_dir("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz*")
      end
    end

    remote_file "Retrieve client certificate from Master[#{certificate_server['fqdn']}]" do
      path "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-master-#{node['fqdn']}.tgz.enc"
      source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/master/generated_certs/openshift-master-#{node['fqdn']}-new.tgz.enc"
      action :create_if_missing
      notifies :run, 'execute[Un-encrypt master certificate tgz files]', :immediately
      notifies :run, 'execute[Extract certificate to Master folder]', :immediately
      retries 12
      retry_delay 5
      sensitive true
    end

    execute 'Un-encrypt master certificate tgz files' do
      command "openssl enc -d -aes-256-cbc -in openshift-master-#{node['fqdn']}.tgz.enc -out openshift-master-#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      action :nothing
    end

    execute 'Extract certificate to Master folder' do
      command "tar -xzf openshift-master-#{node['fqdn']}.tgz ./master.etcd-client.crt ./master.etcd-client.key"
      cwd node['is_apaas_openshift_cookbook']['openshift_master_config_dir']
      action :nothing
    end

    remote_file "Retrieve ETCD CA cert for Master[#{certificate_server['fqdn']}]" do
      path "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}ca.crt"
      source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/etcd/ca.crt"
      owner 'root'
      group 'root'
      mode '0600'
      retries 15
      retry_delay 2
      sensitive true
    end

    %w[client.crt client.key].each do |certificate_type|
      file "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}#{certificate_type}" do
        owner 'root'
        group 'root'
        mode '0600'
      end
    end

    ruby_block 'Restart Master services if valid certificate' do
      block do
      end
      notifies :restart, 'service[atomic-openshift-master-api]', :immediately
      notifies :restart, 'service[atomic-openshift-master-controllers]', :immediately
      only_if { helper.valid_certificate?("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}ca.crt", "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.crt") }
    end
  end
end
