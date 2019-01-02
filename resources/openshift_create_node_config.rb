property :node_file, String

provides :openshift_create_node_config

action :create do
  converge_by 'Create Node configuration file' do
    helper = OpenShiftHelper::NodeHelper.new(node)
    group_label = helper.openshift_node_groups
    template "#{Chef::Config[:file_cache_path]}/node-config.yaml" do
      source 'openshift_node/node-config.yaml.erb'
      variables(
        node_labels: node['is_apaas_openshift_cookbook']['openshift_node_groups'].find { |group| group['name'] == group_label }['labels']
      )
    end

    ruby_block 'Prepare Node Configuration YAML' do
      block do
        pre_node = YAML.load_file("#{Chef::Config[:file_cache_path]}/node-config.yaml")
        openshift_node_kubelet_args = node['is_apaas_openshift_cookbook']['openshift_node_groups'].find { |group| group['name'] == group_label }.key?('kubeletArguments') ? node['is_apaas_openshift_cookbook']['openshift_node_groups'].find { |group| group['name'] == group_label }['kubeletArguments'] : {}
        pre_node['kubeletArguments'] = pre_node['kubeletArguments'].merge(openshift_node_kubelet_args.to_hash)

        file new_resource.node_file do
          content pre_node.to_yaml
          owner 'root'
          group 'root'
          mode '0600'
        end
      end
    end
  end
end

action :create_node_groups do
  converge_by 'Build node config maps' do
    node['is_apaas_openshift_cookbook']['openshift_node_groups'].each do |group|
      template "#{Chef::Config[:file_cache_path]}/node-config-#{group['name']}.yaml" do
        source 'openshift_node/node-config.yaml.erb'
        variables(
          node_labels: group['labels']
        )
      end

      ruby_block "Prepare ConfigMap for #{group['name']}" do
        block do
          pre_node = YAML.load_file("#{Chef::Config[:file_cache_path]}/node-config-#{group['name']}.yaml")
          openshift_node_kubelet_args = group.key?('kubeletArguments') ? group['kubeletArguments'] : {}
          pre_node['kubeletArguments'] = pre_node['kubeletArguments'].merge(openshift_node_kubelet_args.to_hash)

          file "#{Chef::Config[:file_cache_path]}/configmap-#{group['name']}.yaml" do
            content pre_node.to_yaml
            owner 'root'
            group 'root'
            mode '0600'
          end
        end
      end

      execute "Create/Amend ConfigMap for #{group['name']}" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create configmap #{group['name']} --from-file=node-config.yaml=#{Chef::Config[:file_cache_path]}/configmap-#{group['name']}.yaml -n ${namespace_nodes} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig --dry-run -o yaml | #{node['is_apaas_openshift_cookbook']['openshift_client_binary']} apply -f - -n ${namespace_nodes} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
        environment(
          'namespace_nodes' => 'openshift-node'
        )
      end
    end
  end
end

action :create_sync do
  converge_by 'Setup automatic node config reconcilation' do
    remote_directory "#{Chef::Config[:file_cache_path]}/sync" do
      source 'openshift_control_plane/sync'
    end

    ruby_block 'Update the image tag for sync' do
      block do
        pre_sync = YAML.load_file("#{Chef::Config[:file_cache_path]}/sync/images.yaml")
        pre_sync['tag']['from']['name'] = "#{node['is_apaas_openshift_cookbook']['openshift_docker_node_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']}"

        file "#{Chef::Config[:file_cache_path]}/sync/sync-images.yaml" do
          content pre_sync.to_yaml
        end
      end
    end

    execute 'Ensure the sync service account can run privileged' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} adm policy add-scc-to-user privileged system:serviceaccount:openshift-node:sync --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get scc privileged --template {{.users}} | grep system:serviceaccount:openshift-node:sync --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Temporary fix until we fix "oc apply" for image stream tags (sync)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} $ACTION -n openshift-node istag node:v3.10 --ignore-not-found --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      environment 'ACTION' => 'delete'
    end

    ruby_block 'Apply the config for sync node config reconcilation' do
      block do
        run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
        Dir.glob("#{Chef::Config[:file_cache_path]}/sync/sync*").grep(/\.(?:yaml)$/).uniq.each do |file|
          action = Chef::Resource::Execute.new(file, run_context)
          action.command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} apply -f #{file} -n openshift-node --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
          action.run_action(:run)
        end
      end
    end
  end
end

