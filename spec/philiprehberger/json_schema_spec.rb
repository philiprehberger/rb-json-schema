# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::JsonSchema do
  it 'has a version number' do
    expect(Philiprehberger::JsonSchema::VERSION).not_to be_nil
  end

  describe '.validate' do
    it 'returns an empty array for valid data' do
      schema = { type: 'string' }
      expect(described_class.validate('hello', schema)).to eq([])
    end

    it 'returns errors for invalid type' do
      schema = { type: 'string' }
      errors = described_class.validate(42, schema)
      expect(errors).to include(match(/expected type string/))
    end

    it 'validates integer type' do
      schema = { type: 'integer' }
      expect(described_class.validate(42, schema)).to be_empty
      expect(described_class.validate('42', schema)).not_to be_empty
    end

    it 'validates number type' do
      schema = { type: 'number' }
      expect(described_class.validate(3.14, schema)).to be_empty
      expect(described_class.validate(42, schema)).to be_empty
      expect(described_class.validate('42', schema)).not_to be_empty
    end

    it 'validates boolean type' do
      schema = { type: 'boolean' }
      expect(described_class.validate(true, schema)).to be_empty
      expect(described_class.validate(false, schema)).to be_empty
      expect(described_class.validate('true', schema)).not_to be_empty
    end

    it 'validates null type' do
      schema = { type: 'null' }
      expect(described_class.validate(nil, schema)).to be_empty
      expect(described_class.validate('', schema)).not_to be_empty
    end

    it 'validates array type' do
      schema = { type: 'array' }
      expect(described_class.validate([1, 2], schema)).to be_empty
      expect(described_class.validate('not array', schema)).not_to be_empty
    end

    it 'validates object type' do
      schema = { type: 'object' }
      expect(described_class.validate({ 'a' => 1 }, schema)).to be_empty
      expect(described_class.validate('not object', schema)).not_to be_empty
    end
  end

  describe 'required' do
    it 'reports missing required properties' do
      schema = {
        type: 'object',
        required: %w[name email],
        properties: {
          'name' => { type: 'string' },
          'email' => { type: 'string' }
        }
      }
      errors = described_class.validate({ 'name' => 'Alice' }, schema)
      expect(errors).to include(match(/missing required property 'email'/))
    end

    it 'passes when all required properties are present' do
      schema = {
        type: 'object',
        required: %w[name],
        properties: { 'name' => { type: 'string' } }
      }
      expect(described_class.validate({ 'name' => 'Alice' }, schema)).to be_empty
    end
  end

  describe 'properties' do
    it 'validates nested property types' do
      schema = {
        type: 'object',
        properties: {
          'age' => { type: 'integer' }
        }
      }
      errors = described_class.validate({ 'age' => 'not a number' }, schema)
      expect(errors).to include(match(/\$\.age.*expected type integer/))
    end
  end

  describe 'pattern' do
    it 'validates string patterns' do
      schema = { type: 'string', pattern: '^\d{3}-\d{4}$' }
      expect(described_class.validate('123-4567', schema)).to be_empty
      expect(described_class.validate('abc', schema)).not_to be_empty
    end
  end

  describe 'string length' do
    it 'validates minLength' do
      schema = { type: 'string', minLength: 3 }
      expect(described_class.validate('abc', schema)).to be_empty
      expect(described_class.validate('ab', schema)).not_to be_empty
    end

    it 'validates maxLength' do
      schema = { type: 'string', maxLength: 5 }
      expect(described_class.validate('hello', schema)).to be_empty
      expect(described_class.validate('hello!', schema)).not_to be_empty
    end
  end

  describe 'numeric range' do
    it 'validates minimum' do
      schema = { type: 'integer', minimum: 0 }
      expect(described_class.validate(0, schema)).to be_empty
      expect(described_class.validate(-1, schema)).not_to be_empty
    end

    it 'validates maximum' do
      schema = { type: 'integer', maximum: 100 }
      expect(described_class.validate(100, schema)).to be_empty
      expect(described_class.validate(101, schema)).not_to be_empty
    end
  end

  describe 'enum' do
    it 'validates enum values' do
      schema = { type: 'string', enum: %w[red green blue] }
      expect(described_class.validate('red', schema)).to be_empty
      expect(described_class.validate('yellow', schema)).not_to be_empty
    end
  end

  describe 'items' do
    it 'validates array items' do
      schema = { type: 'array', items: { type: 'integer' } }
      expect(described_class.validate([1, 2, 3], schema)).to be_empty
      errors = described_class.validate([1, 'two', 3], schema)
      expect(errors).to include(match(/\$\[1\].*expected type integer/))
    end
  end

  describe 'array length' do
    it 'validates minItems' do
      schema = { type: 'array', minItems: 2 }
      expect(described_class.validate([1, 2], schema)).to be_empty
      expect(described_class.validate([1], schema)).not_to be_empty
    end

    it 'validates maxItems' do
      schema = { type: 'array', maxItems: 3 }
      expect(described_class.validate([1, 2, 3], schema)).to be_empty
      expect(described_class.validate([1, 2, 3, 4], schema)).not_to be_empty
    end
  end

  describe '.valid?' do
    it 'returns true for valid data' do
      expect(described_class.valid?('hello', { type: 'string' })).to be true
    end

    it 'returns false for invalid data' do
      expect(described_class.valid?(42, { type: 'string' })).to be false
    end
  end

  describe 'nested objects' do
    it 'validates deeply nested schemas' do
      schema = {
        type: 'object',
        properties: {
          'address' => {
            type: 'object',
            required: %w[city],
            properties: {
              'city' => { type: 'string' },
              'zip' => { type: 'string' }
            }
          }
        }
      }
      errors = described_class.validate({ 'address' => { 'city' => 'NYC' } }, schema)
      expect(errors).to be_empty
    end

    it 'reports nested missing required property' do
      schema = {
        type: 'object',
        properties: {
          'address' => {
            type: 'object',
            required: %w[city],
            properties: {
              'city' => { type: 'string' }
            }
          }
        }
      }
      errors = described_class.validate({ 'address' => {} }, schema)
      expect(errors).to include(match(/\$\.address.*missing required property 'city'/))
    end
  end

  describe 'combined constraints' do
    it 'validates string with both minLength and maxLength' do
      schema = { type: 'string', minLength: 2, maxLength: 5 }
      expect(described_class.validate('abc', schema)).to be_empty
      expect(described_class.validate('a', schema)).not_to be_empty
      expect(described_class.validate('abcdef', schema)).not_to be_empty
    end

    it 'validates integer with both minimum and maximum' do
      schema = { type: 'integer', minimum: 1, maximum: 10 }
      expect(described_class.validate(5, schema)).to be_empty
      expect(described_class.validate(0, schema)).not_to be_empty
      expect(described_class.validate(11, schema)).not_to be_empty
    end
  end

  describe 'empty data' do
    it 'validates empty string against string type' do
      schema = { type: 'string' }
      expect(described_class.validate('', schema)).to be_empty
    end

    it 'validates empty array against array type' do
      schema = { type: 'array' }
      expect(described_class.validate([], schema)).to be_empty
    end

    it 'validates empty object against object type' do
      schema = { type: 'object' }
      expect(described_class.validate({}, schema)).to be_empty
    end

    it 'validates empty array fails minItems' do
      schema = { type: 'array', minItems: 1 }
      expect(described_class.validate([], schema)).not_to be_empty
    end
  end

  describe 'error messages' do
    it 'includes path in type error messages' do
      schema = { type: 'string' }
      errors = described_class.validate(42, schema)
      expect(errors.first).to start_with('$:')
    end

    it 'includes array index in item error messages' do
      schema = { type: 'array', items: { type: 'string' } }
      errors = described_class.validate(['ok', 123, 'fine'], schema)
      expect(errors.size).to eq(1)
      expect(errors.first).to include('$[1]')
    end

    it 'returns multiple errors for multiple violations' do
      schema = {
        type: 'object',
        required: %w[a b c],
        properties: {
          'a' => { type: 'string' },
          'b' => { type: 'string' },
          'c' => { type: 'string' }
        }
      }
      errors = described_class.validate({}, schema)
      expect(errors.size).to eq(3)
    end
  end

  describe 'schema with no type' do
    it 'does not validate type when type is not specified' do
      schema = { minimum: 5 }
      expect(described_class.validate(10, schema)).to be_empty
    end
  end

  describe 'const' do
    it 'passes when value equals const' do
      schema = { const: 'fixed' }
      expect(described_class.validate('fixed', schema)).to be_empty
    end

    it 'fails when value does not equal const' do
      schema = { const: 'fixed' }
      errors = described_class.validate('other', schema)
      expect(errors).to include(match(/does not equal const/))
    end

    it 'works with numeric const' do
      schema = { const: 42 }
      expect(described_class.validate(42, schema)).to be_empty
      expect(described_class.validate(43, schema)).not_to be_empty
    end

    it 'works with null const' do
      schema = { const: nil }
      expect(described_class.validate(nil, schema)).to be_empty
      expect(described_class.validate('', schema)).not_to be_empty
    end
  end

  describe '$ref and $defs' do
    it 'resolves $ref to $defs' do
      schema = {
        type: 'object',
        properties: {
          'name' => { '$ref' => '#/$defs/name_type' }
        },
        '$defs' => {
          'name_type' => { type: 'string', minLength: 1 }
        }
      }
      expect(described_class.validate({ 'name' => 'Alice' }, schema)).to be_empty
      expect(described_class.validate({ 'name' => '' }, schema)).not_to be_empty
    end

    it 'reports error for unresolved $ref' do
      schema = {
        type: 'object',
        properties: {
          'name' => { '$ref' => '#/$defs/nonexistent' }
        }
      }
      errors = described_class.validate({ 'name' => 'Alice' }, schema)
      expect(errors).to include(match(/unresolved \$ref/))
    end

    it 'resolves nested $ref paths' do
      schema = {
        type: 'object',
        properties: {
          'addr' => { '$ref' => '#/definitions/address' }
        },
        'definitions' => {
          'address' => {
            type: 'object',
            required: %w[city],
            properties: { 'city' => { type: 'string' } }
          }
        }
      }
      expect(described_class.validate({ 'addr' => { 'city' => 'NYC' } }, schema)).to be_empty
      expect(described_class.validate({ 'addr' => {} }, schema)).not_to be_empty
    end
  end

  describe 'allOf' do
    it 'passes when data matches all sub-schemas' do
      schema = {
        allOf: [
          { type: 'object', required: %w[name] },
          { type: 'object', required: %w[age] }
        ]
      }
      expect(described_class.validate({ 'name' => 'Alice', 'age' => 30 }, schema)).to be_empty
    end

    it 'fails when data does not match one of the sub-schemas' do
      schema = {
        allOf: [
          { type: 'object', required: %w[name] },
          { type: 'object', required: %w[age] }
        ]
      }
      errors = described_class.validate({ 'name' => 'Alice' }, schema)
      expect(errors).to include(match(/allOf\[1\] failed/))
    end
  end

  describe 'anyOf' do
    it 'passes when data matches at least one sub-schema' do
      schema = {
        anyOf: [
          { type: 'string' },
          { type: 'integer' }
        ]
      }
      expect(described_class.validate('hello', schema)).to be_empty
      expect(described_class.validate(42, schema)).to be_empty
    end

    it 'fails when data matches none of the sub-schemas' do
      schema = {
        anyOf: [
          { type: 'string' },
          { type: 'integer' }
        ]
      }
      errors = described_class.validate(true, schema)
      expect(errors).to include(match(/does not match any schema in anyOf/))
    end
  end

  describe 'oneOf' do
    it 'passes when data matches exactly one sub-schema' do
      schema = {
        oneOf: [
          { type: 'string', minLength: 5 },
          { type: 'string', maxLength: 3 }
        ]
      }
      expect(described_class.validate('hi', schema)).to be_empty
      expect(described_class.validate('hello world', schema)).to be_empty
    end

    it 'fails when data matches zero sub-schemas' do
      schema = {
        oneOf: [
          { type: 'string', minLength: 10 },
          { type: 'integer' }
        ]
      }
      errors = described_class.validate('short', schema)
      expect(errors).to include(match(/does not match any schema in oneOf/))
    end

    it 'fails when data matches more than one sub-schema' do
      schema = {
        oneOf: [
          { type: 'integer' },
          { type: 'number' }
        ]
      }
      errors = described_class.validate(42, schema)
      expect(errors).to include(match(/matches 2 schemas in oneOf/))
    end
  end

  describe 'not' do
    it 'passes when data does not match the not schema' do
      schema = { not: { type: 'string' } }
      expect(described_class.validate(42, schema)).to be_empty
    end

    it 'fails when data matches the not schema' do
      schema = { not: { type: 'string' } }
      errors = described_class.validate('hello', schema)
      expect(errors).to include(match(/should not match the schema in 'not'/))
    end
  end

  describe 'if/then/else' do
    let(:schema) do
      {
        type: 'object',
        if: { properties: { 'type' => { const: 'business' } }, required: %w[type] },
        then: { required: %w[company] },
        else: { required: %w[first_name] }
      }
    end

    it 'validates against then when if condition matches' do
      data = { 'type' => 'business', 'company' => 'Acme' }
      expect(described_class.validate(data, schema)).to be_empty
    end

    it 'fails when if matches but then fails' do
      data = { 'type' => 'business' }
      errors = described_class.validate(data, schema)
      expect(errors).to include(match(/missing required property 'company'/))
    end

    it 'validates against else when if condition does not match' do
      data = { 'type' => 'personal', 'first_name' => 'Alice' }
      expect(described_class.validate(data, schema)).to be_empty
    end

    it 'fails when if does not match and else fails' do
      data = { 'type' => 'personal' }
      errors = described_class.validate(data, schema)
      expect(errors).to include(match(/missing required property 'first_name'/))
    end
  end

  describe 'additionalProperties' do
    it 'rejects additional properties when set to false' do
      schema = {
        type: 'object',
        properties: { 'name' => { type: 'string' } },
        additionalProperties: false
      }
      errors = described_class.validate({ 'name' => 'Alice', 'extra' => 'nope' }, schema)
      expect(errors).to include(match(/additional property 'extra' is not allowed/))
    end

    it 'allows defined properties when additionalProperties is false' do
      schema = {
        type: 'object',
        properties: { 'name' => { type: 'string' } },
        additionalProperties: false
      }
      expect(described_class.validate({ 'name' => 'Alice' }, schema)).to be_empty
    end

    it 'validates additional properties against a schema' do
      schema = {
        type: 'object',
        properties: { 'name' => { type: 'string' } },
        additionalProperties: { type: 'integer' }
      }
      expect(described_class.validate({ 'name' => 'Alice', 'age' => 30 }, schema)).to be_empty
      errors = described_class.validate({ 'name' => 'Alice', 'age' => 'thirty' }, schema)
      expect(errors).to include(match(/expected type integer/))
    end
  end

  describe 'patternProperties' do
    it 'validates properties matching patterns' do
      schema = {
        type: 'object',
        patternProperties: {
          '^x-' => { type: 'string' }
        }
      }
      expect(described_class.validate({ 'x-custom' => 'hello' }, schema)).to be_empty
      errors = described_class.validate({ 'x-custom' => 42 }, schema)
      expect(errors).to include(match(/expected type string/))
    end

    it 'does not affect properties that do not match patterns' do
      schema = {
        type: 'object',
        patternProperties: {
          '^x-' => { type: 'string' }
        }
      }
      expect(described_class.validate({ 'name' => 42 }, schema)).to be_empty
    end

    it 'works with additionalProperties' do
      schema = {
        type: 'object',
        properties: { 'id' => { type: 'integer' } },
        patternProperties: { '^x-' => { type: 'string' } },
        additionalProperties: false
      }
      expect(described_class.validate({ 'id' => 1, 'x-tag' => 'ok' }, schema)).to be_empty
      errors = described_class.validate({ 'id' => 1, 'x-tag' => 'ok', 'unknown' => true }, schema)
      expect(errors).to include(match(/additional property 'unknown' is not allowed/))
    end
  end

  describe '.compile' do
    it 'returns a CompiledSchema instance' do
      compiled = described_class.compile({ type: 'string' })
      expect(compiled).to be_a(Philiprehberger::JsonSchema::CompiledSchema)
    end

    it 'validates data with compiled schema' do
      compiled = described_class.compile({
                                           type: 'object',
                                           required: %w[name],
                                           properties: { 'name' => { type: 'string' } }
                                         })
      expect(compiled.validate({ 'name' => 'Alice' })).to be_empty
      expect(compiled.validate({})).not_to be_empty
    end

    it 'supports valid? on compiled schema' do
      compiled = described_class.compile({ type: 'integer', minimum: 0 })
      expect(compiled.valid?(42)).to be true
      expect(compiled.valid?(-1)).to be false
    end
  end
end
