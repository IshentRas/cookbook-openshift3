# should create a 'docker-registry' dc in default namespace
describe command("oc get dc/docker-registry -n default --template '{{.metadata.name}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/^docker-registry/) }
end

# dc should have 1 instance (the number of nodes with region=infra label)
describe command('oc get dc/docker-registry -n default --template {{.spec.replicas}}') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/^1$/) }
end

# dc should have region=infra nodeSelector
describe command("oc get dc/docker-registry -n default --template '{{.spec.template.spec.nodeSelector}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/region:infra/) }
end

# persistent volume for registry should exist and be bound
describe command("oc get pv/registry-storage-volume -n default --template '{{.status.phase}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Bound/) }
end

# persistent volume claim for registry should also exist and be bound
describe command("oc get pvc/registry-storage-claim -n default --template '{{.status.phase}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Bound/) }
end
