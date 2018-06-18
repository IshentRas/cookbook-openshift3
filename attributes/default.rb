#
# Cookbook Name:: is_apaas_openshift_cookbook
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

originrepos = [{ 'name' => 'centos-openshift-origin13', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin13/', 'gpgcheck' => false }, { 'name' => 'centos-openshift-origin14', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin14/', 'gpgcheck' => false }, { 'name' => 'centos-openshift-origin15', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin15/', 'gpgcheck' => false }, { 'name' => 'centos-openshift-origin36', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin36/', 'gpgcheck' => false }, { 'name' => 'centos-openshift-origin37', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin37/', 'gpgcheck' => false }]

default['is_apaas_openshift_cookbook']['use_wildcard_nodes'] = false
default['is_apaas_openshift_cookbook']['custom_origin-dns'] = false
default['is_apaas_openshift_cookbook']['custom_origin_location'] = ''
default['is_apaas_openshift_cookbook']['wildcard_domain'] = ''
default['is_apaas_openshift_cookbook']['openshift_cluster_name'] = ''
default['is_apaas_openshift_cookbook']['openshift_HA'] = false
default['is_apaas_openshift_cookbook']['master_servers'] = []
default['is_apaas_openshift_cookbook']['etcd_servers'] = []
default['is_apaas_openshift_cookbook']['node_servers'] = []
default['is_apaas_openshift_cookbook']['lb_servers'] = []
default['is_apaas_openshift_cookbook']['certificate_server'] = {}
default['is_apaas_openshift_cookbook']['openshift_push_via_dns'] = false
default['is_apaas_openshift_cookbook']['openshift_hosted_registry_insecure'] = false

if node['is_apaas_openshift_cookbook']['openshift_HA']
  default['is_apaas_openshift_cookbook']['openshift_common_api_hostname'] = node['is_apaas_openshift_cookbook']['openshift_cluster_name']
  default['is_apaas_openshift_cookbook']['openshift_common_public_hostname'] = node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']
  default['is_apaas_openshift_cookbook']['openshift_master_embedded_etcd'] = false
  default['is_apaas_openshift_cookbook']['openshift_master_etcd_port'] = '2379'
  default['is_apaas_openshift_cookbook']['master_etcd_cert_prefix'] = 'master.etcd-'
else
  default['is_apaas_openshift_cookbook']['openshift_common_api_hostname'] = node['fqdn']
  default['is_apaas_openshift_cookbook']['openshift_common_public_hostname'] = node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']
  default['is_apaas_openshift_cookbook']['openshift_master_embedded_etcd'] = true
  default['is_apaas_openshift_cookbook']['openshift_master_etcd_port'] = '4001'
  default['is_apaas_openshift_cookbook']['master_etcd_cert_prefix'] = ''
end

default['is_apaas_openshift_cookbook']['ose_version'] = nil
default['is_apaas_openshift_cookbook']['persistent_storage'] = []
default['is_apaas_openshift_cookbook']['openshift_deployment_type'] = 'enterprise'
default['is_apaas_openshift_cookbook']['ose_major_version'] = '3.7'
default['is_apaas_openshift_cookbook']['openshift_docker_image_version'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'v3.7' : 'v3.7.2'
default['is_apaas_openshift_cookbook']['upgrade'] = false
default['is_apaas_openshift_cookbook']['deploy_containerized'] = false
default['is_apaas_openshift_cookbook']['deploy_example'] = false
default['is_apaas_openshift_cookbook']['deploy_dnsmasq'] = true
default['is_apaas_openshift_cookbook']['deploy_standalone_registry'] = false
default['is_apaas_openshift_cookbook']['deploy_example_db_templates'] = true
default['is_apaas_openshift_cookbook']['deploy_example_image-streams'] = true
default['is_apaas_openshift_cookbook']['deploy_example_quickstart-templates'] = false
default['is_apaas_openshift_cookbook']['deploy_example_xpaas-streams'] = false
default['is_apaas_openshift_cookbook']['deploy_example_xpaas-templates'] = false

default['is_apaas_openshift_cookbook']['docker_version'] = nil
default['is_apaas_openshift_cookbook']['docker_log_driver'] = 'json-file'
default['is_apaas_openshift_cookbook']['docker_log_options'] = {}
default['is_apaas_openshift_cookbook']['docker_redhat_registry'] = true
default['is_apaas_openshift_cookbook']['openshift_docker_add_redhat_registry'] = node['is_apaas_openshift_cookbook']['docker_redhat_registry'] == true ? '--add-registry registry.access.redhat.com' : ''
default['is_apaas_openshift_cookbook']['install_method'] = 'yum'
default['is_apaas_openshift_cookbook']['httpd_xfer_port'] = '9999'
default['is_apaas_openshift_cookbook']['core_packages'] = %w(libselinux-python wget vim-enhanced net-tools bind-utils git bash-completion dnsmasq yum-utils)
default['is_apaas_openshift_cookbook']['osn_cluster_dns_domain'] = 'cluster.local'
default['is_apaas_openshift_cookbook']['osn_cluster_dns_ip'] = node['ipaddress']
default['is_apaas_openshift_cookbook']['enabled_firewall_rules_certificate'] = %w(firewall_certificate)
default['is_apaas_openshift_cookbook']['enabled_firewall_rules_master'] = %w(firewall_master)
default['is_apaas_openshift_cookbook']['enabled_firewall_rules_master_cluster'] = %w(firewall_master_cluster)
default['is_apaas_openshift_cookbook']['enabled_firewall_rules_node'] = %w(firewall_node)
default['is_apaas_openshift_cookbook']['enabled_firewall_additional_rules_node'] = []
default['is_apaas_openshift_cookbook']['enabled_firewall_additional_rules_master'] = []
default['is_apaas_openshift_cookbook']['enabled_firewall_rules_etcd'] = %w(firewall_etcd)
default['is_apaas_openshift_cookbook']['enabled_firewall_rules_lb'] = %w(firewall_lb)
default['is_apaas_openshift_cookbook']['openshift_service_type'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'atomic-openshift' : 'origin'
default['is_apaas_openshift_cookbook']['registry_persistent_volume'] = ''
default['is_apaas_openshift_cookbook']['yum_repositories'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? %w() : originrepos.find_all { |x| x['name'] =~ /origin#{node['is_apaas_openshift_cookbook']['ose_major_version'].tr('.', '')}/ }
default['is_apaas_openshift_cookbook']['openshift_http_proxy'] = ''
default['is_apaas_openshift_cookbook']['openshift_https_proxy'] = ''
default['is_apaas_openshift_cookbook']['openshift_no_proxy'] = ''
default['is_apaas_openshift_cookbook']['openshift_data_dir'] = '/var/lib/origin'
default['is_apaas_openshift_cookbook']['openshift_common_base_dir'] = '/etc/origin'
default['is_apaas_openshift_cookbook']['openshift_common_master_dir'] = '/etc/origin'
default['is_apaas_openshift_cookbook']['openshift_common_node_dir'] = '/etc/origin'
default['is_apaas_openshift_cookbook']['openshift_common_cloud_provider_dir'] = '/etc/origin'
default['is_apaas_openshift_cookbook']['openshift_common_portal_net'] = '172.30.0.0/16'
default['is_apaas_openshift_cookbook']['openshift_master_external_ip_network_cidrs'] = ['0.0.0.0/0']
default['is_apaas_openshift_cookbook']['openshift_master_mcs_allocator_range'] = 's0:/2'
default['is_apaas_openshift_cookbook']['openshift_master_mcs_labels_per_project'] = 5
default['is_apaas_openshift_cookbook']['openshift_master_uid_allocator_range'] = '1000000000-1999999999/10000'
default['is_apaas_openshift_cookbook']['openshift_common_first_svc_ip'] = node['is_apaas_openshift_cookbook']['openshift_common_portal_net'].split('/')[0].gsub(/\.0$/, '.1')
default['is_apaas_openshift_cookbook']['openshift_common_default_nodeSelector'] = 'region=user'
default['is_apaas_openshift_cookbook']['openshift_common_examples_base'] = '/usr/share/openshift/examples'
default['is_apaas_openshift_cookbook']['openshift_common_hosted_base'] = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? '/etc/origin/hosted' : '/usr/share/openshift/hosted'
default['is_apaas_openshift_cookbook']['openshift_hosted_type'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'enterprise' : 'origin'
default['is_apaas_openshift_cookbook']['openshift_base_images'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'image-streams-rhel7.json' : 'image-streams-centos7.json'
default['is_apaas_openshift_cookbook']['openshift_common_hostname'] = node['fqdn']
default['is_apaas_openshift_cookbook']['openshift_common_ip'] = node['ipaddress']
default['is_apaas_openshift_cookbook']['openshift_common_public_ip'] = node['ipaddress']
default['is_apaas_openshift_cookbook']['openshift_common_admin_binary'] = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? '/usr/local/bin/oc adm' : '/usr/bin/oc adm'
default['is_apaas_openshift_cookbook']['openshift_common_client_binary'] = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? '/usr/local/bin/oc' : '/usr/bin/oc'
default['is_apaas_openshift_cookbook']['openshift_common_service_accounts'] = []
default['is_apaas_openshift_cookbook']['openshift_common_service_accounts'] = [{ 'name' => 'router', 'namespace' => 'default', 'scc' => ['hostnetwork'] }]
default['is_apaas_openshift_cookbook']['openshift_common_service_accounts_additional'] = []
default['is_apaas_openshift_cookbook']['openshift_common_use_openshift_sdn'] = true
default['is_apaas_openshift_cookbook']['openshift_common_sdn_network_plugin_name'] = 'redhat/openshift-ovs-subnet'
default['is_apaas_openshift_cookbook']['openshift_common_svc_names'] = ['openshift', 'openshift.default', 'openshift.default.svc', "openshift.default.svc.#{node['is_apaas_openshift_cookbook']['osn_cluster_dns_domain']}", 'kubernetes', 'kubernetes.default', 'kubernetes.default.svc', "kubernetes.default.svc.#{node['is_apaas_openshift_cookbook']['osn_cluster_dns_domain']}", node['is_apaas_openshift_cookbook']['openshift_common_first_svc_ip']]
default['is_apaas_openshift_cookbook']['openshift_common_registry_url'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-${component}:${version}' : 'openshift/origin-${component}:${version}'
default['is_apaas_openshift_cookbook']['openshift_cloud_provider_config_dir'] = "#{node['is_apaas_openshift_cookbook']['openshift_common_cloud_provider_dir']}/cloudprovider"
default['is_apaas_openshift_cookbook']['openshift_docker_secure'] = false
default['is_apaas_openshift_cookbook']['openshift_docker_insecure_registry_arg'] = []
default['is_apaas_openshift_cookbook']['openshift_docker_add_registry_arg'] = []
default['is_apaas_openshift_cookbook']['openshift_docker_block_registry_arg'] = []
default['is_apaas_openshift_cookbook']['openshift_docker_insecure_registries'] = node['is_apaas_openshift_cookbook']['openshift_hosted_registry_insecure'] ? [node['is_apaas_openshift_cookbook']['openshift_common_portal_net']] + node['is_apaas_openshift_cookbook']['openshift_docker_insecure_registry_arg'] : node['is_apaas_openshift_cookbook']['openshift_docker_insecure_registry_arg']
default['is_apaas_openshift_cookbook']['openshift_docker_master_image'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin'
default['is_apaas_openshift_cookbook']['openshift_docker_node_image'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/node' : 'openshift/node'
default['is_apaas_openshift_cookbook']['openshift_docker_ovs_image'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/openvswitch' : 'openshift/openvswitch'
default['is_apaas_openshift_cookbook']['openshift_docker_etcd_image'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'registry.access.redhat.com/rhel7/etcd' : 'registry.fedoraproject.org/f27/etcd'
default['is_apaas_openshift_cookbook']['openshift_master_config_dir'] = "#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master"
default['is_apaas_openshift_cookbook']['openshift_master_bind_addr'] = '0.0.0.0'
default['is_apaas_openshift_cookbook']['openshift_master_auditconfig'] = { 'enable' => false }
default['is_apaas_openshift_cookbook']['openshift_master_api_port'] = '8443'
default['is_apaas_openshift_cookbook']['openshift_lb_port'] = '8443'
default['is_apaas_openshift_cookbook']['openshift_master_certs'] = %w(admin.crt admin.key admin.kubeconfig master.kubelet-client.crt master.kubelet-client.key ca.crt ca.key ca.serial.txt ca-bundle.crt serviceaccounts.private.key serviceaccounts.public.key master.proxy-client.crt master.proxy-client.key service-signer.crt service-signer.key openshift-registry.crt openshift-registry.key openshift-registry.kubeconfig openshift-router.crt openshift-router.key openshift-router.kubeconfig service-signer.crt service-signer.key)
default['is_apaas_openshift_cookbook']['openshift_master_renew_certs'] = %w(admin.crt admin.key admin.kubeconfig master.kubelet-client.crt master.kubelet-client.key openshift-registry.crt openshift-registry.key openshift-registry.kubeconfig openshift-router.crt openshift-router.key openshift-router.kubeconfig master.proxy-client.crt master.proxy-client.key service-signer.crt service-signer.key openshift-master.crt openshift-master.key openshift-master.kubeconfig master.server.crt master.server.key etcd.server.crt etcd.server.key)
default['is_apaas_openshift_cookbook']['openshift_master_console_port'] = '8443'
default['is_apaas_openshift_cookbook']['openshift_master_controllers_port'] = '8444'
default['is_apaas_openshift_cookbook']['openshift_master_controller_lease_ttl'] = '30'
default['is_apaas_openshift_cookbook']['openshift_master_dynamic_provisioning_enabled'] = true
default['is_apaas_openshift_cookbook']['openshift_master_disabled_features'] = "['Builder', 'S2IBuilder', 'WebConsole']"
default['is_apaas_openshift_cookbook']['openshift_master_embedded_dns'] = true
default['is_apaas_openshift_cookbook']['openshift_master_embedded_kube'] = true
default['is_apaas_openshift_cookbook']['openshift_master_external_ratelimit_burst'] = 400
default['is_apaas_openshift_cookbook']['openshift_master_external_ratelimit_qps'] = 200
default['is_apaas_openshift_cookbook']['openshift_master_loopback_ratelimit_burst'] = 600
default['is_apaas_openshift_cookbook']['openshift_master_loopback_ratelimit_qps'] = 300
default['is_apaas_openshift_cookbook']['openshift_master_debug_level'] = '2'
default['is_apaas_openshift_cookbook']['openshift_master_dns_port'] = node['is_apaas_openshift_cookbook']['deploy_dnsmasq'] == true ? '8053' : '53'
default['is_apaas_openshift_cookbook']['openshift_master_image_bulk_imported'] = 5
default['is_apaas_openshift_cookbook']['openshift_master_image_config_latest'] = false
default['is_apaas_openshift_cookbook']['openshift_master_deserialization_cache_size'] = '50000'
default['is_apaas_openshift_cookbook']['openshift_master_pod_eviction_timeout'] = ''
default['is_apaas_openshift_cookbook']['openshift_master_project_request_message'] = ''
default['is_apaas_openshift_cookbook']['openshift_master_project_request_template'] = ''
default['is_apaas_openshift_cookbook']['openshift_master_logging_public_url'] = nil
default['is_apaas_openshift_cookbook']['openshift_master_router_subdomain'] = 'cloudapps.domain.local'
default['is_apaas_openshift_cookbook']['openshift_master_sdn_cluster_network_cidr'] = '10.128.0.0/14'
default['is_apaas_openshift_cookbook']['openshift_master_sdn_host_subnet_length'] = '9'
default['is_apaas_openshift_cookbook']['openshift_master_saconfig_limitsecretreferences'] = false
default['is_apaas_openshift_cookbook']['openshift_master_oauth_grant_method'] = 'auto'
default['is_apaas_openshift_cookbook']['openshift_master_session_max_seconds'] = '3600'
default['is_apaas_openshift_cookbook']['openshift_master_session_name'] = 'ssn'
default['is_apaas_openshift_cookbook']['openshift_master_session_secrets_file'] = "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/session-secrets.yaml"
default['is_apaas_openshift_cookbook']['openshift_master_access_token_max_seconds'] = '86400'
default['is_apaas_openshift_cookbook']['openshift_master_auth_token_max_seconds'] = '500'
default['is_apaas_openshift_cookbook']['openshift_master_min_tls_version'] = ''
default['is_apaas_openshift_cookbook']['openshift_master_cipher_suites'] = []
default['is_apaas_openshift_cookbook']['openshift_master_ingress_ip_network_cidr'] = ''
default['is_apaas_openshift_cookbook']['openshift_master_public_api_url'] = "https://#{node['is_apaas_openshift_cookbook']['openshift_common_public_hostname']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}"
default['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url'] = "https://#{node['fqdn']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}"
default['is_apaas_openshift_cookbook']['openshift_master_api_url'] = "https://#{node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}"
default['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url'] = "https://#{node['fqdn']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}"
default['is_apaas_openshift_cookbook']['openshift_master_loopback_context_name'] = "current-context: default/#{node['fqdn']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}/system:openshift-master".tr('.', '-')
default['is_apaas_openshift_cookbook']['openshift_master_console_url'] = "https://#{node['is_apaas_openshift_cookbook']['openshift_common_public_hostname']}:#{node['is_apaas_openshift_cookbook']['openshift_master_console_port']}/console"
default['is_apaas_openshift_cookbook']['openshift_master_policy'] = "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/policy.json"
default['is_apaas_openshift_cookbook']['openshift_master_config_file'] = "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master-config.yaml"
default['is_apaas_openshift_cookbook']['openshift_master_api_sysconfig'] = '/etc/sysconfig/atomic-openshift-master-api'
default['is_apaas_openshift_cookbook']['openshift_master_api_systemd'] = '/usr/lib/systemd/system/atomic-openshift-master-api.service'
default['is_apaas_openshift_cookbook']['openshift_master_controllers_sysconfig'] = '/etc/sysconfig/atomic-openshift-master-controllers'
default['is_apaas_openshift_cookbook']['openshift_master_controllers_systemd'] = '/usr/lib/systemd/system/atomic-openshift-master-controllers.service'
default['is_apaas_openshift_cookbook']['openshift_master_ca_certificate'] = { 'data_bag_name' => nil, 'data_bag_item_name' => nil, 'secret_file' => nil }
default['is_apaas_openshift_cookbook']['openshift_master_named_certificates'] = %w()
default['is_apaas_openshift_cookbook']['openshift_master_scheduler_conf'] = "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/scheduler.json"
default['is_apaas_openshift_cookbook']['openshift_master_managed_names_additional'] = %w()
default['is_apaas_openshift_cookbook']['openshift_master_retain_events'] = nil
default['is_apaas_openshift_cookbook']['openshift_master_api_server_args_custom'] = {}
default['is_apaas_openshift_cookbook']['openshift_master_controller_args_custom'] = {}
default['is_apaas_openshift_cookbook']['openshift_node_config_dir'] = "#{node['is_apaas_openshift_cookbook']['openshift_common_node_dir']}/node"
default['is_apaas_openshift_cookbook']['openshift_node_config_file'] = "#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/node-config.yaml"
default['is_apaas_openshift_cookbook']['openshift_node_debug_level'] = '2'
default['is_apaas_openshift_cookbook']['openshift_node_dnsmasq_log_queries'] = false
default['is_apaas_openshift_cookbook']['openshift_node_dnsmasq_cache_size'] = 150
default['is_apaas_openshift_cookbook']['openshift_node_dnsmasq_maxcachettl'] = 1
default['is_apaas_openshift_cookbook']['openshift_node_docker-storage'] = {}
default['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir'] = '/var/www/html/node/generated-configs'
default['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_default'] = {}
default['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_custom'] = {}
default['is_apaas_openshift_cookbook']['openshift_node_iptables_sync_period'] = '30s'
default['is_apaas_openshift_cookbook']['openshift_node_port_range'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_sdn_mtu_sdn'] = '1450'
# Deprecated options (Use openshift_node_kubelet_args_custom instead)
default['is_apaas_openshift_cookbook']['openshift_node_max_pod'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_image_config_latest'] = false
default['is_apaas_openshift_cookbook']['openshift_node_minimum_container_ttl_duration'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_maximum_dead_containers_per_container'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_maximum_dead_containers'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_image_gc_high_threshold'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_image_gc_low_threshold'] = ''
default['is_apaas_openshift_cookbook']['openshift_node_cadvisor_port'] = nil # usually set to '4194'
default['is_apaas_openshift_cookbook']['openshift_node_read_only_port'] = nil # usually set to '10255'

default['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router'] = false
default['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_router_file'] = ''
default['is_apaas_openshift_cookbook']['openshift_hosted_deploy_custom_name'] = 'config-volume'
default['is_apaas_openshift_cookbook']['openshift_hosted_deploy_env_router'] = []
default['is_apaas_openshift_cookbook']['openshift_hosted_manage_router'] = true
default['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards'] = false
default['is_apaas_openshift_cookbook']['openshift_hosted_router_shard'] = []
default['is_apaas_openshift_cookbook']['openshift_hosted_router_selector'] = 'region=infra'
default['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace'] = 'default'
default['is_apaas_openshift_cookbook']['openshift_hosted_router_options'] = []
default['is_apaas_openshift_cookbook']['openshift_hosted_router_certfile'] = "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-router.crt"
default['is_apaas_openshift_cookbook']['openshift_hosted_router_keyfile'] = "#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-router.key"

default['is_apaas_openshift_cookbook']['openshift_hosted_manage_registry'] = true
default['is_apaas_openshift_cookbook']['openshift_hosted_registry_selector'] = 'region=infra'
default['is_apaas_openshift_cookbook']['openshift_hosted_registry_namespace'] = 'default'

default['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics'] = false

default['is_apaas_openshift_cookbook']['erb_corsAllowedOrigins'] = ['127.0.0.1', 'localhost', node['is_apaas_openshift_cookbook']['openshift_common_public_hostname']].uniq + node['is_apaas_openshift_cookbook']['openshift_common_svc_names']

default['is_apaas_openshift_cookbook']['master_generated_certs_dir'] = '/var/www/html/master/generated_certs'
default['is_apaas_openshift_cookbook']['etcd_certs_generated_certs_dir'] = '/var/www/html/etcd_certs/generated_certs'
default['is_apaas_openshift_cookbook']['master_certs_generated_certs_dir'] = '/var/www/html/master_certs/generated_certs'
default['is_apaas_openshift_cookbook']['openshift_master_cert_expire_days'] = '730'
default['is_apaas_openshift_cookbook']['openshift_node_cert_expire_days'] = '730'
default['is_apaas_openshift_cookbook']['openshift_ca_cert_expire_days'] = '1825'
default['is_apaas_openshift_cookbook']['etcd_add_additional_nodes'] = false
default['is_apaas_openshift_cookbook']['etcd_service_name'] = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? 'etcd_container' : 'etcd'
default['is_apaas_openshift_cookbook']['etcd_remove_servers'] = []
default['is_apaas_openshift_cookbook']['etcd_conf_dir'] = '/etc/etcd'
default['is_apaas_openshift_cookbook']['legacy_etcd_ca_dir'] = "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca"
default['is_apaas_openshift_cookbook']['etcd_ca_dir'] = node['is_apaas_openshift_cookbook']['etcd_certs_generated_certs_dir']
default['is_apaas_openshift_cookbook']['etcd_debug'] = 'False'
default['is_apaas_openshift_cookbook']['etcd_generated_certs_dir'] = '/var/www/html/etcd/generated_certs'
default['is_apaas_openshift_cookbook']['etcd_generated_ca_dir'] = '/var/www/html/etcd'
default['is_apaas_openshift_cookbook']['etcd_generated_migrated_dir'] = '/var/www/html/etcd/migration'
default['is_apaas_openshift_cookbook']['etcd_ca_cert'] = "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca.crt"
default['is_apaas_openshift_cookbook']['etcd_cert_file'] = "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/server.crt"
default['is_apaas_openshift_cookbook']['etcd_cert_key'] = "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/server.key"
default['is_apaas_openshift_cookbook']['etcd_peer_file'] = "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/peer.crt"
default['is_apaas_openshift_cookbook']['etcd_peer_key'] = "#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/peer.key"
default['is_apaas_openshift_cookbook']['etcd_quota_backend_bytes'] = 4_294_967_296
default['is_apaas_openshift_cookbook']['etcd_openssl_conf'] = "#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/openssl.cnf"
default['is_apaas_openshift_cookbook']['etcd_ca_name'] = 'etcd_ca'
default['is_apaas_openshift_cookbook']['etcd_req_ext'] = 'etcd_v3_req'
default['is_apaas_openshift_cookbook']['etcd_ca_exts_peer'] = 'etcd_v3_ca_peer'
default['is_apaas_openshift_cookbook']['etcd_ca_exts_server'] = 'etcd_v3_ca_server'

default['is_apaas_openshift_cookbook']['etcd_initial_cluster_state'] = 'new'
default['is_apaas_openshift_cookbook']['etcd_initial_cluster_token'] = 'etcd-cluster-1'
default['is_apaas_openshift_cookbook']['etcd_data_dir'] = '/var/lib/etcd'
default['is_apaas_openshift_cookbook']['etcd_default_days'] = '1825'

default['is_apaas_openshift_cookbook']['etcd_client_port'] = '2379'
default['is_apaas_openshift_cookbook']['etcd_peer_port'] = '2380'

default['is_apaas_openshift_cookbook']['docker_dns_search_option'] = %w()

default['is_apaas_openshift_cookbook']['switch_off_provider_notify_version'] = '12.4.1'

# If a secret is desired, store the password in a data bag, or override the default.
default['is_apaas_openshift_cookbook']['encrypted_file_password'] = { 'data_bag_name' => nil, 'data_bag_item_name' => nil, 'secret_file' => nil, 'default' => 'defaultpass' }

# Unique identifier for this cluster on chef server. Used for 'duty' discovery of node within cluster by introspecting node's role assignments according to a predefined scheme:
# In below, <ID> == openshift_cluster_duty_discovery_id
#
#   role:<ID>_openshift_use_role_based_duty_discovery   - This must be assigned to the node to use role-based duty discovery
#   role:<ID>_openshift_etcd_duty                       - If assigned, this is an etcd node
#   role:<ID>_openshift_first_master_duty               - If assigned, this is the first master node
#   role:<ID>_openshift_certificate_server_duty         - If assigned, this is the certificate server node
#   role:<ID>_openshift_master_duty                     - If assigned, this is a master node
#   role:<ID>_openshift_node_duty                       - If assigned, this is a node
#   role:<ID>_openshift_lb_duty                         - If assigned, this is a load balancer
#
# If openshift_cluster_duty_discovery_id is nil, then the cluster uses duty discovery nowhere on the cluster.
default['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id'] = nil
