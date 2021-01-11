describe package('nfs-common') do
  it { should be_installed }
end

describe package('libdbus-1-3') do
  it { should be_installed }
end

describe package('dkms') do
  it { should be_installed }
end

describe package('curl') do
  it { should be_installed }
end

describe package('unzip') do
  it { should be_installed }
end

describe package('policykit-1') do
  it { should be_installed }
end

control 'os-family-version' do
  describe os.family do
    it { should eq 'debian' }
  end
  describe os.release do
    it { should eq '16.04' }
  end
  describe os.name do
    it { should eq 'ubuntu' }
  end
end

control 'vault' do
  describe file('/usr/local/bin/vault') do
    it { should exist }
    it { should be_file }
    it { should_not be_directory }
    it { should be_owned_by 'root' }
    its('mode') { should cmp '0755' }
  end
  describe file('/etc/vault.d/vault.hcl') do
    it { should exist }
    it { should be_file }
    it { should_not be_directory }
    it { should be_owned_by 'vault' }
  end
end
