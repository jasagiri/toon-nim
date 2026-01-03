## TOON Format Encoder
## Converts ToonValue structures to TOON format strings

import std/[strutils, algorithm, tables]
import ./types
import ./utils

# T050-T055: Encoding implementation

proc needsKeyQuoting(key: string): bool =
  ## Check if a key needs quoting
  if key.len == 0:
    return true
  if key[0] in Whitespace or key[^1] in Whitespace:
    return true
  for c in key:
    if c in {':', '"', '\\', '\n', '\r', '\t', '[', ']', '{', '}'}:
      return true
  if not isValidIdentifier(key):
    # Check for special characters that need quoting
    for c in key:
      if c notin {'A'..'Z', 'a'..'z', '0'..'9', '_', '-', '.'}:
        return true
  false

proc formatKey(key: string): string =
  ## Format a key for output, quoting if necessary
  if needsKeyQuoting(key):
    quoteString(key)
  else:
    key

proc isSimpleArray(arr: seq[ToonValue]): bool =
  ## Check if array contains only primitives (suitable for inline format)
  for item in arr:
    if item.kind in {vkArray, vkObject}:
      return false
  true

proc isIdentifierSegment(s: string): bool =
  ## Check if string is a valid identifier segment for key folding
  ## Must match ^[A-Za-z_][A-Za-z0-9_]*$
  if s.len == 0:
    return false
  if s[0] notin {'A'..'Z', 'a'..'z', '_'}:
    return false
  for i in 1..<s.len:
    if s[i] notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      return false
  true

proc canFoldKey(key: string, val: ToonValue, opts: EncodeOptions): bool =
  ## Check if this key-value pair can be folded (has single-key object value)
  if opts.keyFolding != kfSafe:
    return false
  if not isIdentifierSegment(key):
    return false
  if val.kind != vkObject:
    return false
  if val.objectVal.len != 1:
    return false
  # Check if the nested key is also a valid identifier
  for nestedKey in val.objectVal.keys:
    if not isIdentifierSegment(nestedKey):
      return false
  true

proc collectFoldedPath(key: string, val: ToonValue, opts: EncodeOptions): tuple[path: string, finalVal: ToonValue] =
  ## Collect the full dotted path and final value for key folding
  var path = key
  var current = val

  while current.kind == vkObject and current.objectVal.len == 1:
    var nestedKey: string
    var nestedVal: ToonValue
    for k, v in current.objectVal:
      nestedKey = k
      nestedVal = v
      break

    if not isIdentifierSegment(nestedKey):
      break

    path.add(".")
    path.add(nestedKey)
    current = nestedVal

  (path, current)

proc encodeValue(v: ToonValue, opts: EncodeOptions, indent: int): string

proc encodeArray(arr: seq[ToonValue], opts: EncodeOptions, indent: int): string =
  ## Encode an array
  if arr.len == 0:
    return "null"

  # Check if we can use inline format
  if isSimpleArray(arr):
    var parts: seq[string] = @[]
    let delimStr = case opts.delimiter
      of dlComma: ", "
      of dlTab: "\t"
      of dlPipe: "|"

    for item in arr:
      case item.kind
      of vkNull:
        parts.add("null")
      of vkBool:
        parts.add(if item.boolVal: "true" else: "false")
      of vkInt:
        parts.add($item.intVal)
      of vkFloat:
        parts.add($item.floatVal)
      of vkString:
        if needsQuoting(item.strVal, opts.delimiter):
          parts.add(quoteString(item.strVal))
        else:
          parts.add(item.strVal)
      else:
        discard
    return parts.join(delimStr)

  # Use list format for complex arrays
  result = ""
  let indentStr = makeIndent(indent, opts.indent)
  for i, item in arr:
    if i > 0:
      result.add("\n")
    result.add(indentStr)
    result.add("- ")
    if item.kind == vkObject:
      # Object in list - first key on same line
      var first = true
      for key, val in item.objectVal:
        if first:
          result.add(formatKey(key))
          result.add(": ")
          if val.kind in {vkObject, vkArray}:
            if val.kind == vkArray and isSimpleArray(val.arrayVal):
              result.add(encodeArray(val.arrayVal, opts, indent + 1))
            else:
              result.add("\n")
              result.add(encodeValue(val, opts, indent + 2))
          else:
            result.add(encodeValue(val, opts, indent + 1))
          first = false
        else:
          result.add("\n")
          result.add(makeIndent(indent + 1, opts.indent))
          result.add(formatKey(key))
          result.add(": ")
          if val.kind in {vkObject, vkArray}:
            if val.kind == vkArray and isSimpleArray(val.arrayVal):
              result.add(encodeArray(val.arrayVal, opts, indent + 2))
            else:
              result.add("\n")
              result.add(encodeValue(val, opts, indent + 2))
          else:
            result.add(encodeValue(val, opts, indent + 2))
    elif item.kind == vkArray:
      result.add(encodeArray(item.arrayVal, opts, indent + 1))
    else:
      result.add(encodeValue(item, opts, indent + 1))

