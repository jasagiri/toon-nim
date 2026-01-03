# Library API Contract: toon-nim

**Version**: 0.1.0
**Date**: 2025-12-08

## Module: toon

Main entry point. Re-exports all public API.

```nim
import toon

# All public types and functions available
```

---

## Public Functions

### encode

Encode a ToonValue to TOON format string.

```nim
proc encode*(value: ToonValue, options: EncodeOptions = defaultEncodeOptions): string
```

**Parameters**:
- `value`: The ToonValue to encode
- `options`: Encoding configuration (optional, uses defaults)

**Returns**: TOON formatted string

**Raises**: `ToonEncodeError` on encoding failure

**Example**:
```nim
let obj = newToonObject({"name": newToonString("Ada"), "age": newToonInt(42)})
let toon = encode(obj)
# Output:
# name: Ada
# age: 42
```

---

### decode

Decode a TOON format string to ToonValue.

```nim
proc decode*(input: string, options: DecodeOptions = defaultDecodeOptions): ToonValue
```

**Parameters**:
- `input`: TOON formatted string
- `options`: Decoding configuration (optional, uses defaults)

**Returns**: Parsed ToonValue

**Raises**: `ToonDecodeError` with line/column on parse failure

**Example**:
```nim
let toon = """
name: Ada
age: 42
"""
let value = decode(toon)
assert value.kind == vkObject
assert value["name"].strVal == "Ada"
```

---

### decodeFile

Decode a TOON file to ToonValue.

```nim
proc decodeFile*(path: string, options: DecodeOptions = defaultDecodeOptions): ToonValue
```

**Parameters**:
- `path`: Path to TOON file
- `options`: Decoding configuration (optional)

**Returns**: Parsed ToonValue

**Raises**:
- `IOError` on file read failure
- `ToonDecodeError` on parse failure

---

### encodeToFile

Encode a ToonValue and write to file.

```nim
proc encodeToFile*(value: ToonValue, path: string, options: EncodeOptions = defaultEncodeOptions)
```

**Parameters**:
- `value`: The ToonValue to encode
- `path`: Output file path
- `options`: Encoding configuration (optional)

**Raises**:
- `IOError` on file write failure
- `ToonEncodeError` on encoding failure

---

## ToonValue Constructors

### Null
```nim
proc newToonNull*(): ToonValue
```

### Boolean
```nim
proc newToonBool*(val: bool): ToonValue
```

### Integer
```nim
proc newToonInt*(val: int64): ToonValue
proc newToonInt*(val: int): ToonValue  # Convenience overload
```

### Float
```nim
proc newToonFloat*(val: float64): ToonValue
proc newToonFloat*(val: float): ToonValue  # Convenience overload
```

### String
```nim
proc newToonString*(val: string): ToonValue
```

### Array
```nim
proc newToonArray*(): ToonValue  # Empty array
proc newToonArray*(items: openArray[ToonValue]): ToonValue
proc newToonArray*(items: varargs[ToonValue]): ToonValue
```

### Object
```nim
proc newToonObject*(): ToonValue  # Empty object
proc newToonObject*(pairs: openArray[(string, ToonValue)]): ToonValue
```

---

## ToonValue Accessors

### Kind Check
```nim
proc isNull*(v: ToonValue): bool
proc isBool*(v: ToonValue): bool
proc isInt*(v: ToonValue): bool
proc isFloat*(v: ToonValue): bool
proc isNumber*(v: ToonValue): bool  # isInt or isFloat
proc isString*(v: ToonValue): bool
proc isArray*(v: ToonValue): bool
proc isObject*(v: ToonValue): bool
```

### Value Access
```nim
proc getBool*(v: ToonValue): bool
proc getInt*(v: ToonValue): int64
proc getFloat*(v: ToonValue): float64
proc getStr*(v: ToonValue): string

# Array access
proc len*(v: ToonValue): int  # For arrays and objects
proc `[]`*(v: ToonValue, index: int): ToonValue  # Array index
iterator items*(v: ToonValue): ToonValue  # Array iteration

# Object access
proc `[]`*(v: ToonValue, key: string): ToonValue  # Object key
proc hasKey*(v: ToonValue, key: string): bool
proc keys*(v: ToonValue): seq[string]
iterator pairs*(v: ToonValue): (string, ToonValue)  # Object iteration
```

### Mutators
```nim
proc add*(v: var ToonValue, item: ToonValue)  # Array append
proc `[]=`*(v: var ToonValue, key: string, val: ToonValue)  # Object set
proc delete*(v: var ToonValue, key: string)  # Object delete
```

---

## JSON Interoperability

```nim
proc toJsonNode*(v: ToonValue): JsonNode
proc fromJsonNode*(j: JsonNode): ToonValue

# Convenience: Direct JSON string conversion
proc toJson*(v: ToonValue, pretty: bool = false): string
proc fromJson*(json: string): ToonValue
```

---

## Options Types

### EncodeOptions
```nim
type EncodeOptions* = object
  indent*: int              # Default: 2
  delimiter*: Delimiter     # Default: dlComma
  keyFolding*: KeyFoldingMode  # Default: kfNone
  sortKeys*: bool           # Default: false

const defaultEncodeOptions* = EncodeOptions(
  indent: 2,
  delimiter: dlComma,
  keyFolding: kfNone,
  sortKeys: false
)
```

### DecodeOptions
```nim
type DecodeOptions* = object
  strict*: bool             # Default: true
  expandPaths*: PathExpansionMode  # Default: peNone
  indentSize*: int          # Default: 2

const defaultDecodeOptions* = DecodeOptions(
  strict: true,
  expandPaths: peNone,
  indentSize: 2
)
```

---

## Error Types

```nim
type
  ToonError* = object of CatchableError
    line*: int
    col*: int

  ToonDecodeError* = object of ToonError
  ToonEncodeError* = object of ToonError
```

### Error Message Format
```
ToonDecodeError: <message> at line <line>, column <col>
```

Example:
```
ToonDecodeError: Expected colon after key at line 3, column 15
```

---

## Enums

```nim
type
  ToonValueKind* = enum
    vkNull, vkBool, vkInt, vkFloat, vkString, vkArray, vkObject

  Delimiter* = enum
    dlComma, dlTab, dlPipe

  KeyFoldingMode* = enum
    kfNone, kfSafe, kfAll

  PathExpansionMode* = enum
    peNone, peSafe, peAll
```

---

## Usage Examples

### Basic Encoding
```nim
import toon

let data = newToonObject({
  "id": newToonInt(123),
  "name": newToonString("Ada Lovelace"),
  "active": newToonBool(true),
  "tags": newToonArray([
    newToonString("admin"),
    newToonString("developer")
  ])
})

echo encode(data)
# Output:
# id: 123
# name: Ada Lovelace
# active: true
# tags[2]: admin,developer
```

### Basic Decoding
```nim
import toon

let input = """
id: 123
name: Ada Lovelace
active: true
tags[2]: admin,developer
"""

let data = decode(input)
echo data["name"].getStr()  # Ada Lovelace
echo data["tags"][0].getStr()  # admin
```

### Custom Options
```nim
import toon

# Tabular encoding with pipe delimiter
let options = EncodeOptions(
  indent: 4,
  delimiter: dlPipe,
  keyFolding: kfSafe
)

let output = encode(data, options)
```

### Error Handling
```nim
import toon

try:
  let data = decode(invalidInput)
except ToonDecodeError as e:
  echo "Parse error at line ", e.line, ", col ", e.col
  echo "Message: ", e.msg
```
