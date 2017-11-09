# persistent volume for testpv should exist and be bound
describe command("oc get pv/testpv-volume --template '{{.status.phase}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Bound/) }
end

# persistent volume claim for testpv should also exist and be bound
describe command("oc get pvc/testpv-claim -n default --template '{{.status.phase}}'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Bound/) }
end
