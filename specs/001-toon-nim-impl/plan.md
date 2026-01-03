# Implementation Plan: TOON Format Nim Implementation

**Branch**: `001-toon-nim-impl` | **Date**: 2025-12-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-toon-nim-impl/spec.md`

## Summary

Implement a complete TOON (Token-Oriented Object Notation) format library for Nim with encode/decode functionality and CLI tool. The library will provide lossless serialization of JSON-compatible data structures in a compact, human-readable format optimized for LLM consumption. Architecture follows library-first design with core encode/decode modules, then CLI wrapper.

## Technical Context

**Language/Version**: Nim 2.0+ (latest stable)
**Primary Dependencies**: Nim standard library only (std/json, std/parseopt, std/strutils, std/tables)
**Storage**: N/A (in-memory processing, file I/O via CLI)
**Testing**: Nim's built-in `unittest` module
**Target Platform**: Cross-platform (Linux, macOS, Windows)
**Project Type**: Single project (library + CLI)
**Performance Goals**: Process 1MB files in under 1 second
**Constraints**: Zero external dependencies, single import for library usage
**Scale/Scope**: Pass all 349 official TOON test fixtures

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Library-First | PASS | Core encode/decode as library modules, CLI as separate thin wrapper |
| II. CLI Interface | PASS | CLI supports stdin/stdout, JSON + human-readable output, errors to stderr |
| III. TDD (NON-NEGOTIABLE) | PASS | Tests written first using official 349 test fixtures, then implementation |
| IV. Integration Testing | PASS | Round-trip tests validate encode/decode contract; CLI integration tests |
| V. Observability | PASS | Error messages include line numbers; structured logging for debug mode |
| VI. Versioning | PASS | SemVer versioning; CHANGELOG maintained; --version flag in CLI |
| VII. Simplicity | PASS | Standard library only; no abstractions beyond necessary data types |

**Gate Result**: PASS - All principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/001-toon-nim-impl/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
├── toon.nim             # Main library entry point (re-exports)
├── toon/
│   ├── types.nim        # ToonValue, options, errors
│   ├── decoder.nim      # TOON string → ToonValue
│   ├── encoder.nim      # ToonValue → TOON string
│   ├── scanner.nim      # Lexical analysis/tokenization
│   ├── parser.nim       # Parse tokens into structure
│   └── utils.nim        # String/escape utilities

bin/
└── tooncli.nim          # CLI application entry point

tests/
├── unit/
│   ├── test_types.nim
│   ├── test_scanner.nim
│   ├── test_parser.nim
│   ├── test_decoder.nim
│   └── test_encoder.nim
├── integration/
│   ├── test_roundtrip.nim
│   └── test_cli.nim
└── fixtures/            # Official TOON test fixtures (349 cases)
    ├── decode/
    └── encode/

toon_nim.nimble          # Package definition
```

**Structure Decision**: Single project structure with library (`src/toon.nim`) and CLI (`bin/tooncli.nim`) separation. Library modules organized under `src/toon/` for clean namespace. Tests mirror source structure with unit/ and integration/ separation per Constitution principles III and IV.

## Complexity Tracking

> No violations - all choices follow simplest approach per Constitution VII.

| Decision | Rationale |
|----------|-----------|
| Standard library only | Nim's std/json provides JSON compatibility; no external parsing libraries needed |
| Single package | Library + CLI in one nimble package; simpler than separate packages |
| Variant type for ToonValue | Nim's object variants are idiomatic; simpler than inheritance hierarchy |

## Post-Design Constitution Re-Check

*Evaluated after Phase 1 design completion.*

| Principle | Status | Post-Design Evidence |
|-----------|--------|----------------------|
| I. Library-First | PASS | Library API contract defines standalone `toon` module; CLI is thin wrapper in `bin/` |
| II. CLI Interface | PASS | CLI contract specifies stdin/stdout, --json/--toon flags, stderr errors, exit codes |
| III. TDD | PASS | Test structure in plan: unit/ and integration/ directories; fixtures for 349 cases |
| IV. Integration Testing | PASS | Round-trip tests (test_roundtrip.nim) and CLI tests (test_cli.nim) planned |
| V. Observability | PASS | ToonError type includes line/col; CLI error messages include location |
| VI. Versioning | PASS | --version flag in CLI; version in nimble file; API versioned |
| VII. Simplicity | PASS | Object variants for ToonValue; no external deps; simple module structure |

**Post-Design Gate Result**: PASS - Design maintains Constitution compliance
