# API Reference

Complete API documentation for toon-nim.

## Module: toon

```nim
import toon
```

## Types

### ToonValue

The main value type representing any TOON/JSON value:

```nim
type
  ToonValueKind* = enum
    tvkNull, tvkBool, tvkInt, tvkFloat, tvkString, tvkArray, tvkObject

  ToonValue* = object
    case kind*: ToonValueKind
    of tvkNull: discard
    of tvkBool: boolVal*: bool
    of tvkInt: intVal*: int64
    of tvkFloat: floatVal*: float
    of tvkString: strVal*: string
    of tvkArray: arrayVal*: seq[ToonValue]
    of tvkObject: objectVal*: OrderedTable[string, ToonValue]
```

### EncodeOptions

Options for encoding ToonValue to TOON string:

```nim
type
  Delimiter* = enum
    delComma, delTab, delPipe

  EncodeOptions* = object
    indent*: int          # Spaces per indentation level (default: 2)
    delimiter*: Delimiter # Array delimiter (default: comma)
    sortKeys*: bool       # Sort object keys (default: false)
    keyFolding*: bool     # Fold single-key chains (default: false)
```

### DecodeOptions

Options for decoding TOON string to ToonValue:

```nim
type
  DecodeOptions* = object
    strict*: bool         # Strict mode (default: true)
    indentSize*: int      # Expected indent size (default: 2)
    expandPaths*: bool    # Expand dotted paths (default: false)
```

## Constructors

### newToonNull

```nim
proc newToonNull*(): ToonValue
```

Creates a null value.

### newToonBool

```nim
proc newToonBool*(val: bool): ToonValue
```

Creates a boolean value.

### newToonInt

```nim
proc newToonInt*(val: int64): ToonValue
```

Creates an integer value.

### newToonFloat

```nim
proc newToonFloat*(val: float): ToonValue
```

Creates a floating-point value.

### newToonString

```nim
proc newToonString*(val: string): ToonValue
```

Creates a string value.

### newToonArray

```nim
proc newToonArray*(items: openArray[ToonValue]): ToonValue
proc newToonArray*(items: varargs[ToonValue]): ToonValue
```

Creates an array value.

### newToonObject

```nim
proc newToonObject*(pairs: openArray[(string, ToonValue)]): ToonValue
proc newToonObject*(pairs: varargs[(string, ToonValue)]): ToonValue
```

Creates an object value.

## Accessors

### getBool

```nim
proc getBool*(v: ToonValue): bool
```

Returns the boolean value. Raises if not a boolean.

### getInt

```nim
proc getInt*(v: ToonValue): int64
```

Returns the integer value. Raises if not an integer.

### getFloat

```nim
proc getFloat*(v: ToonValue): float
```

Returns the float value. Raises if not a float.

### getStr

```nim
proc getStr*(v: ToonValue): string
```

Returns the string value. Raises if not a string.

### `[]` (object access)

```nim
proc `[]`*(v: ToonValue, key: string): ToonValue
```

Access object field by key. Raises if key not found.

### `[]` (array access)

```nim
proc `[]`*(v: ToonValue, index: int): ToonValue
```

Access array element by index. Raises if out of bounds.

### hasKey

```nim
proc hasKey*(v: ToonValue, key: string): bool
```

Returns true if object contains the key.

### keys

```nim
proc keys*(v: ToonValue): seq[string]
```

Returns all keys of an object.

### len

```nim
proc len*(v: ToonValue): int
```

Returns length of array or object.

## Encoding/Decoding

### decode

```nim
proc decode*(input: string, opts: DecodeOptions = defaultDecodeOptions): ToonValue
```

Decodes a TOON string to ToonValue.

**Example:**
```nim
let data = decode("""
name: Alice
age: 30
""")
echo data["name"].getStr()  # Alice
```

### decodeFile

```nim
proc decodeFile*(path: string, opts: DecodeOptions = defaultDecodeOptions): ToonValue
```

Decodes a TOON file to ToonValue.

### encode

```nim
proc encode*(v: ToonValue, opts: EncodeOptions = defaultEncodeOptions): string
```

Encodes ToonValue to a TOON string.

**Example:**
```nim
let obj = newToonObject({
  "name": newToonString("Bob"),
  "active": newToonBool(true)
})
echo encode(obj)
# name: Bob
# active: true
```

### encodeToFile

```nim
proc encodeToFile*(v: ToonValue, path: string, opts: EncodeOptions = defaultEncodeOptions)
```

Encodes ToonValue to a file.

## JSON Interoperability

### toJson

```nim
proc toJson*(v: ToonValue): JsonNode
```

Converts ToonValue to std/json JsonNode.

### fromJson

```nim
proc fromJson*(j: JsonNode): ToonValue
```

Converts std/json JsonNode to ToonValue.

### toJsonString

```nim
proc toJsonString*(v: ToonValue, pretty: bool = true): string
```

Converts ToonValue to JSON string.

### fromJsonString

```nim
proc fromJsonString*(s: string): ToonValue
```

Parses JSON string to ToonValue.

## Constants

### defaultEncodeOptions

```nim
const defaultEncodeOptions* = EncodeOptions(
  indent: 2,
  delimiter: delComma,
  sortKeys: false,
  keyFolding: false
)
```

### defaultDecodeOptions

```nim
const defaultDecodeOptions* = DecodeOptions(
  strict: true,
  indentSize: 2,
  expandPaths: false
)
```

## Exceptions

### ToonError

Base exception for all TOON errors.

### ToonParseError

Raised when parsing fails. Includes line and column information.

### ToonEncodeError

Raised when encoding fails.
