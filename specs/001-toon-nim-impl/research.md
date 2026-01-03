# Research: TOON Format Nim Implementation

**Date**: 2025-12-08
**Status**: Complete

## TOON Format Specification Summary (v3.0)

### Core Syntax Rules

#### Key-Value Pairs
- Syntax: `key: value` (exactly one space after colon)
- Nested objects: `key:` (no value) opens nested scope at depth+1

#### Array Headers
- Basic: `[N]:` (root array) or `key[N]:` (named array)
- With fields: `key[N]{field1,field2}:` for tabular data
- With delimiter: `[N|]:` for pipe, literal tab character for tab delimiter
- **Critical**: Every header MUST end with a colon

#### Three Array Forms
1. **Inline Primitives**: `tags[3]: admin,ops,dev` - one space after colon
2. **List Items**: Items at depth+1, each starting with `- ` (hyphen space)
3. **Tabular Objects**: Rows of delimiter-separated values when all elements are objects with same keys and primitive values only

#### Indentation Rules
- Default: 2 spaces per level
- Strict mode: Must be exact multiple of indent size
- No tabs allowed in indentation
- No trailing whitespace

#### Three Delimiters
| Delimiter | Header Syntax | Example |
|-----------|---------------|---------|
| Comma (default) | `[3]:` | `a,b,c` |
| Tab | `[3⟨TAB⟩]:` | `a⟨TAB⟩b⟨TAB⟩c` |
| Pipe | `[3\|]:` | `a\|b\|c` |

### Five Valid Escape Sequences

| Escape | Character |
|--------|-----------|
| `\\` | Backslash |
| `\"` | Double quote |
| `\n` | Newline (U+000A) |
| `\r` | Carriage return (U+000D) |
| `\t` | Tab (U+0009) |

**Important**: Any other escape sequence MUST be rejected in strict mode.

### Quoting Rules

A string value MUST be quoted if it:
- Is empty
- Has leading/trailing whitespace
- Equals `true`, `false`, or `null`
- Matches numeric patterns
- Has forbidden leading zeros (e.g., `05`)
- Contains: colon, quote, backslash, brackets, braces, control characters
- Contains the active delimiter
- Equals or starts with hyphen (`-`)

### Key Folding and Path Expansion

**Key Folding** (encoding, `keyFolding="safe"`):
- Collapses nested single-key objects: `{a: {b: {c: 1}}}` → `a.b.c: 1`
- Segments must match identifier pattern: `^[A-Za-z_][A-Za-z0-9_]*$`

**Path Expansion** (decoding, `expandPaths="safe"`):
- Splits dotted keys: `a.b.c: 1` → `{"a": {"b": {"c": 1}}}`
- Strict mode: Error on conflicts
- Lenient mode: Last-write-wins

### Strict vs Lenient Mode

| Feature | Strict (default) | Lenient |
|---------|------------------|---------|
| Array count | Must match exactly | Flexible |
| Indentation | Exact multiples only | floor(spaces/indentSize) |
| Row widths | Must match header | Flexible |
| Blank lines | Error in arrays | Ignored |
| Tabs | Forbidden | Implementation-defined |
| Trailing spaces | Forbidden | Allowed |
| Conflicts | Error | Last-write-wins |

---

## Nim Implementation Decisions

### Decision 1: Object Variants for ToonValue

**Decision**: Use Nim's object variants (discriminated unions) for ToonValue type.

**Rationale**:
- Idiomatic Nim pattern for sum types
- Type-safe at compile time
- Efficient memory layout
- Standard library json module uses same pattern

**Alternatives Rejected**:
- Inheritance hierarchy: More complex, less idiomatic in Nim
- Pointer-based tagged unions: Unsafe, harder to use

### Decision 2: Lexer Implementation Approach

**Decision**: Hand-written lexer using `std/lexbase` module.

**Rationale**:
- `lexbase.BaseLexer` provides efficient buffering
- Guarantees whole line in buffer (only check refills at line endings)
- Built-in line number tracking for error reporting
- Nim compiler uses same approach

**Alternatives Rejected**:
- Parser generators (nimly, npeg): Overkill for TOON's simple grammar
- Pure string scanning: Less efficient, manual buffer management

### Decision 3: Error Handling Strategy

**Decision**: Custom exception types with line/column tracking.

**Rationale**:
- Constitution requires error messages with line numbers
- Exceptions are idiomatic for parsing errors in Nim
- Simple error propagation without explicit Result handling
- Consistent with Nim standard library patterns

**Implementation**:
```nim
type
  ToonError* = object of CatchableError
    line*: int
    col*: int

  ToonDecodeError* = object of ToonError
  ToonEncodeError* = object of ToonError
```

**Alternatives Rejected**:
- Result types: More verbose for this use case
- Error codes: Less informative, harder to use

### Decision 4: String Processing Strategy

**Decision**: Use `std/parseutils` for low-level parsing, index-based access to avoid copies.

**Rationale**:
- `parseutils` provides efficient primitive parsing
- Index-based access avoids string slice allocations
- Critical for performance goal (1MB in <1 second)

**Key Functions**:
- `parseInt`, `parseFloat` for numbers
- `skip` functions for whitespace handling
- Direct `s[pos]` character access

### Decision 5: Testing Strategy

**Decision**: Use Nim's built-in `unittest` module with fixture-based tests.

**Rationale**:
- Constitution requires TDD; unittest is standard
- Fixture-based testing aligns with 349 official test cases
- Separate unit/ and integration/ directories per Constitution

**Test Organization**:
```
tests/
├── unit/           # Individual module tests
├── integration/    # Round-trip, CLI tests
└── fixtures/       # Official TOON test cases
    ├── decode/
    └── encode/
```

### Decision 6: CLI Architecture

**Decision**: Use `std/parseopt` for argument parsing, thin wrapper over library.

**Rationale**:
- Constitution requires library-first; CLI is thin layer
- `parseopt` is in standard library (no external deps)
- Simple enough for our needs (--json, --toon, --help, --version)

---

## Implementation Notes

### Scanner Token Types

```nim
type
  TokenKind = enum
    tkEof
    tkNewline
    tkIndent        # Indentation at line start
    tkKey           # Identifier before colon
    tkColon         # :
    tkValue         # Unquoted value
    tkQuotedString  # "..."
    tkArrayHeader   # [N] or [N]{fields}
    tkListMarker    # - (hyphen at line start after indent)
    tkDelimiter     # , | or tab based on context
```

### Parser State Machine

1. **Root Level**: Expect key:value pairs or array header
2. **Object Context**: Track indent depth, parse nested key:values
3. **Array Context**: Track expected count, active delimiter
4. **Tabular Context**: Parse rows with field mapping

### Performance Optimizations

1. **Buffer once**: Read entire input into buffer via lexbase
2. **Index-based parsing**: Avoid string slices
3. **Pre-allocated output**: Use `newStringOfCap` for encoder
4. **Stream output**: CLI writes directly to stdout (no buffering entire output)

---

## References

- TOON Spec v3.0: https://github.com/toon-format/spec
- Official test fixtures: https://github.com/toon-format/spec/tree/main/fixtures
- Nim lexbase: https://nim-lang.org/docs/lexbase.html
- Nim parseutils: https://nim-lang.org/docs/parseutils.html
- Nim unittest: https://nim-lang.org/docs/unittest.html
