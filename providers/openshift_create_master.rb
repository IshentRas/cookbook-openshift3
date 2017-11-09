#
# Cookbook Name:: cookbook-openshift3
# Providers:: openshift_create_master
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'openssl'

use_inline_resources
provides :openshift_create_master if defined? provides

def whyrun_supported?
  true
end

named_certificates = []

action :create do
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
      names -= [node['cookbook-openshift3']['openshift_common_api_hostname']] # named certificate apply only to public hostnames, not internal ones.

      named_hash = {}
      named_hash.store('certfile', named['certfile'])
      named_hash.store('keyfile', named['keyfile'])
      named_hash.store('names', names)
      named_certificates << named_hash
    end
  end

  if new_resource.cluster
    template new_resource.master_file do
      source 'master.yaml.erb'
      variables(
        erb_corsAllowedOrigins: new_resource.origins + [node['cookbook-openshift3']['openshift_common_public_ip']],
        standalone_registry: new_resource.standalone_registry,
        erb_master_named_certificates: named_certificates,
        etcd_servers: new_resource.etcd_servers,
        masters_size: new_resource.masters_size,
        ose_major_version: node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']
      )
      # This notify fails on older versions of Chef in providers. This is a workaround.
      unless node['chef_packages']['chef']['version'] == node['cookbook-openshift3']['switch_off_provider_notify_version']
        notifies :run, 'ruby_block[Restart API]', :immediately
      end
    end
  else
    template new_resource.master_file do
      source 'master.yaml.erb'
      variables(
        erb_corsAllowedOrigins: new_resource.origins + [node['cookbook-openshift3']['openshift_common_public_ip']],
        standalone_registry: new_resource.standalone_registry,
        erb_master_named_certificates: named_certificates,
        etcd_servers: new_resource.etcd_servers,
        masters_size: new_resource.masters_size,
        ose_major_version: node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']
      )
      # This notify fails on older versions of Chef in providers. This is a workaround.
      unless node['chef_packages']['chef']['version'] == node['cookbook-openshift3']['switch_off_provider_notify_version']
        notifies :run, 'ruby_block[Restart Master]', :immediately
      end
    end
  end
  new_resource.updated_by_last_action(true)
end
