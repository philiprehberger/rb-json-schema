# frozen_string_literal: true

require_relative 'json_schema/version'
require_relative 'json_schema/validator'

module Philiprehberger
  module JsonSchema
    class Error < StandardError; end

    # Validate data against a JSON Schema and return error messages
    #
    # @param data [Object] the data to validate
    # @param schema [Hash] the JSON Schema definition
    # @return [Array<String>] list of validation errors (empty if valid)
    def self.validate(data, schema)
      Validator.new.validate(data, schema)
    end

    # Check if data is valid against a JSON Schema
    #
    # @param data [Object] the data to validate
    # @param schema [Hash] the JSON Schema definition
    # @return [Boolean] true if data passes validation
    def self.valid?(data, schema)
      validate(data, schema).empty?
    end

    # Validate data against a JSON Schema; raise on failure.
    #
    # @param data [Object] the data to validate
    # @param schema [Hash] the JSON Schema definition
    # @return [Object] the validated data, unchanged
    # @raise [Error] when validation fails (message is the joined errors)
    def self.validate!(data, schema)
      errors = validate(data, schema)
      raise Error, errors.join('; ') unless errors.empty?

      data
    end

    # Compile a schema for repeated validation
    #
    # @param schema [Hash] the JSON Schema definition
    # @return [CompiledSchema] a compiled validator instance
    def self.compile(schema)
      CompiledSchema.new(schema)
    end
  end
end
