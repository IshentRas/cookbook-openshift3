#
# Cookbook Name:: cookbook-openshift3
# Resources:: openshift_deploy_logging
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_deploy_logging if defined? provides

def whyrun_supported?
  true
end

CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
DC_CHARS = ('0'..'9').to_a + ('a'..'z').to_a

FOLDER = Chef::Config['file_cache_path'] + '/hosted_logging'

def random_password(length = 10)
  CHARS.sort_by { rand }.join[0...length]
end

def encode_file(file)
  Base64.strict_encode64(::File.read(file))
end

def generate_secrets(secret)
  secret_skel = { 'apiVersion' => 'v1', 'kind' => 'Secret', 'metadata' => {}, 'data' => {}, 'type' => 'Opaque' }
  secret_skel['metadata'] = secret['metadata']
  secret_skel['data'] = secret['data']
  open("#{FOLDER}/templates/#{secret['metadata']['name']}.yaml", 'w') { |f| f << secret_skel.to_yaml }
end

def generate_routes(route)
  route_skel = { 'apiVersion' => 'v1', 'kind' => 'Route', 'metadata' => {}, 'spec' => {} }
  route_skel['metadata'] = route['metadata']
  route_skel['spec'] = route['spec']
  open("#{FOLDER}/templates/#{route['metadata']['name']}-route.yaml", 'w') { |f| f << route_skel.to_yaml }
end

def generate_serviceaccounts(serviceaccount)
  serviceaccount_skel = { 'apiVersion' => 'v1', 'kind' => 'ServiceAccount', 'metadata' => {} }
  serviceaccount_skel['metadata'] = serviceaccount['metadata']
  serviceaccount_skel['secrets'] = serviceaccount['secrets'] if serviceaccount.key?('secrets')
  open("#{FOLDER}/templates/#{serviceaccount['metadata']['name']}-serviceaccount.yaml", 'w') { |f| f << serviceaccount_skel.to_yaml }
end

def generate_rolebindings(rolebinding)
  type = rolebinding.key?('cluster') ? 'ClusterRoleBinding' : 'RoleBinding'
  rolebinding_skel = { 'apiVersion' => 'v1', 'kind' => type, 'metadata' => {}, 'roleRef' => {}, 'subjects' => {} }
  rolebinding_skel['metadata'] = rolebinding['metadata']
  rolebinding_skel['roleRef'] = rolebinding['rolerefs']
  rolebinding_skel['subjects'] = rolebinding['subjects']
  open("#{FOLDER}/templates/#{rolebinding['metadata']['name']}-rolebinding.yaml", 'w') { |f| f << rolebinding_skel.to_yaml }
end

def generate_roles(role)
  type = role.key?('cluster') ? 'ClusterRole' : 'Role'
  role_skel = { 'apiVersion' => 'v1', 'kind' => type, 'metadata' => {}, 'rules' => {} }
  role_skel['metadata'] = role['metadata']
  role_skel['rules'] = role['rules']
  open("#{FOLDER}/templates/#{role['metadata']['name']}-role.yaml", 'w') { |f| f << role_skel.to_yaml }
end

def generate_services(service)
  service_skel = { 'apiVersion' => 'v1', 'kind' => 'Service', 'metadata' => {}, 'spec' => {} }
  service_skel['metadata'] = service['metadata']
  service_skel['spec']['ports'] = service['ports']
  service_skel['spec']['selector'] = service['selector']
  service_skel['spec']['clusterIP'] = 'None' if service.key?('headless')
  open("#{FOLDER}/templates/#{service['metadata']['name']}-service.yaml", 'w') { |f| f << service_skel.to_yaml }
end

