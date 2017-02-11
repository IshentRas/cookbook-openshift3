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

* `node['cookbook-openshift3']['openshift_adhoc_reboot_node']` -  Defaults to `false`.
* `node['cookbook-openshift3']['openshift_master_asset_config']` -  Defaults to `nil`.
* `node['cookbook-openshift3']['use_wildcard_nodes']` -  Defaults to `false`.
* `node['cookbook-openshift3']['wildcard_domain']` -  Defaults to ``.
* `node['cookbook-openshift3']['openshift_cluster_name']` -  Defaults to `nil`.
* `node['cookbook-openshift3']['openshift_HA']` -  Defaults to `false`.
* `node['cookbook-openshift3']['master_servers']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['etcd_servers']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['node_servers']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_common_public_hostname']` -  Defaults to `node['fqdn']`.
* `node['cookbook-openshift3']['openshift_master_embedded_etcd']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_master_etcd_port']` -  Defaults to `4001`.
* `node['cookbook-openshift3']['master_etcd_cert_prefix']` -  Defaults to ``.
* `node['cookbook-openshift3']['ose_version']` -  Defaults to `nil`.
* `node['cookbook-openshift3']['persistent_storage']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_deployment_type']` -  Defaults to `enterprise`.
* `node['cookbook-openshift3']['ose_major_version']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? '3.4' : '1.4`.
* `node['cookbook-openshift3']['deploy_containerized']` -  Defaults to `false`.
* `node['cookbook-openshift3']['deploy_example']` -  Defaults to `false`.
* `node['cookbook-openshift3']['deploy_dnsmasq']` -  Defaults to `false`.
* `node['cookbook-openshift3']['deploy_standalone_registry']` -  Defaults to `false`.
* `node['cookbook-openshift3']['deploy_example_db_templates']` -  Defaults to `true`.
* `node['cookbook-openshift3']['deploy_example_image-streams']` -  Defaults to `true`.
* `node['cookbook-openshift3']['deploy_example_quickstart-templates']` -  Defaults to `false`.
* `node['cookbook-openshift3']['deploy_example_xpaas-streams']` -  Defaults to `false`.
* `node['cookbook-openshift3']['deploy_example_xpaas-templates']` -  Defaults to `false`.
* `node['cookbook-openshift3']['docker_version']` -  Defaults to `nil`.
* `node['cookbook-openshift3']['docker_log_driver']` -  Defaults to `json-file`.
* `node['cookbook-openshift3']['docker_log_options']` -  Defaults to `{ ... }`.
* `node['cookbook-openshift3']['install_method']` -  Defaults to `yum`.
* `node['cookbook-openshift3']['httpd_xfer_port']` -  Defaults to `9999`.
* `node['cookbook-openshift3']['core_packages']` -  Defaults to `%w(libselinux-python wget vim-enhanced net-tools bind-utils git bash-completion bash-completion dnsmasq)`.
* `node['cookbook-openshift3']['osn_cluster_dns_domain']` -  Defaults to `cluster.local`.
* `node['cookbook-openshift3']['enabled_firewall_rules_master']` -  Defaults to `%w(firewall_master)`.
* `node['cookbook-openshift3']['enabled_firewall_rules_master_cluster']` -  Defaults to `%w(firewall_master_cluster)`.
* `node['cookbook-openshift3']['enabled_firewall_rules_node']` -  Defaults to `%w(firewall_node)`.
* `node['cookbook-openshift3']['enabled_firewall_additional_rules_node']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['enabled_firewall_rules_etcd']` -  Defaults to `%w(firewall_etcd)`.
* `node['cookbook-openshift3']['openshift_service_type']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'atomic-openshift' : 'origin`.
* `node['cookbook-openshift3']['registry_persistent_volume']` -  Defaults to ``.
* `node['cookbook-openshift3']['yum_repositories']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? %w() : [{ 'name' => 'centos-openshift-origin', 'baseurl' => 'http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/', 'gpgcheck' => false }]`.
* `node['cookbook-openshift3']['openshift_data_dir']` -  Defaults to `/var/lib/origin`.
* `node['cookbook-openshift3']['openshift_common_base_dir']` -  Defaults to `/etc/origin`.
* `node['cookbook-openshift3']['openshift_common_master_dir']` -  Defaults to `/etc/origin`.
* `node['cookbook-openshift3']['openshift_common_node_dir']` -  Defaults to `/etc/origin`.
* `node['cookbook-openshift3']['openshift_common_portal_net']` -  Defaults to `172.30.0.0/16`.
* `node['cookbook-openshift3']['openshift_common_first_svc_ip']` -  Defaults to `node['cookbook-openshift3']['openshift_common_portal_net'].split('/')[0].gsub(/\.0$/, '.1')`.
* `node['cookbook-openshift3']['openshift_common_default_nodeSelector']` -  Defaults to `region=user`.
* `node['cookbook-openshift3']['openshift_common_examples_base']` -  Defaults to `/usr/share/openshift/examples`.
* `node['cookbook-openshift3']['openshift_common_hosted_base']` -  Defaults to `/usr/share/openshift/hosted`.
* `node['cookbook-openshift3']['openshift_hosted_type']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'enterprise' : 'origin`.
* `node['cookbook-openshift3']['openshift_base_images']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'image-streams-rhel7.json' : 'image-streams-centos7.json`.
* `node['cookbook-openshift3']['openshift_common_hostname']` -  Defaults to `node['fqdn']`.
* `node['cookbook-openshift3']['openshift_common_ip']` -  Defaults to `node['ipaddress']`.
* `node['cookbook-openshift3']['openshift_common_public_ip']` -  Defaults to `node['ipaddress']`.
* `node['cookbook-openshift3']['openshift_common_admin_binary']` -  Defaults to `node['cookbook-openshift3']['deploy_containerized'] == true ? '/usr/local/bin/oadm' : '/usr/bin/oadm`.
* `node['cookbook-openshift3']['openshift_common_client_binary']` -  Defaults to `node['cookbook-openshift3']['deploy_containerized'] == true ? '/usr/local/bin/oc' : '/usr/bin/oc`.
* `node['cookbook-openshift3']['openshift_common_service_accounts']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_common_service_accounts_additional']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_common_use_openshift_sdn']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_common_sdn_network_plugin_name']` -  Defaults to `redhat/openshift-ovs-subnet`.
* `node['cookbook-openshift3']['openshift_common_svc_names']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_common_registry_url']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose-${component}:${version}' : 'openshift/origin-${component}:${version}`.
* `node['cookbook-openshift3']['openshift_docker_insecure_registry_arg']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_docker_add_registry_arg']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_docker_block_registry_arg']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['openshift_docker_insecure_registries']` -  Defaults to `node['cookbook-openshift3']['openshift_docker_add_registry_arg'].empty? ? [node['cookbook-openshift3']['openshift_common_portal_net']] : [node['cookbook-openshift3']['openshift_common_portal_net']] + node['cookbook-openshift3']['openshift_docker_insecure_registry_arg']`.
* `node['cookbook-openshift3']['openshift_docker_image_version']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'v3.2.0.44' : 'v1.2.0`.
* `node['cookbook-openshift3']['openshift_docker_cli_image']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin`.
* `node['cookbook-openshift3']['openshift_docker_master_image']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/ose' : 'openshift/origin`.
* `node['cookbook-openshift3']['openshift_docker_node_image']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/node' : 'openshift/node`.
* `node['cookbook-openshift3']['openshift_docker_ovs_image']` -  Defaults to `node['cookbook-openshift3']['openshift_deployment_type'] =~ /enterprise/ ? 'openshift3/openvswitch' : 'openshift/openvswitch`.
* `node['cookbook-openshift3']['openshift_master_config_dir']` -  Defaults to `#{node['cookbook-openshift3']['openshift_common_master_dir']}/master`.
* `node['cookbook-openshift3']['openshift_master_bind_addr']` -  Defaults to `0.0.0.0`.
* `node['cookbook-openshift3']['openshift_master_auditconfig']` -  Defaults to `false`.
* `node['cookbook-openshift3']['openshift_master_api_port']` -  Defaults to `8443`.
* `node['cookbook-openshift3']['openshift_master_console_port']` -  Defaults to `8443`.
* `node['cookbook-openshift3']['openshift_master_controllers_port']` -  Defaults to `8444`.
* `node['cookbook-openshift3']['openshift_master_controller_lease_ttl']` -  Defaults to `30`.
* `node['cookbook-openshift3']['openshift_master_dynamic_provisioning_enabled']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_master_disabled_features']` -  Defaults to `['Builder', 'S2IBuilder', 'WebConsole']`.
* `node['cookbook-openshift3']['openshift_master_embedded_dns']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_master_embedded_kube']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_master_debug_level']` -  Defaults to `2`.
* `node['cookbook-openshift3']['openshift_master_dns_port']` -  Defaults to `node['cookbook-openshift3']['deploy_dnsmasq'] == true ? '8053' : '53`.
* `node['cookbook-openshift3']['openshift_master_metrics_public_url']` -  Defaults to `nil`.
* `node['cookbook-openshift3']['openshift_master_image_bulk_imported']` -  Defaults to `5`.
* `node['cookbook-openshift3']['openshift_master_deserialization_cache_size']` - Defaults to `50000` (for small deployments a value of `1000` may be more appropriate).
* `node['cookbook-openshift3']['openshift_master_pod_eviction_timeout']` -  Defaults to ``.
* `node['cookbook-openshift3']['openshift_master_project_request_message']` -  Defaults to ``.
* `node['cookbook-openshift3']['openshift_master_project_request_template']` -  Defaults to ``.
* `node['cookbook-openshift3']['openshift_master_logging_public_url']` -  Defaults to `nil`.
* `node['cookbook-openshift3']['openshift_master_router_subdomain']` -  Defaults to `cloudapps.domain.local`.
* `node['cookbook-openshift3']['openshift_master_sdn_cluster_network_cidr']` -  Defaults to `10.1.0.0/16`.
* `node['cookbook-openshift3']['openshift_master_sdn_host_subnet_length']` -  Defaults to `8`.
* `node['cookbook-openshift3']['openshift_master_oauth_grant_method']` -  Defaults to `auto`.
* `node['cookbook-openshift3']['openshift_master_session_max_seconds']` -  Defaults to `3600`.
* `node['cookbook-openshift3']['openshift_master_session_name']` -  Defaults to `ssn`.
* `node['cookbook-openshift3']['openshift_master_session_secrets_file']` -  Defaults to `#{node['cookbook-openshift3']['openshift_master_config_dir']}/session-secrets.yaml`.
* `node['cookbook-openshift3']['openshift_master_access_token_max_seconds']` -  Defaults to `86400`.
* `node['cookbook-openshift3']['openshift_master_auth_token_max_seconds']` -  Defaults to `500`.
* `node['cookbook-openshift3']['openshift_master_public_api_url']` -  Defaults to `https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']}`.
* `node['cookbook-openshift3']['openshift_master_api_url']` -  Defaults to `https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_api_port']}`.
* `node['cookbook-openshift3']['openshift_master_loopback_api_url']` -  Defaults to `https://#{node['fqdn']}:#{node['cookbook-openshift3']['openshift_master_api_port']}`.
* `node['cookbook-openshift3']['openshift_master_console_url']` -  Defaults to `https://#{node['cookbook-openshift3']['openshift_common_public_hostname']}:#{node['cookbook-openshift3']['openshift_master_console_port']}/console`.
* `node['cookbook-openshift3']['openshift_master_policy']` -  Defaults to `#{node['cookbook-openshift3']['openshift_master_config_dir']}/policy.json`.
* `node['cookbook-openshift3']['openshift_master_config_file']` -  Defaults to `#{node['cookbook-openshift3']['openshift_master_config_dir']}/master-config.yaml`.
* `node['cookbook-openshift3']['openshift_master_api_sysconfig']` -  Defaults to `/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-api`.
* `node['cookbook-openshift3']['openshift_master_api_systemd']` -  Defaults to `/usr/lib/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-api.service`.
* `node['cookbook-openshift3']['openshift_master_controllers_sysconfig']` -  Defaults to `/etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers`.
* `node['cookbook-openshift3']['openshift_master_controllers_systemd']` -  Defaults to `/usr/lib/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers.service`.
* `node['cookbook-openshift3']['openshift_master_named_certificates']` -  Defaults to `%w()`.
* `node['cookbook-openshift3']['openshift_master_scheduler_conf']` -  Defaults to `#{node['cookbook-openshift3']['openshift_master_config_dir']}/scheduler.json`.
* `node['cookbook-openshift3']['openshift_master_managed_names_additional']` -  Defaults to `%w()`.
* `node['cookbook-openshift3']['openshift_node_config_dir']` -  Defaults to `#{node['cookbook-openshift3']['openshift_common_node_dir']}/node`.
* `node['cookbook-openshift3']['openshift_node_config_file']` -  Defaults to `#{node['cookbook-openshift3']['openshift_node_config_dir']}/node-config.yaml`.
* `node['cookbook-openshift3']['openshift_node_debug_level']` -  Defaults to `2`.
* `node['cookbook-openshift3']['openshift_node_docker-storage']` -  Defaults to `{ ... }`.
* `node['cookbook-openshift3']['openshift_node_generated_configs_dir']` -  Defaults to `/var/www/html/node/generated-configs`.
* `node['cookbook-openshift3']['openshift_node_iptables_sync_period']` -  Defaults to `5s`.
* `node['cookbook-openshift3']['openshift_node_max_pod']` -  Defaults to `40`.
* `node['cookbook-openshift3']['openshift_node_sdn_mtu_sdn']` -  Defaults to `1450`.
* `node['cookbook-openshift3']['openshift_node_minimum_container_ttl_duration']` -  Defaults to `10s`.
* `node['cookbook-openshift3']['openshift_node_maximum_dead_containers_per_container']` -  Defaults to `2`.
* `node['cookbook-openshift3']['openshift_node_maximum_dead_containers']` -  Defaults to `100`.
* `node['cookbook-openshift3']['openshift_node_image_gc_high_threshold']` -  Defaults to `90`.
* `node['cookbook-openshift3']['openshift_node_image_gc_low_threshold']` -  Defaults to `80`.
* `node['cookbook-openshift3']['openshift_hosted_manage_router']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_hosted_router_selector']` -  Defaults to `region=infra`.
* `node['cookbook-openshift3']['openshift_hosted_router_namespace']` -  Defaults to `default`.
* `node['cookbook-openshift3']['openshift_hosted_manage_registry']` -  Defaults to `true`.
* `node['cookbook-openshift3']['openshift_hosted_registry_selector']` -  Defaults to `region=infra`.
* `node['cookbook-openshift3']['openshift_hosted_registry_namespace']` -  Defaults to `default`.
* `node['cookbook-openshift3']['openshift_hosted_cluster_metrics']` -  Defaults to `false`.
* `node['cookbook-openshift3']['openshift_hosted_metrics_secrets']` -  Defaults to ``.
* `node['cookbook-openshift3']['openshift_hosted_metrics_parameters']` -  Defaults to `{ ... }`.
* `node['cookbook-openshift3']['erb_corsAllowedOrigins']` -  Defaults to `[ ... ]`.
* `node['cookbook-openshift3']['master_generated_certs_dir']` -  Defaults to `/var/www/html/master/generated_certs`.
* `node['cookbook-openshift3']['etcd_conf_dir']` -  Defaults to `/etc/etcd`.
* `node['cookbook-openshift3']['etcd_ca_dir']` -  Defaults to `#{node['cookbook-openshift3']['etcd_conf_dir']}/ca`.
* `node['cookbook-openshift3']['etcd_generated_certs_dir']` -  Defaults to `/var/www/html/etcd/generated_certs`.
* `node['cookbook-openshift3']['etcd_ca_cert']` -  Defaults to `#{node['cookbook-openshift3']['etcd_conf_dir']}/ca.crt`.
* `node['cookbook-openshift3']['etcd_cert_file']` -  Defaults to `#{node['cookbook-openshift3']['etcd_conf_dir']}/server.crt`.
* `node['cookbook-openshift3']['etcd_cert_key']` -  Defaults to `#{node['cookbook-openshift3']['etcd_conf_dir']}/server.key`.
* `node['cookbook-openshift3']['etcd_peer_file']` -  Defaults to `#{node['cookbook-openshift3']['etcd_conf_dir']}/peer.crt`.
* `node['cookbook-openshift3']['etcd_peer_key']` -  Defaults to `#{node['cookbook-openshift3']['etcd_conf_dir']}/peer.key`.
* `node['cookbook-openshift3']['etcd_openssl_conf']` -  Defaults to `#{node['cookbook-openshift3']['etcd_ca_dir']}/openssl.cnf`.
* `node['cookbook-openshift3']['etcd_ca_name']` -  Defaults to `etcd_ca`.
* `node['cookbook-openshift3']['etcd_req_ext']` -  Defaults to `etcd_v3_req`.
* `node['cookbook-openshift3']['etcd_ca_exts_peer']` -  Defaults to `etcd_v3_ca_peer`.
* `node['cookbook-openshift3']['etcd_ca_exts_server']` -  Defaults to `etcd_v3_ca_server`.
* `node['cookbook-openshift3']['etcd_initial_cluster_state']` -  Defaults to `new`.
* `node['cookbook-openshift3']['etcd_initial_cluster_token']` -  Defaults to `etcd-cluster-1`.
* `node['cookbook-openshift3']['etcd_data_dir']` -  Defaults to `/var/lib/etcd/`.
* `node['cookbook-openshift3']['etcd_default_days']` -  Defaults to `365`.
* `node['cookbook-openshift3']['etcd_client_port']` -  Defaults to `2379`.
* `node['cookbook-openshift3']['etcd_peer_port']` -  Defaults to `2380`.
* `node['cookbook-openshift3']['oauth_Identity']` -  Defaults to `HTPasswdPasswordIdentityProvider`.
* `node['cookbook-openshift3']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']` -  Defaults to `{ ... }`.
* `node['cookbook-openshift3']['openshift_master_identity_provider']['LDAPPasswordIdentityProvider']` -  Defaults to `{ ... }`.
* `node['cookbook-openshift3']['openshift_master_identity_provider']['RequestHeaderIdentityProvider']` -  Defaults to `{ ... }`.
* `node['cookbook-openshift3']['openshift_master_htpasswd']` -  Defaults to `#{default['cookbook-openshift3']['openshift_common_master_dir']}/openshift-passwd`.
* `node['cookbook-openshift3']['openshift_master_htpasswd_users']` -  Defaults to `[ ... ]`.

# Recipes

* cookbook-openshift3::default - Default recipe
* cookbook-openshift3::common - Apply common logic
* cookbook-openshift3::master - Configure basic master logic
* cookbook-openshift3::master_standalone - Configure standalone master logic
* cookbook-openshift3::master_cluster - Configure HA cluster master (Only Native method)
* cookbook-openshift3::master_config_post - Configure Post actions for masters
* cookbook-openshift3::nodes_certificates - Configure certificates for nodes
* cookbook-openshift3::node - Configure node
* cookbook-openshift3::etcd_cluster - Configure HA ETCD cluster
* cookbook-openshift3::adhoc_uninstall - Adhoc action for uninstalling Openshit from server

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
Source:: https://github.com/IshentRas/cookbook-openshift3
Issues:: https://github.com/IshentRas/cookbook-openshift3/issues

License:: all_rights
