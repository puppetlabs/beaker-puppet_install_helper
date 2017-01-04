# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.6.0]
### Changed
- Change the default `PUPPET_INSTALL_TYPE` to `agent`

## [0.5.0]
### Changed
- Bump the beaker dependency range up to allow for beaker 3.

## [0.4.4]
### Fixed
- Always add certs on windows

## [0.4.3]
### Fixed
- Use pe\_ver for the host variable of version to install

## [0.4.2]
### Fixed
- Re-add CA certs on windows and solaris for PE 3.

## [0.4.1]
### Fixed
- Don't copy certs on solaris, as they are no longer needed

## [0.4.0]
### Changed
- Add solaris for installing CA certs as well.

[0.6.0]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.4.4...0.5.0
[0.4.4]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.4.3...0.4.4
[0.4.3]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.4.2...0.4.3
[0.4.2]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.4.1...0.4.2
[0.4.1]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.4.0...0.4.1
[0.4.2]: https://github.com/puppetlabs/beaker-puppet_install_helper/compare/0.3.1...0.4.0
