# should create a replicationcontroller for hawkular-cassandra-1
describe command("oc get rc hawkular-cassandra-1 -n openshift-infra --template '{{.metadata.name}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/hawkular-cassandra-1/) }
end

# should create a replicationcontroller for hawkular-metrics
describe command("oc get rc hawkular-metrics -n openshift-infra --template '{{.metadata.name}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/hawkular-metrics/) }
end

# should create a replicationcontroller for heapster
describe command("oc get rc heapster -n openshift-infra --template '{{.metadata.name}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/heapster/) }
end

# should create rolebinding for hawkular service account
describe command('oc get rolebinding -n openshift-infra --no-headers | grep -q hawkular-view') do
  its('exit_status') { should eq 0 }
end

# should create some 'metrics-*' pods (which probably won't have time to complete)
# at start the pod is metrics-deployer-ID then should be metrics-hawkular etc.
describe command("oc get pods -n openshift-infra --no-headers --selector=metrics-infra | egrep -q '^(hawkular-metrics|heapster|hawkular-cassandra)'") do
  its('exit_status') { should eq 0 }
end
