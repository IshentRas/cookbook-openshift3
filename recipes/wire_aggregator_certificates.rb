#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: wwire_aggregator_certificates
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = OpenShiftHelper::NodeHelper.new(node)
is_certificate_server = server_info.on_certificate_server?

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_certificate_server
  directory "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters" do
    mode '0755'
    owner 'apache'
    group 'apache'
    recursive true
  end

  execute 'Creating Master Aggregator signer certs' do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} ca create-signer-cert \
            --cert=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/front-proxy-ca.crt \
            --key=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/front-proxy-ca.key \
            --serial=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/ca.serial.txt"
    creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/front-proxy-ca.crt"
  end

  # create-api-client-config generates a ca.crt file which will
  # overwrite the OpenShift CA certificate.
  # Generate the aggregator kubeconfig and delete the ca.crt before creating archive for masters

  execute 'Create Master api-client config for Aggregator' do
    command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} create-api-client-config \
            --certificate-authority=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/front-proxy-ca.crt \
            --signer-cert=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/front-proxy-ca.crt \
            --signer-key=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/front-proxy-ca.key \
            --user aggregator-front-proxy \
            --client-dir=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters \
            --signer-serial=#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/ca.serial.txt"
    creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/aggregator-front-proxy.kubeconfig"
  end

  file "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/ca.crt" do
    action :delete
    only_if { File.exist? "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters/ca.crt" }
  end

  execute 'Create a tarball of the aggregator certs' do
    command "tar czvf #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters.tgz -C #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters . "
    creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters.tgz"
  end

  execute 'Encrypt wire aggregator master tgz files' do
    command "openssl enc -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters.tgz  -out #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters.tgz.enc -k '#{encrypted_file_password}' && chmod -R  0755 #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']} && chown -R apache: #{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}"
    creates "#{node['is_apaas_openshift_cookbook']['master_generated_certs_dir']}/wire_aggregator-masters.tgz.enc"
  end
end
