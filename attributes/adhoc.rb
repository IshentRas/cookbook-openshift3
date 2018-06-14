default['cookbook-openshift3']['openshift_adhoc_reboot_node'] = false

default['cookbook-openshift3']['adhoc_redeploy_certificates'] = false
default['cookbook-openshift3']['adhoc_redeploy_etcd_ca'] = false
default['cookbook-openshift3']['adhoc_redeploy_cluster_ca'] = false

default['cookbook-openshift3']['redeploy_etcd_ca_control_flag'] = '/to_be_replaced_ca_etcd'
default['cookbook-openshift3']['redeploy_etcd_certs_control_flag'] = '/to_be_replaced_certs'

default['cookbook-openshift3']['redeploy_cluster_ca_certserver_control_flag'] = '/to_be_replaced_ca_cluster'
default['cookbook-openshift3']['redeploy_cluster_ca_masters_control_flag'] = '/to_be_replaced_masters'
default['cookbook-openshift3']['redeploy_cluster_ca_nodes_control_flag'] = '/to_be_replaced_nodes'
default['cookbook-openshift3']['redeploy_cluster_hosted_certserver_control_flag'] = '/to_be_replaced_hosted_cluster'

default['cookbook-openshift3']['adhoc_reset_control_flag'] = '/to_be_reset_node'

default['cookbook-openshift3']['adhoc_turn_off_openshift3_cookbook'] = '/to_be_replaced_turn_off_openshift3_cookbook'
