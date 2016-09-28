Gem::Specification.new do |s|
  s.name        = "beaker-puppet_install_helper"
  s.version     = '0.5.0'
  s.authors     = ["Puppetlabs"]
  s.email       = ["hunter@puppetlabs.com"]
  s.homepage    = "https://github.com/puppetlabs/beaker-puppet_install_helper"
  s.summary     = %q{Puppet install helper for Beaker}
  s.description = %q{Puppet install helper for Beaker, see https://github.com/puppetlabs/beaker}
  s.license     = 'Apache-2'


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  ## Testing dependencies
  s.add_development_dependency 'rspec'

  # Run time dependencies
  s.add_runtime_dependency 'beaker', '>= 2.0'
end
