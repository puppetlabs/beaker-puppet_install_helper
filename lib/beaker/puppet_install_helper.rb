require 'beaker'
require 'beaker/ca_cert_helper'

module Beaker::PuppetInstallHelper
  def run_puppet_install_helper(type_arg = find_install_type, version = find_install_version)
    run_puppet_install_helper_on(hosts, type_arg, version)
  end

  # Takes a host(s) object, install type string, and install version string.
  # - Type defaults to PE for PE nodes, and puppet5 agent otherwise.
  # - Version will default to the latest 5x agent or pe package, depending on type
  def run_puppet_install_helper_on(hosts, type_arg = find_install_type, version = find_install_version)
    type = type_arg || find_install_type

    # Short circuit based on rspec-system and beaker variables
    if (ENV['RS_PROVISION'] == 'no') || (ENV['BEAKER_provision'] == 'no')
      configure_defaults_on(hosts, type_arg)
      return
    end

    # Example environment variables to be read:
    # PUPPET_INSTALL_VERSION=4.1.0 <-- for agent
    # PUPPET_INSTALL_VERSION=1.0.1 <-- for agent
    #
    # PUPPET_INSTALL_TYPE=pe
    # PUPPET_INSTALL_TYPE=foss
    # PUPPET_INSTALL_TYPE=agent
    # PUPPET_INSTALL_TYPE=nightly

    # For PUPPET_INSTALL_TYPE=puppet6-nightly using a development version of Puppet Agent
    # PUPPET_AGENT_SHA=0ed2bbc918326263da9d97d0361a9e9303b52938 <-- Long form commit SHA used to build the Puppet Agent

    # Ensure windows 2003 is always set to 32 bit
    Array(hosts).each do |host|
      host['install_32'] = true if host['platform'] =~ /windows-2003/i
    end

    case type
    when 'pe'
      # These will skip hosts that are not supported
      install_pe_on(Array(hosts), options.merge('pe_ver' => version))
      install_ca_certs_on(Array(hosts))
    when 'foss'
      opts = options.merge(version: version,
                           default_action: 'gem_install')
      hosts.each do |host|
        if hosts_with_role(hosts, 'master').length>0 then
          next if host == master
        end
        install_puppet_on(host, opts)
      end
      if hosts_with_role(hosts, 'master').length>0 then
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
    when 'agent', 'agent4', 'puppet4'
      install_agent_on(hosts, 'pc1', version)
    when 'agent5', 'puppet5'
      install_agent_on(hosts, 'puppet5', version)
    when /^puppet\d-nightly$/ # Just 'puppet-nightly' doesn't work: https://github.com/puppetlabs/beaker-puppet/blob/63ea32a0d7caa8f261c533b020625de19569f971/lib/beaker-puppet/install_utils/foss_utils.rb#L944
      install_agent_on(hosts, type, version)
    else
      raise ArgumentError, "Type must be pe, puppet4, puppet5, or puppet6-nightly; got #{type.inspect}"
    end
  end

  def find_install_type
    ENV['PUPPET_INSTALL_TYPE'] || if default.is_pe?
                                    'pe'
                                  else
                                    'puppet5'
                                  end
  end

  def find_install_version
    ENV['PUPPET_INSTALL_VERSION'] || ENV['PUPPET_VERSION']
  end

  def install_agent_on(hosts, collection, version)
    if ENV['PUPPET_AGENT_SHA'].nil?
      opts = options.merge(puppet_collection: collection,
                           version: version)
      install_puppet_agent_on(hosts, opts)
    else
      opts = options.merge(puppet_collection: collection,
                           puppet_agent_sha: ENV['PUPPET_AGENT_SHA'],
                           puppet_agent_version: ENV['PUPPET_AGENT_SUITE_VERSION'] || ENV['PUPPET_AGENT_SHA'])
      install_puppet_agent_dev_repo_on(hosts, opts)
    end

    # XXX install_puppet_agent_on() will only add_aio_defaults_on when the
    # nodeset type == 'aio', but we don't want to depend on that.
    add_aio_defaults_on(hosts)
    add_puppet_paths_on(hosts)
  end
end

include Beaker::PuppetInstallHelper
