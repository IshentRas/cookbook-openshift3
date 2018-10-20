# Openshift 3 Cookbook CHANGELOG
This file is used to list changes made in each version of the Openshift 3 cookbook.

## v2.0.91
### Improvement
- Give capability for recovering ETCD cluster
- ETCD Snapshot tuning (etcd_snapshot_count)

## v2.0.90
### Bug
- Fix logic when checking API availability
- Fix issue when disabling firewalld service for the 1st time

## v2.0.88
### Improvement
- Add logic for waiting up to 15 minutes when first time creating etcd server

## v2.0.86
### Improvement
- (FIX) Give capability for specifing personalised Admission Plug-in (openshift_master_admission_plugin_config)
- Patch any shard routers during upgrade

## v2.0.85
### Improvement
- Give capability for specifing personalised Admission Plug-in (openshift_master_admission_plugin_config)

## v2.0.83
### Bug
- Fix MISC etcd migration
- Fix incorrect openshift_master_loopback_api_url (was not proxy safe)

### Improvement
- Make SWAP disabling on nodes optional (but enabled by default).

## v2.0.82
### Bug
- Restrict permission for policy and scheduler (https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/257)
- Add version control for etcd in certificate server

## v2.0.81
### Improvement
- Restrict cookbook run only to control plane and node servers

