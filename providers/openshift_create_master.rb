#
# Cookbook Name:: is_apaas_openshift_cookbook
# Providers:: openshift_create_master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
require 'openssl'

provides :openshift_create_master if defined? provides

def whyrun_supported?
  true
end

action :create do
  converge_by 'Create Master configuration file' do
    named_certificates = []
    named_certificate_original = new_resource.named_certificate
    named_certificate_original.each do |named|
      certfile = named['certfile']
      raw = ::File.read certfile
      certificate = OpenSSL::X509::Certificate.new raw
      common_name = certificate.subject.to_a.find { |e| e.include?('CN') }[1].split(' ')
      begin
        subject_alt_name = certificate.extensions.find { |e| e.oid == 'subjectAltName' }.value.tr(',', '').gsub(/DNS:/, '').split(' ')
      rescue NoMethodError
        print 'No SAN detected'
      ensure
        names = subject_alt_name.nil? ? common_name : common_name + subject_alt_name
        names = names.uniq # openshift fails if the same entry is listed twice, eg. when common_name is also listed in subject_alt_name
        names -= [node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']] unless node['is_apaas_openshift_cookbook']['openshift_common_api_hostname'].eql?(node['is_apaas_openshift_cookbook']['openshift_cluster_name']) # named certificate apply only to public hostnames, not internal ones.
        named_hash = {}
        named_hash.store('certfile', named['certfile'])
        named_hash.store('keyfile', named['keyfile'])
        named_hash.store('names', names)
        named_certificates << named_hash
      end
    end

    etcd3_deployed = true if node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i >= 6

    case node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i
    when 3..4
      admission_default = node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config'].empty? ? {} : node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config']
    when 5..6
      admission_default = node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config'].empty? ? { 'openshift.io/ImagePolicy' => { 'configuration' => { 'apiVersion' => 'v1', 'executionRules' => [{ 'matchImageAnnotations' => [{ 'key' => 'images.openshift.io/deny-execution', 'value' => 'true' }], 'name' => 'execution-denied', 'onResources' => [{ 'resource' => 'pods' }, { 'resource' => 'builds' }], 'reject' => true, 'skipOnResolutionFailure' => true }], 'kind' => 'ImagePolicyConfig' } } } : node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config'].to_hash
    when 7..9
      admission_default = node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config'].empty? ? { 'openshift.io/ImagePolicy' => { 'configuration' => { 'apiVersion' => 'v1', 'executionRules' => [{ 'matchImageAnnotations' => [{ 'key' => 'images.openshift.io/deny-execution', 'value' => 'true' }], 'name' => 'execution-denied', 'onResources' => [{ 'resource' => 'pods' }, { 'resource' => 'builds' }], 'reject' => true, 'skipOnResolutionFailure' => true }], 'kind' => 'ImagePolicyConfig' } }, 'PodPreset' => { 'configuration' => { 'kind' => 'DefaultAdmissionConfig', 'apiVersion' => 'v1', 'disable' => false } } } : node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config'].to_hash.merge('PodPreset' => { 'configuration' => { 'kind' => 'DefaultAdmissionConfig', 'apiVersion' => 'v1', 'disable' => false } })
    end

    if ::File.file?("#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master/master-config.yaml") && node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i == 6
      config_options = YAML.load_file("#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master/master-config.yaml")
      etcd3_deployed = config_options['kubernetesMasterConfig']['apiServerArguments'].key?('storage-backend') ? true : false
    end

    template "#{Chef::Config[:file_cache_path]}/BuildDefaults.yaml" do
      source 'BuildDefaultsConfig.erb'
    end

    template "#{Chef::Config[:file_cache_path]}/BuildOverrides.yaml" do
      source 'BuildOverridesConfig.erb'
    end

    template "#{Chef::Config[:file_cache_path]}/ClusterResourceOverride.yaml" do
      source 'ClusterResourceOverrideConfig.erb'
    end

    if ::File.file?("#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master/master-config.yaml") && node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i == 6
      config_options = YAML.load_file("#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master/master-config.yaml")
      etcd3_deployed = config_options['kubernetesMasterConfig']['apiServerArguments'].key?('storage-backend') ? true : false
    end

    template "#{Chef::Config[:file_cache_path]}/core-master.yaml" do
      source 'master.yaml.erb'
      variables(
        erb_corsAllowedOrigins: new_resource.origins + [node['is_apaas_openshift_cookbook']['openshift_common_public_ip']],
        standalone_registry: new_resource.standalone_registry,
        erb_master_named_certificates: named_certificates,
        etcd_servers: new_resource.etcd_servers,
        masters_size: new_resource.masters_size,
        ose_major_version: node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version'],
        etcd3_deployed: etcd3_deployed
      )
    end

    ruby_block 'Prepare YAML' do
      block do
        pre_builddefaults = YAML.load_file("#{Chef::Config[:file_cache_path]}/BuildDefaults.yaml")
        pre_buildoverrides = YAML.load_file("#{Chef::Config[:file_cache_path]}/BuildOverrides.yaml")
        pre_clusteroverrides = YAML.load_file("#{Chef::Config[:file_cache_path]}/ClusterResourceOverride.yaml")
        pre_master = YAML.load_file("#{Chef::Config[:file_cache_path]}/core-master.yaml")
        builddefaults = pre_builddefaults['BuildDefaults']['configuration'].keys.size.eql?(2) ? {} : pre_builddefaults
        buildoverrides = pre_buildoverrides['BuildOverrides']['configuration'].keys.size.eql?(2) ? {} : pre_buildoverrides
        clusteroverrides = pre_clusteroverrides['ClusterResourceOverride']['configuration'].keys.size.eql?(2) ? {} : pre_clusteroverrides
        pre_master['admissionConfig']['pluginConfig'] = builddefaults.merge(buildoverrides).merge(clusteroverrides).merge(admission_default)

        file new_resource.master_file do
          content pre_master.to_yaml
          unless node['chef_packages']['chef']['version'] == node['is_apaas_openshift_cookbook']['switch_off_provider_notify_version']
            notifies :restart, 'service[Restart Master]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
            notifies :restart, 'service[Restart API]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
            notifies :restart, 'service[Restart Controller]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
          end
        end
      end
    end
  end
end
