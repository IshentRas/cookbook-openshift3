if node['is_apaas_openshift_cookbook']['control_upgrade']
  default['is_apaas_openshift_cookbook']['control_upgrade_version'] = ''
  default['is_apaas_openshift_cookbook']['control_upgrade_flag'] = '/to_be_replaced'
  default['is_apaas_openshift_cookbook']['etcd_migrated'] = true

  if node['is_apaas_openshift_cookbook']['openshift_deployment_type'] == 'enterprise'
    case node['is_apaas_openshift_cookbook']['control_upgrade_version']
    when '14'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '3.4'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '3.4.1.44.38-1.git.0.d04b8d5.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v3.4.1.44.38'
    when '15'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '3.5'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '3.5.5.31.48-1.git.0.245c039.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v3.5.5.31.48'
    when '36'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '3.6'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '3.6.173.0.96-1.git.0.8f6ff22.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v3.6.173.0.96'
    when '37'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '3.7'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '3.7.23-1.git.0.8edc154.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v3.7.23'
    end
  else
    case node['is_apaas_openshift_cookbook']['control_upgrade_version']
    when '14'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '1.4'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '1.4.1-1.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v1.4.1'
    when '15'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '1.5'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '1.5.1-1.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v1.5.1'
    when '36'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '3.6'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '3.6.1-1.0.008f2d5'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v3.6.1'
    when '37'
      default['is_apaas_openshift_cookbook']['upgrade_ose_major_version'] = '3.7'
      default['is_apaas_openshift_cookbook']['upgrade_ose_version'] = '3.7.1-2.el7'
      default['is_apaas_openshift_cookbook']['upgrade_openshift_docker_image_version'] = 'v3.7.2'
    end
  end
end