## v2.0.78
### Bug
- CRT and KEY files permissions were wrong (https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/253 //github.com/IshentRas/is_apaas_openshift_cookbook/issues/254)
- Adjust the permission for OCP node main directory and ETCD

### Improvement
- Update metrics and logging to 3.9

## v2.0.77
### Bug
- CRT and KEY files permissions were wrong (https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/252)
- Adjust the permission for OCP main directory

### Improvement
- Adjust the docker network options via openshift_docker_network_options

## v2.0.76
### Improvement
- Improve logic for adding or removing ETCD servers from ETCD cluster (Read README)
- MISC bugs
- Add first support for 3.9
- Refactoring codes

## v2.0.75
### Improvement
- Add logic for adding or removing ETCD servers from ETCD cluster (Read README)

## v2.0.74
### Improvement
- First draft for deploying logging components

## v2.0.72
### Bug
- Fix issue when deploying router and registry v1/3.5+ on premise. (Default to iexternal redhat registry)
  Possibilty to specify openshift_docker_hosted_registry_image or openshift_docker_hosted_router_image

## v2.0.71
### Bug
- Fix issue with nodes after upgrading and until removing the flag (Keep restarting the openvswitch)

## v2.0.70
### Bug
- Fix issue DNS does not work over TCP from pod (Adjusting DNSMasq binding interfaces) < 3.6

## v2.0.69
### Bug
- Fix issue when ussing docker 1.12+ (https://bugzilla.redhat.com/show_bug.cgi?id=1502560)

## v2.0.68
### Bug
- Fix typo when upgrading ConfigMap of the customised Hosted Router

## v2.0.67
### Bug
- Fix typo when applying openshift_node_kubelet_args_custom

## v2.0.66
### Improvement
- Give the possibility of controlling dnsmasq openshift_node_dnsmasq_log_queries (false) openshift_node_dnsmasq_cache_size (150) openshift_node_dnsmasq_maxcachettl (1)
- Improve the node reset mechanism (Deleting master and node directories)

## v2.0.65
### Improvement
- Give the possibility to override global variables at the node level ((Read README) 
- Give possibility to override sharding router template location file

## v2.0.63-64
### Bug 
- Fix issue when resetting a master node
- Fix issue when resetting an ETCD node
- Fix several Cloning resource attributes issues

## v2.0.62
### Improvement
- Give the possibility to reset a node including the docker-storage thin-pool (If it is in used) adhoc_reset_control_flag

## v2.0.60-61
### Improvement
- Give the possibility to deploy router sharding (Read README)

## v2.0.58-59
### Improvement
- Improve metrics deployment logic

## v2.0.57
### Bug
- Fix issue when deleting servers

## v2.0.56
### Improvement
- Automatically upgrade the custom router template during upgrades

## v2.0.53-55
### Bug
- Fix issue with cloud_provider when restarting node service.

## v2.0.52
### Bug
- Fix issue reported 247 (Upgrade 36 -> 37)

## v2.0.51
### Bug
- Fix rubocop issues

## v2.0.50
### Bug
- Fix issue reported 244 (Insecure docker registry)
- Fix issue reported 247 (Customised CA)

### Improvement
- Give the possibility of providing an array for the SCCs

## v2.0.49
### Bug
- Fix several Cloning resource attributes issues
- Fix ETCD ca perms on certificate server

## v2.0.48
### Bug
- Prevent Docker to reinstall or update without control

## v2.0.47
### Improvement
- Asynchronous Errata Updates via variable asynchronous_upgrade (Default to false)

## v2.0.46
### Improvement
- Add possibility to specify specific yum options when installing docker docker_yum_options
- Add reverse lookup for SkyDNS

## v2.0.45
### Improvement
- Give the possibilty to provide a custom location for '/etc/NetworkManager/dispatcher.d/99-origin-dns.sh'

## v2.0.44
### Improvement
- Change the ETCD CA directory for the certificate server (Moving the certificate server becomes easier: mv /var/www/html)

## v2.0.43
### Bug
- Fix issue 240 when using standalone master

## v2.0.42
### Bug
- Regression bug for controller servers (TTL missing)

## v2.0.41
### Bug
- Remove the openshift-master.kubeconfig file when regenerating certs (Issue < 3.2)

## v2.0.40
### Bug
- Wrong option for generating node certs

## v2.0.39
### Bug
- Bug with certificates renewal for node servers

## v2.0.34 - v2.0.38
### Bug
- Bug with certificates renewal

## v2.0.33
### Bug
- Bug with library for identifying the server roles

## v2.0.32
### Bug
- Bug with library for identifying the server roles

## v2.0.31
### Bug
- Force secret for registry HTTPS

## v2.0.30
### Improvement
- Improve the certs renewal
- Improve the custom router template (Name can be customised) openshift_hosted_deploy_custom_name

## v2.0.29
### Improvement
- Stop pushing for etcd / docker package upgrade
- New vars for upgrade (ETCD/Docker) upgrade_docker_version upgrade_etcd_version

## v2.0.28
### Bug
- Fix issue when upgrading etcd

## v2.0.27
### Bug
- Fix foodcritic issue with new metric logic

## v2.0.26
### Bug
- Fix issue with excluder pkgs when server has got dual roles (master && node)
- Refactor the metrics logi to support all versions (3.3+)
- Fix issue when disabling SWAP for node servers

## v2.0.25
### Bug
- Add option to control docker yum exclude options custom_pkgs_excluder
- Revert last logic not working

## v2.0.24
### Bug
- Fix issue with master keys != 400 perms
### Improvement
- Add option to control docker yum options (Exclude/Include X pkgs) docker_yum_options

## v2.0.23
### Bug
- Fix issue with node service when NM is not turned off (Openshift >= 3.6)

## v2.0.22
### Bug
- Fix issue when restarting ETCD during upgrade

## v2.0.21
### Bug
- Fix issue during upgrade when having certificate_server which is not first master
- Add ETCD package to servers (Master for certificates, Etcd and certificate server for certificate renewal)

## v2.0.20
### Bug
- Fix issue during upgrade when upgrading master services

## v2.0.19
### Improvement
- Split the certificate server function from the other roles
- General code review
- Improve the general experience during certificate renewal

## v2.0.18
### Bug
- Fix issue during upgrade node components

## v2.0.17
### Improvement
- Give the possibility for setting ENV to router (openshift_hosted_deploy_env_router)

## v2.0.16
### Bug
- Fix issue during uninstall when server has not got docker installed

## v2.0.15
### Improvement
- Improve the general experience during upgrades
- Restarts of services are aligned with activities (upgrade/intall)
- Give the possibility for deploying custom router (openshift_hosted_deploy_custom_router)

## v2.0.14
### Bug
- Fix issue during upgrade when master are separated from ETCD

## v2.0.13
### Bug
- Fix race condition for certs
- Fix issue when deploying hosted services outside of the default project

## v2.0.12
### Bug
- General code improvements/MISC issues

## v2.0.11
### Bug
- General code improvements/MISC issues

## v2.0.10
### Bug
- Fix issue for upgrade when being a master only (No need to restart Docker)

## v2.0.9
### Bug
- Fix issue when creating PV (NFS)
- General code improvements/MISC issues

## v2.0.8
### Bug
- General code improvements/MISC issues

## v2.0.7
### Improvement 
- Improve creating PV/PVC

### Bug
- General code improvements/MISC issues

## v2.0.6
### Improvement 
- Add logic for removing redhat registry (Fixed issue 206)
- Improve IPtables logic

### Bug
- General code improvements/MISC issues

## v2.0.5
### Bug
- General code improvements/MISC issues

### Improvement 
- Initial Support for 3.7.x
- Capability for automated upgrade between versions
- Certitificate redeploy for ETCD (CA/CERTS)

## v1.10.67
### Bug
- Fixes error in v1.10.66 - use action ':nothing' on declaration, cf: https://serverfault.com/questions/587188/chef-how-to-run-a-resource-on-notification-only
- admin.kubeconfig made unambiguous - file creation failures avoided


## v1.10.66
### Improvement
- Add timeout to `du` call
- Rewrite ruby blocks into Chef resources

## v1.10.65
### Improvement
- Initial support for 3.6
- Capability for Overriding master and node servingInfo.minTLSVersion and .cipherSuites [openshift_(master|node)_cipher_suites, openshift_(master|node)_min_tls_version]
- Capability for defining ExternalIPNetworkCIDRs controls what values are acceptable for the service external IP field [openshift_master_external_ip_network_cidrs]
- Capability for defining IngressIPNetworkCIDR controls the range to assign ingress IPs [openshift_master_ingress_ip_network_cidr]
- Capability for defining mcs_allocator_range, mcs_labels_per_project and uid_allocator_range [openshift_master_NAME]
- Capability for referencing the registry by a stable name (not IP) [openshift_push_via_dns]
- Add etcd_debug and etcd_log_package_levels capabilities 

## v1.10.64
### Improvement
- All tgz files are encrypted with a default passphrase, and decrypted at the other end after downloading.

### Bug
- Fixes error in v1.10.62 - file permissions on tar.gz
- Fix bug with LDAP Provider (Enforce LDAPS when selecting secure)

## v1.10.63
### Bug
- Fixes error in v1.10.62 - file permissions on tar.gz

## v1.10.62 - BROKEN
### Improvement
- Jenkinsfile parameters added
- New Centos yum repos added

### Bug
- Allow users to suppress ruby block call from provider code (breaks in older Chef client versions)
- Make perms and ownership on tar.gz files explicit for more restrictive distributions
- Kitchen tests updated for latest versions

## v1.10.61
### Improvement
-  Allow passing custom arguments when deploying the hosted router

### Bug
- Fix issue with cookstyle indentation

## v1.10.60
### Improvement
- Update Example files (ImageStreams/Templates)
- Update Hosted templates
- Add more logic for dnsmasq (Install NetworkManager and add conf-dir line)

### Bug
- Fix issues with certificate_servers

## v1.10.59
### Improvement
- Add the possibilty for openshift_buildoverrides 
- Add the possibilty of retrieving the OCP certs from a custom location/server 

### Bug
- Fix issue with cookstyle indentation
- Improve the code for ignoring dnsmasq issues
- Add missing dirs and files to be removed when uninstalling

## v1.10.58
### Improvement
- Remove support for 1.2/3.2 (README)

## v1.10.57
### Improvement
- Remove support for 1.2/3.2
- Update openshift_example files
- Add extra wait time for 1.3/3.3 installation

### Bug
- Change test for 1.3/3.3 to use docker 1.10.x
- Adapt the kubelet args

## v1.10.56
### Improvement
- Add the possibility of deploying Metrics according to https://docs.openshift.com/container-platform/latest/install_config/cluster_metrics.html

## v1.10.55
### Bug
- Fix backticks in environment not working (#138)

## v1.10.54
### Bug
- Fix CHEF-3694 warning that triggered while waiting for node registration

## v1.10.53
### Improvement
- Remove duplicated code between etcd_cluster and master_cluster recipes.

### Bug
- Enable *-master-controllers and *-master-api services on master nodes.
- Fix Jenkinsfile: email address does not support aliases
- Fix CHEF-3694 warning with master certificates

## v1.10.52
### Bug
- Fix cookstyle issues

## v1.10.51
### Bug
- Fix bug when not declaring lb_servers role

## v1.10.50
### Bug
- Fix Foodcritic issues related to CONTRIBUTING.md

## v1.10.49
### Bug
- Fix Foodcritic issues related to metada.rb

## v1.10.48
### Improvement
- Initial support for 1.5/3.5 OCP
- Refactor logic for HA cluster deployment
- Add support for deploying only LB role (Haproxy) https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/100
- MISC bug fix

### Bug
- Separated certificates to be copied from first master

## v1.10.47
### Improvement
- Jenkinsfile gets correct branch
- Kitchen tests at end (less likely to fail)

### Bug
- Separated etcd cluster now works (all certs pulled from first master)

## v1.10.46
### Bug
- Spacing corrected and defaults not included as per discussion in #115

## v1.10.45
### Improvement
- Jenkinsfile has resilient kitchen tests reinstated

### Bug
- Certificate redeployment code fixed to remove node certs
- Certificate redeployment - run etcd code only if etcd on the node (eg standalone)

## v1.10.44
### Improvement
- Upgrade from x.2 to x.3 supported
- Service signer cert created as part of cert creation

## v1.10.43
### Improvement
- Added Jenkinsfile
- Rename file: service_openvsitch-containerized.service.erb -> service_openvswitch-containerized.service.erb

### Bug
- Fix redeploy certs for separate etcd cluster
- Use more config items rather than hard-coded values in delete node

## v1.10.42
### Improvement
- Replace most hard link usage with local copy
- Change http server binding to default IP address
- Give the possibility to specify custom certificate for hosted router

### Bug
- Fix CHEF-3694 warning due to redundant package resource
- Removed potentially unsafe identity providers defaults
- Fix named certificates when common_name is also listed in alternative names
- Allow distinct hostnames for internal and public API access

## v1.10.41
### Bug
- Fix AWS issue when using empty data bag

## v1.10.40
### Bug
- Fix bug for enterprise version (Hosted template files)
- Fix deletion of service files

## v1.10.39
### Improvement
- Give the possibility of adding custom master CA certificate
- Give the possibility of supporting AWS IAM based integration

### Bug
- Fix dnsIP for dedicated nameserver within PODS (Default to IP of the node)

## v1.10.38
### Improvement
- Give the possibility of adding cAdvisor port and read-only port for kubelet arguments
- Give the possibility of skipping nodes when applying schedulability and labelling

### Bug
- Fix issue reported by https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/77

## v1.10.37
### Bug
- Emergency update for fixing ose_major_version when running standalone deployment

## v1.10.36
### Bug
- Fixed cookstyle offenses
- Revert the ETCD change causing issue when adding / removing members
- Make secret call compatible with x.2 version(s)

### Improvement
- Expand .kitchen.yml to test OSE v1.4.1, v1.3.3 and v1.2.1
- Improved code readability
- Added support for multiple identity providers
- Added support for AWS cloud provider

## v1.10.35
### Bug
- Fix ETCD service defined in 2 places
- Fix cookstyle issues
- Fix admin.kubeconfig logic

## v1.10.34
### Bug
- Adjust predicates and priorities based on ose_major_version
- Fix containerized deployment

### Improvement
- Give the possibility to add or remove etcd server members
- Improve ETCD deployment for single etcd server

## v1.10.33
### Bug
- Revert e168f9b, use stable repository URLs again

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
- Fix the Origin deployment issue (https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/20)
- Fix master-api service and master-controllers service (https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/40)

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
- Skip nodes which are not listed when labelling or seetingn schedulability (https://github.com/IshentRas/is_apaas_openshift_cookbook/issues/32)

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
- Only 1 recipe is needed for deploying the environment : recipe[is_apaas_openshift_cookbook]

### Bug
- Remove duplicated resources
- Fix Docker log-driver for json
 
### Removal
- Remove the node['is_apaas_openshift_cookbook']['use_params_roles'] which used the CHEF search capability
- Remove the node['is_apaas_openshift_cookbook']['set_nameserver'] and node['is_apaas_openshift_cookbook']['register_dns']

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
