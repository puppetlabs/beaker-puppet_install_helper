require 'spec_helper'

describe 'Beaker::PuppetInstallHelper' do
  let :subject do
    Class.new { include Beaker::PuppetInstallHelper }
  end
  let :hosts do
    foss_host = double(is_pe?: false)
    pe_host = double(is_pe?: true)
    allow(foss_host).to receive(:[]).with('distmoduledir').and_return('/dne')
    allow(foss_host).to receive(:[]).with('platform').and_return('Debian')
    allow(foss_host).to receive(:[]).with('pe_ver').and_return(nil)
    allow(foss_host).to receive(:[]).with('roles').and_return(['agent'])
    allow(foss_host).to receive(:puppet).and_return('hiera_config' => '/dne')
    allow(pe_host).to receive(:[]).with('pe_ver').and_return('3.8.3')
    allow(pe_host).to receive(:[]).with('distmoduledir').and_return('/dne')
    allow(pe_host).to receive(:[]).with('platform').and_return('Debian')
    allow(pe_host).to receive(:[]).with('roles').and_return(['agent'])
    allow(pe_host).to receive(:puppet).and_return('hiera_config' => '/dne')
    [foss_host, pe_host]
  end
  before :each do
    allow(subject).to receive(:options).and_return({})
    allow(subject).to receive(:on)
    allow(subject).to receive(:fact_on)
    allow(subject).to receive(:agents).and_return(hosts)
    allow(subject).to receive(:default).and_return(hosts[0])
  end
  after :each do
    ENV.delete('PUPPET_VERSION')
    ENV.delete('PUPPET_INSTALL_VERSION')
    ENV.delete('PUPPET_INSTALL_TYPE')
    ENV.delete('PUPPET_AGENT_SHA')
    ENV.delete('PUPPET_AGENT_SUITE_VERSION')
    ENV.delete('BEAKER_IS_PE')
    ENV.delete('BEAKER_PUPPET_COLLECTION')
    ENV.delete('BEAKER_PUPPET_AGENT_VERSION')
    ENV.delete('BEAKER_PUPPET_AGENT_SHA')
    ENV.delete('BEAKER_PE_VER')
  end
  describe '#run_puppet_install_helper' do
    before :each do
      allow(subject).to receive(:hosts).and_return(hosts)
    end
    it 'calls run_puppet_install_helper_on on each host' do
      expect(subject).to receive(:run_puppet_install_helper_on).with(hosts, 'agent', nil)
      subject.run_puppet_install_helper
    end
    %w(BEAKER_PUPPET_AGENT_VERSION PUPPET_VERSION PUPPET_INSTALL_VERSION).each do |version_var|
      it 'calls run_puppet_install_helper_on on each host with a version ' do
        ENV[version_var] = '4.1.0'
        expect(subject).to receive(:run_puppet_install_helper_on).with(hosts, 'agent', '4.1.0')
        subject.run_puppet_install_helper
      end
    end
  end
  describe '#run_puppet_install_helper_on' do
    context 'for default' do
      it 'uses agent by default for non-pe nodes' do
        expect(subject).to receive(:default).and_return(hosts[0])
        expect(subject).to receive(:add_aio_defaults_on).with(hosts)
        expect(subject).to receive(:add_puppet_paths_on).with(hosts)
        expect(subject).to receive(:install_puppet_agent_on).with(hosts, version: nil)
        subject.run_puppet_install_helper_on(hosts)
      end
      it 'windows 2003 node' do
        w2k3 = { 'platform' => 'windows-2003r2-64', 'distmoduledir' => '/dne', 'hieraconf' => '/dne' }
        win_hosts = [w2k3]
        expect(subject).to receive(:default).and_return(double(is_pe?: true))
        expect(subject).to receive(:install_pe_on).with([w2k3.merge('install_32' => true)], 'pe_ver' => nil, 'puppet_agent_version' => nil)
        expect(subject).to receive(:create_cert_on_host).exactly(3).times
        expect(subject).to receive(:add_windows_cert).exactly(3).times
        subject.run_puppet_install_helper_on(win_hosts)
      end
      it 'uses PE by default for PE nodes' do
        expect(subject).to receive(:default).and_return(hosts[1])
        expect(subject).to receive(:install_pe_on).with(hosts, 'pe_ver' => nil, 'puppet_agent_version' => nil)
        subject.run_puppet_install_helper_on(hosts)
      end
    end
    context 'for non-pe' do
      context 'and foss type' do
        let :hosts do
          foss_host = double(is_pe?: false)
          foss_master = double(is_pe?: false)
          allow(foss_host).to receive(:[]).with('distmoduledir').and_return('/dne')
          allow(foss_host).to receive(:[]).with('platform').and_return('Debian')
          allow(foss_host).to receive(:[]).with('pe_ver').and_return(nil)
          allow(foss_host).to receive(:[]).with('roles').and_return(['agent'])
          allow(foss_host).to receive(:puppet).and_return('hiera_config' => '/dne')
          allow(foss_master).to receive(:[]).with('pe_ver').and_return(nil)
          allow(foss_master).to receive(:[]=).with('distmoduledir', 'foo')
          allow(foss_master).to receive(:[]).with('platform').and_return('Debian')
          allow(foss_master).to receive(:[]).with('roles').and_return(['master'])
          allow(foss_master).to receive(:get_ip).and_return('1.2.3.4')
          allow(foss_master).to receive(:install_package).with('puppetserver')
          allow(foss_master).to receive(:get_ip).and_return('1.2.3.4')
          [foss_host, foss_master]
        end
        let :result do
          Beaker::Result.new( nil, nil )
        end
        before :each do
          allow(subject).to receive(:master).and_return(hosts[1])
          allow(subject).to receive(:sign_certificate_for)
          allow(subject).to receive(:puppet_agent)
          allow(subject).to receive(:puppet).with('resource', 'service', 'puppetserver', 'ensure=running')
          allow(subject).to receive(:puppet).with('resource', 'host', 'puppet', 'ensure=present', 'ip=1.2.3.4')
          allow(subject).to receive(:puppet).with('agent', '--test')
          allow(subject).to receive(:puppet).with('config', 'print', 'modulepath')
          allow(subject).to receive(:on).and_return(result)
          result.stdout = 'foo:bar'
        end
        it 'uses foss explicitly' do
          ENV['PUPPET_INSTALL_TYPE'] = 'foss'
          expect(subject).to receive(:install_puppetlabs_release_repo).with(hosts[1], 'pc1')
          expect(subject).to receive(:install_puppet_on).with(hosts[0], version: nil, default_action: 'gem_install')
          subject.run_puppet_install_helper_on(hosts)
        end
        %w(BEAKER_PUPPET_AGENT_VERSION PUPPET_VERSION PUPPET_INSTALL_VERSION).each do |version_var|
          it 'uses foss with a version' do
            ENV['PUPPET_INSTALL_TYPE'] = 'foss'
            ENV[version_var] = '3.8.1'
            expect(subject).to receive(:install_puppetlabs_release_repo).with(hosts[1], 'pc1')
            expect(subject).to receive(:install_puppet_on).with(hosts[0], version: '3.8.1', default_action: 'gem_install')
            subject.run_puppet_install_helper_on(hosts)
          end
          it 'uses foss with a 4.x version detects AIO' do
            ENV['PUPPET_INSTALL_TYPE'] = 'foss'
            ENV[version_var] = '4.1.0'
            expect(subject).to receive(:install_puppetlabs_release_repo).with(hosts[1], 'pc1')
            expect(subject).to receive(:install_puppet_on).with(hosts[0], version: '4.1.0', default_action: 'gem_install')
            expect(subject).to receive(:add_aio_defaults_on).with(hosts)
            expect(subject).to receive(:add_puppet_paths_on).with(hosts)
            subject.run_puppet_install_helper_on(hosts)
          end
          it 'uses pc1 with a 5.x version; this fails' do
            ENV['PUPPET_INSTALL_TYPE'] = 'foss'
            ENV[version_var] = '5.1.0'
            expect(subject).to receive(:install_puppetlabs_release_repo).with(hosts[1], 'pc1')
            expect(subject).to receive(:install_puppet_on).with(hosts[0], version: '5.1.0', default_action: 'gem_install')
            expect(subject).to receive(:add_aio_defaults_on).with(hosts)
            expect(subject).to receive(:add_puppet_paths_on).with(hosts)
            subject.run_puppet_install_helper_on(hosts)
          end
        end
      end
      context 'for agent type' do
        context 'with no collection' do
          it 'uses agent by default for non-pe hosts' do
            expect(subject).to receive(:install_puppet_agent_on).with(hosts, version: nil)
            expect(subject).to receive(:add_aio_defaults_on).with(hosts)
            expect(subject).to receive(:add_puppet_paths_on).with(hosts)
            subject.run_puppet_install_helper_on(hosts)
          end
          it 'uses agent explicitly' do
            ENV['PUPPET_INSTALL_TYPE'] = 'agent'
            expect(subject).to receive(:install_puppet_agent_on).with(hosts, version: nil)
            expect(subject).to receive(:add_aio_defaults_on).with(hosts)
            expect(subject).to receive(:add_puppet_paths_on).with(hosts)
            subject.run_puppet_install_helper_on(hosts)
          end
        end
        ['puppet5', 'puppet6-nightly'].each do |collection|
          context "with #{collection} collection" do
            it "installs puppet-agent from #{collection} repo" do
              ENV['BEAKER_PUPPET_COLLECTION'] = collection
              if collection =~ /-nightly$/
                expect(subject).to receive(:install_puppet_agent_on).with(hosts, release_apt_repo_url: "http://apt.puppetlabs.com/puppet6-nightly", version: nil)
              else
                expect(subject).to receive(:install_puppet_agent_on).with(hosts, version: nil)
              end
              expect(subject).to receive(:add_aio_defaults_on).with(hosts)
              expect(subject).to receive(:add_puppet_paths_on).with(hosts)
              subject.run_puppet_install_helper_on(hosts)
            end
          end
        end
        context 'with a specific development sha' do
          it 'uses a development repo' do
            ENV['BEAKER_PUPPET_AGENT_SHA'] = '0ed2bbc918326263da9d97d0361a9e9303b52938'
            expect(subject).to receive(:install_puppet_agent_dev_repo_on).with(hosts, puppet_agent_sha: '0ed2bbc918326263da9d97d0361a9e9303b52938', puppet_agent_version: '0ed2bbc918326263da9d97d0361a9e9303b52938')
            expect(subject).to receive(:add_aio_defaults_on).with(hosts)
            expect(subject).to receive(:add_puppet_paths_on).with(hosts)
            subject.run_puppet_install_helper_on(hosts)
          end
          it 'uses a development repo with suite version and sha' do
            ENV['BEAKER_PUPPET_AGENT_SHA'] = '0ed2bbc918326263da9d97d0361a9e9303b52938'
            ENV['PUPPET_AGENT_SUITE_VERSION'] = '5.5.0.152.g0ed2bbc'
            expect(subject).to receive(:install_puppet_agent_dev_repo_on).with(hosts, puppet_agent_sha: '0ed2bbc918326263da9d97d0361a9e9303b52938', puppet_agent_version: '5.5.0.152.g0ed2bbc')
            expect(subject).to receive(:add_aio_defaults_on).with(hosts)
            expect(subject).to receive(:add_puppet_paths_on).with(hosts)
            subject.run_puppet_install_helper_on(hosts)
          end
        end
      end
    end
    context 'for PE' do
      it 'uses PE when default is a pe host' do
        expect(subject).to receive(:default).and_return(hosts[1])
        expect(subject).to receive(:install_pe_on).with(hosts, 'pe_ver' => nil, 'puppet_agent_version' => nil)
        subject.run_puppet_install_helper_on(hosts)
      end
      it 'uses PE explicitly' do
        ENV['PUPPET_INSTALL_TYPE'] = 'pe'
        expect(subject).to receive(:install_pe_on).with(hosts, 'pe_ver' => nil, 'puppet_agent_version' => nil)
        subject.run_puppet_install_helper_on(hosts)
      end
      it 'uses PE with a version' do
        ENV['PUPPET_INSTALL_TYPE'] = 'pe'
        ENV['BEAKER_PE_VER'] = '3.8.1'
        expect(subject).to receive(:install_pe_on).with(hosts, 'pe_ver' => '3.8.1', 'puppet_agent_version' => nil)
        subject.run_puppet_install_helper_on(hosts)
      end
      it 'uses PE with an agent version' do
        ENV['PUPPET_INSTALL_TYPE'] = 'pe'
        ENV['PUPPET_INSTALL_VERSION'] = '2017.3.5'
        ENV['BEAKER_IS_PE'] = 'yes'
        ENV['BEAKER_PE_VER'] = '2017.3.5'
        ENV['BEAKER_PUPPET_AGENT_VERSION'] = '5.3.5'
        expect(subject).to receive(:install_pe_on).with(hosts, 'pe_ver' => '2017.3.5', 'puppet_agent_version' => '5.3.5')
        subject.run_puppet_install_helper_on(hosts)
      end
      it 'installs certs on PE 3 solaris' do
        sol = { 'pe_ver' => '3.8.3', 'platform' => 'solaris-11-64', 'distmoduledir' => '/dne', 'hieraconf' => '/dne' }
        hosts = [sol]
        ENV['PUPPET_INSTALL_TYPE'] = 'pe'
        ENV['BEAKER_PE_VER'] = '3.8.1'
        expect(subject).to receive(:install_pe_on).with(hosts, 'pe_ver' => '3.8.1', 'puppet_agent_version' => nil)
        expect(subject).to receive(:create_cert_on_host).exactly(3).times
        expect(subject).to receive(:add_solaris_cert).exactly(3).times
        subject.run_puppet_install_helper_on(hosts)
      end
    end
  end
end
