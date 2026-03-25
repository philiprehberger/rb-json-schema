# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.4] - 2026-03-24

### Changed
- Expand README API table to document all public methods

## [0.1.3] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.2] - 2026-03-22

### Added
- Expand test coverage to 30+ examples with edge cases for nested objects, combined constraints, empty data, error message paths, schema without type

## [0.1.1] - 2026-03-22

### Changed
- Version bump for republishing

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Type validation for string, integer, number, boolean, array, object, and null
- Required properties validation
- Properties with recursive schema validation
- Pattern matching for strings
- String length constraints (minLength, maxLength)
- Numeric range constraints (minimum, maximum)
- Enum value validation
- Array item validation with per-item schemas
- Array length constraints (minItems, maxItems)
