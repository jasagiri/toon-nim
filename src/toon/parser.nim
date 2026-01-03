## TOON Format Parser
## Converts tokens into ToonValue structures

import std/[strutils, parseutils, tables]
import ./types
import ./scanner

# T033: ArrayHeader type
type
  ArrayHeader* = object
    ## Parsed array header information
    count*: int
    fields*: seq[string]

# T034: ParseContext type
type
  ParseContext* = object
    ## Context for parsing TOON input
    scanner*: Scanner
    options*: DecodeOptions
    currentToken*: Token
    indentStack*: seq[int]

proc newParseContext(input: string, options: DecodeOptions): ParseContext =
  ## Create a new parse context
  result = ParseContext(
    scanner: newScanner(input),
    options: options,
    indentStack: @[0]
  )
  result.currentToken = result.scanner.nextToken()

proc advance(ctx: var ParseContext): Token =
  ## Advance to next token and return previous
  result = ctx.currentToken
  ctx.currentToken = ctx.scanner.nextToken()

proc peek(ctx: ParseContext): Token =
  ## Peek at current token
  ctx.currentToken

proc skipNewlines(ctx: var ParseContext) =
  ## Skip newline tokens
  while ctx.peek().kind == tkNewline:
    discard ctx.advance()

proc skipWhitespaceInLine(ctx: var ParseContext) {.used.} =
  ## Skip whitespace tokens (for checking what follows a value)
  # Currently just skips indent tokens if present
  while ctx.peek().kind == tkIndent:
    discard ctx.advance()

proc currentIndent(ctx: ParseContext): int =
  ## Get current indent level from stack
  if ctx.indentStack.len > 0:
    ctx.indentStack[^1]
  else:
    0

# Forward declarations
proc parseValue(ctx: var ParseContext): ToonValue
proc parseObject(ctx: var ParseContext, baseIndent: int): ToonValue

# Path expansion helpers
proc isIdentifierSegment(s: string): bool =
  ## Check if string is a valid identifier segment for path expansion
  ## Must match ^[A-Za-z_][A-Za-z0-9_]*$
  if s.len == 0:
    return false
  if s[0] notin {'A'..'Z', 'a'..'z', '_'}:
    return false
  for i in 1..<s.len:
    if s[i] notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      return false
  true

proc shouldExpandPath(key: string, options: DecodeOptions): bool =
  ## Check if a key should be expanded (contains dots and all segments are valid)
  if options.expandPaths != peSafe:
    return false
  if '.' notin key:
    return false
  # Check all segments are valid identifier segments
  let segments = key.split('.')
  for seg in segments:
    if not isIdentifierSegment(seg):
      return false
  true

proc setNestedValue(obj: var ToonValue, key: string, val: ToonValue, options: DecodeOptions, quoted: bool = false) =
  ## Set a value in an object, expanding dotted paths if enabled
  ## If quoted is true, the key was quoted and should NOT be expanded
  if not quoted and shouldExpandPath(key, options):
    let segments = key.split('.')
    var current = obj
    for i in 0..<segments.len - 1:
      let seg = segments[i]
      if not current.objectVal.hasKey(seg):
        current.objectVal[seg] = newToonObject()
      elif current.objectVal[seg].kind != vkObject:
        # Conflict: existing non-object value at path segment
        # In strict mode this would be an error, in lenient mode use LWW
        if options.strict:
          raise newToonDecodeError("Path expansion conflict: cannot expand into non-object value", 0, 0)
        # LWW: later value wins, overwrite with object
        current.objectVal[seg] = newToonObject()
      current = current.objectVal[seg]
    current.objectVal[segments[^1]] = val
  else:
    # In strict mode with path expansion enabled, check for conflicts
    # e.g., if we previously set a.b: 1 creating {"a": {"b": 1}}, then set a: 2
    # This is a conflict because "a" is already an object created by expansion
    if options.strict and options.expandPaths != peNone:
      if obj.objectVal.hasKey(key):
        let existing = obj.objectVal[key]
        # Conflict if overwriting an object with a non-object, or vice versa
        if existing.kind == vkObject and val.kind != vkObject:
          raise newToonDecodeError("Path expansion conflict: cannot overwrite object with primitive", 0, 0)
        elif existing.kind != vkObject and val.kind == vkObject:
          raise newToonDecodeError("Path expansion conflict: cannot overwrite primitive with object", 0, 0)
        elif existing.kind == vkArray and val.kind != vkArray:
          raise newToonDecodeError("Path expansion conflict: cannot overwrite array with non-array", 0, 0)
        elif existing.kind != vkArray and val.kind == vkArray:
          raise newToonDecodeError("Path expansion conflict: cannot overwrite non-array with array", 0, 0)
    obj.objectVal[key] = val

