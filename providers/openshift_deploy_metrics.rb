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

def random_password(length = 10)
  CHARS.sort_by { rand }.join[0...length]
end

action :delete do
  converge_by 'Uninstalling Metrics' do
    directory "#{Chef::Config['file_cache_path']}/hosted_metric/templates" do
      recursive true
    end

    remote_file "#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig" do
      source "file://#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    execute 'Scaling down cluster before deletion' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get rc -l metrics-infra -o name \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']} | \
              xargs --no-run-if-empty #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale \
              --replicas=0 --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
    end

    execute 'Uninstalling metrics components' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} $ACTION --ignore-not-found \
              --selector=metrics-infra all,sa,secrets,templates,routes,pvc,rolebindings,clusterrolebindings \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      environment 'ACTION' => 'delete'
    end

    execute 'Uninstalling rolebindings' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} $ACTION \
              --ignore-not-found rolebinding/hawkular-view clusterrolebinding/heapster-cluster-reader \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
      environment 'ACTION' => 'delete'
    end
  end
end

action :create do
  converge_by 'Deploying Metrics' do
    ose_major_version = node['is_apaas_openshift_cookbook']['deploy_containerized'] == true ? node['is_apaas_openshift_cookbook']['openshift_docker_image_version'] : node['is_apaas_openshift_cookbook']['ose_major_version']

    directory "#{Chef::Config['file_cache_path']}/hosted_metric/templates" do
      recursive true
    end

    cookbook_file "#{Chef::Config['file_cache_path']}/hosted_metric/import_jks_certs.sh" do
      source 'import_jks_certs.sh'
      mode '0755'
    end

    remote_file "#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig" do
      source "file://#{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/admin.kubeconfig"
    end

    package 'java-1.8.0-openjdk-headless'

    execute 'Generate ca certificate chain' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} ca create-signer-cert \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --key=#{Chef::Config['file_cache_path']}/hosted_metric/ca.key \
              --cert=#{Chef::Config['file_cache_path']}/hosted_metric/ca.crt \
              --serial=#{Chef::Config['file_cache_path']}/hosted_metric/ca.serial.txt \
              --name=metrics-signer@$(date +%s)"
    end

    %w(hawkular-metrics hawkular-cassandra heapster).each do |component|
      execute "Generate #{component} keys" do
        command "#{node['is_apaas_openshift_cookbook']['openshift_common_admin_binary']} ca create-server-cert \
                --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
                --key=#{Chef::Config['file_cache_path']}/hosted_metric/#{component}.key \
                --cert=#{Chef::Config['file_cache_path']}/hosted_metric/#{component}.crt \
                --hostnames=#{component} \
                --signer-key=#{Chef::Config['file_cache_path']}/hosted_metric/ca.key \
                --signer-cert=#{Chef::Config['file_cache_path']}/hosted_metric/ca.crt \
                --signer-serial=#{Chef::Config['file_cache_path']}/hosted_metric/ca.serial.txt"
      end

      execute "Generate #{component} certificate" do
        command "cat #{Chef::Config['file_cache_path']}/hosted_metric/#{component}.key #{Chef::Config['file_cache_path']}/hosted_metric/#{component}.crt > #{Chef::Config['file_cache_path']}/hosted_metric/#{component}.pem"
      end

      file "Generate random password for the #{component} keystore" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/#{component}-keystore.pwd"
        content random_password
      end

      execute "Create the #{component} pkcs12 from the pem file" do
        command "openssl pkcs12 -export -in #{Chef::Config['file_cache_path']}/hosted_metric/#{component}.pem \
                -out #{Chef::Config['file_cache_path']}/hosted_metric/#{component}.pkcs12 \
                -name #{component} -noiter -nomaciter \
                -password pass:$(cat #{Chef::Config['file_cache_path']}/hosted_metric/#{component}-keystore.pwd)"
      end

      file "Generate random password for #{component} truststore" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/#{component}-truststore.pwd"
        content random_password
      end
    end

    %w(hawkular-metrics hawkular-jgroups-keystore).each do |component|
      file "Generate random password for the #{component} truststore" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/#{component}.pwd"
        content random_password
      end
    end

    execute 'Generate htpasswd file for hawkular metrics' do
      command "htpasswd -b -c #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.htpasswd hawkular $(cat #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.pwd)"
    end

    execute 'Generate JKS certs' do
      command "#{Chef::Config['file_cache_path']}/hosted_metric/import_jks_certs.sh"
      environment lazy {
        {
          CERT_DIR: "#{Chef::Config['file_cache_path']}/hosted_metric",
          METRICS_KEYSTORE_PASSWD: ::File.read("#{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics-keystore.pwd"),
          CASSANDRA_KEYSTORE_PASSWD: ::File.read("#{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra-keystore.pwd"),
          METRICS_TRUSTSTORE_PASSWD: ::File.read("#{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics-truststore.pwd"),
          CASSANDRA_TRUSTSTORE_PASSWD: ::File.read("#{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra-truststore.pwd"),
          JGROUPS_PASSWD: ::File.read("#{Chef::Config['file_cache_path']}/hosted_metric/hawkular-jgroups-keystore.pwd")
        }
      }
    end

    if ose_major_version.split('.')[1].to_i < 6
      template 'Generate hawkular-metrics-secrets secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular_metrics_secrets.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-metrics-secrets',
            labels: { 'metrics-infra' => 'hawkular-metrics' },
            data: {
              'hawkular-metrics.keystore' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.keystore`,
              'hawkular-metrics.keystore.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics-keystore.pwd`,
              'hawkular-metrics.truststore' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.truststore`,
              'hawkular-metrics.truststore.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics-truststore.pwd`,
              'hawkular-metrics.keystore.alias' => `echo -n hawkular-metrics | base64`,
              'hawkular-metrics.htpasswd.file' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.htpasswd`,
              'hawkular-metrics.jgroups.keystore' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-jgroups.keystore`,
              'hawkular-metrics.jgroups.keystore.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-jgroups-keystore.pwd`,
              'hawkular-metrics.jgroups.alias' => `echo -n hawkular | base64`
            }
          }
        }
      end

      template 'Generate hawkular-metrics-certificate secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular_metrics_certificate.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-metrics-certificate',
            labels: { 'metrics-infra' => 'hawkular-metrics' },
            data: {
              'hawkular-metrics.certificate' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.crt`,
              'hawkular-metrics-ca.certificate' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/ca.crt`
            }
          }
        }
      end

      template 'Generate hawkular-metrics-account secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular_metrics_account.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-metrics-account',
            labels: { 'metrics-infra' => 'hawkular-metrics' },
            data: {
              'hawkular-metrics.username' => `echo -n hawkular | base64`,
              'hawkular-metrics.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.pwd`
            }
          }
        }
      end

      template 'Generate cassandra secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/cassandra_secrets.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-cassandra-secrets',
            labels: { 'metrics-infra' => 'hawkular-cassandra' },
            data: {
              'cassandra.keystore' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.keystore`,
              'cassandra.keystore.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra-keystore.pwd`,
              'cassandra.keystore.alias' => `echo -n hawkular-cassandra | base64`,
              'cassandra.truststore' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.truststore`,
              'cassandra.truststore.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra-truststore.pwd`,
              'cassandra.pem' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.pem`
            }
          }
        }
      end

      template 'Generate cassandra-certificate secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/cassandra_certificate.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-cassandra-certificate',
            labels: { 'metrics-infra' => 'hawkular-cassandra' },
            data: {
              'cassandra.certificate' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.crt`,
              'cassandra-ca.certificate' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.pem`
            }
          }
        }
      end

      template 'Generate heapster secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/heapster_secrets.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'heapster-secrets',
            labels: { 'metrics-infra' => 'heapster' },
            data: {
              'heapster.cert' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/heapster.crt`,
              'heapster.key' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/heapster.key`,
              'heapster.client-ca' => `base64 --wrap 0 #{node['is_apaas_openshift_cookbook']['openshift_master_config_dir']}/ca-bundle.crt`,
              'heapster.allowed-users' => `echo -n #{node['is_apaas_openshift_cookbook']['openshift_metrics_heapster_allowed_users']} | base64
`
            }
          }
        }
      end

    else
      template 'Generate hawkular-metrics-certs secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular_metrics-certs_secrets.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-metrics-certs',
            labels: { 'metrics-infra' => 'hawkular-metrics-certs' },
            annotations: ['service.alpha.openshift.io/originating-service-name: hawkular-metrics'],
            data: {
              'tls.crt' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.crt`,
              'tls.key' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.key`,
              'tls.truststore.crt' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.crt`,
              'ca.crt' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/ca.crt`
            }
          }
        }
      end

      template 'Generate hawkular-metrics-account secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular_metrics_account.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-metrics-account',
            labels: { 'metrics-infra' => 'hawkular-metrics' },
            data: {
              'hawkular-metrics.username' => `echo -n hawkular | base64`,
              'hawkular-metrics.htpasswd' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.htpasswd`,
              'hawkular-metrics.password' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.pwd`
            }
          }
        }
      end

      template 'Generate cassandra-certificate secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular-cassandra-certs.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'hawkular-cassandra-certs',
            labels: { 'metrics-infra' => 'hawkular-cassandra-certs' },
            annotations: ['service.alpha.openshift.io/originating-service-name: hawkular-cassandra'],
            data: {
              'tls.crt' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.crt`,
              'tls.key' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.key`,
              'tls.peer.truststore.crt' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-cassandra.crt`,
              'tls.client.truststore.crt' => `base64 --wrap 0 #{Chef::Config['file_cache_path']}/hosted_metric/hawkular-metrics.crt`
            }
          }
        }
      end

      template 'Generate heapster secret template' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/heapster_secrets.yaml"
        source 'secret.yaml.erb'
        variables lazy {
          {
            name: 'heapster-secrets',
            labels: { 'metrics-infra' => 'heapster' },
            data: {
              'heapster.allowed-users' => `echo -n #{node['is_apaas_openshift_cookbook']['openshift_metrics_heapster_allowed_users']} | base64
`
            }
          }
        }
      end
    end

    [{ 'name' => 'hawkular', 'labels' => { 'metrics-infra' => 'support' }, 'secrets' => ['hawkular-metrics-secrets'] }, { 'name' => 'cassandra', 'labels' => { 'metrics-infra' => 'support' }, 'secrets' => ['hawkular-cassandra-secrets'] }, { 'name' => 'heapster', 'labels' => { 'metrics-infra' => 'support' }, 'secrets' => ['heapster-secrets', 'hawkular-metrics-certificate', 'hawkular-metrics-account'] }].each do |sa|
      template "Generating serviceaccounts for #{sa['name']}" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/metrics-#{sa['name']}-sa.yaml"
        source 'serviceaccount.yaml.erb'
        variables(sa: sa)
      end
    end

    [{ 'name' => 'hawkular-metrics', 'labels' => { 'metrics-infra' => 'hawkular-metrics', 'name' => 'hawkular-metrics' }, 'selector' => { 'name' => 'hawkular-metrics' }, 'ports' => [{ 'port' => 443, 'targetPort' => 'https-endpoint' }] }, { 'name' => 'hawkular-cassandra', 'labels' => { 'metrics-infra' => 'hawkular-cassandra', 'name' => 'hawkular-cassandra' }, 'selector' => { 'type' => 'hawkular-cassandra' }, 'ports' => [{ 'name' => 'cql-port', 'port' => 9042, 'targetPort' => 'cql-port' }, { 'name' => 'thrift-port', 'port' => 9160, 'targetPort' => 'thrift-port' }, { 'name' => 'tcp-port', 'port' => 7000, 'targetPort' => 'tcp-port' }, { 'name' => 'ssl-port', 'port' => 7001, 'targetPort' => 'ssl-port' }] }, { 'name' => 'hawkular-cassandra-nodes', 'labels' => { 'metrics-infra' => 'hawkular-cassandra-nodes', 'name' => 'hawkular-cassandra-nodes' }, 'selector' => { 'type' => 'hawkular-cassandra-nodes' }, 'ports' => [{ 'name' => 'cql-port', 'port' => 9042, 'targetPort' => 'cql-port' }, { 'name' => 'thrift-port', 'port' => 9160, 'targetPort' => 'thrift-port' }, { 'name' => 'tcp-port', 'port' => 7000, 'targetPort' => 'tcp-port' }, { 'name' => 'ssl-port', 'port' => 7001, 'targetPort' => 'ssl-port' }], 'headless' => true }, { 'name' => 'heapster', 'labels' => { 'metrics-infra' => 'heapster', 'name' => 'heapster' }, 'selector' => { 'name' => 'heapster' }, 'annotations' => ['service.alpha.openshift.io/serving-cert-secret-name: heapster-certs'], 'ports' => [{ 'port' => 80, 'targetPort' => 'http-endpoint' }] }].each do |svc|
      template "Generating serviceaccounts for #{svc['name']}" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/metrics-#{svc['name']}-svc.yaml"
        source 'service.yaml.erb'
        variables(svc: svc)
      end
    end

    [{ 'name' => 'hawkular-view', 'labels' => { 'metrics-infra' => 'hawkular' }, 'rolerefs' => { 'name' => 'view' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'hawkular', 'namespace' => node['is_apaas_openshift_cookbook']['openshift_metrics_project'] }] }, { 'name' => 'hawkular-namespace-watcher', 'labels' => { 'metrics-infra' => 'hawkular' }, 'rolerefs' => { 'name' => 'hawkular-metrics', 'kind' => 'ClusterRole' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'hawkular', 'namespace' => node['is_apaas_openshift_cookbook']['openshift_metrics_project'] }], 'cluster' => true }, { 'name' => 'heapster-cluster-reader', 'labels' => { 'metrics-infra' => 'heapster' }, 'rolerefs' => { 'name' => 'cluster-reader', 'kind' => 'ClusterRole' }, 'subjects' => [{ 'kind' => 'ServiceAccount', 'name' => 'heapster', 'namespace' => node['is_apaas_openshift_cookbook']['openshift_metrics_project'] }], 'cluster' => true }].each do |role|
      template "Generate view role binding for the #{role['name']} service account" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/#{role['name']}-rolebinding.yaml"
        source 'rolebinding.yaml.erb'
        variables(role: role)
      end
    end

    cookbook_file "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular-cluster-role.yaml" do
      source 'hawkular_metrics_role.yaml'
    end

    [{ 'name' => 'hawkular-metrics', 'labels' => { 'metrics-infra' => 'hawkular-metrics' }, 'host' => node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_hostname'], 'to' => { 'kind' => 'Service', 'name' => 'hawkular-metrics' }, 'tls' => true, 'tls_termination' => 'reencrypt' }].each do |route|
      template "Generate the #{route['name']} route" do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/#{route['name']}-route.yaml"
        source 'route.yaml.erb'
        variables lazy {
          {
            route: route,
            annotations: node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_route_annotations'],
            tls_key: node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_key'].empty? ? '' : Mixlib::ShellOut.new("base64 --wrap 0 #{node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_key']}").run_command.stdout.strip,
            tls_certificate: node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_cert'].empty? ? '' : Mixlib::ShellOut.new("cat #{node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_cert']} | ruby -p -e \"gsub(/\n/, '\\n')\"").run_command.stdout.strip,
            tls_ca_certificate: node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_ca'].empty? ? '' : Mixlib::ShellOut.new("cat #{node['is_apaas_openshift_cookbook']['openshift_metrics_hawkular_ca']} | ruby -p -e \"gsub(/\n/, '\\n')\"").run_command.stdout.strip,
            tls_destination_ca_certificate: Mixlib::ShellOut.new("cat #{Chef::Config['file_cache_path']}/hosted_metric/ca.crt | ruby -p -e \"gsub(/\n/, '\\n')\"").run_command.stdout.strip
          }
        }
      end
    end

    template 'Generate heapster replication controller' do
      path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/metrics-heapster-rc.yaml"
      source 'heapster.yaml.erb'
      variables(ose_major_version: ose_major_version)
    end

    template 'Generate hawkular-metrics replication controller' do
      path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular_metrics_rc.yaml"
      source 'hawkular_metrics_rc.yaml.erb'
      variables(
        ose_major_version: ose_major_version,
        random_word: random_password
      )
    end

    template 'Generate cassandra replication controller' do
      path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/hawkular-cassandra-rc1.yaml"
      source 'hawkular_cassandra_rc.yaml.erb'
      variables(ose_major_version: ose_major_version)
    end

    [{ 'name' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_prefix'], 'labels' => { 'metrics-infra' => 'hawkular-cassandra' }, 'annotations' => { 'volume.alpha.kubernetes.io/storage-class' => 'dynamic' }, 'access_modes' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_access'] }].each do |pvc|
      template 'Generate hawkular-cassandra persistent volume claims (dynamic)' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/cassandra-#{pvc['name']}-pvc.yaml"
        source 'pvc.yaml.erb'
        variables(pvc: pvc)
        only_if { node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type'] =~ /dynamic/i }
      end
    end

    [{ 'name' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_prefix'], 'labels' => { 'metrics-infra' => 'hawkular-cassandra' }, 'access_modes' => node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_pvc_access'] }].each do |pvc|
      template 'Generate hawkular-cassandra persistent volume claims' do
        path "#{Chef::Config['file_cache_path']}/hosted_metric/templates/cassandra-#{pvc['name']}-pvc.yaml"
        source 'pvc.yaml.erb'
        variables(pvc: pvc)
        not_if { node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type'] =~ /dynamic/i || node['is_apaas_openshift_cookbook']['openshift_metrics_cassandra_storage_type'] =~ /emptydir/i }
      end
    end

    execute 'Applying template files' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} apply -f \
              #{Chef::Config['file_cache_path']}/hosted_metric/templates \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
    end

    execute 'Scaling down cluster to recognize changes' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get rc -l metrics-infra -o name \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']} | \
              xargs --no-run-if-empty #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale \
              --replicas=0 --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
    end

    execute 'Scaling up cluster' do
      command "#{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} get rc -l metrics-infra -o name \
              --config=#{Chef::Config['file_cache_path']}/hosted_metric/admin.kubeconfig \
              --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']} | \
              xargs --no-run-if-empty #{node['is_apaas_openshift_cookbook']['openshift_common_client_binary']} scale \
              --replicas=1 --namespace=#{node['is_apaas_openshift_cookbook']['openshift_metrics_project']}"
    end

    directory "#{Chef::Config['file_cache_path']}/hosted_metric" do
      recursive true
      action :delete
    end
  end
end
