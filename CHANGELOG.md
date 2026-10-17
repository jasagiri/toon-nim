# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-17

Follows TOON specification 4.4 (it followed 3.0). All 564 official
conformance fixtures pass; 0.1.0 had never run the encode fixtures and failed
23 of the 3.x decode fixtures.

### Changed

- Encoder and decoder rewritten to specification 4.4: nested field groups in
  tabular headers, keyed tabular objects (`users[2:]{age,city}:`), comment
  lines, shortest round-trip numbers, lowercase `\uXXXX`, `key: []` for empty
  arrays, the document delimiter declared in every header, and strict decoding
  of every condition in §14 with only the five recoveries of §14.4 when
  `strict = false`.
- `EncodeOptions.indent` is renamed `indentSize`, as in `DecodeOptions` and
  the specification.
- `==` on `ToonValue` is the JSON-model equality of §2: an int equals the
  float of the same value, and objects compare by ordered keys.
- `fromJsonNode` reads an integer beyond int64 as its float64 approximation
  instead of a string.
- `tooncli` decodes strictly by default (`--lenient` for non-strict).
- `decode` checks that its input is well-formed UTF-8.

### Added

- `encode(JsonNode)`.
- `nimble conformance`, running the official fixtures of specification 4.4.

### Removed

- Key folding, path expansion and `sortKeys`, which specification 4.0 removed
  or which break its key-order rule; `tooncli --sort-keys`, `--fold-keys` and
  `--expand-paths`.
- The modules `toon/scanner`, `toon/parser` and `toon/utils`, with
  `parseToon` and the string helpers they exported.

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
