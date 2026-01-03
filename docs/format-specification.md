# TOON Format Specification

TOON (Token-Oriented Object Notation) is a compact, human-readable encoding of the JSON data model designed for LLM prompts.

Based on TOON Spec v3.0 (November 2025). See the [official specification](https://github.com/toon-format/spec) for the authoritative reference.

## Overview

TOON supports the same data model as JSON:
- Objects (key-value maps)
- Arrays
- Strings
- Numbers
- Booleans (`true`, `false`)
- Null

## Syntax Rules

### Key-Value Pairs

Basic syntax uses `key: value` with exactly one space after the colon:

```toon
name: Ada Lovelace
age: 42
active: true
score: 3.14
nothing: null
```

### Nested Objects

A key followed by just a colon opens a nested scope. Child lines must be indented:

```toon
user:
  name: Alice
  age: 30
  address:
    city: London
    country: UK
```

Default indentation is 2 spaces per level.

### Arrays

TOON supports three array forms:

#### 1. Inline Primitives

Values on the same line, separated by comma (default):

```toon
tags[3]: admin, ops, dev
numbers[4]: 1, 2, 3, 4
```

#### 2. Expanded List Items

Complex arrays use hyphen markers:

```toon
items[3]:
  - value1
  - value2
  - value3
```

List items can contain objects:

```toon
people[2]:
  - name: Alice
    role: engineer
  - name: Bob
    role: designer
```

#### 3. Tabular Objects

Uniform arrays of objects with primitive values use row syntax:

```toon
users[2]{id,name,active}:
  1,Alice,true
  2,Bob,false
```

### Delimiters

Three delimiters are supported:

| Delimiter | Header Syntax | Example |
|-----------|---------------|---------|
| Comma (default) | `key[3]:` | `a,b,c` |
| Tab | `key[3\t]:` | `a\tb\tc` |
| Pipe | `key[3\|]:` | `a\|b\|c` |

### String Quoting

Strings must be quoted if they:

1. Are empty (`""`)
2. Have leading/trailing whitespace
3. Equal `true`, `false`, or `null`
4. Match numeric patterns
5. Have forbidden leading zeros (`05`, `0001`)
6. Contain: colon, quote, backslash, brackets, braces, or control characters
7. Contain the active delimiter
8. Start with a hyphen

```toon
simple: unquoted
quoted: "has colon: here"
empty: ""
number_string: "05"
```

### Escape Sequences

Quoted strings support exactly 5 escapes:

| Escape | Represents |
|--------|------------|
| `\\` | Backslash |
| `\"` | Double quote |
| `\n` | Newline |
| `\r` | Carriage return |
| `\t` | Tab |

## Key Folding

Single-key nested objects can be collapsed:

```toon
# Instead of:
a:
  b:
    c: 1

# Can be written as:
a.b.c: 1
```

## Strict vs Lenient Mode

### Strict Mode (default)

- Indentation must be exact multiples of indent size
- Array counts must match declared `[N]`
- No tabs in indentation
- No trailing spaces
- No blank lines within arrays

### Lenient Mode

- Flexible indentation
- Approximate numeric handling
- Blank lines in arrays are ignored
- Last-write-wins for conflicts

## Comparison with JSON

TOON:
```toon
name: Ada Lovelace
age: 42
address:
  city: London
  country: UK
colors: red, green, blue
```

Equivalent JSON:
```json
{
  "name": "Ada Lovelace",
  "age": 42,
  "address": {
    "city": "London",
    "country": "UK"
  },
  "colors": ["red", "green", "blue"]
}
```

Token reduction: approximately 15-20% in this example.

## References

- [TOON Specification](https://github.com/toon-format/spec)
- [TOON Reference Implementation](https://github.com/toon-format/toon)
