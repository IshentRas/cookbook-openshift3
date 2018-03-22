module OpenShiftHelper
  # Helper for Openshift
  class NodeHelper
    require 'openssl'
    require 'fileutils'

    def initialize(node)
      @node = node
    end

    def server_method?
      !node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id'].nil? && node.run_list.roles.include?("#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_use_role_based_duty_discovery")
    end

    def master_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_master_duty")[0].sort : node['is_apaas_openshift_cookbook']['master_servers']
    end

    def node_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_node_duty")[0].sort : node['is_apaas_openshift_cookbook']['node_servers']
    end

    def etcd_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_etcd_duty")[0].sort : node['is_apaas_openshift_cookbook']['etcd_servers']
    end

    def lb_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_lb_duty")[0].sort : node['is_apaas_openshift_cookbook']['lb_servers']
    end

    def first_master
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_first_master_duty")[0][0] : master_servers.first # ~FC001, ~FC019
    end

    def first_etcd
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_first_etcd_duty")[0][0] : etcd_servers.first # ~FC001, ~FC019
    end

    def certificate_server
      if server_method?
        certificate_server = Chef::Search::Query.new.search(:node, "role:#{node['is_apaas_openshift_cookbook']['openshift_cluster_duty_discovery_id']}_openshift_certificate_server_duty")[0][0] # ~FC001, ~FC019
        certificate_server.nil? ? first_master : certificate_server
      else
        node['is_apaas_openshift_cookbook']['certificate_server'] == {} ? first_master : node['is_apaas_openshift_cookbook']['certificate_server']
      end
    end

    def master_peers
      master_servers.reject { |server_master| server_master['fqdn'] == first_master['fqdn'] }
    end

    def on_master_server?
      master_servers.find { |server_master| server_master['fqdn'] == node['fqdn'] }
    end

    def on_node_server?
      node_servers.find { |server_node| server_node['fqdn'] == node['fqdn'] }
    end

    def on_etcd_server?
      etcd_servers.find { |server_etcd| server_etcd['fqdn'] == node['fqdn'] }
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

    def remove_dir(path)
      FileUtils.rm_rf(Dir.glob(path))
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
end
