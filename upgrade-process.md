# Upgrade Process

### Overview

You can use the upgrade cookbook to automate the OpenShift cluster upgrade
process.

Once the upgrade is done, any future CHEF runs will skip the default
installation/run so as to avoid any clashes with previous variables such as:

* `ose_major_version`
* `ose_version`
* `docker_version`
* `etcd_version`
* `openshift_docker_image_version`

It gives you the time/opportunity to update any references from the previous
list accordingly with the new environment.

For example after a schedulable upgrade from 1.5 to 3.6, you should
update the following variables to get the 'normal' Chef recipes working again:

```json
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "ose_major_version": "1.5",
      "ose_version": "1.5.1-1.0.008f2d5",
      "openshift_docker_image_version": "v1.5.1",
      "docker_version": "1.12.6.x"
    }
  }
```

**The automated upgrade performs the following steps for you:**

- Applies the latest configuration.

- Upgrades master and etcd components and restarts services (aka the control
plane servers).

- Upgrades docker components.

- Upgrades node components and restarts services (aka node servers).

- Applies the latest cluster policies.

- Updates the default router if one exists.

- Updates the default registry if one exists.

*Make sure your servers are assigned to the right groups*

###### Limitation

**The automated upgrade does not perform the following steps for you:**

- Drains node servers.

- Marks drained node servers as unschedulable.

- Reboots servers after upgrade.

- Upgrade metrics or logging components (Coming soon)

#### Control Plane Upgrade

When upgrading in separate phases, the control plane phase includes upgrading:

* Master components (master_servers group)
* Etcd components (etcd_servers group)
* Node services running on masters (node_servers group)
* Docker running on masters
* Docker running on any stand-alone etcd hosts

When upgrading only the nodes, **the control plane must already be upgraded**. 

The node phase includes upgrading:

* Node services running on stand-alone nodes (node_servers group)
* Docker running on stand-alone nodes

#### Supported Upgrade Versions

[x] 1.3 to 1.4

[x] 1.4 to 1.5

[x] 1.5 to 3.6

[x] 3.6 to 3.7

*Cluster upgrades cannot span more than one minor version at a time, so if your
cluster is at a version earlier than the targeted one, you must first upgrade
incrementally (e.g., 1.4 to 1.5, then 1.5 to 3.6...)*

### Running the Control Plane Upgrade

Before upgrading the cluster, some variables need to be declared:

| NAME | PURPOSE | Default value | Mandatory |
| ---------------- | ------------------------------- | ------------------ | ---------- |
| control_upgrade | Execute an upgrade     | `false`    | `YES` |
| control_upgrade_version | Target version (13,14,15,36,37)        |`""` |`YES`|
| control_upgrade_flag | Location of the control upgrade flag | `"/to_be_replaced"`  | `YES` |
| upgrade_repos | Target YUM repo | `""` | `NO` |


```json
  "override_attributes": {
    "is_apaas_openshift_cookbook": {
      "control_upgrade": true,
      "control_upgrade_version": "37",
      "control_upgrade_flag": "/tmp/ready",
      "upgrade_repos": [
        {
          "name": "centos-openshift-origin37",
          "baseurl": "http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin37/",
          "gpgcheck": false
        }
      ]
    }
  }
```

In addition to the previous variables the upgrade mechanism has got a set of
default values from the different target upgrades.

Feel free to override those so as to match your environment:

**CUV = Control Upgrade Version**

##### Origin Deployment

| NAME | CUV | Default value |
| ---------------- | ------------------------------- | ------------------ |
| upgrade_ose_major_version |  14  | `"1.4"`    |
| upgrade_ose_version | 14 | `"1.4.1-1.el7"` |
| upgrade_openshift_docker_image_version | 14 | `"v1.4.1"`  |
| upgrade_ose_major_version |  15  | `"1.5"`    |
| upgrade_ose_version | 15 | `"1.5.1-1.el7"` |
| upgrade_openshift_docker_image_version | 15 | `"v1.5.1"`  |
| upgrade_ose_major_version |  36 | `"3.6"`    |
| upgrade_ose_version | 36 | `"3.6.1-1.0.008f2d5"` |
| upgrade_openshift_docker_image_version | 36 | `"v3.6.1"`  |
| upgrade_ose_major_version |  37 | `"3.7"`    |
| upgrade_ose_version | 37 | `"3.7.0-1.0.7ed6862"` |
| upgrade_openshift_docker_image_version | 37 | `"v3.7.0"`  |

##### Enterprise Deployment

| NAME | CUV | Default value | 
| ---------------- | ------------------------------- | ------------------ | 
| upgrade_ose_major_version |  14  | `"3.4"`    |
| upgrade_ose_version | 14 | `"3.4.1.44.38-1.git.0.d04b8d5.el7"` |
| upgrade_openshift_docker_image_version | 14 | `"v3.4.1.44.38"`  | 
| upgrade_ose_major_version |  15  | `"3.5"`    |
| upgrade_ose_version | 15 | `"3.5.5.31.47-1.git.0.25d535c.el7"` |
| upgrade_openshift_docker_image_version | 15 | `"v3.5.5.31.47"`  |
| upgrade_ose_major_version |  36 | `"3.6"`    |
| upgrade_ose_version | 36 | `"3.6.173.0.63-1.git.0.855ea8b.el7"` |
| upgrade_openshift_docker_image_version | 36 | `"v3.6.173.0.63"`  |
| upgrade_ose_major_version |  37 | `"3.7"`    |
| upgrade_ose_version | 37 | `"3.7.23-1.git.0.8edc154.el7"` |
| upgrade_openshift_docker_image_version | 37 | `"v3.7.23"`  |

##### Please Note

* **The upgrade will not run unless it finds the file designated by the `control_upgrade_flag`**
* **The upgrade will not run unless the `control_upgrade` is set to `true`**
* **The upgrade will not run unless it finds a valid version to upgrade to via `control_upgrade_version`**


##### Known Issues

###### Docker containers not starting

It was found in testing that upgrading docker as part of the upgrade could
result in failures to start docker containers after an upgrade. This could
happen even on sub-point releases, which was not expected.

In these cases, running `rm -rf /var/lib/docker && systemctl restart docker`
recovered the situation.
