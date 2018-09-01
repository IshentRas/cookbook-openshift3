#
# Cookbook Name:: cookbook-openshift3
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

originrepos = [
  { 'name' => 'centos-openshift-origin13', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin13/', 'gpgcheck' => false },
  { 'name' => 'centos-openshift-origin14', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin14/', 'gpgcheck' => false },
  { 'name' => 'centos-openshift-origin15', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin15/', 'gpgcheck' => false },
  { 'name' => 'centos-openshift-origin36', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin36/', 'gpgcheck' => false },
  { 'name' => 'centos-openshift-origin37', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin37/', 'gpgcheck' => false },
  { 'name' => 'centos-openshift-origin39', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin39/', 'gpgcheck' => false },
  { 'name' => 'centos-openshift-origin310', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/', 'gpgcheck' => false }, # hack
].freeze
server_info = OpenShiftHelper::NodeHelper.new(node)

default['cookbook-openshift3']['docker_signature_verification'] = 'false'
default['cookbook-openshift3']['docker_signature_args'] = server_info.getdockerversion ? " --signature-verification=#{node['cookbook-openshift3']['docker_signature_verification']}" : ''
default['cookbook-openshift3']['use_wildcard_nodes'] = false
default['cookbook-openshift3']['custom_origin-dns'] = false
default['cookbook-openshift3']['custom_origin_location'] = ''
default['cookbook-openshift3']['wildcard_domain'] = ''
default['cookbook-openshift3']['openshift_cluster_name'] = ''
default['cookbook-openshift3']['openshift_HA'] = false
default['cookbook-openshift3']['master_servers'] = []
default['cookbook-openshift3']['etcd_servers'] = []
default['cookbook-openshift3']['new_etcd_servers'] = []
default['cookbook-openshift3']['remove_etcd_servers'] = []
default['cookbook-openshift3']['node_servers'] = []
default['cookbook-openshift3']['lb_servers'] = []
default['cookbook-openshift3']['certificate_server'] = {}
default['cookbook-openshift3']['openshift_hosted_registry_insecure'] = false
default['cookbook-openshift3']['openshift_yum_options'] = ''

if node['cookbook-openshift3']['openshift_HA']
  default['cookbook-openshift3']['openshift_common_api_hostname'] = node['cookbook-openshift3']['openshift_cluster_name']
  default['cookbook-openshift3']['openshift_common_public_hostname'] = node['cookbook-openshift3']['openshift_common_api_hostname']
  default['cookbook-openshift3']['openshift_master_embedded_etcd'] = false
  default['cookbook-openshift3']['openshift_master_etcd_port'] = '2379'
  default['cookbook-openshift3']['master_etcd_cert_prefix'] = 'master.etcd-'
else
  default['cookbook-openshift3']['openshift_common_api_hostname'] = node['fqdn']
  default['cookbook-openshift3']['openshift_common_public_hostname'] = node['cookbook-openshift3']['openshift_common_api_hostname']
  default['cookbook-openshift3']['openshift_master_embedded_etcd'] = true
  default['cookbook-openshift3']['openshift_master_etcd_port'] = '4001'
  default['cookbook-openshift3']['master_etcd_cert_prefix'] = ''
end

default['cookbook-openshift3']['ose_version'] = nil
default['cookbook-openshift3']['persistent_storage'] = []
default['cookbook-openshift3']['openshift_deployment_type'] = 'enterprise'
default['cookbook-openshift3']['ose_major_version'] = '3.9'
default['cookbook-openshift3']['openshift_push_via_dns'] = (node['cookbook-openshift3']['ose_major_version'].to_f >= 3.6)
default['cookbook-openshift3']['openshift_docker_image_version'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'v3.9' : 'v3.9.0'
default['cookbook-openshift3']['upgrade'] = false
default['cookbook-openshift3']['deploy_containerized'] = false
default['cookbook-openshift3']['deploy_example'] = false
default['cookbook-openshift3']['deploy_dnsmasq'] = true
default['cookbook-openshift3']['deploy_standalone_registry'] = false
default['cookbook-openshift3']['deploy_example_db_templates'] = true
default['cookbook-openshift3']['deploy_example_image-streams'] = true
default['cookbook-openshift3']['deploy_example_quickstart-templates'] = false
default['cookbook-openshift3']['deploy_example_xpaas-streams'] = false
default['cookbook-openshift3']['deploy_example_xpaas-templates'] = false

default['cookbook-openshift3']['docker_version'] = nil
default['cookbook-openshift3']['docker_log_driver'] = 'json-file'
default['cookbook-openshift3']['docker_log_options'] = {}
default['cookbook-openshift3']['docker_redhat_registry'] = true
default['cookbook-openshift3']['openshift_docker_add_redhat_registry'] = node['cookbook-openshift3']['docker_redhat_registry'] == true ? '--add-registry registry.access.redhat.com' : ''
default['cookbook-openshift3']['install_method'] = 'yum'
default['cookbook-openshift3']['httpd_xfer_port'] = '9999'
default['cookbook-openshift3']['core_packages'] = %w(libselinux-python wget vim-enhanced net-tools bind-utils git bash-completion dnsmasq yum-utils)
default['cookbook-openshift3']['osn_cluster_dns_domain'] = 'cluster.local'
default['cookbook-openshift3']['osn_cluster_dns_ip'] = node['ipaddress']
default['cookbook-openshift3']['enabled_firewall_rules_certificate'] = %w(firewall_certificate)
default['cookbook-openshift3']['enabled_firewall_rules_master'] = %w(firewall_master)
default['cookbook-openshift3']['enabled_firewall_rules_master_cluster'] = %w(firewall_master_cluster)
default['cookbook-openshift3']['enabled_firewall_rules_node'] = %w(firewall_node)
default['cookbook-openshift3']['enabled_firewall_additional_rules_node'] = []
default['cookbook-openshift3']['enabled_firewall_additional_rules_master'] = []
default['cookbook-openshift3']['enabled_firewall_rules_etcd'] = %w(firewall_etcd)
default['cookbook-openshift3']['enabled_firewall_rules_lb'] = %w(firewall_lb)
default['cookbook-openshift3']['openshift_service_type'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'atomic-openshift' : 'origin'
default['cookbook-openshift3']['registry_persistent_volume'] = ''
default['cookbook-openshift3']['yum_repositories'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? %w() : originrepos.find_all { |x| x['name'] =~ /origin#{node['cookbook-openshift3']['ose_major_version'].tr('.', '')}/ }
default['cookbook-openshift3']['openshift_http_proxy'] = ''
default['cookbook-openshift3']['openshift_https_proxy'] = ''
default['cookbook-openshift3']['openshift_no_proxy'] = ''
default['cookbook-openshift3']['openshift_data_dir'] = '/var/lib/origin'
default['cookbook-openshift3']['openshift_common_base_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_master_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_node_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_cloud_provider_dir'] = '/etc/origin'
default['cookbook-openshift3']['openshift_common_portal_net'] = '172.30.0.0/16'
default['cookbook-openshift3']['openshift_master_external_ip_network_cidrs'] = ['0.0.0.0/0']
default['cookbook-openshift3']['openshift_master_mcs_allocator_range'] = 's0:/2'
default['cookbook-openshift3']['openshift_master_mcs_labels_per_project'] = 5
default['cookbook-openshift3']['openshift_master_uid_allocator_range'] = '1000000000-1999999999/10000'
default['cookbook-openshift3']['openshift_common_first_svc_ip'] = node['cookbook-openshift3']['openshift_common_portal_net'].split('/')[0].gsub(/\.0$/, '.1')
default['cookbook-openshift3']['openshift_common_default_nodeSelector'] = node['cookbook-openshift3']['ose_major_version'].to_f >= 3.9 ? 'node-role.kubernetes.io/compute=true' : 'region=user'
default['cookbook-openshift3']['openshift_common_examples_base'] = '/usr/share/openshift/examples'
default['cookbook-openshift3']['openshift_common_hosted_base'] = node['cookbook-openshift3']['deploy_containerized'] == true ? '/etc/origin/hosted' : '/usr/share/openshift/hosted'
default['cookbook-openshift3']['openshift_hosted_type'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'enterprise' : 'origin'
default['cookbook-openshift3']['openshift_base_images'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'image-streams-rhel7.json' : 'image-streams-centos7.json'
default['cookbook-openshift3']['openshift_common_hostname'] = node['fqdn']
default['cookbook-openshift3']['openshift_common_ip'] = node['ipaddress']
default['cookbook-openshift3']['openshift_common_public_ip'] = node['ipaddress']
default['cookbook-openshift3']['openshift_common_admin_binary'] = node['cookbook-openshift3']['deploy_containerized'] == true ? '/usr/local/bin/oc adm' : '/usr/bin/oc adm'
default['cookbook-openshift3']['openshift_common_client_binary'] = node['cookbook-openshift3']['deploy_containerized'] == true ? '/usr/local/bin/oc' : '/usr/bin/oc'
default['cookbook-openshift3']['openshift_common_service_accounts'] = []
default['cookbook-openshift3']['openshift_common_service_accounts'] = [{ 'name' => 'router', 'namespace' => 'default', 'scc' => ['hostnetwork'] }]
default['cookbook-openshift3']['openshift_common_service_accounts_additional'] = []
default['cookbook-openshift3']['openshift_common_use_openshift_sdn'] = true
default['cookbook-openshift3']['openshift_common_sdn_network_plugin_name'] = 'redhat/openshift-ovs-subnet'
default['cookbook-openshift3']['openshift_common_svc_names'] = ['openshift', 'openshift.default', 'openshift.default.svc', "openshift.default.svc.#{node['cookbook-openshift3']['osn_cluster_dns_domain']}", 'kubernetes', 'kubernetes.default', 'kubernetes.default.svc', "kubernetes.default.svc.#{node['cookbook-openshift3']['osn_cluster_dns_domain']}", node['cookbook-openshift3']['openshift_common_first_svc_ip']]
default['cookbook-openshift3']['openshift_common_registry_url'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-${component}:${version}' : 'openshift/origin-${component}:${version}'
default['cookbook-openshift3']['openshift_cloud_provider_config_dir'] = "#{node['cookbook-openshift3']['openshift_common_cloud_provider_dir']}/cloudprovider"
default['cookbook-openshift3']['openshift_docker_secure'] = false
default['cookbook-openshift3']['openshift_docker_insecure_registry_arg'] = []
default['cookbook-openshift3']['openshift_docker_add_registry_arg'] = []
default['cookbook-openshift3']['openshift_docker_block_registry_arg'] = []
default['cookbook-openshift3']['openshift_docker_network_options'] = ''
default['cookbook-openshift3']['openshift_docker_insecure_registries'] = node['cookbook-openshift3']['openshift_hosted_registry_insecure'] ? [node['cookbook-openshift3']['openshift_common_portal_net']] + node['cookbook-openshift3']['openshift_docker_insecure_registry_arg'] : node['cookbook-openshift3']['openshift_docker_insecure_registry_arg']
default['cookbook-openshift3']['openshift_docker_master_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin'
default['cookbook-openshift3']['openshift_docker_hosted_registry_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-\${component}:\${version}' : 'openshift/origin-\${component}:\${version}'
default['cookbook-openshift3']['openshift_docker_hosted_router_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-\${component}:\${version}' : 'openshift/origin-\${component}:\${version}'
default['cookbook-openshift3']['openshift_docker_node_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/node' : 'openshift/node'
default['cookbook-openshift3']['openshift_docker_ovs_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/openvswitch' : 'openshift/openvswitch'
default['cookbook-openshift3']['openshift_docker_etcd_image'] = node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'registry.access.redhat.com/rhel7/etcd' : 'registry.fedoraproject.org/latest/etcd'
default['cookbook-openshift3']['openshift_master_config_dir'] = "#{node['cookbook-openshift3']['openshift_common_master_dir']}/master"
default['cookbook-openshift3']['openshift_master_bind_addr'] = '0.0.0.0'
default['cookbook-openshift3']['openshift_master_auditconfig'] = { 'enable' => false }
default['cookbook-openshift3']['openshift_master_api_port'] = '8443'
default['cookbook-openshift3']['openshift_lb_port'] = '8443'
default['cookbook-openshift3']['openshift_master_certs'] = %w(admin.crt admin.key admin.kubeconfig master.kubelet-client.crt master.kubelet-client.key ca.crt ca.key ca.serial.txt ca-bundle.crt serviceaccounts.private.key serviceaccounts.public.key master.proxy-client.crt master.proxy-client.key service-signer.crt service-signer.key openshift-registry.crt openshift-registry.key openshift-registry.kubeconfig openshift-router.crt openshift-router.key openshift-router.kubeconfig service-signer.crt service-signer.key)
default['cookbook-openshift3']['openshift_master_renew_certs'] = %w(admin.crt admin.key admin.kubeconfig master.kubelet-client.crt master.kubelet-client.key openshift-registry.crt openshift-registry.key openshift-registry.kubeconfig openshift-router.crt openshift-router.key openshift-router.kubeconfig master.proxy-client.crt master.proxy-client.key service-signer.crt service-signer.key openshift-master.crt openshift-master.key openshift-master.kubeconfig master.server.crt master.server.key etcd.server.crt etcd.server.key)
default['cookbook-openshift3']['openshift_master_console_port'] = '8443'
default['cookbook-openshift3']['openshift_master_controllers_port'] = '8444'
default['cookbook-openshift3']['openshift_master_controller_lease_ttl'] = '30'
default['cookbook-openshift3']['openshift_master_dynamic_provisioning_enabled'] = true
default['cookbook-openshift3']['openshift_master_disabled_features'] = "['Builder', 'S2IBuilder', 'WebConsole']"
default['cookbook-openshift3']['openshift_master_embedded_dns'] = true
default['cookbook-openshift3']['openshift_master_embedded_kube'] = true
default['cookbook-openshift3']['openshift_master_external_ratelimit_burst'] = 400
default['cookbook-openshift3']['openshift_master_external_ratelimit_qps'] = 200
default['cookbook-openshift3']['openshift_master_loopback_ratelimit_burst'] = 600
default['cookbook-openshift3']['openshift_master_loopback_ratelimit_qps'] = 300
default['cookbook-openshift3']['openshift_master_debug_level'] = '2'
default['cookbook-openshift3']['openshift_master_dns_port'] = node['cookbook-openshift3']['deploy_dnsmasq'] == true ? '8053' : '53'
default['cookbook-openshift3']['openshift_master_image_bulk_imported'] = 5
default['cookbook-openshift3']['openshift_master_image_config_latest'] = false
default['cookbook-openshift3']['openshift_master_deserialization_cache_size'] = '50000'
default['cookbook-openshift3']['openshift_master_pod_eviction_timeout'] = ''
default['cookbook-openshift3']['openshift_master_project_request_message'] = ''
default['cookbook-openshift3']['openshift_master_project_request_template'] = ''
default['cookbook-openshift3']['openshift_master_logout_url'] = nil
default['cookbook-openshift3']['openshift_master_router_subdomain'] = 'cloudapps.domain.local'
default['cookbook-openshift3']['openshift_master_sdn_cluster_network_cidr'] = '10.128.0.0/14'
default['cookbook-openshift3']['openshift_master_sdn_host_subnet_length'] = '9'
default['cookbook-openshift3']['openshift_master_saconfig_limitsecretreferences'] = false
default['cookbook-openshift3']['openshift_master_oauth_grant_method'] = 'auto'
default['cookbook-openshift3']['openshift_master_session_max_seconds'] = '3600'
default['cookbook-openshift3']['openshift_master_session_name'] = 'ssn'
default['cookbook-openshift3']['openshift_master_session_secrets_file'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/session-secrets.yaml"
default['cookbook-openshift3']['openshift_master_access_token_max_seconds'] = '86400'
default['cookbook-openshift3']['openshift_master_auth_token_max_seconds'] = '500'
default['cookbook-openshift3']['openshift_master_min_tls_version'] = ''
default['cookbook-openshift3']['openshift_master_cipher_suites'] = []
default['cookbook-openshift3']['openshift_master_ingress_ip_network_cidr'] = ''
default['cookbook-openshift3']['openshift_master_public_api_url'] = "https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']}"
default['cookbook-openshift3']['openshift_master_loopback_api_url'] = "https://localhost:#{node['cookbook-openshift3']['openshift_master_api_port']}"
default['cookbook-openshift3']['openshift_master_api_url'] = "https://#{node['cookbook-openshift3']['openshift_common_api_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']}"
default['cookbook-openshift3']['openshift_master_loopback_context_name'] = "current-context: default/#{node['fqdn']}:#{node['cookbook-openshift3']['openshift_master_api_port']}/system:openshift-master".tr('.', '-')
default['cookbook-openshift3']['openshift_master_console_url'] = "https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_console_port']}/console"
default['cookbook-openshift3']['openshift_master_policy'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/policy.json"
default['cookbook-openshift3']['openshift_master_config_file'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/master-config.yaml"
default['cookbook-openshift3']['openshift_master_api_sysconfig'] = "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-api"
default['cookbook-openshift3']['openshift_master_api_systemd'] = "/usr/lib/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-api.service"
default['cookbook-openshift3']['openshift_master_controllers_sysconfig'] = "/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers"
default['cookbook-openshift3']['openshift_master_controllers_systemd'] = "/usr/lib/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers.service"
default['cookbook-openshift3']['openshift_master_ca_certificate'] = { 'data_bag_name' => nil, 'data_bag_item_name' => nil, 'secret_file' => nil }
default['cookbook-openshift3']['openshift_master_named_certificates'] = %w()
default['cookbook-openshift3']['openshift_master_scheduler_conf'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/scheduler.json"
default['cookbook-openshift3']['openshift_master_managed_names_additional'] = %w()
default['cookbook-openshift3']['openshift_master_retain_events'] = nil
default['cookbook-openshift3']['openshift_master_api_server_args_custom'] = {}
default['cookbook-openshift3']['openshift_master_controller_args_custom'] = {}
default['cookbook-openshift3']['openshift_node_config_dir'] = "#{node['cookbook-openshift3']['openshift_common_node_dir']}/node"
default['cookbook-openshift3']['openshift_node_config_file'] = "#{node['cookbook-openshift3']['openshift_node_config_dir']}/node-config.yaml"
default['cookbook-openshift3']['openshift_node_debug_level'] = '2'
default['cookbook-openshift3']['openshift_node_dnsmasq_log_queries'] = false
default['cookbook-openshift3']['openshift_node_dnsmasq_maxcachettl'] = 1
default['cookbook-openshift3']['openshift_node_dnsmasq_interface'] = false
default['cookbook-openshift3']['openshift_node_dnsmasq_bind_interface'] = 'eth0'
default['cookbook-openshift3']['openshift_node_docker-storage'] = {}
default['cookbook-openshift3']['openshift_node_generated_configs_dir'] = '/var/www/html/node/generated-configs'
default['cookbook-openshift3']['openshift_node_kubelet_args_default'] = {}
default['cookbook-openshift3']['openshift_node_kubelet_args_custom'] = {}
default['cookbook-openshift3']['openshift_node_iptables_sync_period'] = '30s'
default['cookbook-openshift3']['openshift_node_port_range'] = ''
default['cookbook-openshift3']['openshift_node_sdn_mtu_sdn'] = '1450'
default['cookbook-openshift3']['openshift_node_disable_swap_on_host'] = true
# Deprecated options (Use openshift_node_kubelet_args_custom instead)
default['cookbook-openshift3']['openshift_node_max_pod'] = ''
default['cookbook-openshift3']['openshift_node_image_config_latest'] = false
default['cookbook-openshift3']['openshift_node_minimum_container_ttl_duration'] = ''
default['cookbook-openshift3']['openshift_node_maximum_dead_containers_per_container'] = ''
default['cookbook-openshift3']['openshift_node_maximum_dead_containers'] = ''
default['cookbook-openshift3']['openshift_node_image_gc_high_threshold'] = ''
default['cookbook-openshift3']['openshift_node_image_gc_low_threshold'] = ''
default['cookbook-openshift3']['openshift_node_cadvisor_port'] = nil # usually set to '4194'
default['cookbook-openshift3']['openshift_node_read_only_port'] = nil # usually set to '10255'

default['cookbook-openshift3']['openshift_hosted_deploy_custom_router'] = false
default['cookbook-openshift3']['openshift_hosted_deploy_custom_router_file'] = ''
default['cookbook-openshift3']['openshift_hosted_deploy_custom_name'] = 'config-volume'
default['cookbook-openshift3']['openshift_hosted_deploy_env_router'] = []
default['cookbook-openshift3']['openshift_hosted_manage_router'] = true
default['cookbook-openshift3']['openshift_hosted_router_deploy_shards'] = false
default['cookbook-openshift3']['openshift_hosted_router_shard'] = []
default['cookbook-openshift3']['openshift_hosted_router_selector'] = 'region=infra'
default['cookbook-openshift3']['openshift_hosted_router_namespace'] = 'default'
default['cookbook-openshift3']['openshift_hosted_router_options'] = []
default['cookbook-openshift3']['openshift_hosted_router_certfile'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-router.crt"
default['cookbook-openshift3']['openshift_hosted_router_keyfile'] = "#{node['cookbook-openshift3']['openshift_master_config_dir']}/openshift-router.key"

default['cookbook-openshift3']['openshift_hosted_manage_registry'] = true
default['cookbook-openshift3']['openshift_hosted_registry_selector'] = 'region=infra'
default['cookbook-openshift3']['openshift_hosted_registry_namespace'] = 'default'

default['cookbook-openshift3']['openshift_hosted_cluster_logging'] = false
default['cookbook-openshift3']['openshift_hosted_cluster_metrics'] = false

default['cookbook-openshift3']['erb_corsAllowedOrigins'] = ['127.0.0.1', 'localhost', node['cookbook-openshift3']['openshift_common_public_hostname']].uniq + node['cookbook-openshift3']['openshift_common_svc_names']

default['cookbook-openshift3']['master_generated_certs_dir'] = '/var/www/html/master/generated_certs'
default['cookbook-openshift3']['etcd_certs_generated_certs_dir'] = '/var/www/html/etcd_certs/generated_certs'
default['cookbook-openshift3']['master_certs_generated_certs_dir'] = '/var/www/html/master_certs/generated_certs'
default['cookbook-openshift3']['openshift_master_cert_expire_days'] = '730'
default['cookbook-openshift3']['openshift_node_cert_expire_days'] = '730'
default['cookbook-openshift3']['openshift_ca_cert_expire_days'] = '1825'
default['cookbook-openshift3']['etcd_add_additional_nodes'] = false
default['cookbook-openshift3']['etcd_service_name'] = node['cookbook-openshift3']['deploy_containerized'] == true ? 'etcd_container' : 'etcd'
default['cookbook-openshift3']['etcd_remove_servers'] = []
default['cookbook-openshift3']['etcd_conf_dir'] = '/etc/etcd'
default['cookbook-openshift3']['legacy_etcd_ca_dir'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca"
default['cookbook-openshift3']['etcd_ca_dir'] = node['cookbook-openshift3']['etcd_certs_generated_certs_dir']
default['cookbook-openshift3']['etcd_debug'] = 'False'
default['cookbook-openshift3']['etcd_generated_certs_dir'] = '/var/www/html/etcd/generated_certs'
default['cookbook-openshift3']['etcd_generated_ca_dir'] = '/var/www/html/etcd'
default['cookbook-openshift3']['etcd_generated_migrated_dir'] = '/var/www/html/etcd/migration'
default['cookbook-openshift3']['etcd_generated_scaleup_dir'] = '/var/www/html/etcd/scaleup'
default['cookbook-openshift3']['etcd_generated_remove_dir'] = '/var/www/html/etcd/removal'
default['cookbook-openshift3']['etcd_ca_cert'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt"
default['cookbook-openshift3']['etcd_cert_file'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/server.crt"
default['cookbook-openshift3']['etcd_cert_key'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/server.key"
default['cookbook-openshift3']['etcd_peer_file'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/peer.crt"
default['cookbook-openshift3']['etcd_peer_key'] = "#{node['cookbook-openshift3']['etcd_conf_dir']}/peer.key"
default['cookbook-openshift3']['etcd_quota_backend_bytes'] = 4_294_967_296
default['cookbook-openshift3']['etcd_openssl_conf'] = "#{node['cookbook-openshift3']['etcd_ca_dir']}/openssl.cnf"
default['cookbook-openshift3']['etcd_ca_name'] = 'etcd_ca'
default['cookbook-openshift3']['etcd_req_ext'] = 'etcd_v3_req'
default['cookbook-openshift3']['etcd_ca_exts_peer'] = 'etcd_v3_ca_peer'
default['cookbook-openshift3']['etcd_ca_exts_server'] = 'etcd_v3_ca_server'

default['cookbook-openshift3']['etcd_initial_cluster_state'] = 'new'
default['cookbook-openshift3']['etcd_initial_cluster_token'] = 'etcd-cluster-1'
default['cookbook-openshift3']['etcd_data_dir'] = '/var/lib/etcd'
default['cookbook-openshift3']['etcd_default_days'] = '1825'

default['cookbook-openshift3']['etcd_client_port'] = '2379'
default['cookbook-openshift3']['etcd_peer_port'] = '2380'

default['cookbook-openshift3']['docker_dns_search_option'] = %w()

default['cookbook-openshift3']['switch_off_provider_notify_version'] = '12.4.1'

# If a secret is desired, store the password in a data bag, or override the default.
default['cookbook-openshift3']['encrypted_file_password'] = { 'data_bag_name' => nil, 'data_bag_item_name' => nil, 'secret_file' => nil, 'default' => 'defaultpass' }

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
default['cookbook-openshift3']['openshift_cluster_duty_discovery_id'] = nil