# T035: Primitive parsing
proc hasLeadingZero(s: string): bool =
  ## Check if a numeric string has a leading zero (making it a string in TOON)
  ## Leading zeros like "05", "007", "-05" are strings, but "0", "0.5" are numbers
  if s.len == 0:
    return false
  var idx = 0
  if s[idx] == '-':
    idx += 1
  if idx >= s.len:
    return false
  if s[idx] == '0' and idx + 1 < s.len and s[idx + 1] in Digits:
    return true  # "05", "007", etc.
  return false

proc parsePrimitiveValue(s: string): ToonValue =
  ## Parse a primitive value string into ToonValue
  let trimmed = s.strip()

  if trimmed.len == 0:
    return newToonNull()

  # Check for keywords (case insensitive)
  let lower = trimmed.toLowerAscii()
  if lower == "null":
    return newToonNull()
  if lower == "true":
    return newToonBool(true)
  if lower == "false":
    return newToonBool(false)

  # Check for leading zeros - these are strings, not numbers
  if hasLeadingZero(trimmed):
    return newToonString(trimmed)

  # Try parsing as integer
  if trimmed[0] in Digits or (trimmed[0] == '-' and trimmed.len > 1 and trimmed[1] in Digits):
    var intVal: int64
    if parseBiggestInt(trimmed, intVal) == trimmed.len:
      return newToonInt(intVal)

    # Try parsing as float
    var floatVal: float
    if parseFloat(trimmed, floatVal) == trimmed.len:
      # Check if float represents a whole number (e.g., 1e6 = 1000000)
      # If so, return as integer for cleaner representation
      let asInt = int64(floatVal)
      if float(asInt) == floatVal and floatVal >= float(low(int64)) and floatVal <= float(high(int64)):
        return newToonInt(asInt)
      return newToonFloat(floatVal)

  # Default to string
  newToonString(trimmed)

# T037: Inline array parsing
proc parseInlineArray(ctx: var ParseContext, firstValue: ToonValue): ToonValue =
  ## Parse an inline array (comma, tab, or pipe separated values)
  ## firstValue is the already-parsed first element of the array
  result = newToonArray()

  # Add first value
  if not firstValue.isNil:
    result.arrayVal.add(firstValue)

  # Continue parsing remaining values
  while ctx.peek().kind == tkDelimiter:
    discard ctx.advance()  # consume delimiter

    # Get next value
    let tok = ctx.peek()
    case tok.kind
    of tkValue:
      discard ctx.advance()
      result.arrayVal.add(parsePrimitiveValue(tok.value))
    of tkQuotedString:
      discard ctx.advance()
      result.arrayVal.add(newToonString(tok.value))
    of tkNewline, tkEof:
      break
    else:
      break

