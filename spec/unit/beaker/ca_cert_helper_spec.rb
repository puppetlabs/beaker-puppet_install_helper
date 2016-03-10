require 'spec_helper'

describe 'beaker::ca_cert_helper' do
  let :subject do
    Class.new do
      include Beaker::PuppetInstallHelper
      include Beaker::CaCertHelper
    end
  end


  describe 'install_ca_certs_on' do
    before :each do
      allow(subject).to receive(:get_cert_hash).and_return(
                            {'geotrustglobal.pem' => 'my cert string',
                             'usertrust-network.pem' => 'my user trust cert'})
    end

    it "windows 2003 node" do
      w2k3 = {"platform" => 'windows-2003r2-64', 'distmoduledir' => '/dne', 'hieraconf' => '/dne'}

      expect(subject).to receive(:add_windows_cert).with(w2k3, 'geotrustglobal.pem')
      expect(subject).to receive(:create_cert_on_host).with(w2k3, 'geotrustglobal.pem', 'my cert string')
      expect(subject).to receive(:add_windows_cert).with(w2k3, 'usertrust-network.pem')
      expect(subject).to receive(:create_cert_on_host).with(w2k3, 'usertrust-network.pem', 'my user trust cert')
      subject.install_ca_certs_on w2k3
    end

    it "solaris 11 node" do
      sol = {"platform" => 'solaris-11-x86_64', 'distmoduledir' => '/dne', 'hieraconf' => '/dne'}

      expect(subject).to receive(:add_solaris_cert).with(sol, 'geotrustglobal.pem')
      expect(subject).to receive(:create_cert_on_host).with(sol, 'geotrustglobal.pem', 'my cert string')
      expect(subject).to receive(:add_solaris_cert).with(sol, 'usertrust-network.pem')
      expect(subject).to receive(:create_cert_on_host).with(sol, 'usertrust-network.pem', 'my user trust cert')
      subject.install_ca_certs_on sol
    end
  end

  describe 'add_windows_cert' do
    it {
      host = {"platform" => 'windows-2003r2-64', 'distmoduledir' => '/dne', 'hieraconf' => '/dne'}
      expect(subject).to receive(:on).with(host, 'cmd /c certutil -v -addstore Root `cygpath -w geotrustglobal.pem`')
      subject.add_windows_cert host, 'geotrustglobal.pem'
    }
  end

  describe 'add_solaris_cert' do
    it {
      host = {"platform" => 'solaris-11-x86_64', 'distmoduledir' => '/dne', 'hieraconf' => '/dne'}
      expect(subject).to receive(:on).with(host, 'echo \'# geotrustglobal.pem\' >> /opt/puppet/ssl/cert.pem')
      expect(subject).to receive(:on).with(host, 'cat geotrustglobal.pem >> /opt/puppet/ssl/cert.pem')
      subject.add_solaris_cert host, 'geotrustglobal.pem'
    }
  end

  describe 'get_cert_hash' do
    it 'should contain 3 certs' do
      cert_hash = subject.get_cert_hash
      expect(cert_hash.length).to equal(3)
      expect(cert_hash.class).to eq(Hash)
    end
  end
end
