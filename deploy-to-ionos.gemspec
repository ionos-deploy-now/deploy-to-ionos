# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'deploy-to-ionos'
  spec.version       = File.read('VERSION').strip
  spec.authors       = ['Robin Müller']
  spec.email         = ['robin.mueller@ionos.com']

  spec.summary       = 'Deploy to IONOS'
  spec.description   = 'Utility for the deployment of IONOS Deploy Now'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/}) || f == '.github' || f == '.gitignore' || f == 'Dockerfile'
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '3.10.0'
  spec.add_development_dependency 'simplecov', '0.21.2'

  spec.add_runtime_dependency 'net-ssh', '6.1.0'
  spec.add_runtime_dependency 'passgen', '1.2.0'
  spec.add_runtime_dependency 'rest-client', '2.1.0'
  spec.add_runtime_dependency 'version', '1.1.1'
end
