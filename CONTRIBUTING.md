# Contributing to toon-nim

Thank you for your interest in contributing to toon-nim! This document provides guidelines for contributing.

## Getting Started

### Prerequisites

- Nim 2.0 or later
- Nimble (Nim's package manager)

### Setting Up Development Environment

```bash
git clone https://github.com/jasagiri/toon-nim.git
cd toon-nim
nimble develop
```

### Running Tests

```bash
# Run all tests
nimble test

# Run unit tests only
nimble testUnit

# Run integration tests only
nimble testIntegration
```

### Building

```bash
# Build the CLI tool
nimble buildCli

# Generate documentation
nimble docs
```

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include:
   - Nim version (`nim --version`)
   - Operating system
   - Steps to reproduce
   - Expected vs actual behavior
   - Sample TOON/JSON input if applicable

### Suggesting Features

1. Check existing issues and discussions
2. Describe the use case
3. Provide examples of the proposed syntax or API

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`nimble test`)
6. Commit with clear messages
7. Push and create a pull request

## Code Style

### Nim Conventions

- Follow the [Nim Style Guide](https://nim-lang.org/docs/nep1.html)
- Use 2-space indentation
- Use camelCase for procedures and variables
- Use PascalCase for types
- Keep procedures focused and small

### Documentation

- Add docstrings to public procedures
- Update docs/ for user-facing changes
- Include examples in docstrings

### Testing

- Write unit tests for new functionality
- Add integration tests for CLI changes
- Use descriptive test names
- Cover edge cases

## Project Structure

```
toon-nim/
├── src/
│   ├── toon.nim          # Main module (public API)
│   └── toon/
│       ├── types.nim     # Type definitions
│       ├── scanner.nim   # Tokenizer
│       ├── parser.nim    # TOON parser
│       ├── decoder.nim   # Decode TOON to ToonValue
│       ├── encoder.nim   # Encode ToonValue to TOON
│       └── utils.nim     # Utility functions
├── bin/
│   └── tooncli.nim       # CLI tool source
├── tests/
│   ├── unit/             # Unit tests
│   └── integration/      # Integration tests
├── docs/                 # Documentation
└── toon_nim.nimble       # Package configuration
```

## Testing Guidelines

### Unit Tests

Located in `tests/unit/`. Each module should have corresponding tests:

```nim
# tests/unit/test_types.nim
import unittest
import toon/types

suite "ToonValue types":
  test "newToonString creates string value":
    let v = newToonString("hello")
    check v.kind == tvkString
    check v.getStr() == "hello"
```

### Integration Tests

Located in `tests/integration/`. Test complete workflows:

```nim
# tests/integration/test_roundtrip.nim
import unittest
import toon

suite "Roundtrip conversion":
  test "TOON -> ToonValue -> TOON":
    let input = "name: Alice\nage: 30"
    let decoded = decode(input)
    let encoded = encode(decoded)
    check decode(encoded) == decoded
```

## Release Process

1. Update version in `toon_nim.nimble`
2. Update CHANGELOG.md
3. Create a git tag
4. Push to GitHub
5. Create GitHub release

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn

## Questions?

Open a discussion or issue on GitHub.
