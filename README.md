Description
===========

* Installs OSEv3 and related packages.

Requirements
============

## Platform ##

* Tested on Red Hat RHEL 7.4
* Tested on Centos 7.4

## Openshift Version ##

* Support OSE version from 3.3+
* Support Origin version from 1.3+
* Default the installation to 3.7

**Highly recommended**: explicitly set `node['cookbook-openshift3']['ose_version']`, `node['cookbook-openshift3']['ose_major_version']`
and ideally `node['cookbook-openshift3']['docker_version']` to be safe when a major version is released on the
CentOS PaaS repository; this cookbook does NOT support upgrade between major versions, so lock your package versions
in your openshift3 role or environment.

Test Matrix
===========

| Platform   | OSE 3.7.0 | OSE 3.6.0 | OSE 1.5.1 | OSE 1.4.1 | OSE 1.3.3 | OSE 1.2.2 |
| --------   | --------- | --------- | --------- | --------- | --------- | --------- |
| centos 7.4 | PASS      | PASS      | PASS      | PASS      | PASS      | Not supported |

Override Attributes
===================

[Read more about overriding attributes here!](https://github.com/IshentRas/cookbook-openshift3/blob/master/attribute-cookbook.md)

#### Structure ####
-------------------

* `node['cookbook-openshift3']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider']`

```json
{
"name" : "htpasswd_auth", 
"login" : true, 
"challenge" : true, 
"kind" : "HTPasswdPasswordIdentityProvider", 
"filename" : "/etc/openshift/openshift-passwd"
}
```

* `node['cookbook-openshift3']['openshift_master_identity_provider']['LDAPPasswordIdentityProvider']`

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

* `node['cookbook-openshift3']['openshift_master_asset_config']`

```json
{
 "extensionStylesheets":["/path/to/css"],
 "extensionScripts":["/path/to/script"],
 "extensions":"/path/to/my_images",
 "templates":"/path/to/template"
}
```

* `node['cookbook-openshift3']['openshift_node_docker-storage']`

```json
{
 "DEVS": ["/dev/sdb","/dev/sdc"],
 "VG": "docker-vg",
 "DATA_SIZE": "80%FREE"
}
```

* `node['cookbook-openshift3']['docker_log_driver']`

Set to `'json-file'` (default), `'journald'` or any other supported [docker log driver](https://docs.docker.com/engine/admin/logging/overview/).
Set to '' to disable it.

* `node['cookbook-openshift3']['docker_log_options']`

Assuming `node['cookbook-openshift3']['docker_log_driver']` is `'json-file'` (the default):

```json
{
 "max-size": "50M",
 "max-file": "3"
}
```

Any option can be set, as long as they are supported by the current [docker log driver](https://docs.docker.com/engine/admin/logging/overview/).


* `node['cookbook-openshift3']['openshift_master_named_certificates']`

* CN or SAN names are automatically detected from the certificate file.

```json
[
  {
   "certfile": "/etc/where_is/my_certfile",
   "keyfile": "/etc/where_is/my_keyfile"
  }
]
```

* `node['cookbook-openshift3']['persistent_storage']`

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
* `node['cookbook-openshift3']['openshift_hosted_cluster_metrics']`

Any option can be set, as long as they are supported by the current [Metrics deployer template](https://docs.openshift.com/container-platform/latest/install_config/cluster_metrics.html#metrics-ansible-variables).

Full list of attributes can be found [here](https://raw.githubusercontent.com/IshentRas/cookbook-openshift3/master/attributes/metrics.rb).

We only support 1 cassandra POD.

Example of options for deploying metrics:
```json
{
  "openshift_hosted_cluster_metrics": true,
  "openshift_metrics_heapster_requests_memory": "1Gi",
  "openshift_metrics_image_version": "v1.5.1",
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

Example of overriding the default kubelet options:
* `node['cookbook-openshift3']['openshift_node_kubelet_args_custom']`
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

Example of overriding the setting for global builds:
Any option can be set, as long as they are supported by current [Global Build Defaults and Overrides](https://docs.openshift.com/container-platform/latest/install_config/build_defaults_overrides.html).
* `node['cookbook-openshift3']['openshift_builddefaults_env']` is the preferred for setting custom environment variables. 

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

## Cloud Providers Integration

Cloud providers integration requires passing some sensetive credentials to OpenShift. This cookbook uses encrypted data bags as the safest way to achieve this. Thus you should have: 

- running Chef Server
- encrypted data bags with cloud providers' credentials

*Currently only AWS integration is supported.*

### AWS 

To integrate your OpenShift installation with AWS you should have following attributes for `cookbook-openshift3` cookbook:

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

**Alternatively** you can attach IAM policies to your AWS instances and do *not* provide AWS credentials in encrypted data bags. In this case you should have the following attribute for `cookbook-openshift3` cookbook:

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
    "recipe[cookbook-openshift3]"
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
    "recipe[cookbook-openshift3::adhoc_uninstall]"
  ],
  "env_run_lists": {

  }
}
```

* REDEPLOY CERTIFICATES (ADHOC)

```json
{
  "name": "redeploy-certificates",
  "description": "Common Base Role",
  "json_class": "Chef::Role",
  "default_attributes": {

  },
  "override_attributes": {
  },
  "chef_type": "role",
  "run_list": [
    "recipe[cookbook-openshift3::adhoc_redeploy_certificates]"
  ],
  "env_run_lists": {

  }
}
```

Some tips to know before attempting to redeploy the openshift certificates:
 - the nodes will be force-disconnected from the cluster and their pods redeployed, because of the certificate change; plan accordingly to not lose data.
 - the certificates mounted into some privileged pods (such as the router pods) may break until those pods are redeployed.

If you still want to redeploy the certificates, then proceed as follows:
 1. add `role[redeploy-certificates]` in the run-list of every node;
 2. converge the nodes the following order: first the first master node, then the other master nodes, then the non-master nodes;
 3. if the services do not restart automatically (thanks to systemd), restart the origin-* services to pickup the new certificates;
 4. when done, remove `role[redeploy-certificates]` from the run-list of every node.
If things turn bad, a backup tarball of the certificates should be present in `/etc/origin`; restore the certificates by hand doing the nodes in the order from step 2.

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
    "cookbook-openshift3": {
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
    "cookbook-openshift3": {
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
* ADD NEW ETCD SERVERS TO CLUSTER ("etcd_add_additional_nodes" must be set to true and a key called "new_node" should be added to the server(s)". If the server was previously part of the cluster, remember to clear its data directory before starting CHEF)

**Members `must` be added one by one !!!**

```json
...
      "etcd_add_additional_nodes": true,
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
        },
        {
          "fqdn": "ose4-server.domain.local",
          "ipaddress": "1.1.1.4",
          "new_node": true
        }
      ]
...
```
* REMOVE ETCD SERVERS FROM CLUSTER ("etcd_remove_servers" must be defined and list all servers you want to remove. etcd_servers should be your desire state")

**You can remove all members in once!!!**

```json
...
      "etcd_remove_servers": [
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
bash <(curl -s https://raw.githubusercontent.com/IshentRas/cookbook-openshift3/master/scripts/origin_deploy.sh)
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
- Update attribute-cookbook.md and
- Update example roles in README.md
- Have you updated the CHANGELOG.md?

Development
==================

License and Author
==================

Author: William Burton (<wburton@redhat.com>)

The MIT License (MIT)

Copyright (C) 2014 OpenBet Limited

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

