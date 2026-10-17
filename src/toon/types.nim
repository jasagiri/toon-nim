## TOON Format Types
## Core type definitions for TOON (Token-Oriented Object Notation)

import std/[tables, json, parseutils]

# T005: ToonValueKind enum
type
  ToonValueKind* = enum
    ## Discriminator for ToonValue variants
    vkNull    ## null literal
    vkBool    ## true or false
    vkInt     ## Integer number
    vkFloat   ## Floating point number
    vkString  ## String value
    vkArray   ## Array of values
    vkObject  ## Object/map of key-value pairs

# T006: Delimiter enum
type
  Delimiter* = enum
    ## Array delimiter types
    dlComma = ","   ## Comma delimiter (default)
    dlTab = "\t"    ## Tab delimiter
    dlPipe = "|"    ## Pipe delimiter

# T009: ToonValue object variant
type
  ToonValue* = ref object
    ## Central type representing any TOON/JSON value
    case kind*: ToonValueKind
    of vkNull:
      discard
    of vkBool:
      boolVal*: bool
    of vkInt:
      intVal*: int64
    of vkFloat:
      floatVal*: float64
    of vkString:
      strVal*: string
    of vkArray:
      arrayVal*: seq[ToonValue]
    of vkObject:
      objectVal*: OrderedTable[string, ToonValue]

# T010: EncodeOptions type
type
  EncodeOptions* = object
    ## Configuration for TOON encoding (specification §13)
    indentSize*: int          ## Spaces per indent level (default: 2)
    delimiter*: Delimiter     ## Document delimiter (default: dlComma)

const defaultEncodeOptions* = EncodeOptions(indentSize: 2, delimiter: dlComma)

# T011: DecodeOptions type
type
  DecodeOptions* = object
    ## Configuration for TOON decoding (specification §13)
    strict*: bool               ## Strict validation mode (default: true)
    indentSize*: int            ## Expected indent size (default: 2)

const defaultDecodeOptions* = DecodeOptions(strict: true, indentSize: 2)

# T012: Error types
type
  ToonError* = object of CatchableError
    ## Base error type for TOON operations
    line*: int      ## 1-based line number
    col*: int       ## 1-based column number

  ToonDecodeError* = object of ToonError
    ## Errors during TOON → ToonValue conversion

  ToonEncodeError* = object of ToonError
    ## Errors during ToonValue → TOON conversion

proc newToonError*(msg: string, line: int = 0, col: int = 0): ref ToonError =
  result = newException(ToonError, msg)
  result.line = line
  result.col = col

proc newToonDecodeError*(msg: string, line: int = 0, col: int = 0): ref ToonDecodeError =
  result = newException(ToonDecodeError, msg)
  result.line = line
  result.col = col

proc newToonEncodeError*(msg: string, line: int = 0, col: int = 0): ref ToonEncodeError =
  result = newException(ToonEncodeError, msg)
  result.line = line
  result.col = col

# T013: ToonValue constructors
proc newToonNull*(): ToonValue =
  ## Create a null ToonValue
  ToonValue(kind: vkNull)

proc newToonBool*(val: bool): ToonValue =
  ## Create a boolean ToonValue
  ToonValue(kind: vkBool, boolVal: val)

proc newToonInt*(val: int64): ToonValue =
  ## Create an integer ToonValue
  ToonValue(kind: vkInt, intVal: val)

proc newToonInt*(val: int): ToonValue =
  ## Create an integer ToonValue (convenience overload)
  ToonValue(kind: vkInt, intVal: val.int64)

proc newToonFloat*(val: float64): ToonValue =
  ## Create a float ToonValue
  ToonValue(kind: vkFloat, floatVal: val)

proc newToonString*(val: string): ToonValue =
  ## Create a string ToonValue
  ToonValue(kind: vkString, strVal: val)

proc newToonArray*(): ToonValue =
  ## Create an empty array ToonValue
  ToonValue(kind: vkArray, arrayVal: @[])

