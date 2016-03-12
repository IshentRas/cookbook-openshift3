!/bin/bash
#
clear
cat << EOF

############################################################
# This installer is suitable for a standalone installation #
# "All in the box" (Master and Node in a server)           #
############################################################

EOF
read -p "Please enter the FQDN of the server: " FQDN
read -p "Please enter the IP of the server: " IP
#
# Add the above information in /etc/hosts
# Remove existing entries
sed -i "/$IP/d" /etc/hosts
echo -e "$IP\t$FQDN" >> /etc/hosts
### Update the server
yum -y update
### Create the chef-local mode infrastructure
mkdir -p chef-solo-example/{backup,cache}
cd chef-solo-example
cat << EOF > Gemfile
source "https://rubygems.org"
gem 'knife-solo'
gem 'librarian-chef'
EOF
### Installing dependencies
yum -y install ruby-devel gcc make git
### Installing gems 
if [ ! -f ~/.gemrc ]
then 
  echo "gem: --no-document" > ~/.gemrc
fi
gem install bundle
bundle
### Create a kitchen by knife
knife solo init .
### Modify the librarian Cheffile for manage the cookbooks
if [ ! -f Cheffile ]
then
  librarian-chef init
fi
sed -i '/cookbook-openshift3/d' Cheffile
echo "cookbook 'cookbook-openshift3', :git => 'https://github.com/IshentRas/cookbook-openshift3.git'" >> Cheffile 
librarian-chef install
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
      "openshift_common_public_hostname": "console.${IP}.xip.io",
      "openshift_deployment_type": "origin",
      "master_servers": [
        {
          "fqdn": "${FQDN}",
          "ipaddress": "$IP"
        }
      ],
      "node_servers": [
        {
          "fqdn": "${FQDN}",
          "ipaddress": "$IP"
        }
      ]
    }
  }
}
EOF
### Create the dedicated role for the Chef run_list
cat << EOF > roles/origin.json 
{
  "name": "origin",
  "description": "",
  "default_attributes": {

  },
  "override_attributes": {

  },
  "chef_type": "role",
  "run_list": [
    "recipe[cookbook-openshift3]",
    "recipe[cookbook-openshift3::common]",
    "recipe[cookbook-openshift3::master]",
    "recipe[cookbook-openshift3::node]",
    "recipe[cookbook-openshift3::node_config_post]"
  ],
  "env_run_lists": {

  }
}
EOF
### Specify the configuration details for chef-solo
cat << EOF > solo.rb
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
chef-client -z --environment origin -j roles/origin.json -c ~/chef-solo-example/solo.rb
if ! $(oc get project test --config=/etc/origin/master/admin.kubeconfig &> /dev/null)
then 
  # Create a demo project
  oadm new-project demo --display-name="Origin Demo Project" --admin=demo
  # Set password for user demo
fi
# Reset password for demo user
htpasswd -b /etc/origin/openshift-passwd demo 1234
cat << EOF

##### Installation DONE ######
#####                   ######
Your installation of Origin is completed.

A demo user has been created for you.
Password is : 1234

Access the console here : https://console.${IP}.xip.io:8443/console

You can also login via CLI : oc login -u demo

Next steps for you (To be performed as system:admin --> oc login -u system:admin):

1) Deploy registry -> oadm registry --service-account=registry --credentials=/etc/origin/master/openshift-registry.kubeconfig --config=/etc/origin/master/admin.kubeconfig
2) Deploy router -> oadm router --service-account=router --credentials=/etc/origin/master/openshift-router.kubeconfig
3) Read the documentation : https://docs.openshift.org/latest/welcome/index.html

You should disconnect and reconnect so as to get the benefit of bash-completion on commands

EOF
