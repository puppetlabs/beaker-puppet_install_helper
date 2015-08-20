require 'spec_helper'

describe 'beaker::puppet_install_helper' do
  let :subject do
    Class.new { include Beaker::PuppetInstallHelper }
  end
  let :hosts do
    foss_host = double(:is_pe? => false)
    pe_host = double(:is_pe? => true)
    allow(foss_host).to receive(:[]).with("distmoduledir").and_return("/dne")
    allow(foss_host).to receive(:[]).with("platform").and_return("Debian")
    allow(foss_host).to receive(:puppet).and_return({"hiera_config" => "/dne"})
    allow(pe_host).to receive(:[]).with("distmoduledir").and_return("/dne")
    allow(pe_host).to receive(:[]).with("platform").and_return("Debian")
    allow(pe_host).to receive(:puppet).and_return({"hiera_config" => "/dne"})
    [foss_host, pe_host]
  end
  before :each do
    allow(subject).to receive(:options).and_return({})
    allow(subject).to receive(:on)
    allow(subject).to receive(:fact_on)
  end
  after :each do
    ENV.delete("PUPPET_VERSION")
    ENV.delete("PUPPET_INSTALL_VERSION")
    ENV.delete("PUPPET_INSTALL_TYPE")
  end
  describe '#run_puppet_install_helper' do
    before :each do
      allow(subject).to receive(:hosts).and_return(hosts)
      allow(subject).to receive(:default).and_return(hosts[0])
    end
    it 'calls run_puppet_install_helper_on on each host' do
      expect(subject).to receive(:run_puppet_install_helper_on).with(hosts,"foss",nil)
      subject.run_puppet_install_helper
    end
    ["PUPPET_VERSION","PUPPET_INSTALL_VERSION"].each do |version_var| 
      it 'calls run_puppet_install_helper_on on each host with a version ' do
        ENV[version_var] = "4.1.0"
        expect(subject).to receive(:run_puppet_install_helper_on).with(hosts,"foss","4.1.0")
        subject.run_puppet_install_helper
      end
    end
  end
  describe '#run_puppet_install_helper_on' do
    context "for default" do
      it "uses foss by default for non-pe nodes" do
        expect(subject).to receive(:default).and_return(hosts[0])
        expect(subject).to receive(:install_puppet_on).with(hosts,{:version => nil,:default_action => "gem_install"})
        subject.run_puppet_install_helper_on(hosts)
      end
      it "windows 2003 node" do
        w2k3 = {"platform" => 'windows-2003r2-64', 'distmoduledir' => '/dne','hieraconf' => '/dne'}
        win_hosts = [ w2k3 ]
        expect(subject).to receive(:default).and_return(double(:is_pe? => true))
        expect(subject).to receive(:install_pe_on).with([w2k3.merge({'install_32' => true})], {"pe_ver" => nil})
        subject.run_puppet_install_helper_on(win_hosts)
      end
      it "uses PE by default for PE nodes" do
        expect(subject).to receive(:default).and_return(hosts[1])
        expect(subject).to receive(:install_pe_on).with(hosts,{"pe_ver" => nil})
        subject.run_puppet_install_helper_on(hosts)
      end
    end
    context "for foss" do
      it "uses foss explicitly" do
        ENV["PUPPET_INSTALL_TYPE"] = "foss"
        expect(subject).to receive(:install_puppet_on).with(hosts,{:version => nil,:default_action => "gem_install"})
        subject.run_puppet_install_helper_on(hosts)
      end
      ["PUPPET_VERSION","PUPPET_INSTALL_VERSION"].each do |version_var| 
        it "uses foss with a version" do
          ENV["PUPPET_INSTALL_TYPE"] = "foss"
          ENV[version_var] = "3.8.1"
          expect(subject).to receive(:install_puppet_on).with(hosts,{:version => "3.8.1",:default_action => "gem_install"})
          subject.run_puppet_install_helper_on(hosts)
        end
        it "uses foss with a >4 version detects AIO" do
          ENV["PUPPET_INSTALL_TYPE"] = "foss"
          ENV[version_var] = "4.1.0"
          expect(subject).to receive(:install_puppet_on).with(hosts,{:version => "4.1.0",:default_action => "gem_install"})
          expect(subject).to receive(:add_aio_defaults_on).with(hosts)
          expect(subject).to receive(:add_puppet_paths_on).with(hosts)
          subject.run_puppet_install_helper_on(hosts)
        end
      end
    end
    context "for PE" do
      it "uses PE explicitly" do
        ENV["PUPPET_INSTALL_TYPE"] = "pe"
        expect(subject).to receive(:install_pe_on).with(hosts,{"pe_ver" => nil})
        subject.run_puppet_install_helper_on(hosts)
      end
      it "uses PE with a version" do
        ENV["PUPPET_INSTALL_TYPE"] = "pe"
        ENV["PUPPET_INSTALL_VERSION"] = "3.8.1"
        expect(subject).to receive(:install_pe_on).with(hosts,{"pe_ver" => "3.8.1"})
        subject.run_puppet_install_helper_on(hosts)
      end
    end
    context "for puppet-agent" do
      it "uses agent explicitly" do
        ENV["PUPPET_INSTALL_TYPE"] = "agent"
        expect(subject).to receive(:install_puppet_agent_on).with(hosts,{:version => nil})
        expect(subject).to receive(:add_aio_defaults_on).with(hosts)
        expect(subject).to receive(:add_puppet_paths_on).with(hosts)
        subject.run_puppet_install_helper_on(hosts)
      end
      it "uses foss with a version" do
        ENV["PUPPET_INSTALL_TYPE"] = "agent"
        ENV["PUPPET_INSTALL_VERSION"] = "1.1.0"
        expect(subject).to receive(:install_puppet_agent_on).with(hosts,{:version => "1.1.0"})
        expect(subject).to receive(:add_aio_defaults_on).with(hosts)
        expect(subject).to receive(:add_puppet_paths_on).with(hosts)
        subject.run_puppet_install_helper_on(hosts)
      end
    end
  end
end
