default['is_apaas_openshift_cookbook']['openshift_hosted_logging_flag'] = '/usr/local/share/info/.logging'
default['is_apaas_openshift_cookbook']['openshift_logging_install_eventrouter'] = false
default['is_apaas_openshift_cookbook']['openshift_logging_image_prefix'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'registry.access.redhat.com/openshift3/' : 'docker.io/openshift/origin-'
default['is_apaas_openshift_cookbook']['openshift_logging_proxy_image_prefix'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'registry.access.redhat.com/openshift3/' : 'docker.io/openshift/'
default['is_apaas_openshift_cookbook']['openshift_logging_image_version'] = 'v3.10'
default['is_apaas_openshift_cookbook']['openshift_logging_proxy_image_version'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'v3.10' : 'v1.1.0'
default['is_apaas_openshift_cookbook']['openshift_logging_install_logging'] = true

default['is_apaas_openshift_cookbook']['openshift_logging_use_ops'] = false
default['is_apaas_openshift_cookbook']['openshift_logging_master_url'] = 'https://kubernetes.default.svc'
default['is_apaas_openshift_cookbook']['openshift_logging_master_public_url'] = node['is_apaas_openshift_cookbook']['openshift_master_public_api_url']
default['is_apaas_openshift_cookbook']['openshift_logging_namespace'] = 'logging'

default['is_apaas_openshift_cookbook']['openshift_logging_curator_default_days'] = 30
default['is_apaas_openshift_cookbook']['openshift_logging_curator_run_hour'] = 3
default['is_apaas_openshift_cookbook']['openshift_logging_curator_run_minute'] = 30
default['is_apaas_openshift_cookbook']['openshift_logging_curator_run_timezone'] = 'UTC'
default['is_apaas_openshift_cookbook']['openshift_logging_curator_script_log_level'] = 'INFO'
default['is_apaas_openshift_cookbook']['openshift_logging_curator_log_level'] = 'ERROR'
default['is_apaas_openshift_cookbook']['openshift_logging_curator_cpu_limit'] = '100m'
default['is_apaas_openshift_cookbook']['openshift_logging_curator_memory_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_curator_nodeselector'] = {}
default['is_apaas_openshift_cookbook']['openshift_logging_curator_ops_cpu_limit'] = '100m'
default['is_apaas_openshift_cookbook']['openshift_logging_curator_ops_memory_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_curator_ops_nodeselector'] = {}

default['is_apaas_openshift_cookbook']['openshift_logging_kibana_hostname'] = "kibana.#{node['is_apaas_openshift_cookbook']['openshift_master_router_subdomain']}"
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_url'] = "https://#{node['is_apaas_openshift_cookbook']['openshift_logging_kibana_hostname']}"
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_cpu_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_memory_limit'] = '736Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_proxy_debug'] = false
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_proxy_cpu_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_proxy_memory_limit'] = '256Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_replica_count'] = 1
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_edge_term_policy'] = 'Redirect'

default['is_apaas_openshift_cookbook']['openshift_logging_kibana_nodeselector'] = {}
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_nodeselector'] = {}

# The absolute path on the First master to the cert file to use
# for the public facing kibana certs
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_cert'] = ''

# The absolute path on the First master to the key file to use
# for the public facing kibana certs
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_key'] = ''

# The absolute path on the First master to the CA file to use
# for the public facing kibana certs
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ca'] = ''

default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_hostname'] = "kibana-ops.#{node['is_apaas_openshift_cookbook']['openshift_master_router_subdomain']}"
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_cpu_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_memory_limit'] = '736Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_proxy_debug'] = false
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_proxy_cpu_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_proxy_memory_limit'] = '256Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_replica_count'] = 1

# The absolute path on the First master to the cert file to use
# for the public facing ops kibana certs
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_cert'] = ''

# The absolute path on the First master to the key file to use
# for the public facing ops kibana certs
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_key'] = ''

# The absolute path on the First master to the CA file to use
# for the public facing ops kibana certs
default['is_apaas_openshift_cookbook']['openshift_logging_kibana_ops_ca'] = ''

default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_file_buffer_limit'] = '256Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_secure'] = 'no'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_host'] = '${HOSTNAME}'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_cert_path'] = 'none'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_key_path'] = 'none'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_passphrase'] = 'none'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_strict'] = 'no'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_aggregating_port'] = 24_284
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_deployment_type'] = 'hosted'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_nodeselector'] = { 'logging-infra-fluentd' => true }
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_cpu_limit'] = '100m'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_memory_limit'] = '512Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_es_copy'] = 'false'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_use_journal'] = 'false'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_journal_source'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_journal_read_from_head'] = 'false'
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_hosts'] = %w(--all)
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_buffer_queue_limit'] = 1024
default['is_apaas_openshift_cookbook']['openshift_logging_fluentd_buffer_size_limit'] = '1m'

