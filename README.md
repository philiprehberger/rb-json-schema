# philiprehberger-json_schema

[![Tests](https://github.com/philiprehberger/rb-json-schema/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-json-schema/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-json_schema.svg)](https://rubygems.org/gems/philiprehberger-json_schema)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-json-schema)](https://github.com/philiprehberger/rb-json-schema/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-json-schema)](https://github.com/philiprehberger/rb-json-schema/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-json-schema)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-json-schema/bug)](https://github.com/philiprehberger/rb-json-schema/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-json-schema/enhancement)](https://github.com/philiprehberger/rb-json-schema/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

JSON Schema validator supporting common draft-07 keywords with schema composition, conditional validation, and compiled schemas

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

Philiprehberger::JsonSchema.valid?({ 'name' => 'Alice', 'age' => 30 }, schema)
# => true
```

### Schema Composition (allOf, anyOf, oneOf)

```ruby
schema = {
  anyOf: [
    { type: 'string' },
    { type: 'integer' }
  ]
}
Philiprehberger::JsonSchema.valid?('hello', schema)  # => true
Philiprehberger::JsonSchema.valid?(42, schema)        # => true
Philiprehberger::JsonSchema.valid?(true, schema)      # => false

# allOf — data must match every sub-schema
schema = { allOf: [{ type: 'object', required: %w[name] }, { type: 'object', required: %w[age] }] }

# oneOf — data must match exactly one sub-schema
schema = { oneOf: [{ type: 'string', minLength: 5 }, { type: 'string', maxLength: 3 }] }
```

### Negation (not)

```ruby
schema = { not: { type: 'string' } }
Philiprehberger::JsonSchema.valid?(42, schema)      # => true
Philiprehberger::JsonSchema.valid?('hello', schema)  # => false
```

### Conditional Validation (if/then/else)

```ruby
schema = {
  type: 'object',
  if: { properties: { 'type' => { const: 'business' } }, required: %w[type] },
  then: { required: %w[company] },
  else: { required: %w[first_name] }
}

Philiprehberger::JsonSchema.valid?({ 'type' => 'business', 'company' => 'Acme' }, schema)
# => true

Philiprehberger::JsonSchema.valid?({ 'type' => 'personal', 'first_name' => 'Alice' }, schema)
# => true
```

### Schema References ($ref and $defs)

```ruby
schema = {
  type: 'object',
  properties: {
    'billing' => { '$ref' => '#/$defs/address' },
    'shipping' => { '$ref' => '#/$defs/address' }
  },
  '$defs' => {
    'address' => {
      type: 'object',
      required: %w[city],
      properties: { 'city' => { type: 'string' } }
    }
  }
}

Philiprehberger::JsonSchema.valid?({ 'billing' => { 'city' => 'NYC' }, 'shipping' => { 'city' => 'LA' } }, schema)
# => true
```

### Additional and Pattern Properties

```ruby
# Reject unknown properties
schema = {
  type: 'object',
  properties: { 'name' => { type: 'string' } },
  additionalProperties: false
}
Philiprehberger::JsonSchema.validate({ 'name' => 'Alice', 'extra' => 'nope' }, schema)
# => ["$.extra: additional property 'extra' is not allowed"]

# Validate properties matching a pattern
schema = {
  type: 'object',
  patternProperties: { '^x-' => { type: 'string' } }
}
Philiprehberger::JsonSchema.valid?({ 'x-custom' => 'ok' }, schema)  # => true
Philiprehberger::JsonSchema.valid?({ 'x-custom' => 42 }, schema)    # => false
```

### Const Validation

```ruby
schema = { const: 'fixed_value' }
Philiprehberger::JsonSchema.valid?('fixed_value', schema)  # => true
Philiprehberger::JsonSchema.valid?('other', schema)        # => false
```

### Compiled Schemas

```ruby
compiled = Philiprehberger::JsonSchema.compile({
  type: 'object',
  required: %w[id],
  properties: { 'id' => { type: 'integer' } }
})

compiled.valid?({ 'id' => 1 })    # => true
compiled.validate({ 'id' => 'x' }) # => ["$.id: expected type integer..."]
```

## API

### `Philiprehberger::JsonSchema`

| Method | Description |
|--------|-------------|
| `.validate(data, schema)` | Validate data against a schema, returns array of error strings |
| `.valid?(data, schema)` | Returns `true` if data passes validation |
| `.compile(schema)` | Returns a `CompiledSchema` for repeated validation |

### `Philiprehberger::JsonSchema::CompiledSchema`

| Method | Description |
|--------|-------------|
| `#validate(data)` | Validate data against the compiled schema |
| `#valid?(data)` | Returns `true` if data passes validation |

### Supported Keywords

| Keyword | Description |
|---------|-------------|
| `type` | Type validation (`string`, `integer`, `number`, `boolean`, `array`, `object`, `null`) |
| `required` | Required object properties |
| `properties` | Per-property sub-schemas |
| `additionalProperties` | Boolean or schema for properties not in `properties` |
| `patternProperties` | Regex-keyed sub-schemas for matching property names |
| `pattern` | Regex match for strings |
| `minLength` / `maxLength` | String length constraints |
| `minimum` / `maximum` | Numeric range constraints |
| `enum` | Allowed value list |
| `const` | Exact value match |
| `items` | Schema for array elements |
| `minItems` / `maxItems` | Array length constraints |
| `allOf` | Data must match all sub-schemas |
| `anyOf` | Data must match at least one sub-schema |
| `oneOf` | Data must match exactly one sub-schema |
| `not` | Data must not match the sub-schema |
| `if` / `then` / `else` | Conditional validation |
| `$ref` | Reference to a sub-schema (supports `#/` JSON Pointer) |
| `$defs` | Schema definitions for `$ref` resolution |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
