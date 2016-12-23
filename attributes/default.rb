#
# Cookbook Name:: cookbook-openshift3
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

default['cookbook-openshift3']['use_params_roles'] = false
default['cookbook-openshift3']['use_wildcard_nodes'] = false
default['cookbook-openshift3']['wildcard_domain'] = ''
default['cookbook-openshift3']['openshift_cluster_name'] = nil
default['cookbook-openshift3']['openshift_HA'] = false
default['cookbook-openshift3']['master_servers'] = []
default['cookbook-openshift3']['etcd_servers'] = []
default['cookbook-openshift3']['node_servers'] = []

if node['cookbook-openshift3']['openshift_HA']
  default['cookbook-openshift3']['openshift_common_public_hostname'] = node['cookbook-openshift3']['openshift_cluster_name']
  default['cookbook-openshift3']['openshift_master_embedded_etcd'] = false
  default['cookbook-openshift3']['openshift_master_etcd_port'] = '2379'
  default['cookbook-openshift3']['master_etcd_cert_prefix'] = 'master.etcd-'
else
  default['cookbook-openshift3']['openshift_common_public_hostname'] = node['fqdn']
  default['cookbook-openshift3']['openshift_master_embedded_etcd'] = true
  default['cookbook-openshift3']['openshift_master_etcd_port'] = '4001'
  default['cookbook-openshift3']['master_etcd_cert_prefix'] = ''
end

