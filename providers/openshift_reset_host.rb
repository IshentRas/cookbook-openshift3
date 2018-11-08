#
# Cookbook Name:: is_apaas_openshift_cookbook
# Providers:: openshift_reset_host
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_reset_host if defined? provides

def whyrun_supported?
  true
end

action :reset do
  converge_by 'Resetting server' do
    helper = OpenShiftHelper::NodeHelper.new(node)
    is_node_server = helper.on_node_server?

    service 'docker' do
      action :nothing
      retry_delay 2
      retries 5
    end

    service 'atomic-openshift-node' do
      action :nothing
    end

    service 'etcd' do
      action :nothing
    end

    service 'etcd-container' do
      action :nothing
    end

    ruby_block 'Refresh SystemD services' do
      block do
        Mixlib::ShellOut.new('systemctl reset-failed').run_command
        Mixlib::ShellOut.new('systemctl daemon-reload').run_command
      end
      notifies :stop, 'service[atomic-openshift-node]', :before
      notifies :disable, 'service[atomic-openshift-node]', :before
      notifies :stop, 'service[atomic-openshift-master]', :before
      notifies :disable, 'service[atomic-openshift-master]', :before
      notifies :stop, 'service[atomic-openshift-master-api]', :before
      notifies :disable, 'service[atomic-openshift-master-api]', :before
      notifies :stop, 'service[atomic-openshift-master-controllers]', :before
      notifies :disable, 'service[atomic-openshift-master-controllers]', :before
      notifies :stop, 'service[etcd]', :before
      notifies :disable, 'service[etcd]', :before
      notifies :stop, 'service[etcd-container]', :before if node['is_apaas_openshift_cookbook']['deploy_containerized']
      notifies :disable, 'service[etcd-container]', :before if node['is_apaas_openshift_cookbook']['deploy_containerized']
      notifies :stop, 'service[openvswitch]', :before
      notifies :disable, 'service[openvswitch]', :before
      notifies :stop, 'service[haproxy]', :before
      notifies :disable, 'service[haproxy]', :before
    end

    execute 'Remove br0 interface' do
      command 'ovs-vsctl del-br br0 || true'
    end

    %w[lbr0 vlinuxbr vovsbr].each do |interface|
      execute "Remove linux interfaces #{interface}" do
        command "ovs-vsctl del #{interface} || true"
      end
    end

    ::Dir.glob('/var/lib/origin/openshift.local.volumes/**/*').select { |fn| ::File.directory?(fn) }.each do |dir|
      execute "Unmount kube volumes for #{dir}" do
        command "$ACTION #{dir} || true"
        environment 'ACTION' => 'umount'
      end
    end

    %w[atomic-openshift atomic-openshift-master atomic-openshift-node atomic-openshift-sdn-ovs atomic-openshift-clients cockpit-bridge cockpit-docker cockpit-shell cockpit-ws openvswitch tuned-profiles-atomic-openshift-node atomic-openshift-excluder atomic-openshift-docker-excluder etcd haproxy].each do |remove_package|
      package remove_package do
        action :remove
        ignore_failure true
      end
    end

    %W[/etc/origin/master /etc/origin/node /var/lib/origin/* /etc/dnsmasq.d/origin-dns.conf /etc/dnsmasq.d/origin-upstream-dns.conf /etc/NetworkManager/dispatcher.d/99-origin-dns.sh /etc/sysconfig/openvswitch* /etc/sysconfig/atomic-openshift-node /etc/sysconfig/atomic-openshift-node-dep /etc/systemd/system/openvswitch.service* /etc/systemd/system/atomic-openshift-master.service /etc/systemd/system/atomic-openshift-master-controllers.service* /etc/systemd/system/atomic-openshift-master-api.service* /etc/systemd/system/atomic-openshift-node-dep.service /etc/systemd/system/atomic-openshift-node.service /etc/systemd/system/atomic-openshift-node.service.wants /run/openshift-sdn /etc/sysconfig/atomic-openshift-master* /etc/sysconfig/atomic-openshift-master-api* /etc/systemd/system/docker.service.wants/atomic-openshift-master-controllers.service /etc/sysconfig/atomic-openshift-master-controllers* /etc/sysconfig/openvswitch* /root/.kube /usr/share/openshift/examples /usr/share/openshift/hosted /usr/local/bin/openshift /usr/local/bin/oadm /usr/local/bin/oc /usr/local/bin/kubectl #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/* /etc/systemd/system/etcd.service.d /etc/systemd/system/etcd* /usr/lib/systemd/system/etcd* /etc/profile.d/etcdctl.sh #{node['is_apaas_openshift_cookbook']['openshift_master_api_systemd']} #{node['is_apaas_openshift_cookbook']['openshift_master_controllers_systemd']} /etc/bash_completion.d/oc /etc/systemd/system/haproxy.service.d /etc/haproxy /etc/yum.repos.d/centos-openshift-origin*.repo].each do |file_to_remove|
      helper.remove_dir(file_to_remove)
    end

    ::Dir.glob('/var/lib/origin/openshift.local.volumes/**/*').select { |fn| ::File.directory?(fn) }.each do |dir|
      execute "Force Unmount kube volumes #{dir}" do
        command "$ACTION #{dir} || true"
        environment 'ACTION' => 'umount'
      end
    end

    helper.remove_dir('/var/lib/origin/*')

    execute 'Clean Iptables rules' do
      command 'sed -i \'/OS_FIREWALL_ALLOW/d\'  /etc/sysconfig/iptables'
    end

    helper.remove_dir('/etc/iptables.d/firewall_*')

    execute 'Clean Iptables saved rules' do
      command 'sed -i \'/OS_FIREWALL_ALLOW/d\' /etc/sysconfig/iptables.save'
      only_if '[ -f /etc/sysconfig/iptables.save ]'
    end

    Mixlib::ShellOut.new('systemctl daemon-reload').run_command

    execute '/usr/sbin/rebuild-iptables' do
      retry_delay 10
      retries 3
    end

    if is_node_server || node['is_apaas_openshift_cookbook']['deploy_containerized']

      ruby_block 'Remove docker directory (Contents Only)' do
        block do
          helper.remove_dir('/var/lib/docker/*')
        end
        notifies :stop, 'service[docker]', :before
      end

      execute 'Resetting docker storage' do
        command '/usr/bin/docker-storage-setup --reset'
      end

      package %w[container-selinux docker docker-client docker-common docker-rhel-push-plugin] do
        action :remove
      end

      ruby_block 'Reload SystemD Daemon services' do
        block do
          Mixlib::ShellOut.new('systemctl daemon-reload').run_command
        end
      end
    end
  end
end
