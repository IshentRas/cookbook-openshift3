default['is_apaas_openshift_cookbook']['openshift_web_console_metrics_public_url'] = node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics'] && node['is_apaas_openshift_cookbook']['openshift_metrics_install_metrics'] ? node['is_apaas_openshift_cookbook']['openshift_metrics_url'] : '""'
default['is_apaas_openshift_cookbook']['openshift_web_console_logging_public_url'] = node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_logging'] && node['is_apaas_openshift_cookbook']['openshift_logging_install_logging'] ? node['is_apaas_openshift_cookbook']['openshift_logging_kibana_url'] : '""'
default['is_apaas_openshift_cookbook']['openshift_web_console_logout_url'] = node['is_apaas_openshift_cookbook']['openshift_master_logout_url'] || '""'
default['is_apaas_openshift_cookbook']['openshift_web_console_extension_script_urls'] = []
default['is_apaas_openshift_cookbook']['openshift_web_console_extension_stylesheet_urls'] = []
default['is_apaas_openshift_cookbook']['openshift_web_console_properties'] = {}
default['is_apaas_openshift_cookbook']['openshift_web_console_inactivity_timeout_minutes'] = 0
default['is_apaas_openshift_cookbook']['openshift_web_console_cluster_resource_overrides_enabled'] = false
default['is_apaas_openshift_cookbook']['openshift_web_console_image'] = node['is_apaas_openshift_cookbook']['openshift_deployment_type'] =~ /enterprise/ ? 'registry.access.redhat.com/openshift3/ose-web-console' : 'docker.io/openshift/origin-web-console'
