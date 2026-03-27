# frozen_string_literal: true

module Philiprehberger
  module JsonSchema
    # Core validation engine that checks data against a JSON Schema (draft-07 subset)
    class Validator
      # Validate data against a schema
      #
      # @param data [Object] the data to validate
      # @param schema [Hash] the JSON Schema
      # @param path [String] the current path for error reporting
      # @return [Array<String>] list of validation error messages
      def validate(data, schema, path: '$')
        errors = []

        validate_type(data, schema, path, errors)
        validate_required(data, schema, path, errors)
        validate_properties(data, schema, path, errors)
        validate_pattern(data, schema, path, errors)
        validate_string_length(data, schema, path, errors)
        validate_numeric_range(data, schema, path, errors)
        validate_enum(data, schema, path, errors)
        validate_items(data, schema, path, errors)
        validate_array_length(data, schema, path, errors)

        errors
      end

      private

      TYPE_MAP = {
        'string' => String,
        'integer' => Integer,
        'number' => Numeric,
        'boolean' => [TrueClass, FalseClass],
        'array' => Array,
        'object' => Hash,
        'null' => NilClass
      }.freeze

      def validate_type(data, schema, path, errors)
        return unless schema.key?(:type) || schema.key?('type')

        type = schema[:type] || schema['type']
        types = Array(type)

        matched = types.any? do |t|
          expected = TYPE_MAP[t.to_s]
          Array(expected).any? { |klass| data.is_a?(klass) }
        end

        return if matched

        errors << "#{path}: expected type #{types.join(' or ')}, got #{ruby_type_name(data)}"
      end

      def validate_required(data, schema, path, errors)
        return unless data.is_a?(Hash)

        required = schema[:required] || schema['required']
        return unless required.is_a?(Array)

        required.each do |key|
          key_str = key.to_s
          errors << "#{path}: missing required property '#{key_str}'" unless data.key?(key_str) || data.key?(key_str.to_sym)
        end
      end

      def validate_properties(data, schema, path, errors)
        return unless data.is_a?(Hash)

        properties = schema[:properties] || schema['properties']
        return unless properties.is_a?(Hash)

        properties.each do |key, prop_schema|
          key_str = key.to_s
          value = data.key?(key_str) ? data[key_str] : data[key_str.to_sym]
          next if value.nil? && !data.key?(key_str) && !data.key?(key_str.to_sym)

          errors.concat(validate(value, prop_schema, path: "#{path}.#{key_str}"))
        end
      end

      def validate_pattern(data, schema, path, errors)
        return unless data.is_a?(String)

        pattern = schema[:pattern] || schema['pattern']
        return unless pattern

        errors << "#{path}: does not match pattern '#{pattern}'" unless data.match?(Regexp.new(pattern))
      end

      def validate_string_length(data, schema, path, errors)
        return unless data.is_a?(String)

        min = schema[:minLength] || schema['minLength']
        max = schema[:maxLength] || schema['maxLength']

        errors << "#{path}: string length #{data.length} is less than minLength #{min}" if min && data.length < min
        errors << "#{path}: string length #{data.length} is greater than maxLength #{max}" if max && data.length > max
      end

      def validate_numeric_range(data, schema, path, errors)
        return unless data.is_a?(Numeric) && !data.is_a?(Complex)

        min = schema[:minimum] || schema['minimum']
        max = schema[:maximum] || schema['maximum']

        errors << "#{path}: value #{data} is less than minimum #{min}" if min && data < min
        errors << "#{path}: value #{data} is greater than maximum #{max}" if max && data > max
      end

      def validate_enum(data, schema, path, errors)
        allowed = schema[:enum] || schema['enum']
        return unless allowed.is_a?(Array)

        errors << "#{path}: value #{data.inspect} is not one of #{allowed.inspect}" unless allowed.include?(data)
      end

      def validate_items(data, schema, path, errors)
        return unless data.is_a?(Array)

        items_schema = schema[:items] || schema['items']
        return unless items_schema.is_a?(Hash)

        data.each_with_index do |item, index|
          errors.concat(validate(item, items_schema, path: "#{path}[#{index}]"))
        end
      end

      def validate_array_length(data, schema, path, errors)
        return unless data.is_a?(Array)

        min = schema[:minItems] || schema['minItems']
        max = schema[:maxItems] || schema['maxItems']

        errors << "#{path}: array length #{data.length} is less than minItems #{min}" if min && data.length < min
        errors << "#{path}: array length #{data.length} is greater than maxItems #{max}" if max && data.length > max
      end

      def ruby_type_name(value)
        case value
        when String then 'string'
        when Integer then 'integer'
        when Float then 'number'
        when TrueClass, FalseClass then 'boolean'
        when Array then 'array'
        when Hash then 'object'
        when NilClass then 'null'
        else value.class.name
        end
      end
    end
  end
end
