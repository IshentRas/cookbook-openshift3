property :version, String
property :options, String
property :docker_version, String

provides :openshift_master_pkg
default_action :install

action :install do
  server_info = OpenShiftHelper::NodeHelper.new(node)
  is_certificate_server = server_info.on_certificate_server?
  first_master = server_info.first_master
  docker_version = new_resource.docker_version.nil? ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : new_resource.docker_version
  ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

  if node['is_apaas_openshift_cookbook']['deploy_containerized']
    docker_image node['is_apaas_openshift_cookbook']['openshift_docker_master_image'] do
      tag docker_version
      action :pull_if_missing
    end

    bash 'Add CLI to master(s)' do
      code <<-BASH
        docker create --name temp-cli ${DOCKER_IMAGE}:${DOCKER_TAG}
        docker cp temp-cli:/usr/bin/${ORIGIN} /usr/local/bin/${ORIGIN}
        docker rm temp-cli
      BASH
      environment(
        'DOCKER_IMAGE' => node['is_apaas_openshift_cookbook']['openshift_docker_master_image'],
        'DOCKER_TAG' => node['is_apaas_openshift_cookbook']['openshift_docker_image_version'],
        'ORIGIN' => ose_major_version.split('.')[1].to_i < 6 ? 'openshift' : 'oc'
      )
      not_if { ::File.exist?('/usr/local/bin/openshift') && !node['is_apaas_openshift_cookbook']['upgrade'] }
    end

    if ose_major_version.split('.')[1].to_i < 6
      %w[oadm oc kubectl].each do |client_symlink|
        link "/usr/local/bin/#{client_symlink}" do
          to '/usr/local/bin/openshift'
          link_type :hard
        end
      end
    else
      %w[oadm kubectl].each do |client_symlink|
        link "/usr/local/bin/#{client_symlink}" do
          to '/usr/local/bin/oc'
          link_type :hard
        end
      end
    end

    execute 'Add bash completion for oc' do
      command '/usr/local/bin/oc completion bash > /etc/bash_completion.d/oc'
      not_if { ::File.exist?('/etc/bash_completion.d/oc') && !node['is_apaas_openshift_cookbook']['upgrade'] }
    end
  end

  if node['is_apaas_openshift_cookbook']['ose_major_version'].split('.')[1].to_i < 10
    yum_package "#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-master" do
      action :install
      version new_resource.version.nil? ? node['is_apaas_openshift_cookbook']['ose_version'] : new_resource.version unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
      options new_resource.options.nil? ? node['is_apaas_openshift_cookbook']['openshift_yum_options'] : new_resource.options
      notifies :run, 'execute[daemon-reload]', :immediately
      not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] || (is_certificate_server && node['fqdn'] != first_master['fqdn']) }
      retries 3
    end

    yum_package "#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-clients" do
      action :install
      version new_resource.version.nil? ? node['is_apaas_openshift_cookbook']['ose_version'] : new_resource.version unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
      options new_resource.options.nil? ? node['is_apaas_openshift_cookbook']['openshift_yum_options'] : new_resource.options
      not_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
      retries 3
    end
  else
    yum_package "#{node['is_apaas_openshift_cookbook']['openshift_service_type']}-clients" do
      action :install
      version new_resource.version.nil? ? node['is_apaas_openshift_cookbook']['ose_version'] : new_resource.version unless node['is_apaas_openshift_cookbook']['ose_version'].nil?
      options new_resource.options.nil? ? node['is_apaas_openshift_cookbook']['openshift_yum_options'] : new_resource.options
    end
  end
end
