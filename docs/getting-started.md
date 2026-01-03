# Getting Started with toon-nim

This guide will help you get started with toon-nim, a Nim library and CLI tool for working with TOON (Token-Oriented Object Notation) format.

## What is TOON?

TOON is a compact, human-readable data format designed for LLM contexts. It achieves 10-20% token reduction compared to JSON while maintaining readability.

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

### As a Library

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

### Using the CLI

```bash
# Convert TOON to JSON
tooncli data.toon --json

# Convert JSON to TOON
tooncli data.json --toon

# Read from stdin
echo "name: Ada" | tooncli --json -

# Write to file
tooncli data.toon --json -o=output.json
```

## Basic TOON Syntax

### Key-Value Pairs

```toon
name: Ada Lovelace
age: 42
active: true
```

### Nested Objects

```toon
user:
  name: Alice
  address:
    city: London
    country: UK
```

### Arrays

Inline format:
```toon
colors: red, green, blue
```

List format:
```toon
items:
  - first
  - second
  - third
```

### Tabular Data

```toon
users[2]{id,name,active}:
  1,Alice,true
  2,Bob,false
```

## Next Steps

- [Format Specification](format-specification.md) - Learn the complete TOON format
- [API Reference](api-reference.md) - Detailed API documentation
- [CLI Usage](cli-usage.md) - Complete CLI reference
