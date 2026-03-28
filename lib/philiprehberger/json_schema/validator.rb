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
      # @param root_schema [Hash, nil] the root schema for $ref resolution
      # @return [Array<String>] list of validation error messages
      def validate(data, schema, path: '$', root_schema: nil)
        root_schema ||= schema
        errors = []

        validate_type(data, schema, path, errors)
        validate_const(data, schema, path, errors)
        validate_required(data, schema, path, errors)
        validate_properties(data, schema, path, errors, root_schema)
        validate_additional_properties(data, schema, path, errors, root_schema)
        validate_pattern_properties(data, schema, path, errors, root_schema)
        validate_pattern(data, schema, path, errors)
        validate_string_length(data, schema, path, errors)
        validate_numeric_range(data, schema, path, errors)
        validate_enum(data, schema, path, errors)
        validate_items(data, schema, path, errors, root_schema)
        validate_array_length(data, schema, path, errors)
        validate_ref(data, schema, path, errors, root_schema)
        validate_all_of(data, schema, path, errors, root_schema)
        validate_any_of(data, schema, path, errors, root_schema)
        validate_one_of(data, schema, path, errors, root_schema)
        validate_not(data, schema, path, errors, root_schema)
        validate_if_then_else(data, schema, path, errors, root_schema)

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

      def schema_key(schema, key)
        sym = key.to_sym
        return schema[sym] if schema.key?(sym)

        schema[key.to_s]
      end

      def validate_type(data, schema, path, errors)
        type = schema_key(schema, :type)
        return unless type

        types = Array(type)

        matched = types.any? do |t|
          expected = TYPE_MAP[t.to_s]
          Array(expected).any? { |klass| data.is_a?(klass) }
        end

        return if matched

        errors << "#{path}: expected type #{types.join(' or ')}, got #{ruby_type_name(data)}"
      end

      def validate_const(data, schema, path, errors)
        return unless schema.key?(:const) || schema.key?('const')

        const_val = schema_key(schema, :const)
        errors << "#{path}: value #{data.inspect} does not equal const #{const_val.inspect}" unless data == const_val
      end

      def validate_required(data, schema, path, errors)
        return unless data.is_a?(Hash)

        required = schema_key(schema, :required)
        return unless required.is_a?(Array)

        required.each do |key|
          key_str = key.to_s
          errors << "#{path}: missing required property '#{key_str}'" unless data.key?(key_str) || data.key?(key_str.to_sym)
        end
      end

      def validate_properties(data, schema, path, errors, root_schema)
        return unless data.is_a?(Hash)

        properties = schema_key(schema, :properties)
        return unless properties.is_a?(Hash)

        properties.each do |key, prop_schema|
          key_str = key.to_s
          value = data.key?(key_str) ? data[key_str] : data[key_str.to_sym]
          next if value.nil? && !data.key?(key_str) && !data.key?(key_str.to_sym)

          errors.concat(validate(value, prop_schema, path: "#{path}.#{key_str}", root_schema: root_schema))
        end
      end

      def validate_additional_properties(data, schema, path, errors, root_schema)
        return unless data.is_a?(Hash)
        return unless schema.key?(:additionalProperties) || schema.key?('additionalProperties')

        additional = schema_key(schema, :additionalProperties)
        properties = schema_key(schema, :properties) || {}
        pattern_props = schema_key(schema, :patternProperties) || {}

        property_names = properties.keys.map(&:to_s)
        pattern_regexes = pattern_props.keys.map { |p| Regexp.new(p.to_s) }

        data.each_key do |key|
          key_str = key.to_s
          next if property_names.include?(key_str)
          next if pattern_regexes.any? { |re| key_str.match?(re) }

          if additional == false
            errors << "#{path}: additional property '#{key_str}' is not allowed"
          elsif additional.is_a?(Hash)
            errors.concat(validate(data[key], additional, path: "#{path}.#{key_str}", root_schema: root_schema))
          end
        end
      end

      def validate_pattern_properties(data, schema, path, errors, root_schema)
        return unless data.is_a?(Hash)

        pattern_props = schema_key(schema, :patternProperties)
        return unless pattern_props.is_a?(Hash)

        pattern_props.each do |pattern, prop_schema|
          regex = Regexp.new(pattern.to_s)
          data.each do |key, value|
            key_str = key.to_s
            next unless key_str.match?(regex)

            errors.concat(validate(value, prop_schema, path: "#{path}.#{key_str}", root_schema: root_schema))
          end
        end
      end

      def validate_pattern(data, schema, path, errors)
        return unless data.is_a?(String)

        pattern = schema_key(schema, :pattern)
        return unless pattern

        errors << "#{path}: does not match pattern '#{pattern}'" unless data.match?(Regexp.new(pattern))
      end

      def validate_string_length(data, schema, path, errors)
        return unless data.is_a?(String)

        min = schema_key(schema, :minLength)
        max = schema_key(schema, :maxLength)

        errors << "#{path}: string length #{data.length} is less than minLength #{min}" if min && data.length < min
        errors << "#{path}: string length #{data.length} is greater than maxLength #{max}" if max && data.length > max
      end

      def validate_numeric_range(data, schema, path, errors)
        return unless data.is_a?(Numeric) && !data.is_a?(Complex)

        min = schema_key(schema, :minimum)
        max = schema_key(schema, :maximum)

        errors << "#{path}: value #{data} is less than minimum #{min}" if min && data < min
        errors << "#{path}: value #{data} is greater than maximum #{max}" if max && data > max
      end

      def validate_enum(data, schema, path, errors)
        allowed = schema_key(schema, :enum)
        return unless allowed.is_a?(Array)

        errors << "#{path}: value #{data.inspect} is not one of #{allowed.inspect}" unless allowed.include?(data)
      end

      def validate_items(data, schema, path, errors, root_schema)
        return unless data.is_a?(Array)

        items_schema = schema_key(schema, :items)
        return unless items_schema.is_a?(Hash)

        data.each_with_index do |item, index|
          errors.concat(validate(item, items_schema, path: "#{path}[#{index}]", root_schema: root_schema))
        end
      end

      def validate_array_length(data, schema, path, errors)
        return unless data.is_a?(Array)

        min = schema_key(schema, :minItems)
        max = schema_key(schema, :maxItems)

        errors << "#{path}: array length #{data.length} is less than minItems #{min}" if min && data.length < min
        errors << "#{path}: array length #{data.length} is greater than maxItems #{max}" if max && data.length > max
      end

      def validate_ref(data, schema, path, errors, root_schema)
        ref = schema_key(schema, '$ref')
        return unless ref.is_a?(String)

        resolved = resolve_ref(ref, root_schema)
        if resolved
          errors.concat(validate(data, resolved, path: path, root_schema: root_schema))
        else
          errors << "#{path}: unresolved $ref '#{ref}'"
        end
      end

      def validate_all_of(data, schema, path, errors, root_schema)
        all_of = schema_key(schema, :allOf)
        return unless all_of.is_a?(Array)

        all_of.each_with_index do |sub_schema, index|
          sub_errors = validate(data, sub_schema, path: path, root_schema: root_schema)
          sub_errors.each do |err|
            errors << "#{path}: allOf[#{index}] failed: #{err.sub(/^\$: ?/, '')}"
          end
        end
      end

      def validate_any_of(data, schema, path, errors, root_schema)
        any_of = schema_key(schema, :anyOf)
        return unless any_of.is_a?(Array)

        matched = any_of.any? do |sub_schema|
          validate(data, sub_schema, path: path, root_schema: root_schema).empty?
        end

        errors << "#{path}: does not match any schema in anyOf" unless matched
      end

      def validate_one_of(data, schema, path, errors, root_schema)
        one_of = schema_key(schema, :oneOf)
        return unless one_of.is_a?(Array)

        match_count = one_of.count do |sub_schema|
          validate(data, sub_schema, path: path, root_schema: root_schema).empty?
        end

        if match_count.zero?
          errors << "#{path}: does not match any schema in oneOf"
        elsif match_count > 1
          errors << "#{path}: matches #{match_count} schemas in oneOf, expected exactly 1"
        end
      end

      def validate_not(data, schema, path, errors, root_schema)
        not_schema = schema_key(schema, :not)
        return unless not_schema.is_a?(Hash)

        sub_errors = validate(data, not_schema, path: path, root_schema: root_schema)
        errors << "#{path}: should not match the schema in 'not'" if sub_errors.empty?
      end

      def validate_if_then_else(data, schema, path, errors, root_schema)
        if_schema = schema_key(schema, :if)
        return unless if_schema.is_a?(Hash)

        condition_met = validate(data, if_schema, path: path, root_schema: root_schema).empty?

        if condition_met
          then_schema = schema_key(schema, :then)
          if then_schema.is_a?(Hash)
            errors.concat(validate(data, then_schema, path: path, root_schema: root_schema))
          end
        else
          else_schema = schema_key(schema, :else)
          if else_schema.is_a?(Hash)
            errors.concat(validate(data, else_schema, path: path, root_schema: root_schema))
          end
        end
      end

      def resolve_ref(ref, root_schema)
        return nil unless ref.start_with?('#/')

        parts = ref.sub('#/', '').split('/')
        current = root_schema

        parts.each do |part|
          decoded = part.gsub('~1', '/').gsub('~0', '~')
          current = if current.is_a?(Hash)
                      current[decoded] || current[decoded.to_sym]
                    else
                      return nil
                    end
          return nil unless current
        end

        current
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

    # Compiled schema for repeated validation without re-parsing
    class CompiledSchema
      # @param schema [Hash] the JSON Schema to compile
      def initialize(schema)
        @schema = schema
        @validator = Validator.new
      end

      # Validate data against the compiled schema
      #
      # @param data [Object] the data to validate
      # @return [Array<String>] list of validation errors
      def validate(data)
        @validator.validate(data, @schema)
      end

      # Check if data is valid against the compiled schema
      #
      # @param data [Object] the data to validate
      # @return [Boolean] true if valid
      def valid?(data)
        validate(data).empty?
      end
    end
  end
end
