#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: node
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

server_info = helper = OpenShiftHelper::NodeHelper.new(node)
certificate_server = server_info.certificate_server
is_node_server = server_info.on_node_server?
docker_version = node['is_apaas_openshift_cookbook']['openshift_docker_image_version']
pkg_node_to_install = node['is_apaas_openshift_cookbook']['pkg_node']

ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']
path_certificate = node['is_apaas_openshift_cookbook']['use_wildcard_nodes'] ? 'wildcard_nodes.tgz.enc' : "#{node['fqdn']}.tgz.enc"

if node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'] && node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name']
  secret_file = node['is_apaas_openshift_cookbook']['encrypted_file_password']['secret_file'] || nil
  encrypted_file_password = data_bag_item(node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_name'], node['is_apaas_openshift_cookbook']['encrypted_file_password']['data_bag_item_name'], secret_file)
else
  encrypted_file_password = node['is_apaas_openshift_cookbook']['encrypted_file_password']['default']
end

if is_node_server
  ruby_block 'Turn off SWAP for nodes' do
    block do
      server_info.turn_off_swap
    end
    not_if { ::File.readlines('/etc/fstab').grep(/(^[^#].*swap.*)\n/).none? }
    only_if { node['is_apaas_openshift_cookbook']['openshift_node_disable_swap_on_host'] }
  end

  file '/usr/local/etc/.firewall_node_additional.txt' do
    content node['is_apaas_openshift_cookbook']['enabled_firewall_additional_rules_node'].join("\n")
    owner 'root'
    group 'root'
  end

  node['is_apaas_openshift_cookbook']['enabled_firewall_rules_node'].each do |rule|
    iptables_rule rule do
      action :enable
      notifies :restart, 'service[iptables]', :immediately
    end
  end

  directory node['is_apaas_openshift_cookbook']['openshift_node_config_dir'] do
    recursive true
  end

  if node['is_apaas_openshift_cookbook']['deploy_containerized']
    execute 'Pull Node Image' do
      command "docker pull #{node['is_apaas_openshift_cookbook']['openshift_docker_node_image']}:#{docker_version}"
    end

    execute 'Pull OVS Image' do
      command "docker pull #{node['is_apaas_openshift_cookbook']['openshift_docker_ovs_image']}:#{docker_version}"
    end

    template '/etc/systemd/system/atomic-openshift-node-dep.service' do
      source 'service_node-deps-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    template '/etc/systemd/system/atomic-openshift-node.service' do
      source 'service_node-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
      variables(ose_major_version: ose_major_version)
    end

    template '/etc/systemd/system/openvswitch.service' do
      source 'service_openvswitch-containerized.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
    end

    template '/etc/sysconfig/openvswitch' do
      source 'service_openvswitch.sysconfig.erb'
      notifies :restart, 'service[openvswitch]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade']
    end
  else
    template '/etc/systemd/system/atomic-openshift-node.service' do
      source 'service_node.service.erb'
      notifies :run, 'execute[daemon-reload]', :immediately
      variables(ose_major_version: ose_major_version)
      only_if { ose_major_version.split('.')[1].to_i >= 6 }
    end
  end

  sysconfig_vars = {}

  if node['is_apaas_openshift_cookbook']['openshift_cloud_provider'] == 'aws'
    if node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_name'] && node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_item_name']
      secret_file = node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['secret_file'] || nil
      aws_vars = data_bag_item(node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_name'], node['is_apaas_openshift_cookbook']['openshift_cloud_providers']['aws']['data_bag_item_name'], secret_file)

      sysconfig_vars['aws_access_key_id'] = aws_vars['access_key_id']
      sysconfig_vars['aws_secret_access_key'] = aws_vars['secret_access_key']
    end
  end

  template '/etc/sysconfig/atomic-openshift-node' do
    source 'service_node.sysconfig.erb'
    variables(sysconfig_vars)
    notifies :restart, 'service[Restart Node]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade'] || Mixlib::ShellOut.new('systemctl is-enabled atomic-openshift-node').run_command.error?
  end

  pkg_node_array = pkg_node_to_install.reject { |x| x == 'tuned-profiles-atomic-openshift-node' && (node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i >= 9 || node['is_apaas_openshift_cookbook']['control_upgrade_version'].to_i >= 39) }
  yum_package pkg_node_array do
    action :install
    version Array.new(pkg_node_array.size, node['is_apaas_openshift_cookbook']['ose_version']) unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
    options node['is_apaas_openshift_cookbook']['openshift_yum_options'] unless node['is_apaas_openshift_cookbook']['openshift_yum_options'].nil?
    not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
    retries 3
  end

  yum_package 'conntrack-tools' do
    action :install
    not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
    retries 3
  end

  if node['is_apaas_openshift_cookbook']['adhoc_redeploy_cluster_ca']
    Chef::Log.warn("The CLUSTER CA CERTS redeploy will be skipped for Node[#{node['fqdn']}]. Could not find the flag: #{node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag']}") unless ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag'])

    ruby_block "Redeploy CA certs for Node server: #{node['fqdn']}" do
      block do
        helper.remove_dir("#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz*")
      end
      only_if { ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag']) }
      notifies :delete, "file[#{node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag']}]", :immediately
      notifies :restart, 'service[Restart Node]', :delayed if ::File.file?(node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag'])
    end

    file node['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag'] do
      action :nothing
    end
  end

  remote_file "Retrieve certificate from Master[#{certificate_server['fqdn']}]" do
    path "#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc"
    source "http://#{certificate_server['ipaddress']}:#{node['is_apaas_openshift_cookbook']['httpd_xfer_port']}/node/generated-configs/#{path_certificate}"
    action :create_if_missing
    notifies :run, 'execute[Un-encrypt node certificate tgz files]', :immediately
    notifies :run, 'execute[Extract certificate to Node folder]', :immediately
    retries 60
    retry_delay 5
  end

  execute 'Un-encrypt node certificate tgz files' do
    command "openssl enc -d -aes-256-cbc -in #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz.enc -out #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/#{node['fqdn']}.tgz -k '#{encrypted_file_password}'"
    action :nothing
  end

  execute 'Extract certificate to Node folder' do
    command "tar xzf #{node['fqdn']}.tgz && chown -R root:root ."
    cwd node['is_apaas_openshift_cookbook']['openshift_node_config_dir']
    action :nothing
  end

  directory "Fix permissions on #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}" do
    path node['is_apaas_openshift_cookbook']['openshift_node_config_dir']
    owner 'root'
    group 'root'
    mode '0755'
  end

  file "Fix permissions on #{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/ca.crt" do
    path ::File.join(node['is_apaas_openshift_cookbook']['openshift_node_config_dir'], 'ca.crt')
    owner 'root'
    group 'root'
    mode '0644'
  end

  remote_file '/etc/pki/ca-trust/source/anchors/openshift-ca.crt' do
    source "file://#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/ca.crt"
    notifies :run, 'ruby_block[Update ca trust]', :immediately
    sensitive true
  end

  # Use ruby_block for copying OpenShift CA to system CA trust
  ruby_block 'Update ca trust' do
    block do
      Mixlib::ShellOut.new('update-ca-trust').run_command
    end
    notifies :restart, 'service[docker]', :immediately
    notifies :run, 'execute[Wait for 30 seconds for docker services to come up]', :immediately
    action :nothing
  end

  execute 'Wait for 30 seconds for docker services to come up' do
    command 'sleep 30'
    action :nothing
    only_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
    not_if { node['is_apaas_openshift_cookbook']['upgrade'] }
  end

  if helper.get_nodevar('deploy_dnsmasq')
    package 'NetworkManager' do
      retries 3
    end

    template '/etc/origin/node/node-dnsmasq.conf' do
      source 'node-dnsmasq.conf.erb'
      only_if { ose_major_version.split('.')[1].to_i >= 6 }
    end

    template '/etc/dnsmasq.d/origin-dns.conf' do
      source 'origin-dns.conf.erb'
      variables(
        ose_major_version: ose_major_version,
        openshift_node_dnsmasq_log_queries: helper.get_nodevar('openshift_node_dnsmasq_log_queries'),
        openshift_node_dnsmasq_maxcachettl: helper.get_nodevar('openshift_node_dnsmasq_maxcachettl'),
        openshift_node_dnsmasq_interface: helper.get_nodevar('openshift_node_dnsmasq_interface'),
        openshift_node_dnsmasq_bind_interface: helper.get_nodevar('openshift_node_dnsmasq_bind_interface')
      )
      notifies :restart, 'service[dnsmasq]', :immediately
    end

    if helper.get_nodevar('custom_origin-dns')
      remote_file 'Retrieve custom file for 99-origin-dns.sh' do
        path '/etc/NetworkManager/dispatcher.d/99-origin-dns.sh'
        source "file://#{helper.get_nodevar('custom_origin_location')}"
        owner 'root'
        group 'root'
        mode '0755'
        notifies :restart, 'service[NetworkManager]', :immediately
      end
    else
      # On some systems, NetworkManager does not exist, so ignore_failure.
      cookbook_file '/etc/NetworkManager/dispatcher.d/99-origin-dns.sh' do
        source '99-origin-dns.sh'
        owner 'root'
        group 'root'
        mode '0755'
        action :create
        ignore_failure true
        notifies :restart, 'service[NetworkManager]', :immediately
      end
    end

    ruby_block 'Setup dnsmasq' do
      block do
        f = Chef::Util::FileEdit.new('/etc/dnsmasq.conf')
        f.insert_line_if_no_match(%r{^conf-dir=/etc/dnsmasq.d}, 'conf-dir=/etc/dnsmasq.d')
        f.write_file
      end
    end

    # ignore_failure in case this fails/is not necessary
    service 'dnsmasq' do
      action %i[enable start]
      ignore_failure true
    end

    ruby_block 'Enforce running NM_CONTROLLED on host (>= 3.6)' do
      block do
        f = Chef::Util::FileEdit.new("/etc/sysconfig/network-scripts/ifcfg-#{node['network']['default_interface']}")
        f.search_file_delete_line(/^NM_CONTROLLED/)
        f.write_file
      end
      notifies :restart, 'service[NetworkManager]', :immediately
      only_if { ::File.exist?("/etc/sysconfig/network-scripts/ifcfg-#{node['network']['default_interface']}") }
      only_if { ose_major_version.split('.')[1].to_i >= 6 }
    end
  end

  template node['is_apaas_openshift_cookbook']['openshift_node_config_file'] do
    source 'node.yaml.erb'
    variables(
      osn_cluster_dns_ip: helper.get_nodevar('osn_cluster_dns_ip'),
      node_labels: helper.nodelabels,
      ose_major_version: ose_major_version,
      kubelet_args: node['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_default'].merge(node['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_custom'])
    )
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :enable, 'service[atomic-openshift-node]', :immediately
    notifies :restart, 'service[Restart Node]', :immediately
  end

  selinux_policy_boolean 'virt_use_nfs' do
    value true
  end

  execute 'Wait for API to become available before starting Node component' do
    command '[[ $(curl --silent --tlsv1.2 --max-time 2 -k ${MASTER_URL}/healthz/ready) =~ "ok" ]]'
    environment 'MASTER_URL' => node['is_apaas_openshift_cookbook']['openshift_master_api_url']
    retries 120
    retry_delay 1
    notifies :start, 'service[Restart Node]', :immediately unless node['is_apaas_openshift_cookbook']['upgrade'] && node['is_apaas_openshift_cookbook']['deploy_containerized']
    notifies :restart, 'service[Restart Node]', :immediately if node['is_apaas_openshift_cookbook']['upgrade'] && node['is_apaas_openshift_cookbook']['deploy_containerized']
  end

  ruby_block 'Adjust permissions for certificate and key files on Node servers' do
    block do
      run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
      Dir.glob("#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/*").grep(/\.(?:key)$/).uniq.each do |key|
        file = Chef::Resource::File.new(key, run_context)
        file.owner 'root'
        file.group 'root'
        file.mode '0600'
        file.run_action(:create)
      end

      Dir.glob("#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/*").grep(/\.(?:crt)$/).uniq.each do |key|
        file = Chef::Resource::File.new(key, run_context)
        file.owner 'root'
        file.group 'root'
        file.mode '0640'
        file.run_action(:create)
      end
    end
  end
end
