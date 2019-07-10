#
# Cookbook Name:: cookbook-openshift3
# Providers:: openshift_delete_host
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

provides :openshift_delete_host if defined? provides

def whyrun_supported?
  true
end

action :delete do
  converge_by 'Uninstalling OpenShift' do
    helper = OpenShiftHelper::NodeHelper.new(node)

    log 'Starting uninstall' do
      level :info
      notifies :stop, 'service[docker]', :immediately
      notifies :disable, 'service[docker]', :immediately
      notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
      notifies :disable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-node]", :immediately
      notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately
      notifies :disable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master]", :immediately
      notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
      notifies :disable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-api]", :immediately
      notifies :stop, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
      notifies :disable, "service[#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers]", :immediately
      notifies :stop, 'service[openvswitch]', :immediately
      notifies :disable, 'service[openvswitch]', :immediately
      notifies :stop, 'service[etcd-service]', :immediately
      notifies :disable, 'service[etcd-service]', :immediately
      notifies :stop, 'service[haproxy]', :immediately
      notifies :disable, 'service[haproxy]', :immediately
    end

    Mixlib::ShellOut.new('systemctl reset-failed').run_command
    Mixlib::ShellOut.new('systemctl daemon-reload').run_command
    Mixlib::ShellOut.new('systemctl unmask firewalld').run_command

    execute 'Remove br0 interface' do
      command 'ovs-vsctl del-br br0 || true'
    end

    %w[lbr0 vlinuxbr vovsbr].each do |interface|
      execute "Remove linux interfaces #{interface}" do
        command "ip link del #{interface} || true"
      end
    end

    execute 'Remove virtual device' do
      command 'nmcli device delete tun0 || true'
    end

    ::Dir.glob('/var/lib/origin/openshift.local.volumes/**/*').select { |fn| ::File.directory?(fn) }.each do |dir|
      execute "Unmount kube volumes for #{dir}" do
        command "$ACTION #{dir} || true"
        environment 'ACTION' => 'umount'
      end
    end

    %W[#{node['cookbook-openshift3']['openshift_service_type']} #{node['cookbook-openshift3']['openshift_service_type']}-master #{node['cookbook-openshift3']['openshift_service_type']}-node #{node['cookbook-openshift3']['openshift_service_type']}-sdn-ovs #{node['cookbook-openshift3']['openshift_service_type']}-clients cockpit-bridge cockpit-docker cockpit-shell cockpit-ws openvswitch tuned-profiles-#{node['cookbook-openshift3']['openshift_service_type']}-node #{node['cookbook-openshift3']['openshift_service_type']}-excluder #{node['cookbook-openshift3']['openshift_service_type']}-docker-excluder etcd httpd haproxy docker docker-client docker-common docker-rhel-push-plugin #{node['cookbook-openshift3']['openshift_service_type']}-hyperkube].each do |remove_package|
      package remove_package do
        action :remove
        ignore_failure true
      end
    end

    %W[/var/lib/origin/* /var/lib/docker/* /var/run/docker* /etc/docker* /etc/sysconfig/docker* /etc/dnsmasq.d/origin-dns.conf /etc/dnsmasq.d/origin-upstream-dns.conf /etc/NetworkManager/dispatcher.d/99-origin-dns.sh /etc/#{node['cookbook-openshift3']['openshift_service_type']} /etc/sysconfig/openvswitch* /etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node /etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node-dep /etc/systemd/system/openvswitch.service* /etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master.service /etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers.service* /etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-master-api.service* /etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-node-dep.service /etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-node.service /etc/systemd/system/#{node['cookbook-openshift3']['openshift_service_type']}-node.service.wants /run/openshift-sdn /etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master* /etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-api* /etc/systemd/system/docker.service.wants/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers.service /etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-master-controllers* /etc/sysconfig/openvswitch* /root/.kube /usr/share/openshift/examples /usr/share/openshift/hosted /usr/local/bin/openshift /usr/local/bin/oadm /usr/local/bin/oc /usr/local/bin/kubectl #{node['cookbook-openshift3']['etcd_conf_dir']}/* /etc/httpd/* /var/lib/etcd/* /etc/systemd/system/etcd.service.d /etc/systemd/system/etcd* /usr/lib/systemd/system/etcd* /etc/profile.d/etcdctl.sh #{node['cookbook-openshift3']['openshift_common_base_dir']}/* /var/www/html/* #{node['cookbook-openshift3']['openshift_master_api_systemd']} #{node['cookbook-openshift3']['openshift_master_controllers_systemd']} /etc/bash_completion.d/oc /etc/systemd/system/haproxy.service.d /etc/haproxy /etc/yum.repos.d/centos-openshift-origin*.repo #{node['cookbook-openshift3']['openshift_hosted_logging_flag']} #{node['cookbook-openshift3']['openshift_hosted_metrics_flag']} /etc/sysconfig/#{node['cookbook-openshift3']['openshift_service_type']}-node* /usr/local/bin/master-* /usr/local/bin/openshift-node /usr/local/share/info/.upgrade*].each do |file_to_remove|
      helper.remove_dir(file_to_remove)
    end

    ::Dir.glob('/var/lib/origin/openshift.local.volumes/**/*').select { |fn| ::File.directory?(fn) }.each do |dir|
      execute "Force Unmount kube volumes #{dir}" do
        command "$ACTION #{dir} || true"
        environment 'ACTION' => 'umount'
      end
    end

    execute 'Clean Iptables rules' do
      command 'sed -i \'/OS_FIREWALL_ALLOW/d\'  /etc/sysconfig/iptables'
    end

    execute 'Clean Iptables saved rules' do
      command 'sed -i \'/OS_FIREWALL_ALLOW/d\' /etc/sysconfig/iptables.save'
      only_if '[ -f /etc/sysconfig/iptables.save ]'
    end

    ruby_block 'Remove left-over files' do
      block do
        helper.remove_dir('/etc/iptables.d/firewall_*')
        helper.remove_dir('/var/lib/origin/*')
        helper.remove_dir('/var/lib/docker/*')
        helper.remove_dir('/etc/cni/net.d/*')
        helper.remove_dir('/var/lib/cni/networks/*')
        helper.remove_dir("#{Chef::Config['file_cache_path']}/*")
      end
    end

    Mixlib::ShellOut.new('systemctl daemon-reload').run_command

    log 'Finish uninstall' do
      level :info
      notifies :restart, 'service[iptables]', :immediately
      notifies :restart, 'service[NetworkManager]', :immediately
    end

    execute '/usr/sbin/rebuild-iptables' do
      retry_delay 10
      retries 3
    end
  end
end
