
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "CI/connector/version"

Gem::Specification.new do |spec|
  spec.name          = "ci-connector"
  spec.version       = CI::Connector::VERSION
  spec.authors       = ["Thomas Auffredou"]
  spec.email         = ["tauffredou@jobteaser.com"]

  spec.summary       = 'CI hook helper gem'
  spec.description   = 'CI hook helper gem'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      "public gem pushes."
  end

  spec.files = Dir.glob('{bin,lib}/**/*')
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'ruby-kafka', '~> 0.5'
end
