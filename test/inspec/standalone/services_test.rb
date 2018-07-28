describe service('etcd') do
  it { should_not be_running }
end

describe service('origin-master') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('origin-master-api') do
  it { should_not be_installed }
end

describe service('origin-master-controllers') do
  it { should_not be_installed }
end

describe service('origin-node') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('dnsmasq') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
