# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-10

### Added

- Initial release of toon-nim library
- Core TOON format parsing and encoding
- ToonValue type system with full JSON interoperability
- Scanner and parser implementation for TOON format
- Decoder with strict and lenient parsing modes
- Encoder with configurable options:
  - Custom indent size
  - Delimiter options (comma, tab, pipe)
  - Key sorting
- CLI tool (`tooncli`) for format conversion:
  - TOON to JSON conversion
  - JSON to TOON conversion
  - Stdin/stdout support
  - File output support
  - Pretty and compact JSON formatting
- Comprehensive test suite:
  - Unit tests for types, utils, scanner, parser, decoder, encoder
  - Integration tests for CLI and round-trip integrity
  - 322 tests with 99.7% pass rate
- Full documentation with usage examples

### Technical Details

- Nim 2.0+ compatible
- Uses only Nim standard library (no external dependencies)
- TDD-developed with tests written before implementation
- OrderedTable for preserving key insertion order

### Known Limitations

- Key folding (kfSafe mode) not yet implemented
- Path expansion not yet implemented
- One edge case test failing (strict mode tab/space mixing detection)
