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
  end
end
