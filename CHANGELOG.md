# Openshift 3 Cookbook CHANGELOG
This file is used to list changes made in each version of the Openshift 3 cookbook.

## v1.10.33
### Bug
- Revert e168f9b, use stable repository URLs again
- Adjust predicates and priorities based on ose_major_version

### Improvement
- Use stable CentOS PaaS repository during tests
- Add integration test for hosted metrics feature

## v1.10.32
### Bug
- Make apiServerArguments conditional on the version for pre-1.3/3.3 versions

## v1.10.31
### Improvement
- Handle 1.4/3.4 deployment
- Clean codes over unused attributes
- Integration tests for 1.4/3.4
- Add the possibility to supply dns-search option via Docker
- Add the possibility to specify a deserialization cache size parameter. 

### Bug
- Fix permissions over /etc/origin/node
- Fix iptables issue due to version used by clients

## v1.10.30
### Improvement
- Add the possibility to deploy the cluster metrics
- Add the possibility to add more manageName serviceaccount in master config
- Move registry persistent_volume_claim name to explicit LWRP attribute
- Added integration test for openshift_hosted_manage_registry feature
- Added integration test for openshift_hosted_manage_router feature
- Added integration test for persistent_storage feature
- Refactor router-related resources to new openshift_deploy_router LWRP
- Move registry persistent_volume_claim name to explicit LWRP attribute

### Bug
- Fix README.md typo
- Fix issue with systemd when uninstalling the Openshift
- Fix issue for systemctl daemon-reload
- Removed redundant guard clause for registry deloyment

## v1.10.29
### Bug
- Remove property attributes for resources (backward compatibility)

## v1.10.28
### Improvement
- Add the possibility to deploy the cluster metrics
- Add the possibility to add more manageName serviceaccount in master config

### Bug
- Fix README.md typo
- Fix issue with systemd when uninstalling the Openshift
- Fix issue for systemctl daemon-reload

