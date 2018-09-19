require 'beaker'
require 'beaker/ca_cert_helper'

module Beaker::PuppetInstallHelper
  def run_puppet_install_helper(type_arg = find_install_type, version = find_install_version)
    run_puppet_install_helper_on(hosts, type_arg, version)
  end

  # Takes a host(s) object, install type string, and install version string.
  def run_puppet_install_helper_on(hosts, type_arg = find_install_type, version = find_install_version)
    type = type_arg || find_install_type

    # Short circuit based on rspec-system and beaker variables
    if (ENV['RS_PROVISION'] == 'no') || (ENV['BEAKER_provision'] == 'no')
      configure_type_defaults_on(hosts)
      return
    end

    # Example environment variables to be read:
    # BEAKER_PUPPET_COLLECTION=pc1 <-- for latest 4.x
    # BEAKER_PUPPET_COLLECTION=puppet5 <-- for latest 5.x
    # BEAKER_PUPPET_COLLECTION=puppet5 BEAKER_PUPPET_AGENT_VERSION=5.3.1 <-- for specific version
    # BEAKER_PUPPET_COLLECTION=puppet6 <-- for latest 6.x
    # BEAKER_PUPPET_COLLECTION=puppet-nightly <-- for latest nightly build
    # BEAKER_PUPPET_AGENT_SHA=0ed2bbc918326263da9d97d0361a9e9303b52938 <-- for specific dev build

    # Ensure windows 2003 is always set to 32 bit
    Array(hosts).each do |host|
      host['install_32'] = true if host['platform'] =~ /windows-2003/i
    end

    case type
    when 'pe'
      # These will skip hosts that are not supported
      install_pe_on(Array(hosts), options.merge('pe_ver' => ENV['BEAKER_PE_VER'],
                                                'puppet_agent_version' => version))
      install_ca_certs_on(Array(hosts))
    when 'foss'
      opts = options.merge(version: version,
                           default_action: 'gem_install')
      hosts.each do |host|
        if hosts_with_role(hosts, 'master').length>0 then
          next if host == master
        end
        # XXX install_puppet_on() will call install_puppet_agent_on() if there
        # is a :version option >= 4.x passed, but does foss by default.
        install_puppet_on(host, opts)
      end
      if hosts_with_role(hosts, 'master').length>0 then
        # TODO Make the puppetserver code work with puppet5/puppet6
        # install puppetserver
        install_puppetlabs_release_repo( master, 'pc1' )
        master.install_package('puppetserver')
        on(master, puppet('resource', 'service', 'puppetserver', 'ensure=running'))
        agents.each do |agent|
          on(agent, puppet('resource', 'host', 'puppet', 'ensure=present', "ip=#{master.get_ip}"))
          on(agent, puppet('agent', '--test'), :acceptable_exit_codes => [0,1])
        end
        master['distmoduledir'] = on(master, puppet('config', 'print', 'modulepath')).stdout.split(':')[0]
        sign_certificate_for(agents)
        run_agent_on(agents)
      end
      # XXX install_puppet_on() will only add_aio_defaults_on when the nodeset
      # type == 'aio', but we don't want to depend on that.
      if opts[:version] && !version_is_less(opts[:version], '4.0.0')
        add_aio_defaults_on(hosts)
        add_puppet_paths_on(hosts)
      end
      Array(hosts).each do |host|
        if hosts_with_role(hosts, 'master').length>0 then
          next if host == master
        end
        if fact_on(host, 'osfamily') != 'windows'
          on host, "mkdir -p #{host['distmoduledir']}"
          # XXX Maybe this can just be removed? What PE/puppet version needs
          # it?
          on host, "touch #{host.puppet['hiera_config']}"
        end
        if fact_on(host, 'operatingsystem') == 'Debian'
          on host, "echo 'export PATH=/var/lib/gems/1.8/bin/:${PATH}' >> ~/.bashrc"
        end
        if fact_on(host, 'operatingsystem') == 'Solaris'
          on host, "echo 'export PATH=/opt/puppet/bin:/var/ruby/1.8/gem_home/bin:${PATH}' >> ~/.bashrc"
        end
      end
    when 'agent'
      if ENV['BEAKER_PUPPET_COLLECTION'] =~ /-nightly$/
        # Workaround for RE-10734
        options[:release_apt_repo_url] = "http://apt.puppetlabs.com/#{ENV['BEAKER_PUPPET_COLLECTION']}"
        options[:win_download_url] = 'http://nightlies.puppet.com/downloads/windows'
        options[:mac_download_url] = 'http://nightlies.puppet.com/downloads/mac'
      end

      agent_sha = find_agent_sha
      if agent_sha.nil? || agent_sha.empty?
        install_puppet_agent_on(hosts, options.merge(version: version))
      else
        # If we have a development sha, assume we're testing internally
        dev_builds_url = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'
        install_from_build_data_url('puppet-agent', "#{dev_builds_url}/puppet-agent/#{agent_sha}/artifacts/#{agent_sha}.yaml", hosts)
      end

      # XXX install_puppet_agent_on() will only add_aio_defaults_on when the
      # nodeset type == 'aio', but we don't want to depend on that.
      add_aio_defaults_on(hosts)
      add_puppet_paths_on(hosts)
    else
      raise ArgumentError, "Type must be pe, foss, or agent; got #{type.inspect}"
    end
  end

  def find_install_type
    # XXX Just use default.is_pe? when PUPPET_INSTALL_TYPE=foss is removed.
    ENV['PUPPET_INSTALL_TYPE'] || if default.is_pe?
                                    'pe'
                                  else
                                    'agent'
                                  end
  end

  def find_agent_sha
    ENV['BEAKER_PUPPET_AGENT_SHA'] || ENV['PUPPET_AGENT_SHA']
  end

  def find_install_version
    ENV['BEAKER_PUPPET_AGENT_VERSION'] || ENV['PUPPET_INSTALL_VERSION'] || ENV['PUPPET_VERSION']
  end
end

include Beaker::PuppetInstallHelper
