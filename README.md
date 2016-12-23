Description
===========

* Installs OSEv3 and related packages.

Requirements
============

## Platform ##

* Tested on Red Hat RHEL 7.2
* Tested on Centos 7.2

## Openshift Version ##

* Support OSE version from 3.1.0.4+
* Support Origin version from 1.1.1+
* Default the installation to 1.3 or 3.3

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

* `node['cookbook-openshift3']['docker_log_driver'`

Set to `'json-file'` (default), `'journald'` or any other supported [docker log driver](https://docs.docker.com/engine/admin/logging/overview/).

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
          "ipaddress": "1.1.1.2"
          "labels": "region=user"
        }
      ],
    }
  }
}
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

Test (ORIGIN)
==================

There is a way to quickly test this cookbook. 
You will need a CentOS 7.1+  with "Minimal" installation option and at least 10GB left on the Volume group. (Later used by Docker)

* Deploy ORIGIN ALL IN THE BOX Flavour (MASTER + NODE)
```
bash <(curl -s https://raw.githubusercontent.com/IshentRas/cookbook-openshift3/master/scripts/origin_deploy.sh)
```

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