proc newToonArray*(items: openArray[ToonValue]): ToonValue =
  ## Create an array ToonValue with items
  ToonValue(kind: vkArray, arrayVal: @items)

proc newToonObject*(): ToonValue =
  ## Create an empty object ToonValue
  ToonValue(kind: vkObject, objectVal: initOrderedTable[string, ToonValue]())

proc newToonObject*(pairs: openArray[(string, ToonValue)]): ToonValue =
  ## Create an object ToonValue with key-value pairs
  result = ToonValue(kind: vkObject, objectVal: initOrderedTable[string, ToonValue]())
  for (k, v) in pairs:
    result.objectVal[k] = v

# T014: ToonValue accessors - Kind checks
proc isNull*(v: ToonValue): bool =
  ## Check if value is null
  v.kind == vkNull

proc isBool*(v: ToonValue): bool =
  ## Check if value is boolean
  v.kind == vkBool

proc isInt*(v: ToonValue): bool =
  ## Check if value is integer
  v.kind == vkInt

proc isFloat*(v: ToonValue): bool =
  ## Check if value is float
  v.kind == vkFloat

proc isNumber*(v: ToonValue): bool =
  ## Check if value is any numeric type
  v.kind in {vkInt, vkFloat}

proc isString*(v: ToonValue): bool =
  ## Check if value is string
  v.kind == vkString

proc isArray*(v: ToonValue): bool =
  ## Check if value is array
  v.kind == vkArray

proc isObject*(v: ToonValue): bool =
  ## Check if value is object
  v.kind == vkObject

# T014: ToonValue accessors - Value getters
proc getBool*(v: ToonValue): bool =
  ## Get boolean value
  if v.kind != vkBool:
    raise newException(ValueError, "ToonValue is not a boolean")
  v.boolVal

proc getInt*(v: ToonValue): int64 =
  ## Get integer value
  if v.kind != vkInt:
    raise newException(ValueError, "ToonValue is not an integer")
  v.intVal

proc getFloat*(v: ToonValue): float64 =
  ## Get float value
  if v.kind == vkFloat:
    return v.floatVal
  elif v.kind == vkInt:
    return v.intVal.float64
  else:
    raise newException(ValueError, "ToonValue is not a number")

proc getStr*(v: ToonValue): string =
  ## Get string value
  if v.kind != vkString:
    raise newException(ValueError, "ToonValue is not a string")
  v.strVal

# T014: Array and Object accessors
proc len*(v: ToonValue): int =
  ## Get length of array or object
  case v.kind
  of vkArray: v.arrayVal.len
  of vkObject: v.objectVal.len
  else: raise newException(ValueError, "ToonValue is not an array or object")

proc `[]`*(v: ToonValue, index: int): ToonValue =
  ## Get array element by index
  if v.kind != vkArray:
    raise newException(ValueError, "ToonValue is not an array")
  v.arrayVal[index]

proc `[]`*(v: ToonValue, key: string): ToonValue =
  ## Get object value by key
  if v.kind != vkObject:
    raise newException(ValueError, "ToonValue is not an object")
  v.objectVal[key]

proc hasKey*(v: ToonValue, key: string): bool =
  ## Check if object has key
  if v.kind != vkObject:
    return false
  key in v.objectVal

proc keys*(v: ToonValue): seq[string] =
  ## Get all keys from object
  if v.kind != vkObject:
    raise newException(ValueError, "ToonValue is not an object")
  result = @[]
  for k in v.objectVal.keys:
    result.add(k)

iterator items*(v: ToonValue): ToonValue =
  ## Iterate over array elements
  if v.kind != vkArray:
    raise newException(ValueError, "ToonValue is not an array")
  for item in v.arrayVal:
    yield item

iterator pairs*(v: ToonValue): (string, ToonValue) =
  ## Iterate over object key-value pairs
  if v.kind != vkObject:
    raise newException(ValueError, "ToonValue is not an object")
  for k, val in v.objectVal:
    yield (k, val)

# T015: ToonValue mutators
proc add*(v: var ToonValue, item: ToonValue) =
  ## Add item to array
  if v.kind != vkArray:
    raise newException(ValueError, "ToonValue is not an array")
  v.arrayVal.add(item)

