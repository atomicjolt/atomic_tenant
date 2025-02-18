require_relative 'lib/atomic_tenant/version'

Gem::Specification.new do |spec|
  spec.name        = 'atomic_tenant'
  spec.version     = AtomicTenant::VERSION
  spec.authors     = ['Nick Benoit']
  spec.email       = ['nick.benoit@atomicjolt.com']
  spec.homepage    = 'https://example.com'
  spec.summary     = 'Summary of AtomicTenant.'
  spec.description = 'Description of AtomicTenant.'
  spec.license = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
  # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'atomic_lti', '>= 1.3', '< 5'
  spec.add_dependency 'rails', '>= 7.0', '< 9'
  spec.add_development_dependency 'rspec', '~> 2.0'
end