# T039: Tabular array parsing
proc parseTabularArray(ctx: var ParseContext, header: Token, baseIndent: int): ToonValue =
  ## Parse a tabular array [N]{fields}
  result = newToonArray()

  let count = header.count
  let fields = header.fields
  # Active delimiter from header, default to comma
  let activeDelim = if header.delimiterChar != '\0': header.delimiterChar else: ','

  # Skip newline after header
  ctx.skipNewlines()

  # Read count rows
  var rowsRead = 0
  while rowsRead < count:
    # Check for proper indentation
    if ctx.peek().kind == tkIndent:
      let indentTok = ctx.advance()
      if indentTok.indent < baseIndent:
        break  # dedented, stop reading rows

    # Read a row of values, respecting the active delimiter
    var rowValues: seq[ToonValue] = @[]

    # Read values until end of line
    while true:
      var fullValue = ""
      var isQuoted = false

      # Collect value including non-active delimiters
      while true:
        let valTok = ctx.peek()
        case valTok.kind
        of tkValue:
          discard ctx.advance()
          fullValue.add(valTok.value)
        of tkQuotedString:
          discard ctx.advance()
          if fullValue.len == 0:
            isQuoted = true
          fullValue.add(valTok.value)
        of tkDelimiter:
          if valTok.delimiterChar == activeDelim:
            discard ctx.advance()  # consume active delimiter
            break  # end of this value
          else:
            # Not active delimiter - include in value
            discard ctx.advance()
            fullValue.add(valTok.delimiterChar)
        of tkNewline, tkEof, tkIndent:
          break
        else:
          break

      if fullValue.len > 0:
        if isQuoted:
          rowValues.add(newToonString(fullValue))
        else:
          rowValues.add(parsePrimitiveValue(fullValue))

      # Check if we hit end of line
      if ctx.peek().kind in {tkNewline, tkEof, tkIndent}:
        break

    if rowValues.len == 0:
      if rowsRead < count and ctx.options.strict:
        raise newToonDecodeError("Expected " & $count & " rows but got " & $rowsRead, ctx.peek().line, ctx.peek().col)
      break

    # Build row object or value
    if fields.len > 0:
      # Create object with field names
      let rowObj = newToonObject()
      for i, field in fields:
        if i < rowValues.len:
          rowObj.objectVal[field] = rowValues[i]
        else:
          rowObj.objectVal[field] = newToonNull()
      result.arrayVal.add(rowObj)

      # Check field count in strict mode
      if ctx.options.strict and rowValues.len != fields.len:
        raise newToonDecodeError("Row has " & $rowValues.len & " values but expected " & $fields.len, ctx.peek().line, ctx.peek().col)
    else:
      # No fields - add first value directly
      if rowValues.len > 0:
        result.arrayVal.add(rowValues[0])

    rowsRead += 1

    # Skip newline
    if ctx.peek().kind == tkNewline:
      discard ctx.advance()

  if ctx.options.strict and rowsRead < count:
    raise newToonDecodeError("Expected " & $count & " rows but got " & $rowsRead, ctx.peek().line, ctx.peek().col)

# T038: List array parsing
proc parseListArray(ctx: var ParseContext, baseIndent: int): ToonValue =
  ## Parse a list array (- item format)
  result = newToonArray()

  while true:
    ctx.skipNewlines()

    # Check for list marker at current indent
    if ctx.peek().kind == tkIndent:
      let indentTok = ctx.peek()
      if indentTok.indent < baseIndent:
        break  # dedented past list
      if indentTok.indent > baseIndent:
        # Could be continuation of previous item
        break
      discard ctx.advance()

    if ctx.peek().kind != tkListMarker:
      break

    discard ctx.advance()  # consume list marker

    # Parse the list item value
    let itemTok = ctx.peek()
    case itemTok.kind
    of tkValue:
      discard ctx.advance()
      # Check for inline array
      if ctx.peek().kind == tkDelimiter:
        result.arrayVal.add(parseInlineArray(ctx, parsePrimitiveValue(itemTok.value)))
      else:
        result.arrayVal.add(parsePrimitiveValue(itemTok.value))
    of tkQuotedString:
      discard ctx.advance()
      # Check for inline array
      if ctx.peek().kind == tkDelimiter:
        result.arrayVal.add(parseInlineArray(ctx, newToonString(itemTok.value)))
      else:
        result.arrayVal.add(newToonString(itemTok.value))
    of tkArrayHeader:
      # List item is an array: - [N]: values or - [N]:\n  - nested
      let arrHeader = ctx.advance()
      # Expect colon
      if ctx.peek().kind == tkColon:
        discard ctx.advance()

      # Empty array [0]: - just add empty array
      if arrHeader.count == 0:
        result.arrayVal.add(newToonArray())
        # Skip to end of line
        if ctx.peek().kind == tkNewline:
          discard ctx.advance()
      # Check if next is newline (nested list) or inline values
      elif ctx.peek().kind == tkNewline:
        discard ctx.advance()
        # Check for indent + list marker (nested list)
        if ctx.peek().kind == tkIndent:
          let nextIndent = ctx.peek().indent
          # Only parse nested if indent is greater than current base
          if nextIndent > baseIndent:
            discard ctx.advance()
            if ctx.peek().kind == tkListMarker:
              # Nested list array
              result.arrayVal.add(parseListArray(ctx, nextIndent))
            else:
              # Not a list - empty array
              result.arrayVal.add(newToonArray())
          else:
            # Indent is same or less - this is a sibling, not nested
            # Add empty array for this item
            result.arrayVal.add(newToonArray())
        elif ctx.peek().kind == tkListMarker:
          # List at same indent level - this is sibling not nested
          result.arrayVal.add(newToonArray())
        else:
          result.arrayVal.add(newToonArray())
      else:
        # Parse inline array values
        let innerArr = newToonArray()
        var valuesRead = 0
        while valuesRead < arrHeader.count:
          let valTok = ctx.peek()
          case valTok.kind
          of tkValue:
            discard ctx.advance()
            innerArr.arrayVal.add(parsePrimitiveValue(valTok.value))
          of tkQuotedString:
            discard ctx.advance()
            innerArr.arrayVal.add(newToonString(valTok.value))
          of tkNewline, tkEof:
            break
          else:
            break
          valuesRead += 1
          if ctx.peek().kind == tkDelimiter:
            discard ctx.advance()
        result.arrayVal.add(innerArr)
    of tkKey:
      # List item is an object
      let itemObj = parseObject(ctx, baseIndent + 2)
      result.arrayVal.add(itemObj)
    of tkNewline, tkEof:
      # Empty list item - should be empty object, not null
      result.arrayVal.add(newToonObject())
    else:
      result.arrayVal.add(newToonNull())

    # Skip newline after item
    if ctx.peek().kind == tkNewline:
      discard ctx.advance()