action :create_sdn do
  converge_by 'Setup SDN for nodes' do
    remote_directory "#{Chef::Config[:file_cache_path]}/sdn" do
      source 'openshift_control_plane/sdn'
    end

    ruby_block 'Update the image tag for sdn' do
      block do
        pre_sdn = YAML.load_file("#{Chef::Config[:file_cache_path]}/sdn/images.yaml")
        pre_sdn['tag']['from']['name'] = "#{node['is_apaas_openshift_cookbook']['openshift_docker_node_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']}"

        file "#{Chef::Config[:file_cache_path]}/sdn/sdn-images.yaml" do
          content pre_sdn.to_yaml
        end
      end
    end

    execute 'Temporary fix until we fix "oc apply" for image stream tags (sdn)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} $ACTION -n openshift-sdn istag node:v3.10 --ignore-not-found --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      environment 'ACTION' => 'delete'
    end

    ruby_block 'Apply the config for sdn node config' do
      block do
        run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
        Dir.glob("#{Chef::Config[:file_cache_path]}/sdn/sdn*").grep(/\.(?:yaml)$/).uniq.each do |file|
          action = Chef::Resource::Execute.new(file, run_context)
          action.command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} apply -f #{file} -n openshift-sdn --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
          action.run_action(:run)
        end
      end
    end
  end
end

action :create_bootstrap_controller do
  converge_by 'Setup the node bootstrap auto approver' do
    remote_directory "#{Chef::Config[:file_cache_path]}/autoapprover" do
      source 'openshift_control_plane/autoapprover'
    end

    ruby_block 'Update the image tag for autoapprover' do
      block do
        pre_autoapprover = YAML.load_file("#{Chef::Config[:file_cache_path]}/autoapprover/images.yaml")
        pre_autoapprover['tag']['from']['name'] = "#{node['is_apaas_openshift_cookbook']['openshift_docker_node_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']}"

        file "#{Chef::Config[:file_cache_path]}/autoapprover/openshift-bootstrap-images.yaml" do
          content pre_autoapprover.to_yaml
        end
      end
    end

    execute 'Temporary fix until we fix "oc apply" for image stream tags (autoapprover)' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} $ACTION -n openshift-infra istag node:v3.10 --ignore-not-found --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      environment 'ACTION' => 'delete'
    end

    ruby_block 'Apply the config for autoapprover node config' do
      block do
        run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
        Dir.glob("#{Chef::Config[:file_cache_path]}/autoapprover/openshift-bootstrap*").grep(/\.(?:yaml)$/).uniq.each do |file|
          action = Chef::Resource::Execute.new(file, run_context)
          action.command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} apply -f #{file} -n openshift-infra --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
          action.run_action(:run)
        end
      end
    end
  end
end

