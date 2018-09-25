module OpenShiftHelper
  # Helper for Openshift
  class NodeHelper
    require 'fileutils'

    def initialize(node)
      @node = node
    end

    def server_method?
      !node['cookbook-openshift3']['openshift_cluster_duty_discovery_id'].nil? && node.run_list.roles.include?("#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_use_role_based_duty_discovery")
    end

    def master_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_master_duty")[0].sort : node['cookbook-openshift3']['master_servers']
    end

    def node_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_node_duty")[0].sort : node['cookbook-openshift3']['node_servers']
    end

    def etcd_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_etcd_duty")[0].sort : node['cookbook-openshift3']['etcd_servers']
    end

    def new_etcd_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_new_etcd_duty")[0].sort : node['cookbook-openshift3']['new_etcd_servers']
    end

    def remove_etcd_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_remove_etcd_duty")[0].sort : node['cookbook-openshift3']['remove_etcd_servers']
    end

    def lb_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_lb_duty")[0].sort : node['cookbook-openshift3']['lb_servers']
    end

    def first_master
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_first_master_duty")[0][0] : master_servers.first # ~FC001, ~FC019
    end

    def first_etcd
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_first_etcd_duty")[0][0] : etcd_servers.first # ~FC001, ~FC019
    end

    def certificate_server
      if server_method?
        case Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_certificate_server_duty")[0].length
        when 0
          first_master
        else
          Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_certificate_server_duty")[0][0]
        end
      else
        node['cookbook-openshift3']['certificate_server'] == {} ? first_master : node['cookbook-openshift3']['certificate_server']
      end
    end

    def master_peers
      master_servers.reject { |server_master| server_master['fqdn'] == first_master['fqdn'] }
    end

    def on_master_server?
      master_servers.any? { |server_master| server_master['fqdn'] == node['fqdn'] }
    end

    def on_node_server?
      node_servers.any? { |server_node| server_node['fqdn'] == node['fqdn'] }
    end

    def on_etcd_server?
      etcd_servers.any? { |server_etcd| server_etcd['fqdn'] == node['fqdn'] }
    end

    def on_new_etcd_server?
      new_etcd_servers.any? { |new_server_etcd| new_server_etcd['fqdn'] == node['fqdn'] }
    end

    def on_remove_etcd_server?
      remove_etcd_servers.any? { |remove_server_etcd| remove_server_etcd['fqdn'] == node['fqdn'] }
    end

    def on_first_master?
      first_master['fqdn'] == node['fqdn']
    end

    def on_first_etcd?
      first_etcd['fqdn'] == node['fqdn']
    end

    def on_certificate_server?
      certificate_server['fqdn'] == node['fqdn']
    end

    def on_control_plane_server?
      on_certificate_server? || on_etcd_server? || on_master_server?
    end

    def should_be_configured?
      on_control_plane_server? || on_node_server?
    end

    def remove_dir(path)
      FileUtils.rm_rf(Dir.glob(path))
    end

    def backup_dir(src, dest)
      FileUtils.cp_r(src, dest)
    end

    def change_owner(user, group, dir)
      FileUtils.chown_R user, group, dir
    end

    def bundle_etcd_ca(old, new)
      File.open(new, 'w+') { |f| f.puts old.map { |s| IO.read(s) } }
    end

    def turn_off_swap
      regex = /(^[^#].*swap.*)\n/m
      fstab_file = Chef::Util::FileEdit.new('/etc/fstab')
      fstab_file.search_file_replace(regex, '# \1')
      fstab_file.write_file
      remove_duplicates('/etc/fstab')
      Mixlib::ShellOut.new('/usr/sbin/swapoff -a').run_command
    end

    def remove_duplicates(filename)
      text = File.read(filename)
      lines = text.split("\n")
      new_contents = lines.uniq.join("\n")
      File.open(filename, 'w') { |file| file.puts new_contents }
    end

    def check_certificate_server_cluster
      ca_exist = File.exist?("#{node['cookbook-openshift3']['openshift_master_config_dir']}/ca.crt")
      dir_exist = File.directory?(node['cookbook-openshift3']['master_certs_generated_certs_dir'])
      ca_exist && !dir_exist
    end

    def check_certificate_server_etcd
      ca_exist = File.exist?("#{node['cookbook-openshift3']['legacy_etcd_ca_dir']}/ca.crt")
      dir_exist = File.directory?(node['cookbook-openshift3']['etcd_certs_generated_certs_dir'])
      ca_exist && !dir_exist
    end

    def get_nodevar(var)
      if node_servers.any? { |server_node| server_node['fqdn'] == node['fqdn'] && server_node.key?(var) }
        node_servers.find { |server_node| server_node['fqdn'] == node['fqdn'] }[var.to_s]
      else
        node['cookbook-openshift3'][var.to_s]
      end
    end

    def getdockerversion
      if ::Mixlib::ShellOut.new('rpm -q docker').run_command.error?
        node['cookbook-openshift3']['docker_version'].nil? || node['cookbook-openshift3']['docker_version'].split('.')[1].to_i >= 12
      else
        current_version = Mixlib::ShellOut.new('repoquery --plugins --installed --qf \'%{version}\' docker').run_command.stdout.strip
        current_version.split('.')[1].to_i >= 12
      end
    end

    def removing_etcd?
      etcd_servers.any? { |item| remove_etcd_servers.include? item }
    end

    def check_master_upgrade?(first_etcd, version)
      if version.to_i < 36
        ::Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 ls /migration/#{version}/#{node['fqdn']}").run_command.error?
      elsif version.to_i == 36
        config_options = YAML.load_file("#{node['cookbook-openshift3']['openshift_common_master_dir']}/master/master-config.yaml")
        if config_options['kubernetesMasterConfig']['apiServerArguments'].key?('storage-backend')
          ::Mixlib::ShellOut.new("test `ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/#{version}/#{node['fqdn']} --print-value-only` == 'ok'").run_command.error?
        else
          ::Mixlib::ShellOut.new("/usr/bin/etcdctl --cert-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --ca-file #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt -C https://#{first_etcd['ipaddress']}:2379 ls /migration/#{version}/#{node['fqdn']}").run_command.error?
        end
      else
        ::Mixlib::ShellOut.new("test `ETCDCTL_API=3 /usr/bin/etcdctl --cert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.crt --key #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-client.key --cacert #{node['cookbook-openshift3']['openshift_master_config_dir']}/master.etcd-ca.crt --endpoints https://#{first_etcd['ipaddress']}:2379 get /migration/#{version}/#{node['fqdn']} --print-value-only` == 'ok'").run_command.error?
      end
    end

    def openshift_node_groups
      if node_servers.any? { |server_node| server_node['fqdn'] == node['fqdn'] && server_node.key?('openshift_node_groups') }
        node_servers.find { |server_node| server_node['fqdn'] == node['fqdn'] }['openshift_node_groups']
      else
        'node-config-master' if on_master_server?
        'node-config-compute' if on_node_server?
      end
    end

    def check_pod_not_ready?(namespace, label, number)
      ::Mixlib::ShellOut.new("[[ $(#{node['cookbook-openshift3']['openshift_client_binary']} get pod -l #{label} --config=#{node['cookbook-openshift3']['openshift_master_config_dir']}/admin.kubeconfig -n #{namespace} -o jsonpath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' | grep -o -w Ready | wc -w) -eq #{number.to_i} ]]").run_command.error?
    end

    protected

    attr_reader :node
  end

  # Helper for Openshift
  class UtilHelper
    def initialize(filepath)
      return ArgumentError, "File '#{filepath}' does not exist" unless File.exist?(filepath)

      @contents = File.open(filepath, &:read)
      @original_pathname = filepath
      @changes = false
    end

    def search_file_replace_line(regex, newline)
      @changes ||= contents.gsub!(regex, newline)
    end

    def write_file
      if @changes
        backup_pathname = original_pathname + '.old'
        FileUtils.cp(original_pathname, backup_pathname, preserve: true)
        File.open(original_pathname, 'w') do |newfile|
          newfile.write(contents)
          newfile.flush
        end
      end
      @changes = false
    end

    private

    attr_reader :contents, :original_pathname
  end

  # Helper for (Re)deploying Certs
  class CertHelper
    require 'openssl'

    def valid_certificate?(ca_path, cert_path)
      ca = OpenSSL::X509::Certificate.new(File.read(ca_path))
      cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
      cert.verify(ca.public_key)
    rescue OpenSSL::X509::CertificateError, Errno::ENOENT
      false
    end
  end
end
