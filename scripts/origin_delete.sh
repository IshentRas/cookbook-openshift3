#!/bin/bash
set -e
clear
cat << EOF

############################################################
#                    DELETE OSE                            #
############################################################
EOF
### Create the chef-local mode infrastructure
mkdir -p ~/chef-solo-example/{backup,cache,roles,cookbooks,environments}
cd ~/chef-solo-example/cookbooks
### Installing dependencies
echo "Installing prerequisite packages, please wait..."
yum -y install -q https://packages.chef.io/files/stable/chef/12.17.44/el/7/chef-12.17.44-1.el7.x86_64.rpm git
### Installing cookbooks
[ -d ~/chef-solo-example/cookbooks/cookbook-openshift3 ] || git clone -q https://github.com/IshentRas/cookbook-openshift3.git
[ -d ~/chef-solo-example/cookbooks/iptables ] || git clone -q https://github.com/chef-cookbooks/iptables.git
[ -d ~/chef-solo-example/cookbooks/yum ] || git clone -q https://github.com/chef-cookbooks/yum.git
[ -d ~/chef-solo-example/cookbooks/selinux_policy ] || git clone -q https://github.com/BackSlasher/chef-selinuxpolicy.git selinux_policy
[ -d ~/chef-solo-example/cookbooks/compat_resource ] || git clone -q https://github.com/chef-cookbooks/compat_resource.git
cd ~/chef-solo-example
### Specify the configuration details for chef-solo
cat << EOF > ~/chef-solo-example/solo.rb
cookbook_path [
               '/root/chef-solo-example/cookbooks',
               '/root/chef-solo-example/site-cookbooks'
              ]
environment_path '/root/chef-solo-example/environments'
file_backup_path '/root/chef-solo-example/backup'
file_cache_path '/root/chef-solo-example/cache'
log_location STDOUT
solo true
EOF
### Delete OSE !!!!
chef-solo -o recipe[cookbook-openshift3::adhoc_uninstall] -c ~/chef-solo-example/solo.rb
cat << EOF

##### Uninstallation DONE ######
#####                     ######
Next steps for you :

1) Reboot this server

EOF
