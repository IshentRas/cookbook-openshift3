#
# Cookbook Name:: is_apaas_openshift_cookbook
# Resources:: openshift_add_etcd
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_add_etcd if defined? provides

def whyrun_supported?
  true
end

action :add_node do
  converge_by 'Add new ETCD server' do
    etcd_servers = new_resource.etcd_servers
    etcd_servers.each do |etcd|
      bash 'add_etcd_nodes_if_needed' do
        code <<-BASH
          list_of_nodes=$(etcdctl -C https://${ETCD_SERVER}:${ETCD_CLIENT_PORT} --cert-file $CRT --key-file $KEY --ca-file $CA member list | cut -d' ' -f2)
          if [[ ! $list_of_nodes =~ "$ETCD_NODE_FQDN" ]]
          then
            etcdctl -C https://${ETCD_SERVER}:${ETCD_CLIENT_PORT} --cert-file $CRT --key-file $KEY --ca-file $CA member add $ETCD_NODE_FQDN https://${ETCD_NODE_IP}:${ETCD_PEER_PORT}
          fi
          BASH
        environment(
          'ETCD_SERVER' => etcd_servers.find { |etcd_node| etcd_node['fqdn'] == node['fqdn'] }['ipaddress'],
          'ETCD_CLIENT_PORT' => node['is_apaas_openshift_cookbook']['etcd_client_port'],
          'ETCD_PEER_PORT' => node['is_apaas_openshift_cookbook']['etcd_peer_port'],
          'CRT' => node['is_apaas_openshift_cookbook']['etcd_peer_file'],
          'KEY' => node['is_apaas_openshift_cookbook']['etcd_peer_key'],
          'CA' => node['is_apaas_openshift_cookbook']['etcd_ca_cert'],
          'ETCD_NODE_FQDN' => etcd['fqdn'],
          'ETCD_NODE_IP' => etcd['ipaddress']
        )
        retries 1
        ignore_failure true
      end
    end
  end
end

action :remove_node do
  converge_by 'Remove ETCD server' do
    etcd_servers = new_resource.etcd_servers
    etcd_servers_to_remove = new_resource.etcd_servers_to_remove
    etcd_servers_to_remove.each do |etcd|
      bash 'remove_etcd_nodes_if_needed' do
        code <<-BASH
          list_of_nodes=$(etcdctl -C https://${ETCD_SERVER}:${ETCD_CLIENT_PORT} --cert-file $CRT --key-file $KEY --ca-file $CA member list | cut -d' ' -f2)
          ID_SERVER=$(etcdctl -C https://${ETCD_SERVER}:${ETCD_CLIENT_PORT} --cert-file $CRT --key-file $KEY --ca-file $CA member list | grep $ETCD_NODE_FQDN | cut -d':' -f1)
          if [[ $list_of_nodes =~ "$ETCD_NODE_FQDN" ]]
          then
            etcdctl -C https://${ETCD_SERVER}:${ETCD_CLIENT_PORT} --cert-file $CRT --key-file $KEY --ca-file $CA member remove $ID_SERVER
          fi
          BASH
        environment(
          'ETCD_SERVER' => etcd_servers.find { |etcd_node| etcd_node['fqdn'] == node['fqdn'] }['ipaddress'],
          'ETCD_CLIENT_PORT' => node['is_apaas_openshift_cookbook']['etcd_client_port'],
          'ETCD_PEER_PORT' => node['is_apaas_openshift_cookbook']['etcd_peer_port'],
          'CRT' => node['is_apaas_openshift_cookbook']['etcd_peer_file'],
          'KEY' => node['is_apaas_openshift_cookbook']['etcd_peer_key'],
          'CA' => node['is_apaas_openshift_cookbook']['etcd_ca_cert'],
          'ETCD_NODE_FQDN' => etcd['fqdn']
        )
        retries 1
        ignore_failure true
      end
    end
  end
end