default['is_apaas_openshift_cookbook']['openshift_logging_elasticsearch_prometheus_sa'] = 'system:serviceaccount:openshift-metrics:prometheus'
default['is_apaas_openshift_cookbook']['openshift_logging_elasticsearch_cpu_request'] = '1000m'
default['is_apaas_openshift_cookbook']['openshift_logging_elasticsearch_proxy_memory_limit'] = '64Mi'
default['is_apaas_openshift_cookbook']['openshift_logging_elasticsearch_proxy_cpu_request'] = '100m'
default['is_apaas_openshift_cookbook']['openshift_logging_elasticsearch_kibana_index_mode'] = 'unique'
default['is_apaas_openshift_cookbook']['openshift_logging_elasticsearch_deployment_type'] = 'data-master'
default['is_apaas_openshift_cookbook']['openshift_logging_es_host'] = 'logging-es'
default['is_apaas_openshift_cookbook']['openshift_logging_es_port'] = 9200
default['is_apaas_openshift_cookbook']['openshift_logging_es_ca'] = '/etc/fluent/keys/ca'
default['is_apaas_openshift_cookbook']['openshift_logging_es_client_cert'] = '/etc/fluent/keys/cert'
default['is_apaas_openshift_cookbook']['openshift_logging_es_client_key'] = '/etc/fluent/keys/key'
default['is_apaas_openshift_cookbook']['openshift_logging_es_cluster_size'] = 1
default['is_apaas_openshift_cookbook']['openshift_logging_es_cpu_limit'] = ''
# The logging appenders for the root loggers to write ES logs. Valid values'] = 'file', 'console'
default['is_apaas_openshift_cookbook']['openshift_logging_es_log_appenders'] = %w(file)
default['is_apaas_openshift_cookbook']['openshift_logging_es_memory_limit'] = '8Gi'
default['is_apaas_openshift_cookbook']['openshift_logging_es_number_of_replicas'] = 0
default['is_apaas_openshift_cookbook']['openshift_logging_es_number_of_shards'] = 1
default['is_apaas_openshift_cookbook']['openshift_logging_es_pvc_size'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_es_pvc_prefix'] = 'logging-es'
default['is_apaas_openshift_cookbook']['openshift_logging_es_recover_after_time'] = '5m'
default['is_apaas_openshift_cookbook']['openshift_logging_es_storage_group'] = %w(65534)
default['is_apaas_openshift_cookbook']['openshift_logging_es_nodeselector'] = {}

# Allow cluster-admin or cluster-reader to view operations index
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_allow_cluster_reader'] = 'false'

default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_host'] = 'logging-es-ops'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_port'] = 9200
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_ca'] = '/etc/fluent/keys/ca'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_client_cert'] = '/etc/fluent/keys/cert'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_client_key'] = '/etc/fluent/keys/key'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_cluster_size'] = 1
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_cpu_limit'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_memory_limit'] = '8Gi'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_pvc_size'] = ''
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_pvc_prefix'] = 'logging-es-ops'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_recover_after_time'] = '5m'
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_storage_group'] = %w(65534)
default['is_apaas_openshift_cookbook']['openshift_logging_es_ops_nodeselector'] = {}

# Storage related defaults
default['is_apaas_openshift_cookbook']['openshift_logging_storage_access_modes'] = %w(ReadWriteOnce)