## v1.10.27
### Bug
- Fix the Origin deployment issue (https://github.com/IshentRas/cookbook-openshift3/issues/20)
- Fix master-api service and master-controllers service (https://github.com/IshentRas/cookbook-openshift3/issues/40)

## v1.10.26
### Improvement
- Set the default ipaddress used in etcd-related attributes accordingly with the etcd_server variable

### Bug
- Remove duplicated variables for ETCD

## v1.10.25
### Bug
- Fix documentation
- Fix redeploying OSE certificates

## v1.10.24
### Improvement
- Add the possibility to run adhoc command for redeploying OSE certificates
- Add FW rules in a dedicated jump chain
- Add a validation point for mandatory variables 
- Add the possibility to specify logging drivers (https://docs.docker.com/engine/admin/logging/overview/)

### Bug
- Fix adhoc uninstall
- Move openssl.conf under CA directory (ETCD)

## v1.10.23
### Bug
- Typo in README
- Fix schedulability and node-labelling guards

## v1.10.22
### Bug
- Skip nodes which are not listed when labelling or seetingn schedulability (https://github.com/IshentRas/cookbook-openshift3/issues/32)

## v1.10.21
### Bug
- Improve delete adhoc
- Remove duplicates for cors origin (Forcing ETCD to fail)

## v1.10.20
### Improvement
- Remove the need to specify the master server peers.
- Add the possibility to specify scc rather than assuming \'privileged\' one
- Add new scheduler predicates & priorities
- Add the possibility to create PV and PVC (Type NFS only)
- Deploy Hosted environment (Registry & Router)
- Autoscale Hosted environment (Registry & Router) based on labelling
- Only 1 recipe is needed for deploying the environment : recipe[cookbook-openshift3]

### Bug
- Remove duplicated resources
- Fix Docker log-driver for json
 
### Removal
- Remove the node['cookbook-openshift3']['use_params_roles'] which used the CHEF search capability
- Remove the node['cookbook-openshift3']['set_nameserver'] and node['cookbook-openshift3']['register_dns']

## v1.10.19
### Improvement
- Add the possibility to enable the Audit logging 
- Add the possibility to label nodes
- Add the possibility to set scheduling against nodes
- Add the possibility to deploy the Stand-alone Registry & Router

### Bug
- Remove automatic rebooting when playing adhoc uninstallation

## v1.10.18
### Improvement
- Add the possibility to run adhoc command for uninstalling Openshift on dedicated server(s)

## v1.10.17
### Improvement
- Add the possibility to have any number of ETCD servers

### Bug
- Fix HTTPD service enabling for ETCD

## v1.10.16
### Improvement
- Add the possibility to only deploy ETCD role

### Bug
- Remove hard-coded values for deployment type (Affecting Origin deploymemts)

## v1.10.15
### Improvement
- Add the possibility to specifying an exact rpm version to install or configure.
- Update Openshift configuration for 1.3 or 3.3
- Add the possibilty to specifying a major version (3.1, 3.2 or 3.3)

## v1.10.14
### Bug
- Add logging EFK

## v1.10.13
### Bug
- Add SNI capability when testing master API

### Improvement
- Give the choice to user to select CHEF search or solo capability
- Add the concept of wildcard nodes --> wildcard kubeconfig (AWS cloud deployment)
- Update Openshift templates

## v1.10.12
### Bug
- Fix nodeSelector issue when using cluster architecture

### Improvement
- Add capacity to manage container logs (Docker options)

## v1.10.11
### Bug
- Remove too restrictive version for RHEL

## v1.10.10
### Bug
- Fix typo for URL for Public master API

## v1.10.9
### Bug
- Fix URL for master API

### Improvement
- Clarify use of masterPublicURL, publicURL and masterURL

## v1.10.8
### Improvement
- Simplify the creation of node/master servers

## v1.10.7
### Bug
- Fix issue for dnsmasq

## v1.10.6
### Bug
- Fix issue for documentation

## v1.10.5
### Bug
- Fix issue for documentation

## v1.10.4
### Bug
- Fix issue for restarting openshift-api or controllers
- Fix issue for restarting node

### Improvement
- Update Openshift documentation
- Use chef-solo attribute style as a default for setting attributes
- Remove queries for any type of data that is indexed by the Chef server 

## v1.10.3
### Bug
- Fix issue for Openshift Node (Clashing ClusterNetwork)
- Fix issue for generating certificates (NODES)

### Improvement
- Add capability for deploying 3.2.x
- Add capability for deploying containerized version of Openshift
- Add capability of using dnsmasq for interacting with skyDNS
- Update Openshift template examples

## v1.10.2
### Bug
- Fix issue for nodes certificate SAN

## v1.10.1
### Bug
- Fix issue for ETCD certificate lifetime
- Fix IP discovery for origin_deploy.sh

### Improvement
- Add capability for enabling or not a yum repository

## v1.10.0
### Bug
- Fix docker restrart when running CHEF
- Fix openshift-master restart when running CHEF
- Fix openshift-node restart when running CHEF

## v1.0.9
### Bug
- Remove dnsIP from node definiton. Default to use the kubernetes service network 172.x.x.1

## v1.0.8
### Improvement
- Add kubeletArguments for node servers

### Bug
- Enable Docker at startup
- Mask master service when running native HA

## v1.0.7
### Improvement
- Add possibility to disable yum repositories
- Fix etcd certificate (Simplify the call for peers members)
- Add possibility to specify a version to be installed for docker

### Bug
- Fix permissions for directory (Set to Apache in case of a dodgy umask number)

## v1.0.6
### Improvement
- Add delay/retry before installing servcieaccount
- Change xip.io for nip.io (STABLE)

### Bug
- Fix scripts/origin_deploy.sh
- Fix hostname for origin_deploy.sh

## v1.0.5
### Bug
- Fix bug when enabling HTTPD at startup

## v1.0.4
### Improvement
- Detect the CN or SAN from certificates file when using named certificates.
- Move origin_deploy.sh in scripts folder

### Bug
- Enable HTTPD at startup
- Fix some typos

mprovement
- Add the possibility to only deploy ETCD role

### Bug
- Remove hard-coded values for deployment type (Affecting Origin deploymemts)
## v1.0.3
### Improvement
- Add possibility to customise docker-storage-setup
- Add possibility for configuring Custom Certificates

## v1.0.2
### Improvement
- Add MIT LICENCE model 
- Add script to auto deploy origin instance
- Add the possibility to exclude packages from updates or installs

### Bug fix
- Fix attributes labelling when using chef in local mode (or solo) 
- Remove specific mentions to OSE

## v0.0.1
- Current public release
