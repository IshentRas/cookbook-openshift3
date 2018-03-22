#
# Cookbook Name:: is_apaas_openshift_cookbook
# Providers:: openshift_delete_host
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

use_inline_resources
provides :openshift_delete_host if defined? provides

def whyrun_supported?
  true
end

action :delete do
  converge_by 'Uninstalling OpenShift' do
    helper = OpenShiftHelper::NodeHelper.new(node)

    service 'atomic-openshift-node' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'openvswitch' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'atomic-openshift-master' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'atomic-openshift-master-api' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'atomic-openshift-master-controllers' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'etcd' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'etcd_container' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'haproxy' do
      action %i(stop disable)
      ignore_failure true
    end

    service 'docker' do
      action :stop
      only_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
    end

    Mixlib::ShellOut.new('systemctl reset-failed').run_command
    Mixlib::ShellOut.new('systemctl daemon-reload').run_command
    Mixlib::ShellOut.new('systemctl unmask firewalld').run_command

    execute 'Remove br0 interface' do
      command 'ovs-vsctl del-br br0 || true'
    end

    %w(lbr0 vlinuxbr vovsbr).each do |interface|
      execute "Remove linux interfaces #{interface}" do
        command "ovs-vsctl del #{interface} || true"
      end
    end

    ::Dir.glob('/var/lib/origin/openshift.local.volumes/**/*').select { |fn| ::File.directory?(fn) }.each do |dir|
      execute 'Unmount kube volumes' do
        command "$ACTION #{dir} || true"
        environment 'ACTION' => 'umount'
      end
    end

    %w(atomic-openshift atomic-openshift-master atomic-openshift-node atomic-openshift-sdn-ovs atomic-openshift-clients cockpit-bridge cockpit-docker cockpit-shell cockpit-ws openvswitch tuned-profiles-atomic-openshift-node atomic-openshift-excluder atomic-openshift-docker-excluder etcd httpd haproxy).each do |remove_package|
      package remove_package do
        action :remove
        ignore_failure true
      end
    end

    %W(/var/lib/origin/* /etc/dnsmasq.d/origin-dns.conf /etc/dnsmasq.d/origin-upstream-dns.conf /etc/NetworkManager/dispatcher.d/99-origin-dns.sh /etc/atomic-openshift /etc/sysconfig/openvswitch* /etc/sysconfig/atomic-openshift-node /etc/sysconfig/atomic-openshift-node-dep /etc/systemd/system/openvswitch.service* /etc/systemd/system/atomic-openshift-master.service /etc/systemd/system/atomic-openshift-master-controllers.service* /etc/systemd/system/atomic-openshift-master-api.service* /etc/systemd/system/atomic-openshift-node-dep.service /etc/systemd/system/atomic-openshift-node.service /etc/systemd/system/atomic-openshift-node.service.wants /run/openshift-sdn /etc/sysconfig/atomic-openshift-master* /etc/sysconfig/atomic-openshift-master-api* /etc/systemd/system/docker.service.wants/atomic-openshift-master-controllers.service /etc/sysconfig/atomic-openshift-master-controllers* /etc/sysconfig/openvswitch* /root/.kube /usr/share/openshift/examples /usr/share/openshift/hosted /usr/local/bin/openshift /usr/local/bin/oadm /usr/local/bin/oc /usr/local/bin/kubectl #{node['is_apaas_openshift_cookbook']['etcd_conf_dir']}/* /etc/httpd/* /var/lib/etcd/* /etc/systemd/system/etcd.service.d /etc/systemd/system/etcd_container.service* /etc/profile.d/etcdctl.sh #{node['is_apaas_openshift_cookbook']['openshift_common_base_dir']}/* /var/www/html/* #{node['is_apaas_openshift_cookbook']['openshift_master_api_systemd']} #{node['is_apaas_openshift_cookbook']['openshift_master_controllers_systemd']} /etc/bash_completion.d/oc /etc/systemd/system/haproxy.service.d /etc/haproxy /etc/yum.repos.d/centos-openshift-origin*.repo).each do |file_to_remove|
      helper.remove_dir(file_to_remove)
    end

    ::Dir.glob('/var/lib/origin/openshift.local.volumes/**/*').select { |fn| ::File.directory?(fn) }.each do |dir|
      execute 'Unmount kube volumes' do
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

    service 'docker' do
      action :start
      only_if { node['is_apaas_openshift_cookbook']['deploy_containerized'] }
    end
  end
end