action :delete do
  converge_by "Uninstalling Logging on #{node['fqdn']}" do
    CERT_FOLDER = node['cookbook-openshift3']['openshift_common_base_dir'] + '/logging'

    directory 'Create temp directory for logging' do
      path FOLDER
      recursive true
    end

    remote_file "#{FOLDER}/admin.kubeconfig" do
      source "file://#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
      sensitive true
    end

    execute 'Remove Fluentd Labels for nodes' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} label node --all ${key}- --config=#{FOLDER}/admin.kubeconfig"
      environment(
        'key' => node['cookbook-openshift3']['openshift_logging_fluentd_nodeselector'].keys.first.to_s
      )
    end

    execute 'Scaling down cluster before deletion (Curator, ES and Kibana)' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} get dc --selector=logging-infra -o name \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} | \
              xargs --no-run-if-empty #{node['cookbook-openshift3']['openshift_common_client_binary']} scale \
              --replicas=0 --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']}"
    end

    execute 'Delete logging api objects' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION dc,rc,svc,routes,templates,daemonset,is --selector=logging-infra \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Delete oauthclient kibana-proxy' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION oauthclient kibana-proxy \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Delete logging secrets' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION secret logging-fluentd logging-elasticsearch logging-kibana logging-kibana-proxy logging-curator \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Delete logging service accounts' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION secret,serviceaccount aggregated-logging-elasticsearch aggregated-logging-kibana aggregated-logging-curator aggregated-logging-fluentd \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Delete logging rolebindings' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION rolebinding logging-elasticsearch-view-role \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Delete logging cluster role bindings' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION rolebinding logging-elasticsearch-view-role \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Delete logging configmaps' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} $ACTION configmap logging-elasticsearch logging-curator logging-fluentd \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} --ignore-not-found=true"
      environment 'ACTION' => 'delete'
    end

    execute 'Remove privileged permissions for fluentd' do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} policy remove-scc-from-user privileged system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-fluentd --config=#{FOLDER}/admin.kubeconfig"
    end

    execute 'Remove cluster-reader permissions for fluentd' do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} policy remove-cluster-role-from-user cluster-reader system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-fluentd --config=#{FOLDER}/admin.kubeconfig"
    end

    directory FOLDER do
      recursive true
      action :delete
    end

    directory CERT_FOLDER do
      recursive true
      action :delete
    end

    file node['cookbook-openshift3']['openshift_hosted_logging_flag'] do
      action :delete
    end
  end
end

