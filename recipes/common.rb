#
# Cookbook Name:: cookbook-openshift3
# Recipe:: common
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

certificate_server = node['cookbook-openshift3']['certificate_server'] == {} ? node['cookbook-openshift3']['master_servers'].first : node['cookbook-openshift3']['certificate_server']

include_recipe 'iptables::default'
include_recipe 'selinux_policy::default'

iptables_rule 'firewall_jump_rule' do
  action :enable
end

lb_servers = node['cookbook-openshift3']['lb_servers']

if !lb_servers.nil? && lb_servers.find { |lb| lb['fqdn'] == node['fqdn'] }
  package 'haproxy'

  node['cookbook-openshift3']['enabled_firewall_rules_lb'].each do |rule|
    iptables_rule rule do
      action :enable
    end
  end

  directory '/etc/systemd/system/haproxy.service.d' do
    recursive true
  end

  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy.conf.erb'
    variables lazy {
      {
        master_servers: node['cookbook-openshift3']['master_servers'],
        maxconn: node['cookbook-openshift3']['lb_default_maxconn'].nil? ? '20000' : node['cookbook-openshift3']['lb_default_maxconn'],
      }
    }
    notifies :restart, 'service[haproxy]', :immediately
  end

  template '/etc/systemd/system/haproxy.service.d/limits.conf' do
    source 'haproxy.service.erb'
    variables nofile: node['cookbook-openshift3']['lb_limit_nofile'].nil? ? '100000' : node['cookbook-openshift3']['lb_limit_nofile']
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :restart, 'service[haproxy]', :immediately
  end
end

if node['cookbook-openshift3']['install_method'].eql? 'yum'
  node['cookbook-openshift3']['yum_repositories'].each do |repo|
    yum_repository repo['name'] do
      description "#{repo['name'].capitalize} aPaaS Repository"
      baseurl repo['baseurl']
      gpgcheck repo['gpgcheck'] if repo.key?(:gpgcheck) && !repo['gpgcheck'].nil?
      gpgkey repo['gpgkey'] if repo.key?(:gpgkey) && !repo['gpgkey'].nil?
      sslverify repo['sslverify'] if repo.key?(:sslverify) && !repo['sslverify'].nil?
      exclude repo['exclude'] if repo.key?(:exclude) && !repo['exclude'].nil?
      enabled repo['enabled'] if repo.key?(:enabled) && !repo['enabled'].nil?
      action :create
    end
  end
end

service 'firewalld' do
  action [:stop, :disable]
end

package 'deltarpm'

node['cookbook-openshift3']['core_packages'].each do |pkg|
  package pkg
end

package 'docker' do
  version node['cookbook-openshift3']['docker_version'] unless node['cookbook-openshift3']['docker_version'].nil?
end

bash "Configure Docker to use the default FS type for #{node['fqdn']}" do
  code <<-EOF
    correct_fs=$(df -T /var | egrep -o 'xfs|ext4')
    sed -i "s/xfs/$correct_fs/" /usr/bin/docker-storage-setup
  EOF
  not_if "grep $(df -T /var | egrep -o 'xfs|ext4') /usr/bin/docker-storage-setup"
end

template '/etc/sysconfig/docker-storage-setup' do
  source 'docker-storage.erb'
end

template '/etc/sysconfig/docker' do
  source 'service_docker.sysconfig.erb'
  notifies :restart, 'service[docker]', :immediately
  notifies :enable, 'service[docker]', :immediately
end

ruby_block 'Change HTTPD port xfer' do
  block do
    # Minimal implementation of Chef::FileEdit, which can idempotently replace
    # a single `Listen` line with multiple `Listen` lines (one per http_address)
    # if #search_file_replace_line is invoked with a multiline Regexp.
    class MyFileEdit
      def initialize(filepath)
        raise ArgumentError, "File '#{filepath}' does not exist" unless File.exist?(filepath)
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

    http_addresses = [node['cookbook-openshift3']['etcd_servers'], node['cookbook-openshift3']['master_servers'], [certificate_server]].each_with_object([]) do |candidate_servers, memo|
      this_server = candidate_servers.find { |server_candidate| server_candidate['fqdn'] == node['fqdn'] }
      memo << this_server['ipaddress'] if this_server
    end.sort.uniq

    openshift_settings = MyFileEdit.new('/etc/httpd/conf/httpd.conf')
    openshift_settings.search_file_replace_line(
      /(^Listen.*?\n)+/m,
      http_addresses.map { |addr| "Listen #{addr}:#{node['cookbook-openshift3']['httpd_xfer_port']}\n" }.join
    )
    openshift_settings.write_file
  end
  action :nothing
  notifies :restart, 'service[httpd]', :immediately
end

include_recipe 'cookbook-openshift3::certificate_server'
include_recipe 'cookbook-openshift3::cloud_provider'