# T036: Object parsing with indentation tracking
proc parseObject(ctx: var ParseContext, baseIndent: int): ToonValue =
  ## Parse an object (key-value pairs)
  result = newToonObject()
  var isFirstKey = true

  while true:
    ctx.skipNewlines()

    # Check indentation
    var currentIndent = baseIndent  # Assume we're at the expected indent
    if ctx.peek().kind == tkIndent:
      currentIndent = ctx.peek().indent
      if currentIndent < baseIndent:
        break  # dedented, done with this object
      if currentIndent > baseIndent and ctx.options.strict and not isFirstKey:
        # Check for inconsistent indent (but not for first key since we're starting fresh)
        let expected = baseIndent + ctx.options.indentSize
        if currentIndent != expected:
          raise newToonDecodeError("Inconsistent indentation: expected " & $expected & " but got " & $currentIndent, ctx.peek().line, ctx.peek().col)
      discard ctx.advance()
    elif ctx.peek().kind == tkKey:
      if baseIndent > 0 and not isFirstKey:
        # No indent token but we expected some indent - we've dedented to 0
        break
      # For first key or at indent 0, we can proceed
      currentIndent = 0

    # Check for key
    if ctx.peek().kind != tkKey:
      # Check for list marker at object level
      if ctx.peek().kind == tkListMarker:
        break
      if ctx.peek().kind in {tkEof, tkNewline}:
        break
      break

    let keyTok = ctx.advance()
    let key = keyTok.value
    let keyQuoted = keyTok.quoted
    isFirstKey = false

    # Check for array header attached to key (key[N]: format)
    var arrayHeader: Token
    var hasArrayHeader = false
    if ctx.peek().kind == tkArrayHeader:
      arrayHeader = ctx.advance()
      hasArrayHeader = true

    # Expect colon
    if ctx.peek().kind != tkColon:
      raise newToonDecodeError("Expected colon after key", ctx.peek().line, ctx.peek().col)
    discard ctx.advance()

    # If we have an array header, parse as inline or tabular array
    if hasArrayHeader:
      # key[N]: format - parse inline values on same line
      if arrayHeader.count == 0:
        # Empty array
        setNestedValue(result, key, newToonArray(), ctx.options, keyQuoted)
      elif arrayHeader.fields.len > 0:
        # Tabular array with fields
        setNestedValue(result, key, parseTabularArray(ctx, arrayHeader, currentIndent), ctx.options, keyQuoted)
      else:
        # Check if next is newline followed by list markers (list format)
        if ctx.peek().kind == tkNewline:
          discard ctx.advance()  # consume newline
          # Check for indent + list marker
          if ctx.peek().kind == tkIndent:
            let nextIndent = ctx.peek().indent
            discard ctx.advance()
            if ctx.peek().kind == tkListMarker:
              # List array with count hint
              setNestedValue(result, key, parseListArray(ctx, nextIndent), ctx.options, keyQuoted)
              continue
            # Not a list - might be tabular without fields
            setNestedValue(result, key, parseTabularArray(ctx, arrayHeader, currentIndent), ctx.options, keyQuoted)
            continue
          elif ctx.peek().kind == tkListMarker:
            # List at root indent
            setNestedValue(result, key, parseListArray(ctx, 0), ctx.options, keyQuoted)
            continue
          # Fall through to tabular
          setNestedValue(result, key, parseTabularArray(ctx, arrayHeader, currentIndent), ctx.options, keyQuoted)
          continue
        # Inline array with count - read values separated by the active delimiter
        # The active delimiter is specified in the array header (e.g., [2\t] means tab delimiter)
        # If delimiter is not specified, default to comma
        let activeDelim = if arrayHeader.delimiterChar != '\0': arrayHeader.delimiterChar else: ','
        let arr = newToonArray()
        var valuesRead = 0
        while valuesRead < arrayHeader.count:
          # Collect value including non-active delimiters
          var fullValue = ""
          var isQuoted = false
          while true:
            let valTok = ctx.peek()
            case valTok.kind
            of tkValue:
              discard ctx.advance()
              fullValue.add(valTok.value)
            of tkQuotedString:
              discard ctx.advance()
              if fullValue.len == 0:
                isQuoted = true
              fullValue.add(valTok.value)
            of tkDelimiter:
              # Check if this is the active delimiter
              if valTok.delimiterChar == activeDelim:
                discard ctx.advance()  # consume the active delimiter
                break  # end of this value
              else:
                # Not the active delimiter - include it in the value
                discard ctx.advance()
                fullValue.add(valTok.delimiterChar)
            of tkNewline, tkEof:
              break
            else:
              break
          if fullValue.len > 0:
            if isQuoted:
              arr.arrayVal.add(newToonString(fullValue))
            else:
              arr.arrayVal.add(parsePrimitiveValue(fullValue))
          else:
            break
          valuesRead += 1
        setNestedValue(result, key, arr, ctx.options, keyQuoted)
      continue

    # Parse value (no array header)
    # WITHOUT an array header, commas are NOT delimiters - they're part of the string value
    # Collect all value/delimiter tokens until end of line to form the full value
    let valueTok = ctx.peek()
    case valueTok.kind
    of tkValue:
      discard ctx.advance()
      # Without array header, collect full value including any delimiters
      var fullValue = valueTok.value
      while ctx.peek().kind == tkDelimiter:
        let delimTok = ctx.advance()
        fullValue.add(delimTok.delimiterChar)
        if ctx.peek().kind == tkValue:
          let nextVal = ctx.advance()
          fullValue.add(nextVal.value)
        elif ctx.peek().kind == tkQuotedString:
          # Quoted string after delimiter - might be intentional array-like syntax
          # but without header, treat as string
          let nextVal = ctx.advance()
          fullValue.add(nextVal.value)
        else:
          break
      setNestedValue(result, key, parsePrimitiveValue(fullValue), ctx.options, keyQuoted)
    of tkQuotedString:
      discard ctx.advance()
      # Quoted string - always treat as string, but check for trailing content
      var fullValue = valueTok.value
      while ctx.peek().kind == tkDelimiter:
        let delimTok = ctx.advance()
        fullValue.add(delimTok.delimiterChar)
        if ctx.peek().kind == tkValue:
          let nextVal = ctx.advance()
          fullValue.add(nextVal.value)
        elif ctx.peek().kind == tkQuotedString:
          let nextVal = ctx.advance()
          fullValue.add(nextVal.value)
        else:
          break
      setNestedValue(result, key, newToonString(fullValue), ctx.options, keyQuoted)
    of tkArrayHeader:
      discard ctx.advance()
      setNestedValue(result, key, parseTabularArray(ctx, valueTok, currentIndent), ctx.options, keyQuoted)
    of tkNewline:
      # Check for nested object or list
      discard ctx.advance()

      # Look ahead for indent
      if ctx.peek().kind == tkIndent:
        let nextIndent = ctx.peek().indent
        discard ctx.advance()

        if ctx.peek().kind == tkListMarker:
          # List array
          setNestedValue(result, key, parseListArray(ctx, nextIndent), ctx.options, keyQuoted)
        elif ctx.peek().kind == tkKey:
          # Nested object
          setNestedValue(result, key, parseObject(ctx, nextIndent), ctx.options, keyQuoted)
        else:
          setNestedValue(result, key, newToonNull(), ctx.options, keyQuoted)
      elif ctx.peek().kind == tkListMarker:
        # List at base indent
        setNestedValue(result, key, parseListArray(ctx, 0), ctx.options, keyQuoted)
      else:
        # key: with nothing after - empty object per TOON spec
        setNestedValue(result, key, newToonObject(), ctx.options, keyQuoted)
    of tkEof:
      # key: at end of file - empty object per TOON spec
      setNestedValue(result, key, newToonObject(), ctx.options, keyQuoted)
    else:
      setNestedValue(result, key, newToonNull(), ctx.options, keyQuoted)

