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
end