proc encodeObject(obj: ToonValue, opts: EncodeOptions, indent: int): string =
  ## Encode an object
  if obj.objectVal.len == 0:
    return ""

  var keys: seq[string] = @[]
  for k in obj.objectVal.keys:
    keys.add(k)

  if opts.sortKeys:
    keys.sort()

  result = ""
  let indentStr = makeIndent(indent, opts.indent)

  for i, key in keys:
    if i > 0:
      result.add("\n")

    let val = obj.objectVal[key]

    # Check for key folding opportunity
    if canFoldKey(key, val, opts):
      let (foldedPath, finalVal) = collectFoldedPath(key, val, opts)
      result.add(indentStr)
      result.add(foldedPath)
      result.add(": ")

      case finalVal.kind
      of vkObject:
        if finalVal.objectVal.len == 0:
          result.add("null")
        else:
          result.add("\n")
          result.add(encodeObject(finalVal, opts, indent + 1))
      of vkArray:
        if finalVal.arrayVal.len == 0:
          result.add("null")
        elif isSimpleArray(finalVal.arrayVal):
          result.add(encodeArray(finalVal.arrayVal, opts, indent + 1))
        else:
          result.add("\n")
          result.add(encodeArray(finalVal.arrayVal, opts, indent + 1))
      else:
        result.add(encodeValue(finalVal, opts, indent))
    else:
      result.add(indentStr)
      result.add(formatKey(key))
      result.add(": ")

      case val.kind
      of vkObject:
        if val.objectVal.len == 0:
          result.add("null")
        else:
          result.add("\n")
          result.add(encodeObject(val, opts, indent + 1))
      of vkArray:
        if val.arrayVal.len == 0:
          result.add("null")
        elif isSimpleArray(val.arrayVal):
          result.add(encodeArray(val.arrayVal, opts, indent + 1))
        else:
          result.add("\n")
          result.add(encodeArray(val.arrayVal, opts, indent + 1))
      else:
        result.add(encodeValue(val, opts, indent))

proc encodeValue(v: ToonValue, opts: EncodeOptions, indent: int): string =
  ## Encode any ToonValue
  case v.kind
  of vkNull:
    "null"
  of vkBool:
    if v.boolVal: "true" else: "false"
  of vkInt:
    $v.intVal
  of vkFloat:
    $v.floatVal
  of vkString:
    if needsQuoting(v.strVal):
      quoteString(v.strVal)
    else:
      v.strVal
  of vkArray:
    encodeArray(v.arrayVal, opts, indent)
  of vkObject:
    encodeObject(v, opts, indent)

# T056: encode() public function
proc encode*(v: ToonValue, opts: EncodeOptions = defaultEncodeOptions): string =
  ## Encode a ToonValue to TOON format string
  ##
  ## Args:
  ##   v: The ToonValue to encode
  ##   opts: Encoding options (indent, delimiter, key folding, etc.)
  ##
  ## Returns:
  ##   TOON format string
  ##
  ## Raises:
  ##   ToonEncodeError: If the value cannot be encoded
  case v.kind
  of vkObject:
    encodeObject(v, opts, 0)
  of vkArray:
    encodeArray(v.arrayVal, opts, 0)
  else:
    encodeValue(v, opts, 0)

# T057: encodeToFile() public function
proc encodeToFile*(v: ToonValue, path: string, opts: EncodeOptions = defaultEncodeOptions) =
  ## Encode a ToonValue and write to a file
  ##
  ## Args:
  ##   v: The ToonValue to encode
  ##   path: Path to the output file
  ##   opts: Encoding options
  ##
  ## Raises:
  ##   IOError: If the file cannot be written
  ##   ToonEncodeError: If the value cannot be encoded
  let content = encode(v, opts)
  writeFile(path, content)
