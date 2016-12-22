require 'beaker'
require 'beaker/ca_cert_helper'

module Beaker::PuppetInstallHelper
  def run_puppet_install_helper(type_arg = find_install_type, version = find_install_version)
    run_puppet_install_helper_on(hosts, type_arg, version)
  end

  # Takes a host(s) object, install type string, and install version string.
  # - Type defaults to PE for PE nodes, and foss otherwise.
  # - Version will default to the latest 3x foss/pe package, depending on type
  def run_puppet_install_helper_on(hosts, type_arg = find_install_type, version = find_install_version)
    type = type_arg || find_install_type

    # Short circuit based on rspec-system and beaker variables
    if (ENV['RS_PROVISION'] == 'no') || (ENV['BEAKER_provision'] == 'no')
      Array(hosts).each do |host|
        case type
        when 'pe'
          configure_pe_defaults_on(host)
        when /foss|agent/
          configure_foss_defaults_on(host)
        end
      end
      return
    end

    # Example environment variables to be read:
    # PUPPET_INSTALL_VERSION=3.8.1 <-- for foss/pe/gem
    # PUPPET_INSTALL_VERSION=4.1.0 <-- for agent/gem
    # PUPPET_INSTALL_VERSION=1.0.1 <-- for agent
    #
    # PUPPET_INSTALL_TYPE=pe
    # PUPPET_INSTALL_TYPE=foss
    # PUPPET_INSTALL_TYPE=agent

    # For PUPPET_INSTALL_TYPE=agent and using a development version of Puppet Agent
    # PUPPET_AGENT_SHA=18d31fd5ed41abb276398201f84a4347e0fc7092   <-- Required.  Long form commit SHA used to build the Puppet Agent
    # PUPPET_AGENT_SUITE_VERSION=1.8.2.350.g18d31fd               <-- Optiona. Version string for the Puppet Agent

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

      install_puppet_on(hosts, opts)
      # XXX install_puppet_on() will only add_aio_defaults_on when the nodeset
      # type == 'aio', but we don't want to depend on that.
      if opts[:version] && !version_is_less(opts[:version], '4.0.0')
        add_aio_defaults_on(hosts)
        add_puppet_paths_on(hosts)
      end
      Array(hosts).each do |host|
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
      if ENV['PUPPET_AGENT_SHA'].nil?
        # This will fail on hosts that are not supported; use foss and specify a 4.x version instead
        install_puppet_agent_on(hosts, options.merge(version: version))
      else
        opts = options.merge(puppet_collection: 'PC1',
                             puppet_agent_sha: ENV['PUPPET_AGENT_SHA'],
                             puppet_agent_version: ENV['PUPPET_AGENT_SUITE_VERSION'] || ENV['PUPPET_AGENT_SHA'])
        install_puppet_agent_dev_repo_on(hosts, opts)
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
    if type = ENV['PUPPET_INSTALL_TYPE']
      type
    elsif default.is_pe?
      'pe'
    else
      'foss'
    end
  end

  def find_install_version
    if type = ENV['PUPPET_INSTALL_VERSION']
      type
    elsif type = ENV['PUPPET_VERSION']
      type
    end
  end
end

include Beaker::PuppetInstallHelper
