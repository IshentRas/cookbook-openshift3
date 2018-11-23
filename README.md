Description
===========

* Installs OSEv3 and related packages.

Requirements
============

## Platform ##

* Tested on Red Hat RHEL 7.4
* Tested on Centos 7.4

## Openshift Version ##

* Support OSE version from 3.4+
* Support Origin version from 1.4+
* Default the installation to 3.10

**Highly recommended**: 

Explicitly set `node['is_apaas_openshift_cookbook']['ose_version']`, `node['is_apaas_openshift_cookbook']['ose_major_version']`
and ideally `node['is_apaas_openshift_cookbook']['docker_version']` to be safe when a major version is released on the
CentOS PaaS repository; 

This cookbook does support upgrade between major versions (Read doc).

## New Features!

- Control upgrades between versions
- ETCD migration v2 to v3 (Mandatory before upgrading to 3.7)
- Node vars override variables
- Add or remove ETCD members from ETCD cluster
- Early support for 3.10 (Work still ongoing)

Supported Node Variables:

| NAME |
| ---------------- |
| deploy_dnsmasq |
| custom_origin-dns |
| custom_origin_location |
| osn_cluster_dns_ip |

In the following example, DNSMASQ will only be deployed on mynodeoverride.domain.local (Being overrided by local vars)

```json
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "deploy_dnsmasq": false,
      "node_servers": [
        {
          "fqdn": "mynode.domain.local",
          "ipaddress": "1.1.1.1"
        },
        {
          "fqdn": "mynodeoverride.domain.local",
          "ipaddress": "1.2.2.2",
          "deploy_dnsmasq": true
        }
      ],
      ....
    }
  }
```

### Supported version
[x] 1.4 to 1.5

[x] 1.5 to 3.6

[x] 3.6 to 3.7

