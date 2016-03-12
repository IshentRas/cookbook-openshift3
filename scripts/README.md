Test (ORIGIN)
==================

There is a way to quickly test this cookbook. 
You will need a CentOS 7.1+  with "Minimal" installation option and at least 10GB left on the Volume group. (Later used by Docker)

* Deploy ORIGIN ALL IN THE BOX Flavour (MASTER + NODE)
```
bash <(curl -s https://raw.githubusercontent.com/IshentRas/cookbook-openshift3/master/scripts/origin_deploy.sh)
```

* Post installation

Your installation of Origin is completed.

A demo user has been created for you.

Password is : 1234

Access the console via : https://console.${IP}.xip.io:8443/console

(More about [xip.io](http://xip.io/))

You can also login via CLI : oc login -u demo

Next steps for you (To be performed as system:admin --> oc login -u system:admin):

1) Deploy registry -> oadm registry --service-account=registry --credentials=/etc/origin/master/openshift-registry.kubeconfig --config=/etc/origin/master/admin.kubeconfig

2) Deploy router -> oadm router --service-account=router --credentials=/etc/origin/master/openshift-router.kubeconfig

3) Read the [documentation](https://docs.openshift.org/latest/welcome/index.html)

You should disconnect and reconnect so as to get the benefit of bash-completion on commands
