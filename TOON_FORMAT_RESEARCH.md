# TOON Format Specification - Comprehensive Parser Implementation Guide

Source: https://raw.githubusercontent.com/toon-format/spec/main/SPEC.md
Version: 3.0 (November 24, 2025)

## Overview
TOON is a compact, human-readable encoding of the JSON data model designed for LLM prompts. It supports objects, arrays, and primitives while minimizing token usage.

---

## 1. EXACT SYNTAX RULES

### 1.1 Array Headers with Length [N] and Field Declarations {field1,field2}

**Header Structure:**
- **Root array**: `[N]:` or `[N]{fields}:`
- **Named array**: `key[N]:` or `key[N]{fields}:`
- **With delimiter**: `[N⟨TAB⟩]:` (tab) or `[N|]:` (pipe); comma is default

**Critical Rules:**
- Every header line MUST end with a colon (§6)
- The active delimiter declared in brackets applies to splitting inline values and tabular rows
- Field names in braces are separated by the same active delimiter (§6)
- Field names follow key encoding rules - unquoted only if matching `^[A-Za-z_][A-Za-z0-9_.]*$`

**Examples:**
```toon
tags[3]: admin,ops,dev
users[2]{id,name,active}:
  1,Alice,true
  2,Bob,false
items[3⟨TAB⟩]{name⟨TAB⟩value}:
  foo⟨TAB⟩42
  bar⟨TAB⟩99
  baz⟨TAB⟩-1
```

### 1.2 Three Array Forms

#### Form 1: Inline Primitives
Values appear on the same line as the header, separated by the active delimiter.

**Rules:**
- "When inline values follow a header on the same line (non-empty primitive arrays), there MUST be exactly one space after the colon" (§6)

**Example:**
```toon
tags[3]: admin,ops,dev
```

#### Form 2: Expanded List Items
Complex or non-uniform arrays use list-item syntax with hyphen markers.

**Rules:**
- "Items appear at depth +1, each starting with '- '" (§9.2)
- List items can contain primitives, inline arrays, or objects
- Each item starts with a hyphen followed by a space

**Example:**
```toon
items[3]:
  - value1
  - value2
  - nested object:
      key: value
```

#### Form 3: Tabular Objects
Uniform arrays of objects with primitive-only values use row syntax.

**Detection Requirements:**
- "Every element is an object"
- "All objects have the same set of keys"
- "All values across these keys are primitives" (§9.3)

**Example:**
```toon
users[2]{id,name,active}:
  1,Alice,true
  2,Bob,false
```

### 1.3 Key-Value Pair Syntax with Colons

**Basic Syntax:** `key: value`
- Exactly one space after the colon for values on the same line
- Keys without values open nested scopes

**Nested Objects:**
```toon
user:
  name: Alice
  age: 30
```

**Rule:** "A line 'key:' with nothing after the colon at depth d opens an object; subsequent lines at depth > d belong to that object" (§8)

### 1.4 Indentation Rules

**Default Configuration:**
- Default unit: 2 spaces per level
- Depth = leading spaces ÷ indent unit

**Strict Mode Requirements (strict=true):**
- "The number of leading spaces on a line MUST be an exact multiple of indentSize" (§12)
- "Tabs MUST NOT be used for indentation" (§12)
- "No trailing spaces at the end of any line" (§12)

**Lenient Mode (strict=false):**
- Flexible indentation: depth computed via `floor(spaces/indentSize)`
- Tab characters in indentation with implementation-defined handling

### 1.5 Quoting Rules for Strings

A string value MUST be quoted if it:
1. Is empty (`""`)
2. Has leading/trailing whitespace
3. Equals `true`, `false`, or `null`
4. Matches numeric patterns: `42`, `-3.14`, `1e-6`
5. Has forbidden leading zeros: `05`, `0001`
6. Contains: colon, quote, backslash, brackets, braces, or control characters
7. Contains the relevant delimiter (document or active)
8. Equals or starts with hyphen (`-`)

**Examples:**
```toon
name: "has colon: here"
simple: unquoted
empty: ""
number: "05"
hyphen: "-"
```

### 1.6 The Three Delimiters

| Delimiter | Header Syntax | Row/Array Example |
|-----------|---------------|-------------------|
| Comma (default) | `key[3]:` | `v1,v2,v3` |
| Tab | `key[3⟨TAB⟩]:` | `v1⟨TAB⟩v2⟨TAB⟩v3` |
| Pipe | `key[3\|]:` | `v1\|v2\|v3` |

**Critical Rule:** "Absence of a delimiter symbol in a bracket segment ALWAYS means comma, regardless of any parent header" (§6)

**Quoting Implication:** Strings containing the active delimiter must be quoted.

---

## 2. ESCAPE SEQUENCES - The 5 Valid Escapes

Quoted strings support ONLY these escape sequences:

| Escape | Represents | Unicode |
|--------|------------|---------|
| `\\` | Backslash | \ |
| `\"` | Double quote | " |
| `\n` | Newline | U+000A |
| `\r` | Carriage return | U+000D |
| `\t` | Tab | U+0009 |

**Critical Rule:** "Decoders MUST reject any other escape sequence and unterminated strings" (§7.1)

**Example:**
```toon
message: "Line 1\nLine 2\tTabbed"
path: "C:\\Users\\file.txt"
quote: "He said \"Hello\""
```

---

## 3. KEY FOLDING AND PATH EXPANSION FEATURES

### 3.1 Key Folding (Encoding)

**Option:** `keyFolding="safe"`

**Function:** Collapses nested single-key objects into dotted paths.

