module OpenShiftHelper
  class NodeHelper
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

    def lb_servers
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_lb_duty")[0].sort : node['cookbook-openshift3']['lb_servers']
    end

    def first_master
      server_method? ? Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_first_master_duty")[0][0] : master_servers.first
    end

    def certificate_server
      if server_method?
        certificate_server = Chef::Search::Query.new.search(:node, "role:#{node['cookbook-openshift3']['openshift_cluster_duty_discovery_id']}_openshift_certificate_server_duty")[0][0]
        certificate_server.nil? ? first_master : certificate_server
      else
        node['cookbook-openshift3']['certificate_server'] == {} ? first_master : node['cookbook-openshift3']['certificate_server']
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

    def on_certificate_server?
      certificate_server['fqdn'] == node['fqdn']
    end

    protected

    attr_reader :node
  end
end
