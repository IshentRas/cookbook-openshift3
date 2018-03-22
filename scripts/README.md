Test (ORIGIN)
==================

There is a way to quickly test this cookbook. 
You will need a CentOS 7.1+  with "Minimal" installation option and at least 10GB left on the Volume group. (Later used by Docker)

* Deploy ORIGIN ALL IN THE BOX Flavour (MASTER + NODE)
```
bash <(curl -s https://raw.githubusercontent.com/IshentRas/is_apaas_openshift_cookbook/master/scripts/origin_deploy.sh)
```

* Delete ORIGIN installation
```
bash <(curl -s https://raw.githubusercontent.com/IshentRas/is_apaas_openshift_cookbook/master/scripts/origin_delete.sh)
```

* Post installation

Your installation of Origin is completed.

An admin user has been created for you.

Username is : admin
Password is : admin

Access the console via : https://console.${IP}.nip.io:8443/console

(More about [nip.io](http://nip.io/))

You can also login via CLI : oc login -u admin

Next steps for you:

1) Read the [documentation](https://docs.openshift.org/latest/welcome/index.html)
