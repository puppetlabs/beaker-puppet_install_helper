## beaker-puppet\_install\_helper

This gem is simply an abstraction for the various ways that we install puppet from the `spec/spec_helper_acceptance.rb` files across the modules.

### `run_puppet_install_helper`

The way to use this is to declare either `run_puppet_install_helper()` or `run_puppet_install_helper_on(hosts)` and set environment variables `BEAKER_PUPPET_AGENT_VERSION` and/or `BEAKER_PUPPET_COLLECTION` in the following combinations to have puppet installed on the desired hosts. The nodeset should be configured with `type: pe` or `type: aio` to control the type of install.

- `BEAKER_PUPPET_COLLECTION=<puppet collection>` will install the specified `BEAKER_PUPPET_AGENT_VERSION` from the specified collection. Valid values are `pc1`, `puppet5`, `puppet6-nightly` etc. This may change with time.
- `BEAKER_PUPPET_AGENT_VERSION=<version>` to specify
- `BEAKER_IS_PE=<yes or no>` may be used to force a nodeset to be PE or not, regardless of the nodeset `type` or absence thereof.
- `BEAKER_PUPPET_AGENT_SHA=<sha>` may be used in order to use a development puppet-agent package.
- `PUPPET_INSTALL_TYPE=foss` may be used to install foss puppet 3.x, but is deprecated and should not be used.

The best way is explicitly set `BEAKER_PUPPET_COLLECTION` and `BEAKER_PUPPET_AGENT_VERSION` to what you want. It'll probably do what you expect.

### `install_ca_certs`

Install Certificate Authority Certs on Windows and OSX for Geotrust, User Trust Network, and Equifax
On Windows it currently is limited to hosts that use cygwin

### `install_ca_certs_on`

Install certs on a given host(s)

### Support

No support is supplied or implied. Use at your own risk.

### TODO
- Add support for ci-ready builds