proc `[]=`*(v: var ToonValue, key: string, val: ToonValue) =
  ## Set object value by key
  if v.kind != vkObject:
    raise newException(ValueError, "ToonValue is not an object")
  v.objectVal[key] = val

proc delete*(v: var ToonValue, key: string) =
  ## Delete object key
  if v.kind != vkObject:
    raise newException(ValueError, "ToonValue is not an object")
  v.objectVal.del(key)

# T080: Equality comparison
proc `==`*(a, b: ToonValue): bool =
  ## JSON-model equality (specification §2): numbers compare by value, so an
  ## integer equals the float of the same value; objects compare by their
  ## ordered key sequence.
  if a.isNil or b.isNil:
    return a.isNil and b.isNil
  if a.kind in {vkInt, vkFloat} and b.kind in {vkInt, vkFloat}:
    if a.kind == vkInt and b.kind == vkInt:
      return a.intVal == b.intVal
    return a.getFloat() == b.getFloat()
  if a.kind != b.kind:
    return false

  case a.kind
  of vkNull:
    true
  of vkBool:
    a.boolVal == b.boolVal
  of vkInt, vkFloat:
    false
  of vkString:
    a.strVal == b.strVal
  of vkArray:
    if a.arrayVal.len != b.arrayVal.len:
      return false
    for i in 0..<a.arrayVal.len:
      if a.arrayVal[i] != b.arrayVal[i]:
        return false
    true
  of vkObject:
    if a.objectVal.len != b.objectVal.len:
      return false
    var bKeys: seq[string]
    for key in b.objectVal.keys:
      bKeys.add key
    var i = 0
    for key, val in a.objectVal:
      if key != bKeys[i] or b.objectVal[key] != val:
        return false
      inc i
    true

# T082: JSON interoperability
proc toJsonNode*(v: ToonValue): JsonNode {.raises: [].} =
  ## Convert ToonValue to JsonNode
  case v.kind
  of vkNull:
    newJNull()
  of vkBool:
    newJBool(v.boolVal)
  of vkInt:
    newJInt(v.intVal)
  of vkFloat:
    newJFloat(v.floatVal)
  of vkString:
    newJString(v.strVal)
  of vkArray:
    var arr = newJArray()
    for item in v.arrayVal:
      arr.add(item.toJsonNode())
    arr
  of vkObject:
    var obj = newJObject()
    for key, val in v.objectVal:
      obj[key] = val.toJsonNode()
    obj

proc fromJsonNode*(j: JsonNode): ToonValue {.raises: [].} =
  ## Convert JsonNode to ToonValue
  case j.kind
  of JNull:
    newToonNull()
  of JBool:
    newToonBool(j.getBool())
  of JInt:
    newToonInt(j.getBiggestInt())
  of JFloat:
    newToonFloat(j.getFloat())
  of JString:
    # std/json keeps an integer literal beyond int64 as a JString whose `$`
    # is the bare literal (the flag that marks it is not exported). Such a
    # number becomes its float64 approximation, the policy of README.md.
    let raw = $j
    var approximation: float
    if raw.len > 0 and raw[0] != '"' and parseFloat(raw, approximation) == raw.len:
      newToonFloat(approximation)
    else:
      newToonString(j.getStr())
  of JArray:
    var arr = newToonArray()
    for item in j:
      arr.arrayVal.add(item.fromJsonNode())
    arr
  of JObject:
    var obj = newToonObject()
    for key, val in j:
      obj.objectVal[key] = val.fromJsonNode()
    obj

# T083: JSON string convenience functions
proc toJson*(v: ToonValue, pretty: bool = false): string =
  ## Convert ToonValue to JSON string
  let node = v.toJsonNode()
  if pretty:
    node.pretty()
  else:
    $node

proc fromJson*(jsonStr: string): ToonValue =
  ## Parse JSON string to ToonValue
  let node = parseJson(jsonStr)
  node.fromJsonNode()