[x] 3.7 to 3.9 (Need to add repository for 3.8 as well (Double upgrades)

### Control Upgrade

Control upgrade requires variables to be set before running.

*The CHEF run will ignore any upgrade unless all variables are correctly set*

Variables:

| NAME | PURPOSE | Default value | Mandatory |
| ---------------- | ------------------------------- | ------------------ | ---------- |
| control_upgrade | Execute an upgrade     | `false`    | `YES` |
| control_upgrade_version | Target version (14,15,36,37,39)        |`""` |`YES`|
| control_upgrade_flag | Location of the control upgrade flag | `"/to_be_replaced"`  | `YES` |
| upgrade_repos | Target YUM repo | `""` | `NO` |

```json
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "control_upgrade": true,
      "control_upgrade_version": "39",
      "control_upgrade_flag": "/tmp/ready",
      "upgrade_repos": [
        {
          "name": "centos-openshift-origin38",
          "baseurl": "http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin38/",
          "gpgcheck": false
        },
        {
          "name": "centos-openshift-origin39",
          "baseurl": "http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin39/",
          "gpgcheck": false
        }
      ]
    }
  }
```

[Read more about the upgrade process here!](docs/upgrade-process.md)

Test Matrix
===========

| Platform   | OSE 3.10 | OSE 3.9.0 | OSE 3.7.0 | OSE 3.6.1 | OSE 1.5.1 | OSE <= 1.4.x |
| --------   | -------- | --------- | --------- | --------- | --------- | ------------ |
| centos 7.4 "cluster native" | ONGOING | PASS   | PASS      | PASS      | PASS      | Not supported |
| centos 7.4 "standalone" | Not supported | Not supported   | Not supported      | PASS      | PASS      | Not supported |

Override Attributes
===================

[Read more about overriding attributes here!](docs/attribute-cookbook.md)

#### Structure ####
-------------------

* `node['is_apaas_openshift_cookbook']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']`

```json
{
"name" : "htpasswd_auth", 
"login" : true, 
"challenge" : true, 
"kind" : "HTPasswdPasswordIdentityProvider", 
"filename" : "/etc/openshift/openshift-passwd"
}
```

* `node['is_apaas_openshift_cookbook']['openshift_master_identity_provider']['LDAPPasswordIdentityProvider']`

```json
{
"name" : "ldap_identity", 
"login" : true, 
"challenge" : true, 
"kind" : "LDAPPasswordIdentityProvider", 
"ldap_server" : "ldap.domain.local",
 "ldap_bind_dn" : "", 
 "ldap_bind_password" : "",
 "ldap_insecure" : true, 
 "ldap_base_ou" : "OU=people,DC=domain,DC=local", 
 "ldap_preferred_username" : "uid"
}
```

* `node['is_apaas_openshift_cookbook']['openshift_master_asset_config']`

```json
{
 "extensionStylesheets":["/path/to/css"],
 "extensionScripts":["/path/to/script"],
 "extensions":"/path/to/my_images",
 "templates":"/path/to/template"
}
```

* `node['is_apaas_openshift_cookbook']['openshift_node_docker-storage']`

```json
{
 "DEVS": ["/dev/sdb","/dev/sdc"],
 "VG": "docker-vg",
 "DATA_SIZE": "80%FREE"
}
```

* `node['is_apaas_openshift_cookbook']['docker_log_driver']`

Set to `'json-file'` (default), `'journald'` or any other supported [docker log driver](https://docs.docker.com/engine/admin/logging/overview/).
Set to '' to disable it.

* `node['is_apaas_openshift_cookbook']['docker_log_options']`

Assuming `node['is_apaas_openshift_cookbook']['docker_log_driver']` is `'json-file'` (the default):

```json
{
 "max-size": "50M",
 "max-file": "3"
}
```

Any option can be set, as long as they are supported by the current [docker log driver](https://docs.docker.com/engine/admin/logging/overview/).


* `node['is_apaas_openshift_cookbook']['openshift_master_named_certificates']`

* CN or SAN names are automatically detected from the certificate file.

```json
[
  {
   "certfile": "/etc/where_is/my_certfile",
   "keyfile": "/etc/where_is/my_keyfile"
  }
]
```

* `node['is_apaas_openshift_cookbook']['persistent_storage']`

* They key called 'claim' is optional and will automatically create a PersistentVolumeClaim within a specified namespace.
 
```json
{
  "name": "registry",
  "capacity": "5Gi",
  "access_modes": "ReadWriteMany",
  "server": "core.domain.local",
  "path": "/var/nfs/registry",
  "claim": {
    "namespace": "default"
  }
}
```

* `node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_metrics']`

Any option can be set, as long as they are supported by the current [Metrics deployer template](https://docs.openshift.com/container-platform/latest/install_config/cluster_metrics.html#metrics-ansible-variables).

Full list of attributes can be found [here](https://raw.githubusercontent.com/IshentRas/is_apaas_openshift_cookbook/master/attributes/metrics.rb).

We only support 1 cassandra POD.
Once the metrics addon is deployed, it creates a flag (openshift_hosted_metrics_flag) on the first master to avoid having CHEF re-creating the resources over and over.

Example of options for deploying metrics:
```json
{
  "openshift_hosted_cluster_metrics": true,
  "openshift_metrics_heapster_requests_memory": "1Gi",
  "openshift_metrics_image_version": "v3.9",
  "openshift_metrics_cassandra_storage_type": "dynamic",
  "openshift_metrics_hawkular_user_write_access": false,
  "....."
}
```

Example of removing metrics components:
```json
{
  "openshift_hosted_cluster_metrics": true,
  "openshift_metrics_install_metrics": false,
  "....."
}
```

* `node['is_apaas_openshift_cookbook']['openshift_hosted_cluster_logging']`

Any option can be set, as long as they are supported by the current [Logging deployer template](https://docs.openshift.com/container-platform/latest/install_config/aggregate_logging.html#aggregate-logging-ansible-variables).

Full list of attributes can be found [here](https://raw.githubusercontent.com/IshentRas/is_apaas_openshift_cookbook/master/attributes/logging.rb).

We only support 1 elasticsearch POD.
Once the logging addon is deployed, it creates a flag (openshift_hosted_logging_flag) on the first master to avoid having CHEF re-creating the resources over and over.

Example of options for deploying logging:
```json
{
  "openshift_hosted_cluster_logging": true,
  "openshift_logging_es_memory_limit": "1Gi",
  "openshift_logging_kibana_memory_limit": "512Mi",
  "openshift_logging_image_version": "v3.9",
  "....."
}
```

Example of removing metrics components:
```json
{
  "openshift_hosted_cluster_logging": true,
  "openshift_logging_install_logging": false,
  "....."
}
```

Example of overriding the default kubelet options:
* `node['is_apaas_openshift_cookbook']['openshift_node_kubelet_args_custom']`
Any option can be set, as long as they are supported by current [Kubelet Options](https://kubernetes.io/docs/admin/kubelet/).

```json
{
  "openshift_node_kubelet_args_custom": {
    "pods-per-core": "5",
    "image-gc-high-threshold": "85",
    "resolv-conf": "/etc/resolv.conf"
  },
  "....."
}
```

Example of enabling a specific "feature-gate": enabling the [persistent local volumes feature](https://docs.openshift.com/container-platform/3.7/install_config/configuring_local.html#local-volume-enabling-local-volumes) (OSE v3.7 and up):
```json
{
  "openshift_master_api_server_args_custom": {
    "feature-gates": ["PersistentLocalVolumes=true"]
  },
  "openshift_master_controller_args_custom": {
    "feature-gates": ["PersistentLocalVolumes=true"]
  },
  "openshift_node_kubelet_args_custom": {
    "feature-gates": ["PersistentLocalVolumes=true"]
  }
}
```

* `node['is_apaas_openshift_cookbook']['openshift_hosted_router_deploy_shards']`

Any ENV options can be set for the sharding router, as long as they are supported by the current documentation [Set ENV for router sharding](https://docs.openshift.com/container-platform/latest/install_config/router/default_haproxy_router.html#modifying-router-shards).

** The dedicated service account must have access to the hostnetwork SCC **

** custom_router (Deploying custom template) is optional and should be omitted if not wanted

Example of options for deploying router sharding:
```json
{
  "....."
  "openshift_hosted_router_deploy_shards": true,
  "openshift_hosted_router_shard":[
    {
      "namespace": "custom-shard1",
      "service_account": "shard1",
      "selector": "region=shard1",
      "env": [
        "ROUTE_LABELS='shard1=yes'"
      ]
    },
    {
      "namespace": "custom-shard2",
      "service_account": "shard2",
      "selector": "region=shard2",
      "custom_router": true,
      "custom_router_file": "/folder/custom_template_forshard2",
      "env": [
        "NAMESPACE_LABELS='dept != finance'"
      ]
    }
  ],
  "openshift_common_service_accounts_additional": [
    { 
      "name": "shard1", 
      "namespace": "shard1", 
      "scc": ["hostnetwork"] 
    },
    { 
      "name": "shard2", 
      "namespace": "custom-shard2", 
      "scc": ["hostnetwork"] 
    }
  ],
  "....."
}
```

Example of overriding the Audit Configuration Parameters for the `openshift_master_auditconfig` Hash

| Key Name   | Description |
| --------   | --------- |
| enable | A boolean to enable or disable audit logs. Default is `false`. |
| audit-file | File path where the requests should be logged to. If not set, logs are printed to master logs. |
| max-retention-day | Specifies maximum number of days to retain old audit log files based on the time stamp encoded in their filename. |
| max-file-number | Specifies the maximum number of old audit log files to retain. |
| max-file-size | Specifies maximum size in megabytes of the log file before it gets rotated. Defaults to 100MB. |

```json
{
  ...
  "openshift_master_auditconfig": {
    "enable": true,
    "audit-file": "/var/log/audit-ocp",
    "max-file-size": "50",
    "max-file-number": "10"
  },
  ...
}
```

Example of overriding the Audit Configuration Parameters for the `openshift_master_auditconfig` Hash

| Key Name   | Description |
| --------   | --------- |
| enable | A boolean to enable or disable audit logs. Default is `false`. |
| audit-file | File path where the requests should be logged to. If not set, logs are printed to master logs. |
| max-retention-day | Specifies maximum number of days to retain old audit log files based on the time stamp encoded in their filename. |
| max-file-number | Specifies the maximum number of old audit log files to retain. |
| max-file-size | Specifies maximum size in megabytes of the log file before it gets rotated. Defaults to 100MB. |

```json
{
  ...
  "openshift_master_auditconfig": {
    "enable": true,
    "audit-file": "/var/log/audit-ocp",
    "max-file-size": "50",
    "max-file-number": "10"
  },
  ...
}
```

Example of overriding the setting for global builds:
Any option can be set, as long as they are supported by current [Global Build Defaults and Overrides](https://docs.openshift.com/container-platform/latest/install_config/build_defaults_overrides.html).

**When setting CPU/Memory via `openshift_builddefaults_resources_*`, `openshift_builddefaults_resources` needs to be set to `true`**

```json
{
  "....."
  "openshift_builddefaults_git_http_proxy": "http://USER:PASSWORD@HOST:PORT",
  "openshift_builddefaults_git_https_proxy": "https://USER:PASSWORD@HOST:PORT",
  "openshift_builddefaults_git_no_proxy": "mycorp.com",
  "openshift_builddefaults_env": [
    {
      "http_proxy": "http://proxy.example.com.redhat.com:3128"
    },
    {
      "NO_PROXY": "ose3-master.example.com"
    }
  ],
  "openshift_builddefaults_image_labels": [
    {
      "name": "imagelabelname1",
      "value": "imagelabelvalue1"
    }
  ],
  "openshift_builddefaults_nodeselectors": {
    "nodelabel1": "nodelabelvalue1",
    "nodelabel2": "nodelabelvalue2"
  },
  "openshift_builddefaults_annotations": {
    "annotationkey1": "annotationvalue1"
  },
  "openshift_buildoverrides_force_pull": "true",
  "openshift_buildoverrides_image_labels": [
    {
      "name": "imagelabelname1",
      "value": "imagelabelvalue1"
    }
  ],
  "openshift_buildoverrides_nodeselectors": {
    "nodelabel1": "nodelabelvalue1"
  },
  "openshift_buildoverrides_annotations": {
    "annotationkey1": "annotationvalue1"
  },
  "....."
}
```

If OpenShift Container Platform administrators would like to control the level of overcommit and manage container density on nodes, masters can be configured to override the ratio between request and limit set on developer containers. This requires configuring the ClusterResourceOverride variables.

```json
{
  ".....",
  "openshift_clusterresourceoverrides_memorylimit_percent": "10",
  "openshift_clusterresourceoverrides_cpulimit_percent": "50",
  "openshift_clusterresourceoverrides_limitcputomem_percent": "200",
  "...."
}
```

## Cloud Providers Integration

Cloud providers integration requires passing some sensitive credentials to OpenShift. This cookbook uses encrypted data bags as the safest way to achieve this. Thus you should have:

- running Chef Server
- encrypted data bags with cloud providers' credentials

*Currently only AWS integration is supported.*

### AWS 

To integrate your OpenShift installation with AWS you should have following attributes for `is_apaas_openshift_cookbook` cookbook:

```json
{
  "openshift_cloud_provider": "aws",
  "openshift_cloud_providers": {
    "aws": {
      "data_bag_name": "cloud-provider",
      "data_bag_item_name": "aws",
      "secret_file": "/etc/chef/shared_secret"
    }
  }
}
```

You should also have data bag named `cloud-provider` (`data_bag_name` attribute above) and encrypted with some shared secret data bag item named `aws` (`data_bag_item_name` attribute above) at your Chef Server. If `secret_file` attribute from above is *not* defined a default for Chef Client shared secret file will be used (`/etc/chef/encrypted_data_bag_secret`). For more information see [official Chef docs](https://docs.chef.io/data_bags.html#encrypt-a-data-bag-item).

Data bag item content should be of the form:

```json
{
  "id": "aws",
  "access_key_id": "your_access_key_id",
  "secret_access_key": "your_secret_access_key"
}
```

Please note: `id` value should be exactly the same as `data_bag_item_name` attribute value from above.

**Alternatively** you can attach IAM policies to your AWS instances and do *not* provide AWS credentials in encrypted data bags. In this case you should have the following attribute for `is_apaas_openshift_cookbook` cookbook:

```json
{
  "openshift_cloud_provider": "aws"
}
```

and the following IAM policy attached to your *master* servers:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "elasticloadbalancing:*",
      "Resource": "*"
    }
  ]
}
```

and the following IAM policy attached to your *node* servers: 

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    }
  ]
}
```

## Admission Controllers

Admission control plug-ins intercept requests to the master API prior to persistence of a resource, but after the request is authenticated and authorised.

To specify a customised Admission Plug-In use `node['is_apaas_openshift_cookbook']['openshift_master_admission_plugin_config']`

Following example is for enforcing the Image Policy

```json
{
  "openshift_master_admission_plugin_config": {
      "openshift.io/ImagePolicy": {
          "configuration": {
              "apiVersion": "v1",
              "executionRules": [
                  {
                      "matchImageAnnotations": [
                          {
                              "key": "images.openshift.io/deny-execution",
                              "value": "true"
                          }
                      ],
                      "name": "execution-denied",
                      "onResources": [
                          {
                              "resource": "pods"
                          },
                          {
                              "resource": "builds"
                          }
                      ],
                      "reject": true,
                      "skipOnResolutionFailure": true
                  },
                  {
                      "matchIntegratedRegistry": true,
                      "name": "allow-images-from-internal-registry",
                      "onResources": [
                          {
                              "resource": "pods"
                          },
                          {
                              "resource": "builds"
                          }
                      ]
                  },
                  {
                      "matchRegistries": [
                          "docker.io"
                      ],
                      "name": "allow-images-from-dockerhub",
                      "onResources": [
                          {
                              "resource": "pods"
                          },
                          {
                              "resource": "builds"
                          }
                      ]
                  }
              ],
              "kind": "ImagePolicyConfig",
              "resolveImages": "AttemptRewrite"
          }
      }
  }
}
```

=====

Include the default recipe in a CHEF role so as to ease the deployment. 

## Roles (Examples) 

* BASE

```json
{
  "name": "base",
  "description": "Common Base Role",
  "json_class": "Chef::Role",
  "default_attributes": {

  },
  "override_attributes": {
  },
  "chef_type": "role",
  "run_list": [
    "recipe[is_apaas_openshift_cookbook]"
  ],
  "env_run_lists": {

  }
}
```

* UNINSTALL (ADHOC)

```json
{
  "name": "uninstall",
  "description": "Common Base Role",
  "json_class": "Chef::Role",
  "default_attributes": {

  },
  "override_attributes": {
  },
  "chef_type": "role",
  "run_list": [
    "recipe[is_apaas_openshift_cookbook::adhoc_uninstall]"
  ],
  "env_run_lists": {

  }
}
```

* REDEPLOY CERTIFICATES (ADHOC)

The redeployment of the certificates requires variables and flags to be set before running.

*The CHEF run will ignore any attempts unless all variables are correctly set*

Variables:

| NAME | PURPOSE | Default value | Mandatory | Target |
| ---------------- | ------------------------------- | ------------------ | ---------- | ---------- |
| adhoc_redeploy_certificates | Execute certificates redeploy    | `false`    | `YES` | Masters/Nodes/Certificate Server |
| adhoc_redeploy_etcd_ca | Execute an ETCD CA redeploy    | `false`    | `YES` | ETCD/Masters |
| adhoc_redeploy_cluster_ca | Execute a CLUSTER CA CERTS redeploy   | `false` | `YES` | Masters/Nodes/Certificate Server |
| redeploy_etcd_ca_control_flag | Location of the etcd ca control flag | `"/to_be_replaced_ca_etcd"`  | `YES` | Certificate Server |
| redeploy_etcd_certs_control_flag | Location of the etcd certs control flag | `"/to_be_replaced_certs"`  | `YES` | ETCD/Masters |
| redeploy_cluster_ca_certserver_control_flag | Location of the cluster ca control flag | `"/to_be_replaced_ca_cluster"`  | `YES` | Certificate Server |
| redeploy_cluster_ca_masters_control_flag | Location of the cluster master ca control flag | `"/to_be_replaced_masters"`  | `YES` | Masters |
| redeploy_cluster_ca_nodes_control_flag | Location of the node ca control flag | `"/to_be_replaced_nodes"`  | `YES` | Nodes |
| redeploy_cluster_hosted_certserver_control_flag | Location of the hosted control flag | `"/to_be_replaced_hosted_cluster"`  | `YES` | 1st Master |

```json
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "redeploy_cluster_ca_certserver_control_flag": "/tmp/caready",
      "adhoc_redeploy_etcd_ca": true
    }
  }
```

[Read more about the certificate redeploy process here!](docs/certificates-process.md)

ENVIRONMENT
===========

Modify the attributes as required in your environments to change how various configurations are applied per the attributes section above. 
In general, override attributes in the environment should be used when changing attributes.

### Minimal example ###

* CLUSTER-NATIVE (Only available option)

```json
{
  "name": "cluster_native",
  "description": "",
  "cookbook_versions": {

  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {

  },
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "openshift_HA": true,
      "openshift_cluster_name": "ose-cluster.domain.local",
      "persistent_storage": [
        {
          "name": "registry",
          "capacity": "5Gi",
          "access_modes": "ReadWriteMany",
          "server": "core.domain.local",
          "path": "/var/nfs/registry",
          "claim": {
            "namespace": "default"
          }
        },
        {
          "name": "metrics",
          "capacity": "3Gi",
          "access_modes": "ReadWriteOnce",
          "server": "core.domain.local",
          "path": "/var/nfs/metrics",
          "policy": "Recycle"
        },
        {
          "name": "logging",
          "capacity": "2Gi",
          "access_modes": "ReadWriteOnce",
          "server": "core.domain.local",
          "path": "/var/nfs/logging",
          "policy": "Recycle"
        }
      ],
      "lb_servers": [
        {
          "fqdn": "lb1-server.domain.local",
          "ipaddress": "1.1.1.4"
        },
      ],
      "master_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2"
        },
        {
          "fqdn": "ose3-server.domain.local",
          "ipaddress": "1.1.1.3"
        }
      ],
      "etcd_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2"
         
        },
        {
          "fqdn": "ose3-server.domain.local",
          "ipaddress": "1.1.1.3"
        }
      ],
      "node_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1",
          "schedulable": true,
          "labels": "region=infra"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2",
          "schedulable": true,
          "labels": "region=infra"
        },
        {
          "fqdn": "ose3-server.domain.local",
          "ipaddress": "1.1.1.3",
          "schedulable": true,
          "labels": "region=infra"
        },
        {
          "fqdn": "ose4-server.domain.local",
          "ipaddress": "1.1.1.4",
          "labels": "region=user zone=east"
        },
        {
          "fqdn": "ose5-server.domain.local",
          "ipaddress": "1.1.1.5",
          "labels": "region=user zone=west"
        },        
      ],
    }
  }
}
```
* SINGLE MASTER (EMBEDDED ETCD)

```json
{
  "name": "single",
  "description": "",
  "cookbook_versions": {

  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {

  },
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "master_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1"
        }
      ],
      "node_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2",
          "labels": "region=user"
        }
      ],
    }
  }
}
```
* ADD NEW ETCD SERVERS TO CLUSTER ("new_etcd_servers" group should be used for adding new etcd members". If the server was previously part of the cluster, remember to clear its data directory before starting CHEF)

```json
...
      "etcd_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2"
         
        },
        {
          "fqdn": "ose3-server.domain.local",
          "ipaddress": "1.1.1.3"
        }
      ],
      "new_etcd_servers": [
        {
          "fqdn": "ose4-server.domain.local",
          "ipaddress": "1.1.1.4",
        }
      ]
...
```
* REMOVE ETCD SERVERS FROM CLUSTER ("remove_etcd_servers" group must be used to remove members. etcd_servers should be your desire state")

  **You can remove all members in once!!!**
  
  **Make sure the ETCD set that you wish to keep is not part of the remove_etcd_servers group!!! If it the case the removal operation will be skipped.**


```json
...
      "remove_etcd_servers": [
        {
          "fqdn": "ose4-server.domain.local",
        }
      ]
      "etcd_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2"

        },
        {
          "fqdn": "ose3-server.domain.local",
          "ipaddress": "1.1.1.3"
        }
      ]
...
```

Here is a simple example of a addition/removal for the ETCD cluster:

1. Part1: Creating an OCP cluster with 3 etcd servers (etc1, etcd2 and etcd3)

2. Part2: Adding new etcd members (etcd4, etcd5 and etcd6)

3. Part3: Remove etcd1, etcd2 and etcd3

[![Simple Example](https://asciinema.org/a/194110.png)](https://asciinema.org/a/194110)

* EXCLUDE NODES FROM SCHEDULING AND LABELLING("skip_run" must be defined and the node will be excluded when enforcing labels and schedulability")
  
  Ex (ose2 and ose3 will be skipped when enforcing the schedulable and labels parts.)
```json
...
      "node_servers": [
        {
          "fqdn": "ose1-server.domain.local",
          "ipaddress": "1.1.1.1",
          "schedulable": true,
          "labels": "region=infra"
        },
        {
          "fqdn": "ose2-server.domain.local",
          "ipaddress": "1.1.1.2",
          "schedulable": true,
          "labels": "region=infra",
	  "skip_run": true
        },
        {
          "fqdn": "ose3-server.domain.local",
          "ipaddress": "1.1.1.3",
          "schedulable": true,
          "labels": "region=infra",
	  "skip_run": true
        }
      ]

...
```

###Once it is done you should assign the node to the relevant environment.###
```
knife node environment set NODE_NAME ENVIRONMENT_NAME
```

Run list
==================

```
knife node run_list add NODE_NAME 'role[base]'
```

Manual Integration Test (ORIGIN)
================================

There is a way to quickly test this cookbook. 
You will need a CentOS 7.1+  with "Minimal" installation option and at least 10GB left on the Volume group. (Later used by Docker)

* Deploy ORIGIN ALL IN THE BOX Flavour (MASTER + NODE)
```
bash <(curl -s https://raw.githubusercontent.com/IshentRas/is_apaas_openshift_cookbook/master/scripts/origin_deploy.sh)
```

Automated Integration Tests (KITCHEN)
=====================================

This cookbook features [inspect](http://inspec.io/) integration tests,
for both standalone and cluster-native (HA) variants.

**Attention**: the `.kitchen.yml` tests all the versions listed in the [Test Matrix](#Test Matrix),
so use `kitchen list` and selective `kitchen converge` to only test a subset of the versions.

Assuming the latest [chef-dk](https://downloads.chef.io/chefdk) is installed,
running the tests is as simple as:

```sh
kitchen converge
# wait a few minutes to give openshift a chance to initialize before running the tests
kitchen verify
kitchen destroy
```

Check the `.kitchen.yml` file to get started.

Automated Integration Tests (SHUTIT)
=====================================

For multi-node setups, testing can be done using a [ShutIt](http://ianmiell.github.io/shutit) script.

There is a [chef branch](https://github.com/ianmiell/shutit-openshift-cluster/tree/chef), which tests this cookbook.

```sh
[sudo] pip install shutit
git clone --recursive https://github.com/ianmiell/shutit-openshift-cluster/tree/chef
cd shutit-openshift-cluster
./run.sh
```

Release Checklist
=================

- Run kitchen tests
- Are there any attributes changes? If yes:
- Update docs/attribute-cookbook.md and
- Update example roles in README.md
- Have you updated the CHANGELOG.md?

Development
==================

License and Author
==================

Author: William Burton (<william17.burton@gmail.com>)

The MIT License (MIT)

Copyright (C) 2014 OpenBet Limited

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

