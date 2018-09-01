default['is_apaas_openshift_cookbook']['openshift_adhoc_reboot_node'] = false

default['is_apaas_openshift_cookbook']['adhoc_redeploy_certificates'] = false
default['is_apaas_openshift_cookbook']['adhoc_redeploy_etcd_ca'] = false
default['is_apaas_openshift_cookbook']['adhoc_redeploy_cluster_ca'] = false
default['is_apaas_openshift_cookbook']['adhoc_migrate_etcd_flag'] = '/to_be_migrated_etcd'

default['is_apaas_openshift_cookbook']['redeploy_etcd_ca_control_flag'] = '/to_be_replaced_ca_etcd'
default['is_apaas_openshift_cookbook']['redeploy_etcd_certs_control_flag'] = '/to_be_replaced_certs'

default['is_apaas_openshift_cookbook']['redeploy_cluster_ca_certserver_control_flag'] = '/to_be_replaced_ca_cluster'
default['is_apaas_openshift_cookbook']['redeploy_cluster_ca_masters_control_flag'] = '/to_be_replaced_masters'
default['is_apaas_openshift_cookbook']['redeploy_cluster_ca_nodes_control_flag'] = '/to_be_replaced_nodes'
default['is_apaas_openshift_cookbook']['redeploy_cluster_hosted_certserver_control_flag'] = '/to_be_replaced_hosted_cluster'

default['is_apaas_openshift_cookbook']['adhoc_reset_control_flag'] = '/to_be_reset_node'

default['is_apaas_openshift_cookbook']['adhoc_turn_off_openshift3_cookbook'] = '/to_be_replaced_turn_off_openshift3_cookbook'

default['is_apaas_openshift_cookbook']['adhoc_redeploy_registry_certificates_flag'] = '/to_be_replaced_registry_certificates'
