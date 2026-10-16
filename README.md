# toon-nim

A Nim library and CLI tool for working with TOON (Token-Oriented Object Notation) format.

TOON is a compact, human-readable data format designed for LLM contexts. It achieves 10-20% token reduction compared to JSON while maintaining human readability.

## Installation

### Using Nimble

```bash
nimble install toon_nim
```

### From Source

```bash
git clone https://github.com/jasagiri/toon-nim.git
cd toon-nim
nimble build
```

## Quick Start

### Library Usage

```nim
import toon

# Decode TOON to ToonValue
let data = decode("""
name: Ada Lovelace
age: 42
skills: math, programming, logic
""")

echo data["name"].getStr()  # Ada Lovelace
echo data["age"].getInt()   # 42
echo data["skills"][0].getStr()  # math

# Encode ToonValue to TOON
let person = newToonObject({
  "name": newToonString("Bob"),
  "active": newToonBool(true),
  "scores": newToonArray([newToonInt(95), newToonInt(87)])
})

echo encode(person)
# Output:
# name: Bob
# active: true
# scores: 95, 87
```

### CLI Usage

```bash
# Convert TOON to JSON
tooncli data.toon --json

# Convert JSON to TOON
tooncli data.json --toon

# Read from stdin
echo "name: Ada" | tooncli --json -

# Write to file
tooncli data.toon --json -o=output.json

# Custom formatting
tooncli data.json --toon --indent=4 --delimiter=tab
```

## TOON Format Overview

TOON is designed to be concise yet readable:

```toon
# Simple key-value pairs
name: Ada Lovelace
age: 42

# Nested objects use indentation
address:
  city: London
  country: UK

# Arrays can be inline or list format
colors: red, green, blue

people:
- name: Alice
  role: engineer
- name: Bob
  role: designer
```

Compared to equivalent JSON:

```json
{
  "name": "Ada Lovelace",
  "age": 42,
  "address": {
    "city": "London",
    "country": "UK"
  },
  "colors": ["red", "green", "blue"],
  "people": [
    {"name": "Alice", "role": "engineer"},
    {"name": "Bob", "role": "designer"}
  ]
}
```

## API Reference

### Types

- `ToonValue`: The main value type (null, bool, int, float, string, array, object)
- `EncodeOptions`: Options for encoding (indent, delimiter, sortKeys)
- `DecodeOptions`: Options for decoding (strict mode, indent size)

### Constructors

```nim
newToonNull(): ToonValue
newToonBool(val: bool): ToonValue
newToonInt(val: int64): ToonValue
newToonFloat(val: float): ToonValue
newToonString(val: string): ToonValue
newToonArray(items: varargs[ToonValue]): ToonValue
newToonObject(pairs: varargs[(string, ToonValue)]): ToonValue
```

### Accessors

```nim
v.getBool(): bool
v.getInt(): int64
v.getFloat(): float
v.getStr(): string
v[key: string]: ToonValue  # object access
v[index: int]: ToonValue   # array access
v.hasKey(key: string): bool
v.keys(): seq[string]
```

### Encoding/Decoding

```nim
# Decode TOON string to ToonValue
proc decode*(input: string, opts: DecodeOptions = defaultDecodeOptions): ToonValue

# Decode TOON file to ToonValue
proc decodeFile*(path: string, opts: DecodeOptions = defaultDecodeOptions): ToonValue

# Encode ToonValue to TOON string
proc encode*(v: ToonValue, opts: EncodeOptions = defaultEncodeOptions): string

# Encode ToonValue to file
proc encodeToFile*(v: ToonValue, path: string, opts: EncodeOptions = defaultEncodeOptions)
```

## CLI Reference

```
tooncli - TOON Format CLI Converter

Usage: tooncli [OPTIONS] [FILE]

Arguments:
  FILE                Input file (use '-' for stdin)

Options:
  -h, --help          Show help message
  -v, --version       Show version number
  -j, --json          Output as JSON
  -t, --toon          Output as TOON
  -o, --output FILE   Write output to file
  --pretty            Pretty-print JSON (default)
  --compact           Compact JSON output
  --indent N          Indentation size (default: 2)
  --delimiter TYPE    Array delimiter: comma, tab, pipe
  --sort-keys         Sort object keys alphabetically
  --strict            Enable strict mode parsing
```

## Testing

```bash
# Run all tests
nimble test

# Run unit tests only
nimble testUnit

# Run integration tests only
nimble testIntegration
```

## License

Apache-2.0