action :create do
  converge_by "Deploying Logging on #{node['fqdn']}" do
    ose_major_version = node['cookbook-openshift3']['deploy_containerized'] == true ? node['cookbook-openshift3']['openshift_docker_image_version'] : node['cookbook-openshift3']['ose_major_version']
    FOLDER_LOGGING = if ose_major_version.split('.')[1].to_i < 6
                       'logging_legacy'
                     elsif ose_major_version.split('.')[1].to_i >= 6
                       "logging_3#{ose_major_version.split('.')[1]}"
                     end
    CERT_FOLDER = node['cookbook-openshift3']['openshift_common_base_dir'] + '/logging'
    OAUTH_SECRET = random_password(64)

    package 'java-1.8.0-openjdk-headless'

    directory FOLDER.to_s do
      recursive true
      action :delete
    end

    directory "#{FOLDER}/templates" do
      recursive true
    end

    directory CERT_FOLDER do
      mode '0755'
    end

    cookbook_file "#{FOLDER}/generate-jks.sh" do
      source 'generate-jks.sh'
      mode '0755'
    end

    remote_file "#{FOLDER}/admin.kubeconfig" do
      source "file://#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
      sensitive true
    end

    execute 'Create logging project' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} adm new-project ${namespace} --node-selector='' --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
      environment(
        'namespace' => node['cookbook-openshift3']['openshift_logging_namespace']
      )
      not_if "#{node['cookbook-openshift3']['openshift_common_client_binary']} get project ${namespace} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    template "#{CERT_FOLDER}/signing.conf" do
      source 'signing.conf.erb'
      sensitive true
      variables(
        top_dir: CERT_FOLDER
      )
    end

    template "#{FOLDER}/signing.conf" do
      source 'signing.conf.erb'
      sensitive true
      variables(
        top_dir: FOLDER
      )
    end

    execute 'Generate certificates' do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-signer-cert \
              --config=#{FOLDER}/admin.kubeconfig \
              --key=#{CERT_FOLDER}/ca.key \
              --cert=#{CERT_FOLDER}/ca.crt \
              --serial=#{CERT_FOLDER}/ca.serial.txt \
              --name=logging-signer-test"
      not_if { ::File.exist?("#{CERT_FOLDER}/ca.crt") }
    end

    execute 'Generate kibana-internal keys' do
      command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} ca create-server-cert \
              --config=#{FOLDER}/admin.kubeconfig \
              --key=#{CERT_FOLDER}/kibana-internal.key \
              --cert=#{CERT_FOLDER}/kibana-internal.crt \
              --hostnames='kibana, kibana-ops, #{node['cookbook-openshift3']['openshift_logging_kibana_hostname']}, #{node['cookbook-openshift3']['openshift_logging_kibana_ops_hostname']}' \
              --signer-key=#{CERT_FOLDER}/ca.key \
              --signer-cert=#{CERT_FOLDER}/ca.crt \
              --signer-serial=#{CERT_FOLDER}/ca.serial.txt"
      not_if { ::File.exist?("#{CERT_FOLDER}/kibana-internal.crt") }
    end

    cookbook_file "#{CERT_FOLDER}/server-tls.json" do
      source 'logging/server-tls.json'
    end

    %w(ca.db ca.crl.srl).each do |ca_help|
      file "Initialise #{ca_help}" do
        path "#{CERT_FOLDER}/#{ca_help}"
        content ''
        not_if { ::File.exist?("#{CERT_FOLDER}/#{ca_help}") }
      end
    end

    %w(system.logging.fluentd system.logging.kibana system.logging.curator system.admin).each do |component|
      execute "Creating cert req for #{component}" do
        command "openssl req -out #{CERT_FOLDER}/#{component}.csr -new -newkey rsa:2048 -keyout #{CERT_FOLDER}/#{component}.key -subj \"/CN=#{component}/OU=OpenShift/O=Logging\" -days 712 -nodes"
        creates "#{CERT_FOLDER}/#{component}.csr"
      end

      execute "Sign cert request with CA for #{component}" do
        command "openssl ca -in #{CERT_FOLDER}/#{component}.csr -notext -out #{CERT_FOLDER}/#{component}.crt -config #{CERT_FOLDER}/signing.conf -extensions v3_req -batch -extensions server_ext"
        creates "#{CERT_FOLDER}/#{component}.crt"
      end
    end

    %w(ca.crt ca.key ca.serial.txt ca.crl.srl ca.db).each do |signing|
      remote_file "#{FOLDER}/#{signing}" do
        source "file://#{CERT_FOLDER}/#{signing}"
        sensitive true
      end
    end

    execute 'Run JKS generation script' do
      command "#{FOLDER}/generate-jks.sh ${folder} ${namespace}"
      environment(
        folder: FOLDER.to_s,
        namespace: node['cookbook-openshift3']['openshift_logging_namespace']
      )
      not_if { ::File.exist?("#{CERT_FOLDER}/elasticsearch.jks") || ::File.exist?("#{CERT_FOLDER}/logging-es.jks") || ::File.exist?("#{CERT_FOLDER}/system.admin.jks") || ::File.exist?("#{CERT_FOLDER}/truststore.jks") }
    end

    %w(elasticsearch.jks logging-es.jks system.admin.jks truststore.jks).each do |jks|
      remote_file "#{CERT_FOLDER}/#{jks}" do
        source "file://#{FOLDER}/#{jks}"
        sensitive true
        action :create_if_missing
      end
    end

    %w(kibana curator fluentd).each do |component|
      ruby_block "Generating secrets for logging #{component}" do
        block do
          [{ 'metadata' => { 'name' => "logging-#{component}" }, 'data' => { 'ca' => encode_file("#{CERT_FOLDER}/ca.crt"), 'key' => encode_file("#{CERT_FOLDER}/system.logging.#{component}.key"), 'cert' => encode_file("#{CERT_FOLDER}/system.logging.#{component}.crt") } }].each do |secret|
            generate_secrets(secret)
          end
        end
      end
    end

    ruby_block 'Generating secrets for kibana proxy' do
      block do
        kibana_proxy_secret = { 'metadata' => { 'name' => 'logging-kibana-proxy' }, 'data' => { 'oauth-secret' => Base64.strict_encode64(OAUTH_SECRET), 'session-secret' => Base64.strict_encode64(random_password(200)), 'server-cert' => encode_file("#{CERT_FOLDER}/kibana-internal.crt"), 'server-key' => encode_file("#{CERT_FOLDER}/kibana-internal.key"), 'server-tls.json' => encode_file("#{CERT_FOLDER}/server-tls.json") } }
        generate_secrets(kibana_proxy_secret)
      end
    end

    execute 'Generating secrets for elasticsearch' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} secrets new logging-elasticsearch \
              --config=#{FOLDER}/admin.kubeconfig \
              key=#{CERT_FOLDER}/logging-es.jks truststore=#{CERT_FOLDER}/truststore.jks \
              searchguard.key=#{CERT_FOLDER}/elasticsearch.jks searchguard.truststore=#{CERT_FOLDER}/truststore.jks \
              admin-key=#{CERT_FOLDER}/system.admin.key admin-cert=#{CERT_FOLDER}/system.admin.crt \
              admin-ca=#{CERT_FOLDER}/ca.crt admin.jks=#{CERT_FOLDER}/system.admin.jks -o yaml > #{FOLDER}/templates/logging-elasticsearch-secret.yaml"
    end

    template "#{FOLDER}/elasticsearch-logging.yml" do
      source "#{FOLDER_LOGGING}/elasticsearch-logging.yml.erb"
      sensitive true
      variables(
        root_logger: node['cookbook-openshift3']['openshift_logging_es_log_appenders'].join(', ')
      )
    end

    template "#{FOLDER}/elasticsearch.yml" do
      source "#{FOLDER_LOGGING}/elasticsearch.yml.erb"
      sensitive true
      variables(
        es_number_of_replicas: node['cookbook-openshift3']['openshift_logging_es_number_of_replicas'],
        es_number_of_shards: node['cookbook-openshift3']['openshift_logging_es_number_of_shards'],
        allow_cluster_reader: node['cookbook-openshift3']['openshift_logging_es_ops_allow_cluster_reader'],
        es_min_masters: node['cookbook-openshift3']['openshift_logging_es_cluster_size'].to_i == 1 ? '1' : node['cookbook-openshift3']['openshift_logging_es_cluster_size'].to_i / 2 + 1
      )
    end

    execute 'Generating configmap logging-elasticsearch' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} create configmap logging-elasticsearch \
              --config=#{FOLDER}/admin.kubeconfig \
              --from-file=logging.yml=#{FOLDER}/elasticsearch-logging.yml \
              --from-file=elasticsearch.yml=#{FOLDER}/elasticsearch.yml -o yaml --dry-run > #{FOLDER}/templates/logging-elasticsearch-configmap.yaml"
    end

    cookbook_file "#{FOLDER}/curator.yml" do
      source 'logging/curator.yml'
    end

    execute 'Generating configmap curator' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} create configmap logging-curator \
              --config=#{FOLDER}/admin.kubeconfig \
              --from-file=config.yaml=#{FOLDER}/curator.yml -o yaml --dry-run > #{FOLDER}/templates/logging-curator-configmap.yaml"
    end

    %w(fluent.conf fluentd-throttle-config.yaml secure-forward.conf).each do |fluent|
      next if ose_major_version.split('.')[1].to_i >= 6 && fluent == 'fluent.conf'
      cookbook_file "#{FOLDER}/#{fluent}" do
        source "logging/#{fluent}"
      end
    end

    template "#{FOLDER}/fluent.conf" do
      source "#{FOLDER_LOGGING}/fluent.conf.erb"
      sensitive true
      variables(
        deploy_type: %w(hosted secure-aggregator secure-host).include?(node['cookbook-openshift3']['openshift_logging_fluentd_deployment_type']) ? true : false,
        openshift_logging_fluentd_shared_key: random_password(128)
      )
      only_if { ose_major_version.split('.')[1].to_i >= 6 }
    end

    execute 'Generating configmap fluentd' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} create configmap logging-fluentd \
              --config=#{FOLDER}/admin.kubeconfig \
              --from-file=fluent.conf=#{FOLDER}/fluent.conf \
 			        --from-file=throttle-config.yaml=#{FOLDER}/fluentd-throttle-config.yaml \
 			        --from-file=secure-forward.conf=#{FOLDER}/secure-forward.conf -o yaml --dry-run > #{FOLDER}/templates/logging-fluentd-configmap.yaml"
    end

    %w(elasticsearch kibana fluentd curator).each do |serviceaccount|
      ruby_block "Create Service Account for #{serviceaccount}" do
        block do
          sa = { 'metadata' => { 'name' => "aggregated-logging-#{serviceaccount}" } }
          generate_serviceaccounts(sa)
        end
      end
    end

    ruby_block 'Create Services for Logging components' do
      block do
        services = [{ 'metadata' => { 'name' => 'logging-es', 'labels' => { 'logging-infra' => 'support' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'es' }, 'ports' => [{ 'port' => 9200, 'targetPort' => 'restapi' }] }, { 'metadata' => { 'name' => 'logging-es-cluster', 'labels' => { 'logging-infra' => 'support' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'es' }, 'ports' => [{ 'name' => 'cql-port', 'port' => 9300 }] }, { 'metadata' => { 'name' => 'logging-kibana', 'labels' => { 'logging-infra' => 'support' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'kibana' }, 'ports' => [{ 'port' => 443, 'targetPort' => 'oaproxy' }] }, { 'metadata' => { 'name' => 'logging-es-ops', 'labels' => { 'logging-infra' => 'support' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'es-ops' }, 'ports' => [{ 'port' => 9200, 'targetPort' => 'restapi' }] }, { 'metadata' => { 'name' => 'logging-es-ops-cluster', 'labels' => { 'logging-infra' => 'support' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'es-ops' }, 'ports' => [{ 'name' => 'cql-port', 'port' => 9300 }] }, { 'metadata' => { 'name' => 'logging-kibana-ops', 'labels' => { 'logging-infra' => 'support' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'kibana-ops' }, 'ports' => [{ 'port' => 443, 'targetPort' => 'oaproxy' }] }]
        services.each do |svc|
          next if !node['cookbook-openshift3']['openshift_logging_use_ops'] && /-ops/ =~ svc['metadata']['name']
          generate_services(svc)
        end
      end
    end

    if ose_major_version.split('.')[1].to_i >= 7
      ruby_block 'Set logging-es-prometheus service' do
        block do
          services = [{ 'metadata' => { 'name' => 'logging-es-prometheus', 'labels' => { 'logging-infra' => 'support' }, 'annotations' => { 'service.alpha.openshift.io/serving-cert-secret-name' => 'prometheus-tls', 'prometheus.io/scrape' => 'true', 'prometheus.io/scheme' => 'https', 'prometheus.io/path' => '_prometheus/metrics' } }, 'selector' => { 'provider' => 'openshift', 'component' => 'es' }, 'ports' => [{ 'name' => 'proxy', 'port' => 443, 'targetPort' => 4443 }] }]
          services.each do |svc|
            generate_services(svc)
          end
        end
      end
    end

    template "#{FOLDER}/templates/oauth-client.yaml" do
      source "#{FOLDER_LOGGING}/oauth-client.erb"
      sensitive true
      variables(
        secret: OAUTH_SECRET
      )
    end

    ruby_block 'Generate ClusterRole/RoleBinding/Route' do
      block do
        role = { 'metadata' => { 'name' => 'rolebinding-reader' }, 'rules' => [{ 'resources' => ['clusterrolebindings'], 'verbs' => %w(get) }], 'cluster' => true }
        rolebinding = { 'metadata' => { 'name' => 'logging-elasticsearch-view-role' }, 'rolerefs' => { 'name' => 'view' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'aggregated-logging-elasticsearch' }] }
        routes = [{ 'metadata' => { 'name' => 'logging-kibana', 'labels' => { 'component' => 'support', 'logging-infra' => 'support', 'provider' => 'openshift' } }, 'spec' => { 'host' => node['cookbook-openshift3']['openshift_logging_kibana_hostname'], 'to' => { 'kind' => 'Service', 'name' => 'logging-kibana' }, 'tls' => { 'termination' => 'reencrypt', 'caCertificate' => ::File.read("#{FOLDER}/ca.crt"), 'destinationCACertificate' => ::File.read("#{FOLDER}/ca.crt"), 'insecureEdgeTerminationPolicy' => ose_major_version.split('.')[1].to_i >= 5 ? node['cookbook-openshift3']['openshift_logging_kibana_edge_term_policy'] : '' } } }, { 'metadata' => { 'name' => 'logging-kibana-ops', 'labels' => { 'component' => 'support', 'logging-infra' => 'support', 'provider' => 'openshift' } }, 'spec' => { 'host' => node['cookbook-openshift3']['openshift_logging_kibana_ops_hostname'], 'to' => { 'kind' => 'Service', 'name' => 'logging-kibana-ops' }, 'tls' => { 'termination' => 'reencrypt', 'caCertificate' => ::File.read("#{FOLDER}/ca.crt"), 'destinationCACertificate' => ::File.read("#{FOLDER}/ca.crt"), 'insecureEdgeTerminationPolicy' => ose_major_version.split('.')[1].to_i >= 5 ? node['cookbook-openshift3']['openshift_logging_kibana_edge_term_policy'] : '' } } }]
        generate_roles(role)
        generate_rolebindings(rolebinding)
        routes.each do |route|
          next if !node['cookbook-openshift3']['openshift_logging_use_ops'] && /-ops/ =~ route['metadata']['name']
          generate_routes(route)
        end
      end
    end

    1.upto(node['cookbook-openshift3']['openshift_logging_es_cluster_size'].to_i) do |es_num|
      template "#{FOLDER}/templates/logging-es-dc-#{es_num}.yaml" do
        source "#{FOLDER_LOGGING}/es.erb"
        sensitive true
        variables(
          component: 'es',
          cookie_secret: Base64.strict_encode64(random_password(16)),
          basic_auth_passwd: random_password(16),
          deploy_name: "logging-es-#{DC_CHARS.sort_by { rand }.join[0...8]}",
          deploy_type: %w(data-master master data-client).include?(node['cookbook-openshift3']['openshift_logging_elasticsearch_deployment_type']) ? 'true' : false,
          logging_component: 'elasticsearch',
          deploy_name_prefix: 'logging-es',
          image: "#{node['cookbook-openshift3']['openshift_logging_image_prefix']}logging-elasticsearch:#{node['cookbook-openshift3']['openshift_logging_image_version']}",
          proxy_image: "#{node['cookbook-openshift3']['openshift_logging_proxy_image_prefix']}oauth-proxy:#{node['cookbook-openshift3']['openshift_logging_proxy_image_version']}",
          es_cluster_name: 'es',
          es_memory_limit: node['cookbook-openshift3']['openshift_logging_es_memory_limit'],
          es_cpu_request: node['cookbook-openshift3']['openshift_logging_elasticsearch_cpu_request']
        )
      end
    end

    template "#{FOLDER}/templates/logging-kibana-dc.yaml" do
      source "#{FOLDER_LOGGING}/kibana.erb"
      sensitive true
      variables(
        component: 'kibana',
        logging_component: 'kibana',
        deploy_name: 'logging-kibana',
        deploy_name_prefix: 'logging-es',
        image: "#{node['cookbook-openshift3']['openshift_logging_image_prefix']}logging-kibana:#{node['cookbook-openshift3']['openshift_logging_image_version']}",
        proxy_image: "#{node['cookbook-openshift3']['openshift_logging_image_prefix']}logging-auth-proxy:#{node['cookbook-openshift3']['openshift_logging_image_version']}",
        es_host: 'logging-es',
        es_port: node['cookbook-openshift3']['openshift_logging_es_port']
      )
    end

    template "#{FOLDER}/templates/logging-curator-dc.yaml" do
      source "#{FOLDER_LOGGING}/curator.erb"
      sensitive true
      variables(
        component: 'curator',
        logging_component: 'curator',
        deploy_name: 'logging-curator',
        image: "#{node['cookbook-openshift3']['openshift_logging_image_prefix']}logging-curator:#{node['cookbook-openshift3']['openshift_logging_image_version']}",
        es_host: 'logging-es',
        es_port: node['cookbook-openshift3']['openshift_logging_es_port']
      )
    end

    template "#{FOLDER}/templates/logging-fluentd-ds.yaml" do
      source "#{FOLDER_LOGGING}/fluentd.erb"
      sensitive true
      variables(
        daemonset_component: 'fluentd',
        daemonset_name: 'logging-fluentd',
        daemonset_container_name: 'fluentd-elasticsearch',
        daemonset_serviceAccount: 'aggregated-logging-fluentd',
        image: "#{node['cookbook-openshift3']['openshift_logging_image_prefix']}logging-fluentd:#{node['cookbook-openshift3']['openshift_logging_image_version']}",
        fluentd_nodeselector_key: node['cookbook-openshift3']['openshift_logging_fluentd_nodeselector'].keys.first.to_s,
        fluentd_nodeselector_value: node['cookbook-openshift3']['openshift_logging_fluentd_nodeselector'].values.first.to_s
      )
    end

    unless ::File.file?(node['cookbook-openshift3']['openshift_hosted_logging_flag'])
      execute 'Applying template files' do
        command "#{node['cookbook-openshift3']['openshift_common_client_binary']} apply -f \
                #{FOLDER}/templates \
                --config=#{FOLDER}/admin.kubeconfig \
                --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']}"
      end

      execute 'Set rolebinding-reader permissions for ES' do
        command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} policy add-cluster-role-to-user rolebinding-reader system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-elasticsearch --config=#{FOLDER}/admin.kubeconfig"
        not_if "#{node['cookbook-openshift3']['openshift_common_client_binary']} get clusterrole/rolebinding-reader -o yaml --config=#{FOLDER}/admin.kubeconfig | grep system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-elasticsearch"
      end

      execute 'Set auth-delegator permissions for ES' do
        command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} policy add-cluster-role-to-user system:auth-delegator system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-elasticsearch --config=#{FOLDER}/admin.kubeconfig"
        not_if "#{node['cookbook-openshift3']['openshift_common_client_binary']} get clusterrole/system:auth-delegator -o yaml --config=#{FOLDER}/admin.kubeconfig | grep system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-elasticsearch"
        only_if { ose_major_version.split('.')[1].to_i >= 7 }
      end

      execute 'Set privileged permissions for fluentd' do
        command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} policy add-scc-to-user privileged system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-fluentd --config=#{FOLDER}/admin.kubeconfig"
        not_if "#{node['cookbook-openshift3']['openshift_common_client_binary']} get scc/privileged -o yaml --config=#{FOLDER}/admin.kubeconfig | grep system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-fluentd"
      end

      execute 'Set cluster-reader permissions for fluentd' do
        command "#{node['cookbook-openshift3']['openshift_common_admin_binary']} policy add-cluster-role-to-user cluster-reader system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-fluentd --config=#{FOLDER}/admin.kubeconfig"
        not_if "#{node['cookbook-openshift3']['openshift_common_client_binary']} get clusterrolebinding/cluster-readers -o yaml --config=#{FOLDER}/admin.kubeconfig | grep system:serviceaccount:#{node['cookbook-openshift3']['openshift_logging_namespace']}:aggregated-logging-fluentd"
      end

      execute 'Scaling up ES' do
        command "#{node['cookbook-openshift3']['openshift_common_client_binary']} get dc --selector=component=es --config=#{FOLDER}/admin.kubeconfig --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} -o name | xargs #{node['cookbook-openshift3']['openshift_common_client_binary']} scale --replicas=1 \
                --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} \
                --config=#{FOLDER}/admin.kubeconfig"
      end

      execute 'Rollout DCS ES (>=3.7)' do
        command "#{node['cookbook-openshift3']['openshift_common_client_binary']} get dc --selector=component=es --config=#{FOLDER}/admin.kubeconfig --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} -o name | xargs #{node['cookbook-openshift3']['openshift_common_client_binary']} rollout latest \
                --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} \
                --config=#{FOLDER}/admin.kubeconfig"
        only_if { ose_major_version.split('.')[1].to_i >= 7 }
      end

      execute 'Scaling up Kibana' do
        command "#{node['cookbook-openshift3']['openshift_common_client_binary']} get dc --selector=component=kibana --config=#{FOLDER}/admin.kubeconfig --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} -o name | xargs #{node['cookbook-openshift3']['openshift_common_client_binary']} scale --replicas=#{node['cookbook-openshift3']['openshift_logging_kibana_replica_count']} \
                --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} \
                --config=#{FOLDER}/admin.kubeconfig"
      end

      execute 'Scaling up Curator' do
        command "#{node['cookbook-openshift3']['openshift_common_client_binary']} get dc --selector=component=curator --config=#{FOLDER}/admin.kubeconfig --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} -o name | xargs #{node['cookbook-openshift3']['openshift_common_client_binary']} scale --replicas=1 \
                --namespace=#{node['cookbook-openshift3']['openshift_logging_namespace']} \
                --config=#{FOLDER}/admin.kubeconfig"
      end

      file node['cookbook-openshift3']['openshift_hosted_logging_flag'] do
        action :create_if_missing
      end
    end

    execute 'Set Fluentd Labels for all nodes' do
      command "#{node['cookbook-openshift3']['openshift_common_client_binary']} label node --all ${key}=${value} --overwrite --config=#{FOLDER}/admin.kubeconfig"
      environment(
        'key' => node['cookbook-openshift3']['openshift_logging_fluentd_nodeselector'].keys.first.to_s,
        'value' => node['cookbook-openshift3']['openshift_logging_fluentd_nodeselector'].values.first.to_s
      )
      only_if "[[ $(#{node['cookbook-openshift3']['openshift_common_client_binary']} get node -l ${key}!=${value} --no-headers --config=#{FOLDER}/admin.kubeconfig | wc -l) > 0 ]]"
    end
  end
end
