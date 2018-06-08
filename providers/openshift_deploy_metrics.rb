#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_deploy_metrics
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_deploy_metrics if defined? provides

def whyrun_supported?
  true
end

CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a

FOLDER = Chef::Config['file_cache_path'] + '/hosted_metrics'

def random_password(length = 10)
  CHARS.sort_by { rand }.join[0...length]
end

def encode_file(file)
  Base64.strict_encode64(::File.read(file))
end

def generate_secrets(secret)
  secret_skel = { 'apiVersion' => 'v1', 'kind' => 'Secret', 'metadata' => {}, 'data' => {} }
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
  converge_by "Uninstalling Metrics on #{node['fqdn']}" do
    CERT_FOLDER = node['is_apaas_openshift_cookbook']['openshift_common_base_dir'] + '/metrics'

    directory "#{FOLDER}/templates" do
      recursive true
    end

    remote_file "#{FOLDER}/admin.kubeconfig" do
      source "file://#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      sensitive true
    end

    execute 'Scaling down cluster before deletion' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get rc -l metrics-infra -o name \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']} | \
              xargs --no-run-if-empty #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale \
              --replicas=0 --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
    end

    execute 'Uninstalling metrics components' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} $ACTION --ignore-not-found \
              --selector=metrics-infra all,sa,secrets,templates,routes,pvc,rolebindings,clusterrolebindings \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      environment 'ACTION' => 'delete'
    end

    execute 'Uninstalling rolebindings' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} $ACTION \
              --ignore-not-found rolebinding/hawkular-view clusterrolebinding/heapster-cluster-reader \
              --config=#{FOLDER}/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      environment 'ACTION' => 'delete'
    end

    %W(#{CERT_FOLDER} #{FOLDER}).each do |dir|
      directory dir do
        recursive true
        action :delete
      end
    end

    file node['is_apaas_openshift_cookbook']['openshift_hosted_metrics_flag'] do
      action :delete
    end
  end
end

action :create do
  converge_by "Deploying Metrics on #{node['fqdn']}" do
    ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']
    FOLDER_METRICS = ose_major_version.split('.')[1].to_i < 6 ? 'metrics_legacy' : 'metrics_36'
    CERT_FOLDER = node['is_apaas_openshift_cookbook']['openshift_common_base_dir'] + '/metrics'

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

    cookbook_file "#{FOLDER}/import_jks_certs.sh" do
      source 'import_jks_certs.sh'
      mode '0755'
    end

    remote_file "#{FOLDER}/admin.kubeconfig" do
      source "file://#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
      sensitive true
    end

    package 'java-1.8.0-openjdk-headless'
    package 'httpd-tools'

    execute 'Generate ca certificate chain' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} ca create-signer-cert \
              --config=#{FOLDER}/admin.kubeconfig \
              --key=#{CERT_FOLDER}/ca.key \
              --cert=#{CERT_FOLDER}/ca.crt \
              --serial=#{CERT_FOLDER}/ca.serial.txt \
              --name=metrics-signer@$(date +%s)"
      not_if { ::File.exist?("#{CERT_FOLDER}/ca.crt") }
    end

    %w(hawkular-metrics hawkular-cassandra heapster).each do |component|
      execute "Generate #{component} keys" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} ca create-server-cert \
                --config=#{FOLDER}/admin.kubeconfig \
                --key=#{CERT_FOLDER}/#{component}.key \
                --cert=#{CERT_FOLDER}/#{component}.crt \
                --hostnames=#{component} \
                --signer-key=#{CERT_FOLDER}/ca.key \
                --signer-cert=#{CERT_FOLDER}/ca.crt \
                --signer-serial=#{CERT_FOLDER}/ca.serial.txt"
        not_if { ::File.exist?("#{CERT_FOLDER}/#{component}.crt") }
      end

      ruby_block "Generate #{component} certificate" do
        block do
          ::File.open("#{CERT_FOLDER}/#{component}.pem", 'w+') { |f| f.puts ["#{CERT_FOLDER}/#{component}.key", "#{CERT_FOLDER}/#{component}.crt"].map { |s| IO.read(s) } }
        end
        not_if { ::File.exist?("#{CERT_FOLDER}/#{component}.pem") }
      end

      file "Generate random password for the #{component} keystore" do
        path "#{CERT_FOLDER}/#{component}-keystore.pwd"
        content random_password
        not_if { ::File.exist?("#{CERT_FOLDER}/#{component}-keystore.pwd") }
      end

      execute "Create the #{component} pkcs12 from the pem file" do
        command "openssl pkcs12 -export -in #{CERT_FOLDER}/#{component}.pem \
                -out #{CERT_FOLDER}/#{component}.pkcs12 \
                -name #{component} -noiter -nomaciter \
                -password pass:$(cat #{CERT_FOLDER}/#{component}-keystore.pwd)"
        creates "#{CERT_FOLDER}/#{component}.pkcs12"
      end

      file "Generate random password for #{component} truststore" do
        path "#{CERT_FOLDER}/#{component}-truststore.pwd"
        content random_password
        not_if { ::File.exist?("#{CERT_FOLDER}/#{component}-truststore.pwd") }
      end
    end

    %w(hawkular-metrics hawkular-jgroups-keystore).each do |component|
      file "Generate random password for the #{component} truststore" do
        path "#{CERT_FOLDER}/#{component}.pwd"
        content random_password
        not_if { ::File.exist?("#{CERT_FOLDER}/#{component}.pwd") }
      end
    end

    execute 'Generate htpasswd file for hawkular metrics' do
      command "htpasswd -b -c #{CERT_FOLDER}/hawkular-metrics.htpasswd hawkular $(cat #{CERT_FOLDER}/hawkular-metrics.pwd)"
      creates "#{CERT_FOLDER}/hawkular-metrics.htpasswd"
    end

    execute 'Generate JKS certs' do
      command "#{FOLDER}/import_jks_certs.sh"
      environment lazy {
        {
          CERT_DIR: CERT_FOLDER.to_s,
          METRICS_KEYSTORE_PASSWD: ::File.read("#{CERT_FOLDER}/hawkular-metrics-keystore.pwd"),
          CASSANDRA_KEYSTORE_PASSWD: ::File.read("#{CERT_FOLDER}/hawkular-cassandra-keystore.pwd"),
          METRICS_TRUSTSTORE_PASSWD: ::File.read("#{CERT_FOLDER}/hawkular-metrics-truststore.pwd"),
          CASSANDRA_TRUSTSTORE_PASSWD: ::File.read("#{CERT_FOLDER}/hawkular-cassandra-truststore.pwd"),
          JGROUPS_PASSWD: ::File.read("#{CERT_FOLDER}/hawkular-jgroups-keystore.pwd")
        }
      }
    end

    if ose_major_version.split('.')[1].to_i < 6

      ruby_block 'Create Metrics Secrets (<3.6)' do
        block do
          [{ 'metadata' => { 'name' => 'hawkular-metrics-secrets', 'labels' => { 'metrics-infra' => 'hawkular-metrics' } }, 'data' => { 'hawkular-metrics.keystore' => encode_file("#{CERT_FOLDER}/hawkular-metrics.keystore"), 'hawkular-metrics.keystore.password' => encode_file("#{CERT_FOLDER}/hawkular-metrics-keystore.pwd"), 'hawkular-metrics.truststore' => encode_file("#{CERT_FOLDER}/hawkular-metrics.truststore"), 'hawkular-metrics.truststore.password' => encode_file("#{CERT_FOLDER}/hawkular-metrics-truststore.pwd"), 'hawkular-metrics.keystore.alias' => Base64.strict_encode64('hawkular-metrics'), 'hawkular-metrics.htpasswd.file' => encode_file("#{CERT_FOLDER}/hawkular-metrics.htpasswd"), 'hawkular-metrics.jgroups.keystore' => encode_file("#{CERT_FOLDER}/hawkular-jgroups.keystore"), 'hawkular-metrics.jgroups.keystore.password' => encode_file("#{CERT_FOLDER}/hawkular-jgroups-keystore.pwd"), 'hawkular-metrics.jgroups.alias' => Base64.strict_encode64('hawkular') } }, { 'metadata' => { 'name' => 'hawkular-metrics-certificate', 'labels' => { 'metrics-infra' => 'hawkular-metrics' } }, 'data' => { 'hawkular-metrics.certificate' => encode_file("#{CERT_FOLDER}/hawkular-metrics.crt"), 'hawkular-metrics-ca.certificate' => encode_file("#{CERT_FOLDER}/ca.crt") } }, { 'metadata' => { 'name' => 'hawkular-metrics-account', 'labels' => { 'metrics-infra' => 'hawkular-metrics' } }, 'data' => { 'hawkular-metrics.username' => Base64.strict_encode64('hawkular'), 'hawkular-metrics.password' => encode_file("#{CERT_FOLDER}/hawkular-metrics.pwd") } }, { 'metadata' => { 'name' => 'hawkular-cassandra-secrets', 'labels' => { 'metrics-infra' => 'hawkular-cassandra' } }, 'data' => { 'cassandra.keystore' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.keystore"), 'cassandra.keystore.password' => encode_file("#{CERT_FOLDER}/hawkular-cassandra-keystore.pwd"), 'cassandra.keystore.alias' => Base64.strict_encode64('hawkular-cassandra'), 'cassandra.truststore' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.truststore"), 'cassandra.truststore.password' => encode_file("#{CERT_FOLDER}/hawkular-cassandra-truststore.pwd"), 'cassandra.pem' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.pem") } }, { 'metadata' => { 'name' => 'hawkular-cassandra-certificate', 'labels' => { 'metrics-infra' => 'hawkular-cassandra' } }, 'data' => { 'cassandra.certificate' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.crt"), 'cassandra-ca.certificate' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.pem") } }, { 'metadata' => { 'name' => 'heapster-secrets', 'labels' => { 'metrics-infra' => 'heapster' } }, 'data' => { 'heapster.cert' => encode_file("#{CERT_FOLDER}/heapster.crt"), 'heapster.key' => encode_file("#{CERT_FOLDER}/heapster.key"), 'heapster.client-ca' => encode_file("#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt"), 'heapster.allowed-users' => Base64.strict_encode64((node['is_apaas_openshift_cookbook']['openshift_metrics_heapster_allowed_users']).to_s) } }].each do |secret|
            generate_secrets(secret)
          end
        end
      end
    else
      ruby_block 'Create Metrics Secrets (>=3.6)' do
        block do
          [{ 'metadata' => { 'name' => 'hawkular-metrics-certs', 'labels' => { 'metrics-infra' => 'hawkular-metrics-certs' } }, 'data' => { 'tls.crt' => encode_file("#{CERT_FOLDER}/hawkular-metrics.crt"), 'tls.key' => encode_file("#{CERT_FOLDER}/hawkular-metrics.key"), 'tls.truststore.crt' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.crt"), 'ca.crt' => encode_file("#{CERT_FOLDER}/ca.crt") } }, { 'metadata' => { 'name' => 'hawkular-metrics-account', 'labels' => { 'metrics-infra' => 'hawkular-metrics' } }, 'data' => { 'hawkular-metrics.username' => Base64.strict_encode64('hawkular'), 'hawkular-metrics.htpasswd' => encode_file("#{CERT_FOLDER}/hawkular-metrics.htpasswd"), 'hawkular-metrics.password' => encode_file("#{CERT_FOLDER}/hawkular-metrics.pwd") } }, { 'metadata' => { 'name' => 'hawkular-cassandra-certs', 'labels' => { 'metrics-infra' => 'hawkular-cassandra-certs' }, 'annotations' => { 'service.alpha.openshift.io/originating-service-name' => 'hawkular-cassandra' } }, 'data' => { 'tls.crt' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.crt"), 'tls.key' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.key"), 'tls.peer.truststore.crt' => encode_file("#{CERT_FOLDER}/hawkular-cassandra.crt"), 'tls.client.truststore.crt' => encode_file("#{CERT_FOLDER}/hawkular-metrics.crt") } }, { 'metadata' => { 'name' => 'heapster-secrets', 'labels' => { 'metrics-infra' => 'heapster' } }, 'data' => { 'heapster.allowed-users' => Base64.strict_encode64((node['is_apaas_openshift_cookbook']['openshift_metrics_heapster_allowed_users']).to_s) } }].each do |secret|
            generate_secrets(secret)
          end
        end
      end
    end

    metric_components = { 'serviceaccounts' => [{ 'metadata' => { 'name' => 'hawkular', 'labels' => { 'metrics-infra' => 'support' } }, 'secrets' => [{ 'name' => 'hawkular-metrics-secrets' }] }, { 'metadata' => { 'name' => 'cassandra', 'labels' => { 'metrics-infra' => 'support' } }, 'secrets' => [{ 'name' => 'hawkular-cassandra-secrets' }] }, { 'metadata' => { 'name' => 'heapster', 'labels' => { 'metrics-infra' => 'support' } }, 'secrets' => [{ 'name' => 'heapster-secrets' }, { 'name' => 'hawkular-metrics-certificate' }, { 'name' => 'hawkular-metrics-account' }] }], 'services' => [{ 'metadata' => { 'name' => 'hawkular-metrics', 'labels' => { 'metrics-infra' => 'hawkular-metrics', 'name' => 'hawkular-metrics' } }, 'selector' => { 'name' => 'hawkular-metrics' }, 'ports' => [{ 'port' => 443, 'targetPort' => 'https-endpoint' }] }, { 'metadata' => { 'name' => 'hawkular-cassandra', 'labels' => { 'metrics-infra' => 'hawkular-cassandra', 'name' => 'hawkular-cassandra' } }, 'selector' => { 'type' => 'hawkular-cassandra' }, 'ports' => [{ 'name' => 'cql-port', 'port' => 9042, 'targetPort' => 'cql-port' }, { 'name' => 'thrift-port', 'port' => 9160, 'targetPort' => 'thrift-port' }, { 'name' => 'tcp-port', 'port' => 7000, 'targetPort' => 'tcp-port' }, { 'name' => 'ssl-port', 'port' => 7001, 'targetPort' => 'ssl-port' }] }, { 'metadata' => { 'name' => 'hawkular-cassandra-nodes', 'labels' => { 'metrics-infra' => 'hawkular-cassandra-nodes', 'name' => 'hawkular-cassandra-nodes' } }, 'selector' => { 'type' => 'hawkular-cassandra' }, 'ports' => [{ 'name' => 'cql-port', 'port' => 9042, 'targetPort' => 'cql-port' }, { 'name' => 'thrift-port', 'port' => 9160, 'targetPort' => 'thrift-port' }, { 'name' => 'tcp-port', 'port' => 7000, 'targetPort' => 'tcp-port' }, { 'name' => 'ssl-port', 'port' => 7001, 'targetPort' => 'ssl-port' }], 'headless' => true }, { 'metadata' => { 'name' => 'heapster', 'labels' => { 'metrics-infra' => 'heapster', 'name' => 'heapster' }, 'annotations' => { 'service.alpha.openshift.io/serving-cert-secret-name' => 'heapster-certs' } }, 'selector' => { 'name' => 'heapster' }, 'ports' => [{ 'port' => 80, 'targetPort' => 'http-endpoint' }] }], 'rolebindings' => [{ 'metadata' => { 'name' => 'hawkular-view', 'labels' => { 'metrics-infra' => 'hawkular' } }, 'rolerefs' => { 'name' => 'view' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'hawkular', 'namespace' => node['is_apaas_openshift_cookbook']['openshift_metrics_project'] }] }, { 'metadata' => { 'name' => 'hawkular-namespace-watcher', 'labels' => { 'metrics-infra' => 'hawkular' } }, 'rolerefs' => { 'name' => 'hawkular-metrics', 'kind' => 'ClusterRole' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'hawkular', 'namespace' => node['is_apaas_openshift_cookbook']['openshift_metrics_project'] }], 'cluster' => true }, { 'metadata' => { 'name' => 'heapster-cluster-reader', 'labels' => { 'metrics-infra' => 'heapster' } }, 'rolerefs' => { 'name' => 'cluster-reader', 'kind' => 'ClusterRole' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'heapster', 'namespace' => node['is_apaas_openshift_cookbook']['openshift_metrics_project'] }], 'cluster' => true }], 'roles' => [{ 'metadata' => { 'name' => 'hawkular-metrics', 'labels' => { 'metrics-infra' => 'hawkular-metrics' } }, 'rules' => [{ 'apiGroups' => [''], 'resources' => ['namespaces'], 'verbs' => %w(list get watch) }], 'cluster' => true }] }

    ruby_block 'Create Resources for Metrics' do
      block do
        metric_components['serviceaccounts'].each do |serviceaccount|
          generate_serviceaccounts(serviceaccount)
        end
        metric_components['services'].each do |service|
          generate_services(service)
        end
        metric_components['rolebindings'].each do |rolebinding|
          generate_rolebindings(rolebinding)
        end
        metric_components['roles'].each do |role|
          generate_roles(role)
        end
      end
    end

    ruby_block 'Create Routes' do
      block do
        [{ 'metadata' => { 'name' => 'hawkular-metrics', 'labels' => { 'metrics-infra' => 'hawkular-metrics' } }, 'spec' => { 'host' => node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_hostname'], 'to' => { 'kind' => 'Service', 'name' => 'hawkular-metrics' }, 'tls' => { 'termination' => 'reencrypt', 'destinationCACertificate' => ::File.read("#{CERT_FOLDER}/ca.crt") } } }].each do |route|
          generate_routes(route)
        end
      end
    end

    template 'Generate heapster replication controller' do
      path "#{FOLDER}/templates/heapster-rc.yaml"
      source "#{FOLDER_METRICS}/heapster.yaml.erb"
      variables(ose_major_version: ose_major_version)
      sensitive true
    end

    template 'Generate hawkular-metrics replication controller' do
      path "#{FOLDER}/templates/hawkular-metrics-rc.yaml"
      source "#{FOLDER_METRICS}/hawkular_metrics_rc.yaml.erb"
      variables(
        ose_major_version: ose_major_version,
        random_word: random_password
      )
      sensitive true
    end

    template 'Generate cassandra replication controller' do
      path "#{FOLDER}/templates/hawkular-cassandra-1-rc.yaml"
      source "#{FOLDER_METRICS}/hawkular_cassandra_rc.yaml.erb"
      variables(ose_major_version: ose_major_version)
      sensitive true
    end

    [{ 'name' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_prefix'], 'labels' => { 'metrics-infra' => 'hawkular-cassandra' }, 'annotations' => { 'volume.alpha.kubernetes.io/storage-class' => 'dynamic' }, 'access_modes' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_access'] }].each do |pvc|
      template 'Generate hawkular-cassandra persistent volume claims (dynamic)' do
        path "#{FOLDER}/templates/cassandra-#{pvc['name']}-pvc.yaml"
        source 'pvc.yaml.erb'
        variables(pvc: pvc)
        only_if { node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type'] =~ /dynamic/i }
      end
    end

    [{ 'name' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_prefix'], 'labels' => { 'metrics-infra' => 'hawkular-cassandra' }, 'access_modes' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_access'] }].each do |pvc|
      template 'Generate hawkular-cassandra persistent volume claims' do
        path "#{FOLDER}/templates/cassandra-#{pvc['name']}-pvc.yaml"
        source 'pvc.yaml.erb'
        variables(pvc: pvc)
        not_if { node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type'] =~ /dynamic/i || node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type'] =~ /emptydir/i }
      end
    end

    unless ::File.file?(node['is_apaas_openshift_cookbook']['openshift_hosted_metrics_flag'])
      execute 'Applying template files' do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} apply -f \
                #{FOLDER}/templates \
                --config=#{FOLDER}/admin.kubeconfig \
                --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      end

      execute 'Scaling down cluster to recognize changes' do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get rc -l metrics-infra -o name \
                --config=#{FOLDER}/admin.kubeconfig \
                --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']} | \
                xargs --no-run-if-empty #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale \
                --replicas=0 --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      end

      execute 'Scaling up cluster' do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get rc -l metrics-infra -o name \
                --config=#{FOLDER}/admin.kubeconfig \
                --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']} | \
                xargs --no-run-if-empty #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale \
                --replicas=1 --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      end
    end

    file node['is_apaas_openshift_cookbook']['openshift_hosted_metrics_flag'] do
      action :create_if_missing
    end

    directory FOLDER.to_s do
      recursive true
      action :delete
    end
  end
end
