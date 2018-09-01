# should create a DC for curator
describe command("oc get dc -l component=curator,logging-infra=curator -n logging -o jsonpath='{ .items[*].metadata.name }'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/logging-curator/) }
end

# should create a DC for elasticsearch
describe command("oc get dc -l component=es,logging-infra=elasticsearch -n logging -o jsonpath='{ .items[*].metadata.name }'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/logging-es-\w+/) }
end

# should create a DC for kibana
describe command("oc get dc -l component=kibana,logging-infra=kibana -n logging -o jsonpath='{ .items[*].metadata.name }'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/logging-kibana/) }
end

# should create a DS for fluentd
describe command("oc get ds -l component=fluentd,logging-infra=fluentd -n logging -o jsonpath='{ .items[*].metadata.name }'") do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/logging-fluentd/) }
end

# should label all nodes with logging-infra-fluentd=true
describe command('oc get nodes -l logging-infra-fluentd!=true 2>/dev/null | wc -l') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/^0$/) }
end
