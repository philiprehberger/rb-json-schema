# philiprehberger-json_schema

[![Tests](https://github.com/philiprehberger/rb-json-schema/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-json-schema/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-json_schema.svg)](https://rubygems.org/gems/philiprehberger-json_schema)
[![License](https://img.shields.io/github/license/philiprehberger/rb-json-schema)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

JSON Schema validator supporting common draft-07 keywords

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-json_schema"
```

Or install directly:

```bash
gem install philiprehberger-json_schema
```

## Usage

```ruby
require "philiprehberger/json_schema"

schema = {
  type: 'object',
  required: %w[name age],
  properties: {
    'name' => { type: 'string', minLength: 1 },
    'age' => { type: 'integer', minimum: 0 }
  }
}

errors = Philiprehberger::JsonSchema.validate({ 'name' => 'Alice', 'age' => 30 }, schema)
# => []

errors = Philiprehberger::JsonSchema.validate({ 'name' => '', 'age' => -1 }, schema)
# => ["$.name: string length 0 is less than minLength 1", "$.age: value -1 is less than minimum 0"]
```

### Quick Boolean Check

```ruby
Philiprehberger::JsonSchema.valid?({ 'name' => 'Alice', 'age' => 30 }, schema)
# => true
```

### Type Validation

Supports `string`, `integer`, `number`, `boolean`, `array`, `object`, and `null`:

```ruby
Philiprehberger::JsonSchema.valid?('hello', { type: 'string' })   # => true
Philiprehberger::JsonSchema.valid?(42, { type: 'integer' })       # => true
Philiprehberger::JsonSchema.valid?(3.14, { type: 'number' })      # => true
```

### Pattern Matching

```ruby
schema = { type: 'string', pattern: '^\d{3}-\d{4}$' }
Philiprehberger::JsonSchema.valid?('123-4567', schema)  # => true
Philiprehberger::JsonSchema.valid?('abc', schema)        # => false
```

### Array Validation

```ruby
schema = { type: 'array', items: { type: 'integer' }, minItems: 1, maxItems: 5 }
Philiprehberger::JsonSchema.validate([1, 2, 3], schema)        # => []
Philiprehberger::JsonSchema.validate([1, 'two', 3], schema)    # => ["$[1]: expected type integer..."]
```

### Enum Validation

```ruby
schema = { type: 'string', enum: %w[red green blue] }
Philiprehberger::JsonSchema.valid?('red', schema)     # => true
Philiprehberger::JsonSchema.valid?('yellow', schema)  # => false
```

## API

### `Philiprehberger::JsonSchema`

| Method | Description |
|--------|-------------|
| `.validate(data, schema)` | Validate data against a schema, returns array of error strings |
| `.valid?(data, schema)` | Returns `true` if data passes validation |

### `Philiprehberger::JsonSchema::Validator`

| Method | Description |
|--------|-------------|
| `#validate(data, schema, path: '$')` | Run all validations and return an array of error strings |
| `#validate_type(data, schema, path, errors)` | Check `type` keyword (`string`, `integer`, `number`, `boolean`, `array`, `object`, `null`) |
| `#validate_required(data, schema, path, errors)` | Check `required` keyword — verify object contains required keys |
| `#validate_properties(data, schema, path, errors)` | Check `properties` keyword — recursively validate each property against its sub-schema |
| `#validate_pattern(data, schema, path, errors)` | Check `pattern` keyword — match string against a regular expression |
| `#validate_string_length(data, schema, path, errors)` | Check `minLength` / `maxLength` keywords for strings |
| `#validate_numeric_range(data, schema, path, errors)` | Check `minimum` / `maximum` keywords for numbers |
| `#validate_enum(data, schema, path, errors)` | Check `enum` keyword — verify value is in the allowed list |
| `#validate_items(data, schema, path, errors)` | Check `items` keyword — recursively validate each array element |
| `#validate_array_length(data, schema, path, errors)` | Check `minItems` / `maxItems` keywords for arrays |
| `#ruby_type_name(value)` | Map a Ruby value to its JSON Schema type name string |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
