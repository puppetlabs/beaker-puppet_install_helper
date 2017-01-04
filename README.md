## beaker-puppet\_install\_helper

This gem is simply an abstraction for the various ways that we install puppet from the `spec/spec_helper_acceptance.rb` files across the modules.

### `run_puppet_install_helper`

The way to use this is to declare either `run_puppet_install_helper()` or `run_puppet_install_helper_on(hosts)` and set environment variables `PUPPET_INSTALL_VERSION` and/or `PUPPET_INSTALL_TYPE` in the following combinations to have puppet installed on the desired hosts:

- `PUPPET_INSTALL_TYPE` is unset: if `type: pe` is set for the default node in the nodeset, it will us the PE install method. Otherwise it will only install an agent.
- `PUPPET_INSTALL_TYPE=pe` will read `PUPPET_INSTALL_VERSION` and attempt to install that version of the PE tarball. If no version is set, then it uses the latest stable build.
- `PUPPET_INSTALL_TYPE=agent` will read `PUPPET_INSTALL_VERSION` and install that version of puppet-agent (eg, `PUPPET_INSTALL_TYPE=agent PUPPET_INSTALL_VERSION=1.0.0`)
- `PUPPET_INSTALL_TYPE=foss` will read `PUPPET_INSTALL_VERSION` and:
  - if `PUPPET_INSTALL_VERSION` is less than 4 will attempt to install that version of the system package if available, or else the ruby gem of that version.
  - if `PUPPET_INSTALL_VERSION` is 4 or more it will attempt to install the corresponding puppet-agent package, or gem version otherwise.

The best way is explicitly set `PUPPET_INSTALL_TYPE` and `PUPPET_INSTALL_VERSION` to what you want. It'll probably do what you expect.

#### Installing a puppet-agent package from a development repository

In order to use a custom, or unreleased, puppet-agent package set the following environment variables"
- `PUPPET_INSTALL_TYPE=agent`
- `PUPPET_AGENT_SHA` is the longform commit SHA used when building the puppet-agent package, for example `PUPPET_AGENT_SHA=18d31fd5ed41abb276398201f84a4347e0fc7092`.  This is required to be set in order to use a development puppet-agent package
- `PUPPET_AGENT_SUITE_VERSION` is the version of the puppet-agent package, for example `PUPPET_AGENT_SUITE_VERSION="1.8.2.350.g18d31fd`.  This is optional, and will default to `PUPPET_AGENT_SHA` if not set

### `install_ca_certs`

Install Certificate Authority Certs on Windows and OSX for Geotrust, User Trust Network, and Equifax
On Windows it currently is limited to hosts that use cygwin

### `install_ca_certs_on`

Install certs on a given host(s)

### Support

No support is supplied or implied. Use at your own risk.

### TODO
- Add support for ci-ready builds