**Input:**
```json
{
  "a": {
    "b": {
      "c": 1
    }
  }
}
```

**Output:**
```toon
a.b.c: 1
```

**Requirements:**
- All segments must be IdentifierSegments matching `^[A-Za-z_][A-Za-z0-9_]*$`
- Contain no separators
- Avoid collisions
- Require no quoting

### 3.2 Path Expansion (Decoding)

**Option:** `expandPaths="safe"`

**Function:** Splits dotted keys into nested structures.

**Input:**
```toon
data.meta.items[2]: a,b
```

**Output:**
```json
{
  "data": {
    "meta": {
      "items": ["a", "b"]
    }
  }
}
```

**Rule:** "Only expand when ALL resulting segments are IdentifierSegments and none contain '.' after splitting" (§13.4)

### 3.3 Conflict Resolution

**Strict Mode (strict=true, default):**
- "Decoders MUST error on any expansion conflict" (§14.5)

**Lenient Mode (strict=false):**
- "Last-write-wins (LWW) conflict resolution: keys appearing later in document order overwrite earlier values" (§13.4)

---

## 4. STRICT VS LENIENT MODE DIFFERENCES

### 4.1 Strict Mode (Default: strict=true)

**Enforces:**
- Array count matches declared `[N]`
- Indentation is exact multiple of indent size
- Row width matches field count
- No blank lines within array/tabular rows
- No forbidden escape sequences
- Required colons after keys
- Expansion conflicts cause errors
- "In strict mode, if a blank line occurs between the first and last row/item line in an array/tabular block, this MUST error" (§12)

### 4.2 Lenient Mode (strict=false)

**Permits:**
- Flexible indentation: depth computed via `floor(spaces/indentSize)`
- Tab characters in indentation with implementation-defined handling
- Blank lines within arrays ignored (not counted as items)
- Approximate numeric handling
- Last-write-wins for expansion conflicts

---

## 5. ADDITIONAL PARSER IMPLEMENTATION DETAILS

### 5.1 Object-as-List-Item Encoding

When a list-item object has a tabular array as its first field:
- "Encoders MUST emit the tabular header on the hyphen line" at depth+1
- Rows at depth+2
- Other fields at depth+1

**Example:**
```toon
items[1]:
  - users[2]{id,name}:
      1,Ada
      2,Bob
    status: active
```

### 5.2 Root Form Detection

**Rule:** "If the first non-empty depth-0 line is a valid root array header per §6 (must include a colon), decode a root array" (§5)

Otherwise, parse as object or primitive.

### 5.3 Canonical Number Encoding

**Encoders must emit numbers:**
- "No exponent notation (1e6 → 1000000)"
- "No leading zeros except '0'"
- "No trailing fractional zeros"
- "-0 → 0" (§2)

**Decoders:**
- Accept input forms but treat "tokens with forbidden leading zeros (e.g., '05', '0001') as strings, not numbers" (§2)

---

## 6. PARSING ALGORITHM SUMMARY

### 6.1 Line Processing
1. Check for blank lines (ignore in lenient mode)
2. Calculate indentation depth
3. Detect line type:
   - Array header: `[N]` with optional delimiter and fields
   - Key-value pair: `key: value`
   - List item: `- item`
   - Tabular row: values separated by active delimiter
   - Object key: `key:`

### 6.2 Value Parsing
1. Check if quoted (starts with `"`)
2. If quoted: parse string with escape sequences
3. If unquoted: determine type
   - `null` → null
   - `true`/`false` → boolean
   - Numeric pattern → number (check for leading zeros)
   - Otherwise → string

### 6.3 Array Detection
1. Check for array header `[N]` or `[N]{fields}`
2. Determine form:
   - Inline primitives: values on header line
   - List items: next lines at depth+1 start with `-`
   - Tabular: next lines at depth+1 are delimiter-separated values

### 6.4 Delimiter Handling
1. Extract delimiter from bracket segment
2. Default to comma if not specified
3. Apply delimiter to:
   - Inline array values
   - Tabular row values
   - Field name declarations

---

## 7. ERROR CASES TO HANDLE

### Strict Mode Errors
- Indentation not multiple of indent size
- Array count mismatch
- Row width mismatch with field count
- Blank lines in arrays
- Invalid escape sequences
- Missing colons
- Expansion conflicts
- Tabs in indentation
- Trailing spaces

### Universal Errors
- Unterminated quoted strings
- Invalid escape sequences (not in the 5 valid ones)
- Malformed array headers
- Invalid numeric formats in strict contexts

---

## 8. REFERENCE RESOURCES

- **Main Spec:** https://raw.githubusercontent.com/toon-format/spec/main/SPEC.md
- **Repository:** https://github.com/toon-format/spec
- **Test Fixtures:** 349 language-agnostic JSON test fixtures in tests/fixtures/
- **Reference Implementation:** TypeScript/JavaScript at github.com/toon-format/toon
- **Version:** 3.0 (November 24, 2025)

---

## 9. IMPLEMENTATION CHECKLIST

For a complete TOON parser implementation:

- [ ] Line parser with indentation calculation
- [ ] Array header parser with delimiter detection
- [ ] Field declaration parser
- [ ] String parser with 5 escape sequences
- [ ] Value type detection (null, bool, number, string)
- [ ] Three array form handlers (inline, list, tabular)
- [ ] Key-value pair parser
- [ ] Delimiter handling (comma, tab, pipe)
- [ ] Key folding encoder
- [ ] Path expansion decoder
- [ ] Strict mode validator
- [ ] Lenient mode handler
- [ ] Error reporting system
- [ ] Number canonicalization
- [ ] Quote requirement checker
