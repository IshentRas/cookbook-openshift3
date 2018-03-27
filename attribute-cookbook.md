# Description

Installs/Configures Openshift 3.x (>= 3.2)

# Requirements

## Platform:

* redhat (>= 7.1)
* centos (>= 7.1)

## Cookbooks:

* iptables (>= 1.0.0)
* selinux_policy

# Attributes

* `node['is_apaas_openshift_cookbook']['openshift_adhoc_reboot_node']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['openshift_push_via_dns']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['openshift_master_asset_config']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['use_wildcard_nodes']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['wildcard_domain']` -  Defaults to ``.
* `node['is_apaas_openshift_cookbook']['openshift_cluster_name']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_HA']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['master_servers']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['etcd_servers']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['node_servers']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']` -  Defaults to `node['fqdn']`.
* `node['is_apaas_openshift_cookbook']['openshift_common_public_hostname']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']`.
* `node['is_apaas_openshift_cookbook']['openshift_master_embedded_etcd']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_master_etcd_port']` -  Defaults to `4001`.
* `node['is_apaas_openshift_cookbook']['master_etcd_cert_prefix']` -  Defaults to ``.
* `node['is_apaas_openshift_cookbook']['ose_version']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['persistent_storage']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_deployment_type']` -  Defaults to `enterprise`.
* `node['is_apaas_openshift_cookbook']['ose_major_version']` -  Defaults to `'3.7'`.
* `node['is_apaas_openshift_cookbook']['deploy_containerized']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['deploy_example']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['deploy_dnsmasq']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['deploy_standalone_registry']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['deploy_example_db_templates']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['deploy_example_image-streams']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['deploy_example_quickstart-templates']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['deploy_example_xpaas-streams']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['deploy_example_xpaas-templates']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['docker_version']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['docker_log_driver']` -  Defaults to `json-file`.
* `node['is_apaas_openshift_cookbook']['docker_log_options']` -  Defaults to `{ ... }`.
* `node['is_apaas_openshift_cookbook']['install_method']` -  Defaults to `yum`.
* `node['is_apaas_openshift_cookbook']['httpd_xfer_port']` -  Defaults to `9999`.
* `node['is_apaas_openshift_cookbook']['core_packages']` -  Defaults to `%w(libselinux-python wget vim-enhanced net-tools bind-utils git bash-completion dnsmasq)`.
* `node['is_apaas_openshift_cookbook']['osn_cluster_dns_domain']` -  Defaults to `cluster.local`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_rules_master']` -  Defaults to `%w(firewall_master)`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_rules_master_cluster']` -  Defaults to `%w(firewall_master_cluster)`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_rules_node']` -  Defaults to `%w(firewall_node)`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_additional_rules_node']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_additional_rules_master']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_rules_etcd']` -  Defaults to `%w(firewall_etcd)`.
* `node['is_apaas_openshift_cookbook']['enabled_firewall_rules_lb']` -  Defaults to `%w(firewall_lb)`.
* `node['is_apaas_openshift_cookbook']['openshift_service_type']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'atomic-openshift' : 'origin`.
* `node['is_apaas_openshift_cookbook']['registry_persistent_volume']` -  Defaults to ``.
* `node['is_apaas_openshift_cookbook']['yum_repositories']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? %w() : [{ 'name' => 'centos-openshift-origin', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/', 'gpgcheck' => false }]`.
* `node['is_apaas_openshift_cookbook']['openshift_http_proxy']` -  Defaults to `""`.
* `node['is_apaas_openshift_cookbook']['openshift_https_proxy']` -  Defaults to `""`.
* `node['is_apaas_openshift_cookbook']['openshift_no_proxy']` -  Defaults to `""`.
* `node['is_apaas_openshift_cookbook']['openshift_data_dir']` -  Defaults to `/var/lib/origin`.
* `node['is_apaas_openshift_cookbook']['openshift_common_base_dir']` -  Defaults to `/etc/origin`.
* `node['is_apaas_openshift_cookbook']['openshift_common_master_dir']` -  Defaults to `/etc/origin`.
* `node['is_apaas_openshift_cookbook']['openshift_common_node_dir']` -  Defaults to `/etc/origin`.
* `node['is_apaas_openshift_cookbook']['openshift_common_portal_net']` -  Defaults to `172.30.0.0/16`.
* `node['is_apaas_openshift_cookbook']['openshift_common_first_svc_ip']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_common_portal_net'].split('/')[0].gsub(/\.0$/, '.1')`.
* `node['is_apaas_openshift_cookbook']['openshift_common_default_nodeSelector']` -  Defaults to `region=user`.
* `node['is_apaas_openshift_cookbook']['openshift_common_examples_base']` -  Defaults to `/usr/share/openshift/examples`.
* `node['is_apaas_openshift_cookbook']['openshift_common_hosted_base']` -  Defaults to `/usr/share/openshift/hosted`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_type']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'enterprise' : 'origin`.
* `node['is_apaas_openshift_cookbook']['openshift_base_images']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'image-streams-rhel7.json' : 'image-streams-centos7.json`.
* `node['is_apaas_openshift_cookbook']['openshift_common_hostname']` -  Defaults to `node['fqdn']`.
* `node['is_apaas_openshift_cookbook']['openshift_common_ip']` -  Defaults to `node['ipaddress']`.
* `node['is_apaas_openshift_cookbook']['openshift_common_public_ip']` -  Defaults to `node['ipaddress']`.
* `node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']` -  Defaults to `node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? '/usr/local/bin/oadm' : '/usr/bin/oadm`.
* `node['is_apaas_openshift_cookbook']['openshift_common_client_binary']` -  Defaults to `node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? '/usr/local/bin/oc' : '/usr/bin/oc`.
* `node['is_apaas_openshift_cookbook']['openshift_common_service_accounts']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_common_service_accounts_additional']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_common_use_openshift_sdn']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_common_sdn_network_plugin_name']` -  Defaults to `redhat/openshift-ovs-subnet`.
* `node['is_apaas_openshift_cookbook']['openshift_common_svc_names']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_common_registry_url']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-${component}:${version}' : 'openshift/origin-${component}:${version}`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_insecure_registry_arg']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_add_registry_arg']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_block_registry_arg']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_insecure_registries']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_docker_add_registry_arg'].empty? ? [node['is_apaas_openshift_cookbook']['openshift_common_portal_net']] : [node['is_apaas_openshift_cookbook']['openshift_common_portal_net']] + node['is_apaas_openshift_cookbook']['openshift_docker_insecure_registry_arg']`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_image_version']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'v3.7' : 'v3.7.0`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_master_image']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_node_image']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/node' : 'openshift/node`.
* `node['is_apaas_openshift_cookbook']['openshift_docker_ovs_image']` -  Defaults to `node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/openvswitch' : 'openshift/openvswitch`.
* `node['is_apaas_openshift_cookbook']['openshift_master_config_dir']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/master`.
* `node['is_apaas_openshift_cookbook']['openshift_master_external_ip_network_cidrs']` -  Defaults to `[0.0.0.0/0]`.
* `node['is_apaas_openshift_cookbook']['openshift_master_ingress_ip_network_cidr']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_master_bind_addr']` -  Defaults to `0.0.0.0`.
* `node['is_apaas_openshift_cookbook']['openshift_master_auditconfig']['enable']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['openshift_master_auditconfig']['audit-file']` - Default to `nil`
* `node['is_apaas_openshift_cookbook']['openshift_master_auditconfig']['max-retention-day']` - Default to `nil`
* `node['is_apaas_openshift_cookbook']['openshift_master_auditconfig']['max-file-size']` - Default to `nil`
* `node['is_apaas_openshift_cookbook']['openshift_master_auditconfig']['max-file-number']` - Default to `nil`
* `node['is_apaas_openshift_cookbook']['openshift_master_api_port']` -  Defaults to `8443`.
* `node['is_apaas_openshift_cookbook']['openshift_master_console_port']` -  Defaults to `8443`.
* `node['is_apaas_openshift_cookbook']['openshift_lb_port']` -  Defaults to `8443`.
* `node['is_apaas_openshift_cookbook']['openshift_master_controllers_port']` -  Defaults to `8444`.
* `node['is_apaas_openshift_cookbook']['openshift_master_controller_lease_ttl']` -  Defaults to `30`.
* `node['is_apaas_openshift_cookbook']['openshift_master_dynamic_provisioning_enabled']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_master_disabled_features']` -  Defaults to `['Builder', 'S2IBuilder', 'WebConsole']`.
* `node['is_apaas_openshift_cookbook']['openshift_master_embedded_dns']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_master_embedded_kube']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_master_debug_level']` -  Defaults to `2`.
* `node['is_apaas_openshift_cookbook']['openshift_master_dns_port']` -  Defaults to `node['is_apaas_openshift_cookbook']['deploy_dnsmasq'] == true ? '8053' : '53`.
* `node['is_apaas_openshift_cookbook']['openshift_master_metrics_public_url']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_master_image_bulk_imported']` -  Defaults to `5`.
* `node['is_apaas_openshift_cookbook']['openshift_master_deserialization_cache_size']` - Defaults to `50000` (for small deployments a value of `1000` may be more appropriate).
* `node['is_apaas_openshift_cookbook']['openshift_master_pod_eviction_timeout']` -  Defaults to ``.
* `node['is_apaas_openshift_cookbook']['openshift_master_min_tls_version']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_master_cipher_suites']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_master_project_request_message']` -  Defaults to ``.
* `node['is_apaas_openshift_cookbook']['openshift_master_project_request_template']` -  Defaults to ``.
* `node['is_apaas_openshift_cookbook']['openshift_master_logging_public_url']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_master_router_subdomain']` -  Defaults to `cloudapps.domain.local`.
* `node['is_apaas_openshift_cookbook']['openshift_master_sdn_cluster_network_cidr']` -  Defaults to `10.1.0.0/16`.
* `node['is_apaas_openshift_cookbook']['openshift_master_sdn_host_subnet_length']` -  Defaults to `9`.
* `node['is_apaas_openshift_cookbook']['openshift_master_oauth_grant_method']` -  Defaults to `auto`.
* `node['is_apaas_openshift_cookbook']['openshift_master_session_max_seconds']` -  Defaults to `3600`.
* `node['is_apaas_openshift_cookbook']['openshift_master_session_name']` -  Defaults to `ssn`.
* `node['is_apaas_openshift_cookbook']['openshift_master_session_secrets_file']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/session-secrets.yaml`.
* `node['is_apaas_openshift_cookbook']['openshift_master_access_token_max_seconds']` -  Defaults to `86400`.
* `node['is_apaas_openshift_cookbook']['openshift_master_auth_token_max_seconds']` -  Defaults to `500`.
* `node['is_apaas_openshift_cookbook']['openshift_master_public_api_url']` -  Defaults to `https://#{node['is_apaas_openshift_cookbook']['openshift_common_public_hostname']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}`.
* `node['is_apaas_openshift_cookbook']['openshift_master_api_url']` -  Defaults to `https://#{node['is_apaas_openshift_cookbook']['openshift_common_api_hostname']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}`.
* `node['is_apaas_openshift_cookbook']['openshift_master_loopback_api_url']` -  Defaults to `https://#{node['fqdn']}:#{node['is_apaas_openshift_cookbook']['openshift_master_api_port']}`.
* `node['is_apaas_openshift_cookbook']['openshift_master_console_url']` -  Defaults to `https://#{node['is_apaas_openshift_cookbook']['openshift_common_public_hostname']}:#{node['is_apaas_openshift_cookbook']['openshift_master_console_port']}/console`.
* `node['is_apaas_openshift_cookbook']['openshift_master_policy']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/policy.json`.
* `node['is_apaas_openshift_cookbook']['openshift_master_config_file']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/master-config.yaml`.
* `node['is_apaas_openshift_cookbook']['openshift_master_api_sysconfig']` -  Defaults to `/etc/sysconfig/#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-master-api`.
* `node['is_apaas_openshift_cookbook']['openshift_master_api_systemd']` -  Defaults to `/usr/lib/systemd/system/#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-master-api.service`.
* `node['is_apaas_openshift_cookbook']['openshift_master_controllers_sysconfig']` -  Defaults to `/etc/sysconfig/#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-master-controllers`.
* `node['is_apaas_openshift_cookbook']['openshift_master_controllers_systemd']` -  Defaults to `/usr/lib/systemd/system/#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-master-controllers.service`.
* `node['is_apaas_openshift_cookbook']['openshift_master_ca_certificate']` -  Defaults to `{ 'data_bag_name' => nil, 'data_bag_item_name' => nil, 'secret_file' => nil }`.
* `node['is_apaas_openshift_cookbook']['openshift_master_named_certificates']` -  Defaults to `%w()`.
* `node['is_apaas_openshift_cookbook']['openshift_master_scheduler_conf']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/scheduler.json`.
* `node['is_apaas_openshift_cookbook']['openshift_master_managed_names_additional']` -  Defaults to `%w()`.
* `node['is_apaas_openshift_cookbook']['openshift_master_retain_events']` default to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_master_api_server_args_custom']` default to `{}`.
* `node['is_apaas_openshift_cookbook']['openshift_master_controller_args_custom']` default to `{}`.
* `node['is_apaas_openshift_cookbook']['openshift_node_config_dir']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_common_node_dir']}/node`.
* `node['is_apaas_openshift_cookbook']['openshift_node_config_file']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_node_config_dir']}/node-config.yaml`.
* `node['is_apaas_openshift_cookbook']['openshift_node_min_tls_version']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_node_cipher_suites']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_node_debug_level']` -  Defaults to `2`.
* `node['is_apaas_openshift_cookbook']['openshift_node_docker-storage']` -  Defaults to `{ ... }`.
* `node['is_apaas_openshift_cookbook']['openshift_node_generated_configs_dir']` -  Defaults to `/var/www/html/node/generated-configs`.
* `node['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_default']` default to `{ 'max-pods' => '250', 'image-gc-high-threshold' => '90', 'image-gc-low-threshold' => '80' }`.
* `node['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_custom']` default to `{}`.
* `node['is_apaas_openshift_cookbook']['openshift_node_iptables_sync_period']` -  Defaults to `5s`.
* `node['is_apaas_openshift_cookbook']['openshift_node_max_pod']` -  Defaults to `40`. (Deprecated use `openshift_node_kubelet_args_custom`)
* `node['is_apaas_openshift_cookbook']['openshift_node_sdn_mtu_sdn']` -  Defaults to `1450`.
* `node['is_apaas_openshift_cookbook']['openshift_node_minimum_container_ttl_duration']` -  Defaults to `10s`. (Deprecated use `openshift_node_kubelet_args_custom`)
* `node['is_apaas_openshift_cookbook']['openshift_node_maximum_dead_containers_per_container']` -  Defaults to `2`. (Deprecated use `openshift_node_kubelet_args_custom`)
* `node['is_apaas_openshift_cookbook']['openshift_node_maximum_dead_containers']` -  Defaults to `100`. (Deprecated use `openshift_node_kubelet_args_custom`)
* `node['is_apaas_openshift_cookbook']['openshift_node_image_gc_high_threshold']` -  Defaults to `90`. (Deprecated use `openshift_node_kubelet_args_custom`)
* `node['is_apaas_openshift_cookbook']['openshift_node_image_gc_low_threshold']` -  Defaults to `80`. (Deprecated use `openshift_node_kubelet_args_custom`)
* `node['is_apaas_openshift_cookbook']['openshift_node_cadvisor_port']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_node_read_only_port']` -  Defaults to `nil`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_manage_router']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_router_selector']` -  Defaults to `region=infra`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_router_namespace']` -  Defaults to `default`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_router_options']` -  Defaults to `[]`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_manage_registry']` -  Defaults to `true`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_router_certfile']` - Defaults to `"#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-router.crt"`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_router_keyfile']` - Defaults to `"#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/openshift-router.key"`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_registry_selector']` -  Defaults to `region=infra`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_registry_namespace']` -  Defaults to `default`.
* `node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['erb_corsAllowedOrigins']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['master_generated_certs_dir']` -  Defaults to `/var/www/html/master/generated_certs`.
* `node['is_apaas_openshift_cookbook']['etcd_add_additional_nodes']` -  Defaults to `false`.
* `node['is_apaas_openshift_cookbook']['etcd_remove_servers']` -  Defaults to `[...]`.
* `node['is_apaas_openshift_cookbook']['etcd_conf_dir']` -  Defaults to `/etc/etcd`.
* `node['is_apaas_openshift_cookbook']['etcd_ca_dir']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca`.
* `node['is_apaas_openshift_cookbook']['etcd_generated_certs_dir']` -  Defaults to `/var/www/html/etcd/generated_certs`.
* `node['is_apaas_openshift_cookbook']['etcd_ca_cert']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/ca.crt`.
* `node['is_apaas_openshift_cookbook']['etcd_cert_file']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/server.crt`.
* `node['is_apaas_openshift_cookbook']['etcd_cert_key']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/server.key`.
* `node['is_apaas_openshift_cookbook']['etcd_peer_file']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/peer.crt`.
* `node['is_apaas_openshift_cookbook']['etcd_peer_key']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/peer.key`.
* `node['is_apaas_openshift_cookbook']['etcd_openssl_conf']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['etcd_ca_dir']}/openssl.cnf`.
* `node['is_apaas_openshift_cookbook']['etcd_ca_name']` -  Defaults to `etcd_ca`.
* `node['is_apaas_openshift_cookbook']['etcd_req_ext']` -  Defaults to `etcd_v3_req`.
* `node['is_apaas_openshift_cookbook']['etcd_ca_exts_peer']` -  Defaults to `etcd_v3_ca_peer`.
* `node['is_apaas_openshift_cookbook']['etcd_ca_exts_server']` -  Defaults to `etcd_v3_ca_server`.
* `node['is_apaas_openshift_cookbook']['etcd_initial_cluster_state']` -  Defaults to `new`.
* `node['is_apaas_openshift_cookbook']['etcd_initial_cluster_token']` -  Defaults to `etcd-cluster-1`.
* `node['is_apaas_openshift_cookbook']['etcd_data_dir']` -  Defaults to `/var/lib/etcd/`.
* `node['is_apaas_openshift_cookbook']['etcd_default_days']` -  Defaults to `365`.
* `node['is_apaas_openshift_cookbook']['etcd_client_port']` -  Defaults to `2379`.
* `node['is_apaas_openshift_cookbook']['etcd_peer_port']` -  Defaults to `2380`.
* `node['is_apaas_openshift_cookbook']['oauth_Identity']` -  Defaults to `HTPasswdPasswordIdentityProvider`.
* `node['is_apaas_openshift_cookbook']['oauth_Identities']` -  Defaults to `[node['is_apaas_openshift_cookbook']['oauth_Identity']]`.
* `node['is_apaas_openshift_cookbook']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']` -  Defaults to `{ ... }`.
* `node['is_apaas_openshift_cookbook']['openshift_master_identity_provider']['LDAPPasswordIdentityProvider']` -  Defaults to `{ ... }`.
* `node['is_apaas_openshift_cookbook']['openshift_master_identity_provider']['RequestHeaderIdentityProvider']` -  Defaults to `{ ... }`.
* `node['is_apaas_openshift_cookbook']['openshift_master_htpasswd']` -  Defaults to `#{node['is_apaas_openshift_cookbook']['openshift_common_master_dir']}/openshift-passwd`.
* `node['is_apaas_openshift_cookbook']['openshift_master_htpasswd_users']` -  Defaults to `[ ... ]`.
* `node['is_apaas_openshift_cookbook']['encrypted_file_password']`  - Defaults to `{ 'data_bag_name' => nil, 'data_bag_item_name' => nil, 'secret_file' => nil, 'default' => 'defaultpass' }`
* `node['is_apaas_openshift_cookbook']['openshift_cluster_chef_id']` - Defaults to `default`
* `node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']` - Defaults to `nil`

