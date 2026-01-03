# TOON Test Fixtures

This directory contains the official TOON format test fixtures downloaded from the [toon-format/spec](https://github.com/toon-format/spec) repository.

## Overview

The fixtures provide comprehensive language-agnostic JSON test cases for validating TOON implementations. These standardized conformance tests cover all specification requirements and include 390 test cases total.

## Directory Structure

```
fixtures/
├── fixtures.schema.json      # JSON Schema for fixture validation
├── encode/                    # Encoding tests (JSON → TOON)
│   ├── arrays-nested.json     # 16 tests - Nested and mixed arrays
│   ├── arrays-objects.json    # 27 tests - Arrays of objects
│   ├── arrays-primitive.json  # 10 tests - Inline primitive arrays
│   ├── arrays-tabular.json    # 5 tests  - Tabular array format
│   ├── delimiters.json        # 22 tests - Delimiter handling
│   ├── key-folding.json       # 15 tests - Key folding (v1.5+)
│   ├── objects.json           # 27 tests - Object encoding
│   ├── primitives.json        # 39 tests - Primitive values
│   └── whitespace.json        # 5 tests  - Whitespace handling
└── decode/                    # Decoding tests (TOON → JSON)
    ├── arrays-nested.json     # 33 tests - Nested array parsing
    ├── arrays-primitive.json  # 13 tests - Primitive array parsing
    ├── arrays-tabular.json    # 10 tests - Tabular array parsing
    ├── blank-lines.json       # 15 tests - Blank line handling
    ├── delimiters.json        # 29 tests - Delimiter parsing
    ├── indentation-errors.json # 15 tests - Indentation validation
    ├── numbers.json           # 22 tests - Number parsing
    ├── objects.json           # 29 tests - Object parsing
    ├── path-expansion.json    # 14 tests - Path expansion (v1.5+)
    ├── primitives.json        # 25 tests - Primitive value parsing
    ├── root-form.json         # 1 test   - Root-level values
    ├── validation-errors.json # 10 tests - Error cases
    └── whitespace.json        # 8 tests  - Whitespace parsing
```

## Test Counts

- **Encode fixtures**: 166 tests
- **Decode fixtures**: 224 tests
- **Total**: 390 tests

## Fixture Format

Each fixture file is a JSON document with the following structure:

```json
{
  "version": "1.4",
  "category": "encode" | "decode",
  "description": "Brief description of fixture purpose",
  "tests": [
    {
      "name": "Descriptive test name",
      "input": <JSON value for encode | TOON string for decode>,
      "expected": <TOON string for encode | JSON value for decode>,
      "shouldError": false,
      "options": {
        "delimiter": ",",
        "indent": 2,
        "keyFolding": "off" | "safe",
        "expandPaths": "off" | "safe",
        "strict": true
      },
      "specSection": "7.2",
      "note": "Optional explanation"
    }
  ]
}
```

### Test Case Properties

- **name**: Descriptive identifier for what is being validated
- **input**: Source value (JSON for encode tests, TOON string for decode tests)
- **expected**: Target output (TOON string for encode tests, JSON for decode tests)
- **shouldError**: Boolean flag indicating if the test expects an error
- **options**: Optional encoder/decoder configuration parameters
- **specSection**: Reference to relevant specification section
- **note**: Optional contextual explanation for special cases

### Encoding Options

- **delimiter**: Character separating array elements (`,`, `\t`, or `|`)
- **indent**: Spaces per indentation level (default: 2)
- **keyFolding**: Key folding mode - `"off"` or `"safe"` (v1.5+)
- **flattenDepth**: Maximum nesting depth for key folding

### Decoding Options

- **indent**: Expected spacing per level (default: 2)
- **strict**: Enable validation enforcement
- **expandPaths**: Path expansion mode - `"off"` or `"safe"` (v1.5+)

## Using the Fixtures

To validate your TOON implementation:

1. Load fixture JSON from the appropriate category directory
2. Iterate through the `tests` array
3. For each test case:
   - If `shouldError` is true, verify your implementation throws an error
   - Otherwise, confirm the output matches the `expected` value
   - Apply any specified `options` before processing

Note: Error tests don't specify expected error messages, as these vary across implementations.

## Validation

All fixtures validate against `fixtures.schema.json` using standard JSON Schema validators.

## Source

Downloaded from: https://github.com/toon-format/spec/tree/main/tests/fixtures

Last updated: 2025-12-09
