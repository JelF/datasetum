
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'datasetum/version'

Gem::Specification.new do |spec|
  spec.name          = 'datasetum'
  spec.version       = Datasetum::VERSION
  spec.authors       = ['Alexander Smirnov']
  spec.email         = ['jelf.personal@zoho.eu']

  spec.summary       = 'Quering ruby datasets'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  # Ice nine provides deep object freezing which is required to make
  # dataset immutable
  spec.add_runtime_dependency 'ice_nine'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'launchy'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'yard'
end
