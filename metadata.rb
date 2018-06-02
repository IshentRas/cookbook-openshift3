name 'cookbook-openshift3'
maintainer 'ENC4U Ltd'
maintainer_email 'wburton@redhat.com'
license 'MIT'
source_url 'https://github.com/IshentRas/cookbook-openshift3'
issues_url 'https://github.com/IshentRas/cookbook-openshift3/issues'
description 'Installs/Configures Openshift 3.x (>= 3.3)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
chef_version '>= 12.4' if respond_to?(:chef_version)
version '2.0.54'
supports 'redhat', '>= 7.1'
supports 'centos', '>= 7.1'

depends 'yum', '>= 5.0'
depends 'iptables', '>= 4.0.0'
depends 'selinux_policy'
depends 'docker', '>= 4.0'

recipe 'cookbook-openshift3::adhoc_migrate_etcd', 'Adhoc action for migrating ETCD from v2 to v3'
recipe 'cookbook-openshift3::adhoc_redeploy_certificates', 'Redeploy certificates'
recipe 'cookbook-openshift3::adhoc_redeploy_cluster_ca', 'Redeploy OpenShift certificates'
recipe 'cookbook-openshift3::adhoc_redeploy_etcd_ca', 'Redeploy ETCD CA certificates'
recipe 'cookbook-openshift3::adhoc_uninstall', 'Adhoc action for uninstalling Openshift from server'
recipe 'cookbook-openshift3::certificate_server', 'Configure the certificate server'
recipe 'cookbook-openshift3::cloud_provider', 'Configure cloud providers'
recipe 'cookbook-openshift3::common', 'Apply common packages'
recipe 'cookbook-openshift3::commons', 'Apply common logic'
recipe 'cookbook-openshift3::default', 'Default recipe'
recipe 'cookbook-openshift3::docker', 'Install/Configure docker service'
recipe 'cookbook-openshift3::etcd_certificates', 'Configure ETCD CA certificate'
recipe 'cookbook-openshift3::etcd_cluster', 'Configure ETCD cluster'
recipe 'cookbook-openshift3::etcd_packages', 'Install/Configure ETCD packages'
recipe 'cookbook-openshift3::excluder', 'Install/Configure the excluder packages'
recipe 'cookbook-openshift3::helper_migrate_certificate_server_cluster', 'Helper for migrating old cert logic to new'
recipe 'cookbook-openshift3::helper_migrate_certificate_server_etcd', 'Helper for migrating old cert logic to new'
recipe 'cookbook-openshift3::master_cluster_ca', 'Configure CA cluster certificate'
recipe 'cookbook-openshift3::master_cluster_certificates', 'Configure Master/Node certificates'
recipe 'cookbook-openshift3::master_cluster', 'Configure HA cluster master (Only Native method)'
recipe 'cookbook-openshift3::master_config_post', 'Configure Post actions for master server'
recipe 'cookbook-openshift3::master_packages', 'Install/Configure Master packages'
recipe 'cookbook-openshift3::master', 'Configure basic master logic'
recipe 'cookbook-openshift3::master_standalone', 'Configure standalone master logic (<= 3.6)'
recipe 'cookbook-openshift3::node', 'Configure node server'
recipe 'cookbook-openshift3::nodes_certificates', 'Configure certificates for nodes'
recipe 'cookbook-openshift3::packages', 'Configure YUM repositories'
recipe 'cookbook-openshift3::services', 'Apply common services'
recipe 'cookbook-openshift3::upgrade_certificate_server', 'Control Upgrade for the certificate server (1.3 to 3.7)'
recipe 'cookbook-openshift3::upgrade_control_plane14', 'Control Upgrade from 1.3 to 1.4 (Control plane)'
recipe 'cookbook-openshift3::upgrade_control_plane15', 'Control Upgrade from 1.4 to 1.5 (Control plane)'
recipe 'cookbook-openshift3::upgrade_control_plane36', 'Control Upgrade from 1.5 to 3.6 (Control plane)'
recipe 'cookbook-openshift3::upgrade_control_plane37_part1', 'Control Upgrade from 3.6 to 3.7 (Control plane)'
recipe 'cookbook-openshift3::upgrade_control_plane37_part2', 'Control Upgrade from 3.6 to 3.7 (Control plane)'
recipe 'cookbook-openshift3::upgrade_control_plane37', 'Control Upgrade from 3.6 to 3.7 (Control plane)'
recipe 'cookbook-openshift3::upgrade_node14', 'Control Upgrade from 1.3 to 1.4 (Node only)'
recipe 'cookbook-openshift3::upgrade_node15', 'Control Upgrade from 1.4 to 1.5 (Node only)'
recipe 'cookbook-openshift3::upgrade_node36', 'Control Upgrade from 1.5 to 3.6 (Node only)'
recipe 'cookbook-openshift3::upgrade_node37', 'Control Upgrade from 3.6 to 3.7 (Node only)'
recipe 'cookbook-openshift3::validate', 'Pre-validation check before installing OpenShift'
recipe 'cookbook-openshift3::wire_aggregator', 'Configure Wire-aggregator for Service Catalog logic (>= 3.6)'
