# Data Model: TOON Format Nim Implementation

**Date**: 2025-12-08
**Status**: Complete

## Core Types

### ToonValue (Discriminated Union)

The central type representing any TOON/JSON value.

```
ToonValue
├── kind: ToonValueKind (discriminator)
├── When vkNull: (no additional fields)
├── When vkBool: boolVal: bool
├── When vkInt: intVal: int64
├── When vkFloat: floatVal: float64
├── When vkString: strVal: string
├── When vkArray: arrayVal: seq[ToonValue]
└── When vkObject: objectVal: OrderedTable[string, ToonValue]
```

**Field Descriptions**:
- `kind`: Discriminator determining which variant is active
- `boolVal`: Boolean value (true/false)
- `intVal`: 64-bit signed integer
- `floatVal`: 64-bit floating point (IEEE 754)
- `strVal`: UTF-8 encoded string
- `arrayVal`: Ordered sequence of ToonValue
- `objectVal`: Ordered map of string keys to ToonValue (preserves insertion order)

**Validation Rules**:
- Numbers must not use exponent notation in TOON format
- Strings with special characters must be quoted
- Object keys must be valid identifiers for key folding

---

### ToonValueKind (Enum)

```
ToonValueKind
├── vkNull    # null literal
├── vkBool    # true or false
├── vkInt     # Integer number
├── vkFloat   # Floating point number
├── vkString  # String value
├── vkArray   # Array of values
└── vkObject  # Object/map of key-value pairs
```

---

### Delimiter (Enum)

```
Delimiter
├── dlComma  # , (default)
├── dlTab    # TAB character
└── dlPipe   # |
```

**Usage**: Determines how inline arrays and tabular rows are split.

---

### EncodeOptions

Configuration for TOON encoding behavior.

```
EncodeOptions
├── indent: int = 2                    # Spaces per indent level
├── delimiter: Delimiter = dlComma     # Array delimiter
├── keyFolding: KeyFoldingMode = kfNone  # Key folding behavior
└── sortKeys: bool = false             # Sort object keys alphabetically
```

**Field Descriptions**:
- `indent`: Number of spaces for each nesting level (must be > 0)
- `delimiter`: Delimiter for inline arrays and tabular format
- `keyFolding`: Whether to collapse single-key object chains
- `sortKeys`: Whether to sort object keys (false preserves insertion order)

---

### KeyFoldingMode (Enum)

```
KeyFoldingMode
├── kfNone   # No key folding (default)
├── kfSafe   # Fold only identifier-safe keys (a.b.c pattern)
└── kfAll    # Fold all keys (may require quoting)
```

---

### DecodeOptions

Configuration for TOON decoding behavior.

```
DecodeOptions
├── strict: bool = true                  # Strict validation mode
├── expandPaths: PathExpansionMode = peNone  # Path expansion behavior
└── indentSize: int = 2                  # Expected indent size
```

**Field Descriptions**:
- `strict`: Enable strict validation (errors on format violations)
- `expandPaths`: Whether to expand dotted keys into nested objects
- `indentSize`: Expected indentation size (for validation)

---

### PathExpansionMode (Enum)

```
PathExpansionMode
├── peNone   # No path expansion (default)
├── peSafe   # Expand only identifier-safe paths
└── peAll    # Expand all dotted paths
```

---

### ToonError (Exception)

Base error type for TOON operations.

```
ToonError (extends CatchableError)
├── line: int      # 1-based line number
├── col: int       # 1-based column number
└── message: string  # Human-readable error description
```

**Derived Types**:
- `ToonDecodeError`: Errors during TOON → ToonValue conversion
- `ToonEncodeError`: Errors during ToonValue → TOON conversion

---

## Internal Types (Parser)

### Token

Lexical token from scanner.

```
Token
├── kind: TokenKind    # Token type
├── value: string      # Token text content
├── line: int          # Source line (1-based)
└── col: int           # Source column (1-based)
```

---

### TokenKind (Enum)

```
TokenKind
├── tkEof           # End of input
├── tkNewline       # Line ending
├── tkIndent        # Whitespace at line start
├── tkKey           # Identifier before colon
├── tkColon         # : character
├── tkValue         # Unquoted primitive value
├── tkQuotedString  # "..." quoted string
├── tkArrayHeader   # [N] or [N]{fields} or [N|]
├── tkListMarker    # - at line start (after indent)
└── tkDelimiter     # Active delimiter (, | or tab)
```

---

### ArrayHeader

Parsed array header information.

```
ArrayHeader
├── length: int              # Declared element count (N)
├── delimiter: Delimiter     # Active delimiter for this array
├── fields: seq[string]      # Field names for tabular format (may be empty)
└── isTabular: bool          # Whether {fields} were specified
```

**Validation Rules**:
- `length` must be >= 0
- `fields` required for tabular arrays
- All fields must be unique

---

### ParseContext

Parser state during decoding.

```
ParseContext
├── depth: int                # Current nesting depth (0 = root)
├── indentSize: int           # Detected/configured indent size
├── activeDelimiter: Delimiter  # Current delimiter scope
└── inArray: bool             # Whether parsing array content
```

---

## Type Relationships

```
┌─────────────────────────────────────────────────────────────────┐
│                        Public API                                │
├─────────────────────────────────────────────────────────────────┤
│  encode(value: ToonValue, options: EncodeOptions): string       │
│  decode(input: string, options: DecodeOptions): ToonValue       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ToonValue                                  │
│  (discriminated union - central data structure)                  │
├─────────────────────────────────────────────────────────────────┤
│  vkNull │ vkBool │ vkInt │ vkFloat │ vkString │ vkArray │ vkObject│
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Scanner  │   │ Encoder  │   │   CLI    │
        │ (tokens) │   │ (output) │   │ (I/O)    │
        └────┬─────┘   └──────────┘   └──────────┘
             │
             ▼
        ┌──────────┐
        │  Parser  │
        │ (decode) │
        └──────────┘
```

---

## JSON Interoperability

ToonValue maps directly to Nim's std/json types:

| ToonValueKind | JsonNodeKind |
|---------------|--------------|
| vkNull | JNull |
| vkBool | JBool |
| vkInt | JInt |
| vkFloat | JFloat |
| vkString | JString |
| vkArray | JArray |
| vkObject | JObject |

Conversion functions:
- `toJsonNode(v: ToonValue): JsonNode`
- `fromJsonNode(j: JsonNode): ToonValue`

---

## State Transitions

### Decoder State Machine

```
[Start] → [RootLevel]
              │
    ┌─────────┴─────────┐
    ▼                   ▼
[KeyValue]          [ArrayHeader]
    │                   │
    ▼                   ▼
[NestedObject]   ┌──────┴──────┐
    │            ▼             ▼
    │      [InlineArray]  [ListArray]
    │            │             │
    │            ▼             ▼
    │      [Primitives]   [ListItems]
    │                          │
    └──────────────────────────┤
                               ▼
                           [TabularArray]
                               │
                               ▼
                           [TabularRows]
```

### Encoder Output Selection

```
ToonValue → Analyze Structure → Select Format
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
[Primitive]   [Object]      [Array]
    │             │             │
    ▼             ▼             │
[Inline]    [Indented]    ┌────┴────┐
                          ▼         ▼
                    [Uniform?]  [Mixed]
                          │         │
                    ┌─────┴───┐     ▼
                    ▼         ▼  [List]
               [Tabular]  [Inline]
```
