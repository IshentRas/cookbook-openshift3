#!/bin/bash
set -e
clear
cat << EOF

############################################################
# This installer is suitable for a standalone installation #
# "All in the box" (Master and Node in a server)           #
############################################################

EOF
IP_DETECT=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
DF=""
read -p "Please enter the FQDN of the server: " FQDN
read -p "Please enter the IP of the server (Auto Detect): $IP_DETECT" IP

if [ -z $IP ] 
then IP=$IP_DETECT
fi

# Add the above information in /etc/hosts
# Remove existing entries
sed -i "/$IP/d" /etc/hosts
echo -e "$IP\t$FQDN" >> /etc/hosts
### Update the server
echo "Updating system, please wait..."
yum -y update -q -e 0
### Create the chef-local mode infrastructure
mkdir -p ~/chef-solo-example/{backup,cache,roles,cookbooks,environments}
cd ~/chef-solo-example/cookbooks
### Installing dependencies
echo "Installing prerequisite packages, please wait..."
curl -s -L https://omnitruck.chef.io/install.sh | bash
yum install -y git
### Installing cookbooks
[ -d ~/chef-solo-example/cookbooks/cookbook-openshift3 ] || git clone -q https://github.com/IshentRas/cookbook-openshift3.git
[ -d ~/chef-solo-example/cookbooks/iptables ] || git clone -q https://github.com/chef-cookbooks/iptables.git
[ -d ~/chef-solo-example/cookbooks/yum ] || git clone -q https://github.com/chef-cookbooks/yum.git
[ -d ~/chef-solo-example/cookbooks/selinux_policy ] || git clone -q https://github.com/BackSlasher/chef-selinuxpolicy.git selinux_policy
[ -d ~/chef-solo-example/cookbooks/compat_resource ] || git clone -q https://github.com/chef-cookbooks/compat_resource.git
cd ~/chef-solo-example
### Create the dedicated environment for Origin deployment
cat << EOF > environments/origin.json
{
  "name": "origin",
  "description": "",
  "cookbook_versions": {

  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {

  },
  "override_attributes": {
    "cookbook-openshift3": {
      "openshift_common_public_hostname": "console.${IP}.nip.io",
      "openshift_deployment_type": "origin",
      "openshift_common_default_nodeSelector": "region=infra",
      "deploy_containerized": true,
      "deploy_example": true,
      "openshift_master_router_subdomain": "cloudapps.${IP}.nip.io",
      "master_servers": [
        {
          "fqdn": "${FQDN}",
          "ipaddress": "$IP"
        }
      ],
      "node_servers": [
        {
          "fqdn": "${FQDN}",
          "ipaddress": "$IP",
          "schedulable": true,
          "labels": "region=infra"
        }
      ]
    }
  }
}
EOF
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
### Deploy OSE !!!!
chef-solo --environment origin -o recipe[cookbook-openshift3] -c ~/chef-solo-example/solo.rb
if ! $(oc get project test --config=/etc/origin/master/admin.kubeconfig &> /dev/null)
then 
  # Create a demo project
  oc adm new-project demo --display-name="Origin Demo Project" --admin=demo
fi
# Reset password for demo user
htpasswd -b /etc/origin/openshift-passwd demo 1234
cat << EOF

##### Installation DONE ######
#####                   ######
Your installation of Origin is completed.

A demo user has been created for you.
Password is : 1234

Access the console here : https://console.${IP}.nip.io:8443/console

You can also login via CLI : oc login -u demo

Next steps for you :

1) Read the documentation : https://docs.openshift.org/latest/welcome/index.html

You should disconnect and reconnect so as to get the benefit of bash-completion on commands

##############################
########## DONE ##############
EOF
