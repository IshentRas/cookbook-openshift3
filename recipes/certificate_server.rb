master_servers = node['cookbook-openshift3']['master_servers']
certificate_server = node['cookbook-openshift3']['certificate_server'] == {} ? master_servers.first : node['cookbook-openshift3']['certificate_server']

# Certificate server needs oadm installed
package node['cookbook-openshift3']['openshift_service_type'] do
  action :install
  version node['cookbook-openshift3']['ose_version'] unless node['cookbook-openshift3']['ose_version'].nil?
  only_if { certificate_server['fqdn'] == node['fqdn'] }
end

# If this is the certificate server, create the master certs. TODO: refactor this.
execute 'Create the master certificates' do
  command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-master-certs \
          --hostnames=#{(node['cookbook-openshift3']['erb_corsAllowedOrigins'] + [node['cookbook-openshift3']['openshift_common_ip']]).uniq.join(',')} \
          --master=#{node['cookbook-openshift3']['openshift_master_api_url']} \
          --public-master=#{node['cookbook-openshift3']['openshift_master_public_api_url']} \
          --cert-dir=#{node['cookbook-openshift3']['openshift_master_config_dir']} --overwrite=false"
  creates "#{node['cookbook-openshift3']['openshift_master_config_dir']}/master.server.key"
  only_if { certificate_server['fqdn'] == node['fqdn'] }
end
