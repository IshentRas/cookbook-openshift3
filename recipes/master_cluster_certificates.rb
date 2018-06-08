#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: master_cluster_certificates
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
master_servers = server_info.master_servers
is_certificate_server = server_info.on_certificate_server?

ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_certificate_server
  %W(/var/www/html/master #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}).each do |path|
    directory path do
      mode '0755'
      owner 'apache'
      group 'apache'
    end
  end

  template "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/.htaccess" do
    owner 'apache'
    group 'apache'
    source 'access-htaccess.erb'
    notifies :run, 'ruby_block[Modify the AllowOverride options]', :immediately
    variables(servers: master_servers)
  end

  master_servers.each do |master_server|
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

    execute "ETCD Sign and create the CLIENT crt for #{master_server['fqdn']}" do
      command "openssl ca -name #{node['is_apaas_openshift_cookbook']['etcd_ca_name']} -config #{node['is_apaas_openshift_cookbook']['etcd_openssl_conf']} -out #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.crt -in #{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.csr -batch"
      environment 'SAN' => ''
      cwd "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}"
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}client.crt"
    end

    execute "Create a tarball of the etcd master certs for #{master_server['fqdn']}" do
      command "tar --mode='0644' --owner=root --group=root -czvf #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz -C #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']} . && chown apache:apache #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz"
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz"
    end

    execute "Encrypt etcd tgz files for #{master_server['fqdn']}" do
      command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz  -out #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chown apache:apache #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz.enc"
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-master-#{master_server['fqdn']}.tgz.enc"
    end
  end

  master_servers.each do |master_server|
    directory "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}" do
      mode '0755'
      owner 'apache'
      group 'apache'
      recursive true
    end

    execute "Create the master server certificates for #{master_server['fqdn']}" do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} ca create-server-cert \
			        ${legacy_certs} \
              --hostnames=#{(node['is_apaas_openshift_cookbook']['erb_corsAllowedOrigins'] + [master_server['ipaddress'], master_server['fqdn'], node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']]).uniq.join(',')} \
              --cert=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/master.server.crt \
              --key=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/master.server.key \
              --signer-cert=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.crt \
              --signer-key=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.key \
              --signer-serial=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.serial.txt ${validity_certs} \
              --overwrite=false"
      environment(
        'validity_certs' => ose_major_version.split('.')[1].to_i < 5 ? '' : "--expire-days=#{node['is_apaas_openshift_cookbook']['openshift_master_cert_expire_days']}",
        'legacy_certs' => File.directory?("#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}-legacy-ca") ? "--certificate-authority=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}-legacy-ca/ca.crt" : ''
      )
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/master.server.crt"
    end

    execute "Generate master client configuration for #{master_server['fqdn']}" do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} create-api-client-config \
              --certificate-authority=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.crt \
              --master=https://#{master_server['fqdn']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']} \
              --public-master=https://#{master_server['fqdn']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']} \
              --client-dir=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']} \
              --groups=system:masters,system:openshift-master \
              --signer-cert=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.crt \
              --signer-key=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.key \
              --signer-serial=#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca.serial.txt \
              --user=system:openshift-master --basename=openshift-master ${validity_certs}"
      environment 'validity_certs' => ose_major_version.split('.')[1].to_i < 5 ? '' : "--expire-days=#{node['is_apaas_openshift_cookbook']['openshift_master_cert_expire_days']}"
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/openshift-master.kubeconfig"
    end

    certs = case ose_major_version.split('.')[1].to_i
            when 5..7
              node['is_apaas_openshift_cookbook']['openshift_master_certs'] + %w(service-signer.crt service-signer.key)
            else
              node['is_apaas_openshift_cookbook']['openshift_master_certs']
            end

    certs.grep(/\.(?:crt|kubeconfig)$/).uniq.each do |master_certificate|
      remote_file "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/#{master_certificate}" do
        source "file://#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/#{master_certificate}"
        only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/#{master_certificate}") }
        mode '0644'
        sensitive true
      end
    end

    certs.grep(/\.(?:key)$/).uniq.each do |master_key|
      remote_file "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/#{master_key}" do
        source "file://#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/#{master_key}"
        only_if { ::File.file?("#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/#{master_key}") }
        mode '0600'
        sensitive true
      end
    end

    %w(client.crt client.key).each do |remove_etcd_certificate|
      file "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/#{node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']}#{remove_etcd_certificate}" do
        action :delete
      end
    end

    if node['is_apaas_openshift_cookbook']['adhoc_redeploy_cluster_ca']
      ruby_block "(NEW-CA) Update the Master KUBECONFIG certificates for #{master_server['fqdn']}" do
        block do
          kubeconfig = YAML.load_file("#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/openshift-master.kubeconfig")
          kubeconfig['clusters'][0]['cluster']['certificate-authority-data'] = Base64.encode64(::File.read("#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca-bundle.crt")).delete("\n")
          open("#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/openshift-master.kubeconfig", 'w') { |f| f << kubeconfig.to_yaml }
        end
        only_if { ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_certserver_control_flag']) }
      end

      ruby_block "(NEW-CA) Update the Admin KUBECONFIG certificates for #{master_server['fqdn']}" do
        block do
          kubeconfig = YAML.load_file("#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/admin.kubeconfig")
          kubeconfig['clusters'][0]['cluster']['certificate-authority-data'] = Base64.encode64(::File.read("#{node['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir']}/ca-bundle.crt")).delete("\n")
          open("#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}/admin.kubeconfig", 'w') { |f| f << kubeconfig.to_yaml }
        end
        only_if { ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_certserver_control_flag']) }
      end
    end

    execute "Create a tarball of the master certs for #{master_server['fqdn']}" do
      command "tar --owner=root --group=root -czvf #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz -C #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']} . && chown apache:apache #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz"
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz"
    end

    execute "Encrypt master master tgz files for #{master_server['fqdn']}" do
      command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz  -out #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz.enc -k '#{encrypted_file_password}' && chown apache:apache #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz.enc"
      creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/openshift-#{master_server['fqdn']}.tgz.enc"
    end
  end
end