# Recipes

* is_apaas_openshift_cookbook::default - Default recipe
* is_apaas_openshift_cookbook::common - Apply common logic
* is_apaas_openshift_cookbook::master - Configure basic master logic
* is_apaas_openshift_cookbook::master_standalone - Configure standalone master logic
* is_apaas_openshift_cookbook::master_cluster - Configure HA cluster master (Only Native method)
* is_apaas_openshift_cookbook::master_config_post - Configure Post actions for masters
* is_apaas_openshift_cookbook::nodes_certificates - Configure certificates for nodes
* is_apaas_openshift_cookbook::node - Configure node
* is_apaas_openshift_cookbook::etcd_cluster - Configure HA ETCD cluster
* is_apaas_openshift_cookbook::adhoc_uninstall - Adhoc action for uninstalling Openshift from server

# Libraries

* openshift_helper - abstracts node 'duty' identification code

# Resources

* [openshift_create_master](#openshift_create_master)
* [openshift_create_pv](#openshift_create_pv)
* [openshift_delete_host](#openshift_delete_host)
* [openshift_deploy_metrics](#openshift_deploy_metrics)
* [openshift_deploy_registry](#openshift_deploy_registry)
* [openshift_deploy_router](#openshift_deploy_router)
* [openshift_redeploy_certificate](#openshift_redeploy_certificate)


## openshift_create_master

### Actions

- create:  Default action.

### Attribute Parameters

- named_certificate:  Defaults to <code>[]</code>.
- origins:  Defaults to <code>[]</code>.
- standalone_registry:  Defaults to <code>false</code>.
- master_file:  Defaults to <code>nil</code>.
- etcd_servers:  Defaults to <code>[]</code>.
- masters_size:  Defaults to <code>nil</code>.
- openshift_service_type:  Defaults to <code>nil</code>.
- cluster:  Defaults to <code>false</code>.
- cluster_name:  Defaults to <code>nil</code>.

## openshift_create_pv

### Actions

- create:  Default action.

### Attribute Parameters

- persistent_storage:

## openshift_delete_host

### Actions

- delete:  Default action.

## openshift_deploy_metrics

### Actions

- create:  Default action.

### Attribute Parameters

- metrics_params:

## openshift_deploy_registry

### Actions

- create:  Default action.

### Attribute Parameters

- persistent_registry: whether to enable registry persistence or not.
- persistent_volume_claim_name: name of persist volume claim to use for registry storage

## openshift_deploy_router

### Actions

- create:  Default action.

### Attribute Parameters

- none (for now)

## openshift_redeploy_certificate

### Actions

- redeploy:  Default action.

# License and Maintainer

Maintainer:: The Authors (<wburton@redhat.com>)
Source:: https://github.com/IshentRas/is_apaas_openshift_cookbook
Issues:: https://github.com/IshentRas/is_apaas_openshift_cookbook/issues