action :create_kube_service_catalog do
  converge_by 'Setup the Service Catalog' do
    server_info = OpenShiftHelper::NodeHelper.new(node)
    etcd_servers = server_info.etcd_servers

    remote_directory "#{Chef::Config[:file_cache_path]}/service_catalog" do
      source 'openshift_control_plane/service_catalog'
    end

    generated_certs_dir = "#{node['is_apaas_openshift_cookbook']['openshift_common_base_dir']}/service-catalog"

    execute 'Make kube-service-catalog project network global' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} adm pod-network make-projects-global kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      only_if { node['is_apaas_openshift_cookbook']['openshift_common_sdn_network_plugin_name'] == 'redhat/openshift-ovs-multitenant' }
    end

    execute 'Generate signing cert' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} adm ca create-signer-cert \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              --cert=#{generated_certs_dir}/ca.crt \
              --key=#{generated_certs_dir}/ca.key \
              --serial=#{generated_certs_dir}/apiserver.serial.txt \
              --name=service-catalog-signer"
      creates "#{generated_certs_dir}/ca.crt"
    end

    execute 'Generating API Server keys' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} adm ca create-server-cert \
              --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig \
              --hostnames='apiserver.kube-service-catalog.svc,apiserver.kube-service-catalog.svc.cluster.local,apiserver.kube-service-catalog' \
              --cert=#{generated_certs_dir}/apiserver.crt \
              --key=#{generated_certs_dir}/apiserver.key \
              --signer-cert=#{generated_certs_dir}/ca.crt \
              --signer-key=#{generated_certs_dir}/ca.key \
              --signer-serial=#{generated_certs_dir}/apiserver.serial.txt"
      creates "#{generated_certs_dir}/apiserver.crt"
    end

    execute 'Create apiserver-ssl secret' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create secret generic apiserver-ssl --from-file=tls.crt=#{generated_certs_dir}/apiserver.crt --from-file=tls.key=#{generated_certs_dir}/apiserver.key -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get secret apiserver-ssl -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    ruby_block 'Prepare api service' do
      block do
        api_service = YAML.load_file("#{Chef::Config[:file_cache_path]}/service_catalog/servicecatalog.k8s.yaml")
        api_service['spec']['caBundle'] = Base64.strict_encode64(::File.read("#{generated_certs_dir}/ca.crt"))

        file "#{Chef::Config[:file_cache_path]}/service_catalog/servicecatalog.yaml" do
          content api_service.to_yaml
        end
      end
    end

    execute 'Create api service' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/servicecatalog.yaml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get apiservices.apiregistration v1beta1.servicecatalog.k8s.io -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    { 'service-catalog-role-bindings' => 'kube-service-catalog', 'kube-system-service-catalog-role-bindings' => 'kube-system' }.each_pair do |k, v|
      execute "Deploy template #{k} in #{v} namespace" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/#{k} -n #{v} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
        not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get template #{k} -n #{v} --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      end

      execute "Process template #{k} in #{v} namespace" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} process #{k} -n #{v} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | oc apply -f - -n #{v}"
      end
    end

    execute 'Apply Service Catalog cluster roles' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} auth reconcile -f #{Chef::Config[:file_cache_path]}/service_catalog/openshift_catalog_clusterroles.yml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Set SA cluster-role' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} adm policy add-cluster-role-to-user admin system:serviceaccount:kube-service-catalog:default -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get clusterrolebinding admin --template={{.userNames}} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig | grep 'system:serviceaccount:kube-service-catalog:default'"
    end

    template "#{Chef::Config[:file_cache_path]}/service_catalog/service_catalog_api_server.yml" do
      source 'openshift_control_plane/service_catalog/api_server.erb'
      variables(
        lazy do
          {
            cors_allowed_origin: 'localhost',
            etcd_servers: etcd_servers.map { |srv| "https://#{srv['ipaddress']}:2379" }.join(','),
            ca_hash: Digest::SHA1.file("#{generated_certs_dir}/ca.crt").hexdigest,
            etcd_cafile: ::File.exist?('/etc/origin/master/master.etcd-ca.crt') ? '/etc/origin/master/master.etcd-ca.crt' : '/etc/origin/master/ca-bundle.crt',
            openshift_service_catalog_image: "#{node['is_apaas_openshift_cookbook']['openshift_service_catalog_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']}"
          }
        end
      )
    end

    execute 'Set Service Catalog API Server daemonset' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/service_catalog_api_server.yml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get ds apiserver -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Set Service Catalog API Server service' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/apiserver-service.yaml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get svc apiserver -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Set Service Catalog API Server route' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/service_catalog_api_route.yml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get route apiserver -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    template "#{Chef::Config[:file_cache_path]}/service_catalog/controller_manager.yml" do
      source 'openshift_control_plane/service_catalog/controller_manager.erb'
      variables(
        openshift_service_catalog_image: "#{node['is_apaas_openshift_cookbook']['openshift_service_catalog_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']}"
      )
    end

    execute 'Set Controller Manager deployment' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/controller_manager.yml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get ds controller-manager -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Set Controller Manager service' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create -f #{Chef::Config[:file_cache_path]}/service_catalog/controller-service.yaml -n kube-service-catalog --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get svc controller-manager -n kube-service-catalog --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end
  end
end

action :create_template_service_broker do
  converge_by 'Setup the Template broker' do
    remote_directory "#{Chef::Config[:file_cache_path]}/template_service_broker" do
      source 'openshift_control_plane/template_service_broker'
    end

    execute 'Create API_SERVER_CONFIG ConfigMap for TSB' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} create configmap apiserver-config --from-file=#{Chef::Config[:file_cache_path]}/template_service_broker/apiserver-config.yaml -n openshift-template-service-broker --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      not_if "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} get cm apiserver-config -n openshift-template-service-broker --no-headers --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Apply template file for TSB' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} process -f #{Chef::Config[:file_cache_path]}/template_service_broker/apiserver-template.yaml -p IMAGE='#{node['is_apaas_openshift_cookbook']['template_service_broker_image']}:#{node['is_apaas_openshift_cookbook']['openshift_docker_image_version']}' --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift-template-service-broker | oc apply -f -"
    end

    execute 'Reconcile with RBAC file for TSB' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} process -f #{Chef::Config[:file_cache_path]}/template_service_broker/rbac-template.yaml --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift-template-service-broker | oc apply -f -"
    end

    execute 'Wait for TSB API to become available' do
      command '[[ $(curl --silent https://apiserver.openshift-template-service-broker.svc/healthz --cacert /etc/origin/master/service-signer.crt) =~ "ok" ]]'
      environment 'no_proxy' => 'apiserver.openshift-template-service-broker.svc'
      retries 60
      retry_delay 2
    end

    execute 'Register TSB with broker' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_client_binary']} process -f #{Chef::Config[:file_cache_path]}/template_service_broker/template-service-broker-registration.yaml -p CA_BUNDLE=${ca_bundle} --config=#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig -n openshift-template-service-broker | oc apply -f -"
      environment 'ca_bundle' => Base64.strict_encode64(::File.read('/etc/origin/master/service-signer.crt'))
    end
  end
end
