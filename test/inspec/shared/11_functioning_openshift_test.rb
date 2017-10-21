# It produces a working cluster
describe command('oc status') do
  its('exit_status') { should eq 0 }
end

# It initializes system services with plausible clusterIP (see role/openshift3-base.json)
describe command('oc get service/kubernetes -n default --no-headers') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/172\.30\.0/) }
end

# It initializes a `default` namespace
describe command('oc get namespace/default --no-headers') do
  its('exit_status') { should eq 0 }
end

# logs the `system:admin` user
describe command('oc whoami') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/system:admin/) }
end

# node has proper hostIP
describe command('oc get hostsubnet/$HOSTNAME --template="{{.hostIP}}"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should eq '10.0.2.15' }
end

# node has proper hostsubnet (see role/openshift3-base.json)
describe command('oc get hostsubnet/$HOSTNAME --template="{{.subnet}}"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should eq '10.128.0.0/23' }
end

# node is ready
describe command('oc get node/$HOSTNAME --no-headers') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Ready/) }
end

# node should not be schedulable unless stated in attributes
describe command('oc get node/$HOSTNAME --no-headers') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/SchedulingDisabled/) }
end

# the openshift master api endpoints should by queriable using the https protocol; in other words,
# `curl --fail https://$(oc get endpoints kubernetes -n default -o jsonpath='{.subsets[*].addresses[0].ip}'):8443`
# should always work, even if the endpoint ipaddress is not explicitly listed in `node['cookbook-openshift3']['erb_corsAllowedOrigins']`.
describe command('curl --fail --cacert /etc/origin/node/ca.crt https://10.0.2.15:8443') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include('/api/v1') }
end

# non-regression test for https://github.com/IshentRas/cookbook-openshift3/issues/170#issuecomment-338193509
describe command('host kubernetes.default.svc.cluster.local') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include('172.30.0.1') }
end

describe command('host 172.30.0.1') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include('kubernetes.default.svc.cluster.local') }
end