proc parseValue(ctx: var ParseContext): ToonValue =
  ## Parse any TOON value
  let tok = ctx.peek()
  case tok.kind
  of tkKey:
    parseObject(ctx, 0)
  of tkValue:
    discard ctx.advance()
    parsePrimitiveValue(tok.value)
  of tkQuotedString:
    discard ctx.advance()
    newToonString(tok.value)
  of tkArrayHeader:
    discard ctx.advance()
    parseTabularArray(ctx, tok, 0)
  of tkListMarker:
    parseListArray(ctx, 0)
  else:
    newToonObject()

# Public API
proc parseToon*(input: string, options: DecodeOptions = defaultDecodeOptions): ToonValue =
  ## Parse TOON format string into ToonValue
  var ctx = newParseContext(input, options)
  ctx.skipNewlines()

  if ctx.peek().kind == tkEof:
    return newToonObject()

  # Check if first token is a primitive (not a key)
  let firstTok = ctx.peek()
  case firstTok.kind
  of tkValue:
    # Could be a primitive at root or a key
    # If followed by colon, it's a key - parse as object
    # Otherwise it's a primitive value
    discard ctx.advance()
    ctx.skipWhitespaceInLine()
    if ctx.peek().kind == tkColon:
      # It's actually a key - we need to reparse
      var ctx2 = newParseContext(input, options)
      ctx2.skipNewlines()
      return parseObject(ctx2, 0)
    # It's a standalone primitive
    return parsePrimitiveValue(firstTok.value)
  of tkQuotedString:
    # Quoted string - check if it's a key or value
    discard ctx.advance()
    ctx.skipWhitespaceInLine()
    if ctx.peek().kind == tkColon:
      # It's a key - reparse as object
      var ctx2 = newParseContext(input, options)
      ctx2.skipNewlines()
      return parseObject(ctx2, 0)
    if ctx.peek().kind == tkArrayHeader:
      # It's a key with array header - reparse as object
      var ctx2 = newParseContext(input, options)
      ctx2.skipNewlines()
      return parseObject(ctx2, 0)
    # It's a standalone string
    return newToonString(firstTok.value)
  of tkKey:
    parseObject(ctx, 0)
  of tkListMarker:
    parseListArray(ctx, 0)
  of tkArrayHeader:
    let arrHeader = ctx.advance()
    # Check for colon
    if ctx.peek().kind == tkColon:
      discard ctx.advance()
      # Check if next is newline (multi-line) or values (inline)
      if ctx.peek().kind == tkNewline:
        discard ctx.advance()
        # Check for indent + list marker
        if ctx.peek().kind == tkIndent:
          let nextIndent = ctx.peek().indent
          discard ctx.advance()
          if ctx.peek().kind == tkListMarker:
            return parseListArray(ctx, nextIndent)
        # Tabular format
        return parseTabularArray(ctx, arrHeader, 0)
      # Inline values
      let arr = newToonArray()
      var valuesRead = 0
      while valuesRead < arrHeader.count:
        let valTok = ctx.peek()
        case valTok.kind
        of tkValue:
          discard ctx.advance()
          arr.arrayVal.add(parsePrimitiveValue(valTok.value))
        of tkQuotedString:
          discard ctx.advance()
          arr.arrayVal.add(newToonString(valTok.value))
        of tkNewline, tkEof:
          break
        else:
          break
        valuesRead += 1
        if ctx.peek().kind == tkDelimiter:
          discard ctx.advance()
      return arr
    # No colon - tabular
    parseTabularArray(ctx, arrHeader, 0)
  else:
    parseObject(ctx, 0)
