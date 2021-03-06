# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_model/serializer/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_model_serializers'
  spec.version       = ActiveModel::Serializer::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Steve Klabnik']
  spec.email         = ['steve@steveklabnik.com']
  spec.summary       = 'Conventions-based JSON generation for Rails.'
  spec.description   = 'ActiveModel::Serializers allows you to generate your JSON in an object-oriented and convention-driven manner.'
  spec.homepage      = 'https://github.com/rails-api/active_model_serializers'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9.3'

  rails_versions = '>= 4.0'
  spec.add_runtime_dependency 'activemodel', rails_versions
    # 'activesupport', rails_versions
    # 'builder'

  spec.add_runtime_dependency 'actionpack', rails_versions
    # 'activesupport', rails_versions
    # 'rack'
    # 'rack-test', '~> 0.6.2'

  spec.add_runtime_dependency 'railties', rails_versions
    # 'activesupport', rails_versions
    # 'actionpack', rails_versions
    # 'rake', '>= 0.8.7'

  # 'activesupport', rails_versions
    # 'i18n,
    # 'tzinfo'
    # 'minitest'
    # 'thread_safe'

  # Soft dependency for pagination
  spec.add_development_dependency 'kaminari'
  spec.add_development_dependency 'will_paginate'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'timecop', '>= 0.7'
end
