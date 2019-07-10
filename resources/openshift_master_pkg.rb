property :version, String
property :options, String
property :docker_version, String

provides :openshift_master_pkg
default_action :install

action :install do
  server_info = OpenShiftHelper::NodeHelper.new(node)
  is_certificate_server = server_info.on_certificate_server?
  is_node_server = server_info.on_node_server?
  first_master = server_info.first_master
  docker_version = new_resource.docker_version.nil? ? node['cookbook-openshift3']['openshift_docker_image_version'] : new_resource.docker_version
  ose_major_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']
  pkg_master_to_install = is_node_server ? node['cookbook-openshift3']['pkg_master'] | node['cookbook-openshift3']['pkg_node'] : node['cookbook-openshift3']['pkg_master']
  version = new_resource.version.nil? ? node['cookbook-openshift3']['ose_version'] : new_resource.version

  if node['cookbook-openshift3']['deploy_containerized']
    docker_image node['cookbook-openshift3']['openshift_docker_master_image'] do
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
        'DOCKER_IMAGE' => node['cookbook-openshift3']['openshift_docker_master_image'],
        'DOCKER_TAG' => node['cookbook-openshift3']['openshift_docker_image_version'],
        'ORIGIN' => ose_major_version.split('.')[1].to_i < 6 ? 'openshift' : 'oc'
      )
      not_if { ::File.exist?('/usr/local/bin/openshift') && !node['cookbook-openshift3']['upgrade'] }
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
      not_if { ::File.exist?('/etc/bash_completion.d/oc') && !node['cookbook-openshift3']['upgrade'] }
    end
  end

  if node['cookbook-openshift3']['ose_major_version'].split('.')[1].to_i < 10
    pkg_master_array = pkg_master_to_install.reject { |x| x == "tuned-profiles-#{node['cookbook-openshift3']['openshift_service_type']}-node" && (node['cookbook-openshift3']['ose_major_version'].split('.')[1].to_i >= 9 || node['cookbook-openshift3']['control_upgrade_version'].to_i >= 39) }
    yum_package pkg_master_array do
      action :install
      version Array.new(pkg_master_array.size, version) unless version.nil?
      options new_resource.options.nil? ? node['cookbook-openshift3']['openshift_yum_options'] : new_resource.options
      notifies :run, 'execute[daemon-reload]', :immediately
      not_if { node['cookbook-openshift3']['deploy_containerized'] || (is_certificate_server && node['fqdn'] != first_master['fqdn']) }
      flush_cache [:before]
      retries 3
    end

    if node['cookbook-openshift3']['asynchronous_upgrade']
      log 'Master services (Asynchronous Upgrade)' do
        level :info
        notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately if node['cookbook-openshift3']['openshift_HA']
        notifies :restart, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately if node['cookbook-openshift3']['openshift_HA']
        not_if { ::File.file?("/usr/local/share/info/.upgrade-#{node['cookbook-openshift3']['ose_version']}") }
      end
      file "/usr/local/share/info/.upgrade-#{node['cookbook-openshift3']['ose_version']}" do
        action :create_if_missing
      end
    end

    yum_package "#{node['cookbook-openshift3']['openshift_service_type']}-clients" do
      action :install
      version version unless version.nil?
      options new_resource.options.nil? ? node['cookbook-openshift3']['openshift_yum_options'] : new_resource.options
      not_if { node['cookbook-openshift3']['deploy_containerized'] || (is_certificate_server && node['fqdn'] == first_master['fqdn']) }
      retries 3
    end
  else
    yum_package "#{node['cookbook-openshift3']['openshift_service_type']}-clients" do
      action :install
      version new_resource.version.nil? ? node['cookbook-openshift3']['ose_version'] : new_resource.version unless node['cookbook-openshift3']['ose_version'].nil?
      options new_resource.options.nil? ? node['cookbook-openshift3']['openshift_yum_options'] : new_resource.options
    end
  end
end