default['cookbook-openshift3']['ose_version'] = nil
default['cookbook-openshift3']['persistent_storage'] = []
default['cookbook-openshift3']['openshift_deployment_type'] = 'enterprise'
default['cookbook-openshift3']['ose_major_version'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? '3.3' : '1.3'
default['cookbook-openshift3']['deploy_containerized'] = false
default['cookbook-openshift3']['deploy_example'] = false
default['cookbook-openshift3']['deploy_dnsmasq'] = false
default['cookbook-openshift3']['deploy_standalone_registry'] = false
default['cookbook-openshift3']['deploy_example_db_templates'] = true
default['cookbook-openshift3']['deploy_example_image-streams'] = true
default['cookbook-openshift3']['deploy_example_quickstart-templates'] = false
default['cookbook-openshift3']['deploy_example_xpaas-streams'] = false
default['cookbook-openshift3']['deploy_example_xpaas-templates'] = false

default['cookbook-openshift3']['docker_version'] = nil
default['cookbook-openshift3']['docker_log_driver'] = 'json-file'
default['cookbook-openshift3']['docker_log_options'] = {}
default['cookbook-openshift3']['install_method'] = 'yum'
default['cookbook-openshift3']['httpd_xfer_port'] = '9999'
default['cookbook-openshift3']['core_packages'] = %w(libselinux-python wget vim-enhanced net-tools bind-utils git bash-completion bash-completion dnsmasq)
default['cookbook-openshift3']['osn_cluster_dns_domain'] = 'cluster.local'
default['cookbook-openshift3']['enabled_firewall_rules_master'] = %w(firewall_master)
default['cookbook-openshift3']['enabled_firewall_rules_master_cluster'] = %w(firewall_master_cluster)
default['cookbook-openshift3']['enabled_firewall_rules_node'] = %w(firewall_node)
default['cookbook-openshift3']['enabled_firewall_additional_rules_node'] = []
default['cookbook-openshift3']['enabled_firewall_rules_etcd'] = %w(firewall_etcd)
default['cookbook-openshift3']['openshift_service_type'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'atomic-openshift' : 'origin'
default['cookbook-openshift3']['registry_persistent_volume'] = ''
default['cookbook-openshift3']['yum_repositories'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? %w() : [{ 'name' => 'centos-openshift-origin', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/', 'gpgcheck' => false }]

default['cookbook-openshift3']['openshift_data_dir'] = '/var/lib/origin'
default['cookbook-openshift3']['openshift_master_cluster_password'] = 'openshift_cluster'
default['cookbook-openshift3']['openshift_common_base_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_master_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_node_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_portal_net'] = '172.30.0.0/16'
default['cookbook-openshift3']['openshift_common_first_svc_ip'] = node['cookbook-openshift3']['openshift_common_portal_net'].split('/')[0].gsub(/\.0$/, '.1')
default['cookbook-openshift3']['openshift_common_reverse_svc_ip'] = node['cookbook-openshift3']['openshift_common_portal_net'].split('/')[0].split('.')[0..1].reverse!.join('.')
default['cookbook-openshift3']['openshift_common_default_nodeSelector'] = 'region=user'
default['cookbook-openshift3']['openshift_common_examples_base'] = '/usr/share/openshift/examples'
default['cookbook-openshift3']['openshift_common_hosted_base'] = '/usr/share/openshift/hosted'
default['cookbook-openshift3']['openshift_hosted_type'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'enterprise' : 'origin'
default['cookbook-openshift3']['openshift_base_images'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'image-streams-rhel7.json' : 'image-streams-centos7.json'
default['cookbook-openshift3']['openshift_common_hostname'] = node['fqdn']
default['cookbook-openshift3']['openshift_common_ip'] = node['ipaddress']
default['cookbook-openshift3']['openshift_common_infra_project'] = %w(default openshift-infra)
default['cookbook-openshift3']['openshift_common_public_ip'] = node['ipaddress']
default['cookbook-openshift3']['openshift_common_admin_binary'] = node['cookbook-openshift3']['deploy_containerized'] == true ? '/usr/local/bin/oadm' : '/usr/bin/oadm'
default['cookbook-openshift3']['openshift_common_client_binary'] = node['cookbook-openshift3']['deploy_containerized'] == true ? '/usr/local/bin/oc' : '/usr/bin/oc'
default['cookbook-openshift3']['openshift_common_service_accounts'] = []
default['cookbook-openshift3']['openshift_common_service_accounts'] = [{ 'name' => 'router', 'namespace' => 'default', 'scc' => 'hostnetwork' }]
default['cookbook-openshift3']['openshift_common_service_accounts_additional'] = []
default['cookbook-openshift3']['openshift_common_use_openshift_sdn'] = true
default['cookbook-openshift3']['openshift_common_sdn_network_plugin_name'] = 'redhat/openshift-ovs-subnet'
default['cookbook-openshift3']['openshift_common_svc_names'] = ['openshift', 'openshift.default', 'openshift.default.svc', "openshift.default.svc.#{node['cookbook-openshift3']['osn_cluster_dns_domain']}", 'kubernetes', 'kubernetes.default', 'kubernetes.default.svc', "kubernetes.default.svc.#{node['cookbook-openshift3']['osn_cluster_dns_domain']}", node['cookbook-openshift3']['openshift_common_first_svc_ip']]
default['cookbook-openshift3']['openshift_common_registry_url'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-${component}:${version}' : 'openshift/origin-${component}:${version}'
default['cookbook-openshift3']['openshift_docker_insecure_registry_arg'] = []
default['cookbook-openshift3']['openshift_docker_add_registry_arg'] = []
default['cookbook-openshift3']['openshift_docker_block_registry_arg'] = []
default['cookbook-openshift3']['openshift_docker_insecure_registries'] = node['cookbook-openshift3']['openshift_docker_add_registry_arg'].empty? ? [node['cookbook-openshift3']['openshift_common_portal_net']] : [node['cookbook-openshift3']['openshift_common_portal_net']] + node['cookbook-openshift3']['openshift_docker_insecure_registry_arg']
default['cookbook-openshift3']['openshift_docker_image_version'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'v3.2.0.44' : 'v1.2.0'
default['cookbook-openshift3']['openshift_docker_cli_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin'
default['cookbook-openshift3']['openshift_docker_master_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin'
default['cookbook-openshift3']['openshift_docker_node_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/node' : 'openshift/node'
default['cookbook-openshift3']['openshift_docker_ovs_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/openvswitch' : 'openshift/openvswitch'
default['cookbook-openshift3']['openshift_master_config_dir'] = "#{node['cookbook-openshift3']['openshift_common_master_dir']}/master"
default['cookbook-openshift3']['openshift_master_bind_addr'] = '0.0.0.0'
default['cookbook-openshift3']['openshift_master_auditconfig'] = false
default['cookbook-openshift3']['openshift_master_api_port'] = '8443'
default['cookbook-openshift3']['openshift_master_console_port'] = '8443'
default['cookbook-openshift3']['openshift_master_controllers_port'] = '8444'
default['cookbook-openshift3']['openshift_master_controller_lease_ttl'] = '30'
default['cookbook-openshift3']['openshift_master_dynamic_provisioning_enabled'] = true
default['cookbook-openshift3']['openshift_master_disabled_features'] = "['Builder', 'S2IBuilder', 'WebConsole']"
default['cookbook-openshift3']['openshift_master_embedded_dns'] = true
default['cookbook-openshift3']['openshift_master_embedded_kube'] = true
default['cookbook-openshift3']['openshift_master_debug_level'] = '2'
default['cookbook-openshift3']['openshift_master_dns_port'] = node['cookbook-openshift3']['deploy_dnsmasq'] == true ? '8053' : '53'
default['cookbook-openshift3']['openshift_master_metrics_public_url'] = nil
default['cookbook-openshift3']['openshift_master_image_bulk_imported'] = 5
default['cookbook-openshift3']['openshift_master_pod_eviction_timeout'] = ''
default['cookbook-openshift3']['openshift_master_project_request_message'] = ''
default['cookbook-openshift3']['openshift_master_project_request_template'] = ''
default['cookbook-openshift3']['openshift_master_logging_public_url'] = nil
default['cookbook-openshift3']['openshift_master_router_subdomain'] = 'cloudapps.domain.local'
default['cookbook-openshift3']['openshift_master_sdn_cluster_network_cidr'] = '10.1.0.0/16'
default['cookbook-openshift3']['openshift_master_sdn_host_subnet_length'] = '8'
default['cookbook-openshift3']['openshift_master_oauth_grant_method'] = 'auto'
default['cookbook-openshift3']['openshift_master_session_max_seconds'] = '3600'
default['cookbook-openshift3']['openshift_master_session_name'] = 'ssn'
default['cookbook-openshift3']['openshift_master_session_secrets_file'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/session-secrets.yaml"
default['cookbook-openshift3']['openshift_master_access_token_max_seconds'] = '86400'
default['cookbook-openshift3']['openshift_master_auth_token_max_seconds'] = '500'
default['cookbook-openshift3']['openshift_master_public_api_url'] = "https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']}"
default['cookbook-openshift3']['openshift_master_api_url'] = "https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']}"
default['cookbook-openshift3']['openshift_master_loopback_api_url'] = "https://#{node['fqdn']}:#{node['cookbook-openshift3']['openshift_master_api_port']}"
default['cookbook-openshift3']['openshift_master_console_url'] = "https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_console_port']}/console"
default['cookbook-openshift3']['openshift_master_etcd_url'] = "https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_etcd_port']}"
default['cookbook-openshift3']['openshift_master_policy'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/policy.json"
default['cookbook-openshift3']['openshift_master_config_file'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/master-config.yaml"
default['cookbook-openshift3']['openshift_master_api_sysconfig'] = "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-api"
default['cookbook-openshift3']['openshift_master_api_systemd'] = "/usr/lib/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-api.service"
default['cookbook-openshift3']['openshift_master_controllers_sysconfig'] = "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers"
default['cookbook-openshift3']['openshift_master_controllers_systemd'] = "/usr/lib/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers.service"
default['cookbook-openshift3']['openshift_master_named_certificates'] = %w()
default['cookbook-openshift3']['openshift_master_scheduler_conf'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/scheduler.json"
default['cookbook-openshift3']['openshift_master_certs_no_etcd'] = %w(admin.crt master.kubelet-client.crt master.server.crt openshift-master.crt openshift-registry.crt openshift-router.crt etcd.server.crt)
default['cookbook-openshift3']['openshift_node_config_dir'] = "#{node['cookbook-openshift3']['openshift_common_node_dir']}/node"
default['cookbook-openshift3']['openshift_node_config_file'] = "#{node['cookbook-openshift3']['openshift_node_config_dir']}/node-config.yaml"
default['cookbook-openshift3']['openshift_node_debug_level'] = '2'
default['cookbook-openshift3']['openshift_node_docker-storage'] = {}
default['cookbook-openshift3']['openshift_node_generated_configs_dir'] = '/var/www/html/node/generated-configs'
default['cookbook-openshift3']['openshift_node_label'] = node['cookbook-openshift3']['openshift_common_default_nodeSelector']
default['cookbook-openshift3']['openshift_node_iptables_sync_period'] = '5s'
default['cookbook-openshift3']['openshift_node_max_pod'] = '40'
default['cookbook-openshift3']['openshift_node_sdn_mtu_sdn'] = '1450'
default['cookbook-openshift3']['openshift_node_minimum_container_ttl_duration'] = '10s'
default['cookbook-openshift3']['openshift_node_maximum_dead_containers_per_container'] = '2'
default['cookbook-openshift3']['openshift_node_maximum_dead_containers'] = '100'
default['cookbook-openshift3']['openshift_node_image_gc_high_threshold'] = '90'
default['cookbook-openshift3']['openshift_node_image_gc_low_threshold'] = '80'

default['cookbook-openshift3']['openshift_hosted_manage_router'] = true
default['cookbook-openshift3']['openshift_hosted_router_selector'] = 'region=infra'
default['cookbook-openshift3']['openshift_hosted_router_namespace'] = 'default'

default['cookbook-openshift3']['openshift_hosted_manage_registry'] = true
default['cookbook-openshift3']['openshift_hosted_registry_selector'] = 'region=infra'
default['cookbook-openshift3']['openshift_hosted_registry_namespace'] = 'default'

default['cookbook-openshift3']['erb_corsAllowedOrigins'] = ['127.0.0.1', 'localhost', node['cookbook-openshift3']['openshift_common_hostname'], node['cookbook-openshift3']['openshift_common_public_hostname']] + node['cookbook-openshift3']['openshift_common_svc_names']

default['cookbook-openshift3']['erb_etcdClientInfo_urls'] = [node['cookbook-openshift3']['openshift_master_etcd_url'], "https://#{node['cookbook-openshift3']['openshift_common_hostname']}:#{node['cookbook-openshift3']['openshift_master_etcd_port']}"]

default['cookbook-openshift3']['master_generated_certs_dir'] = '/var/www/html/master/generated_certs'
default['cookbook-openshift3']['etcd_conf_dir'] = '/etc/etcd'
default['cookbook-openshift3']['etcd_ca_dir'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca"
default['cookbook-openshift3']['etcd_generated_certs_dir'] = '/var/www/html/etcd/generated_certs'
default['cookbook-openshift3']['etcd_ca_cert'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt"
default['cookbook-openshift3']['etcd_ca_peer'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt"
default['cookbook-openshift3']['etcd_cert_file'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/server.crt"
default['cookbook-openshift3']['etcd_cert_key'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/server.key"
default['cookbook-openshift3']['etcd_peer_file'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/peer.crt"
default['cookbook-openshift3']['etcd_peer_key'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/peer.key"
default['cookbook-openshift3']['etcd_openssl_conf'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/openssl.cnf"
default['cookbook-openshift3']['etcd_ca_name'] = 'etcd_ca'
default['cookbook-openshift3']['etcd_req_ext'] = 'etcd_v3_req'
default['cookbook-openshift3']['etcd_ca_exts_peer'] = 'etcd_v3_ca_peer'
default['cookbook-openshift3']['etcd_ca_exts_server'] = 'etcd_v3_ca_server'

default['cookbook-openshift3']['etcd_initial_cluster_state'] = 'new'
default['cookbook-openshift3']['etcd_initial_cluster_token'] = 'etcd-cluster-1'
default['cookbook-openshift3']['etcd_data_dir'] = '/var/lib/etcd/'
default['cookbook-openshift3']['etcd_default_days'] = '365'

default['cookbook-openshift3']['etcd_client_port'] = '2379'
default['cookbook-openshift3']['etcd_peer_port'] = '2380'

default['cookbook-openshift3']['etcd_initial_advertise_peer_urls'] = "https://#{node['ipaddress']}:#{node['cookbook-openshift3']['etcd_peer_port']}"
default['cookbook-openshift3']['etcd_listen_peer_urls'] = "https://#{node['ipaddress']}:#{node['cookbook-openshift3']['etcd_peer_port']}"
default['cookbook-openshift3']['etcd_listen_client_urls'] = "https://#{node['ipaddress']}:#{node['cookbook-openshift3']['etcd_client_port']}"
default['cookbook-openshift3']['etcd_advertise_client_urls'] = "https://#{node['ipaddress']}:#{node['cookbook-openshift3']['etcd_client_port']}"
default['cookbook-openshift3']['etcd_listen_client_urls'] = "https://#{node['ipaddress']}:#{node['cookbook-openshift3']['etcd_client_port']}"
