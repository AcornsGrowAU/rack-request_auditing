# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/request_auditing/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack-request_auditing'
  spec.version       = Rack::RequestAuditing::VERSION
  spec.authors       = ['Kyle Chong']
  spec.email         = ['kyle.chong@acorns.com']

  spec.summary       = 'Request auditing.'
  spec.description   = 'Provides rack middleware for generating and propagating requesting and correlation ids.'
  spec.homepage      = 'https://github.com/Acornsgrow/rack-request_auditing'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rack-test', '~> 0.6'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.4'
end
