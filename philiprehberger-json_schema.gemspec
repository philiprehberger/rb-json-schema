# frozen_string_literal: true

require_relative 'lib/philiprehberger/json_schema/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-json_schema'
  spec.version = Philiprehberger::JsonSchema::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'JSON Schema validator supporting common draft-07 keywords with schema composition, ' \
                 'conditional validation, and compiled schemas'
  spec.description = 'Validate Ruby data structures against JSON Schema definitions with support for ' \
                     'type checking, required properties, pattern matching, numeric ranges, enums, and array validation.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-json_schema'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-json-schema'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-json-schema/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-json-schema/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
