## TOON Format Scanner
## Tokenizer for TOON format input

import std/[strutils]
import ./types

# T027: Token and TokenKind types
type
  TokenKind* = enum
    ## Types of tokens in TOON format
    tkEof           ## End of file
    tkNewline       ## Line break
    tkIndent        ## Indentation change (start of line)
    tkKey           ## Object key
    tkColon         ## Key-value separator
    tkValue         ## Unquoted value
    tkQuotedString  ## Quoted string "..."
    tkListMarker    ## List item marker -
    tkArrayHeader   ## Array header [N] or [N]{fields}
    tkDelimiter     ## Array delimiter (, \t |)

  Token* = object
    ## A single token from the input
    kind*: TokenKind
    value*: string         ## String content (for keys, values, strings)
    line*: int            ## 1-based line number
    col*: int             ## 1-based column number
    indent*: int          ## Indentation level (for tkIndent)
    count*: int           ## Array count (for tkArrayHeader)
    fields*: seq[string]  ## Field names (for tkArrayHeader)
    delimiterChar*: char  ## Delimiter character (for tkDelimiter or tkArrayHeader)
    quoted*: bool         ## True if key was quoted (for tkKey)

  Scanner* = object
    ## TOON format tokenizer
    input: string
    pos: int
    line: int
    col: int
    atLineStart: bool
    pendingListMarker: bool   ## True if we need to emit a list marker next
    lastIndent: int           ## Last indent level returned
    expectingValue: bool      ## True after colon - reading value, not key

# T028: Scanner implementation
proc newScanner*(input: string): Scanner =
  ## Create a new scanner for the given input
  Scanner(
    input: input,
    pos: 0,
    line: 1,
    col: 1,
    atLineStart: true,
    pendingListMarker: false,
    lastIndent: 0,
    expectingValue: false
  )

proc peek(s: Scanner, offset: int = 0): char =
  ## Peek at character at current position + offset
  let pos = s.pos + offset
  if pos >= s.input.len:
    '\0'
  else:
    s.input[pos]

proc advance(s: var Scanner): char =
  ## Advance one character and return it
  if s.pos >= s.input.len:
    return '\0'
  result = s.input[s.pos]
  s.pos += 1
  if result == '\n':
    s.line += 1
    s.col = 1
    s.atLineStart = true
  else:
    s.col += 1

proc skipWhitespaceInLine(s: var Scanner) =
  ## Skip spaces only (tabs may be delimiters)
  while s.peek() == ' ':
    discard s.advance()

proc readIndent(s: var Scanner): int =
  ## Read leading whitespace and return indent level
  result = 0
  while s.peek() == ' ':
    discard s.advance()
    result += 1

proc readQuotedString(s: var Scanner): string =
  ## Read a quoted string, handling escapes
  ## Assumes opening quote already consumed
  result = ""
  while true:
    let c = s.advance()
    case c
    of '\0':
      raise newToonDecodeError("Unterminated quoted string", s.line, s.col)
    of '"':
      return  # End of string
    of '\\':
      let next = s.advance()
      case next
      of '\\': result.add('\\')
      of '"': result.add('"')
      of 'n': result.add('\n')
      of 'r': result.add('\r')
      of 't': result.add('\t')
      of '\0':
        raise newToonDecodeError("Unterminated escape sequence", s.line, s.col)
      else:
        raise newToonDecodeError("Invalid escape sequence: \\" & next, s.line, s.col)
    else:
      result.add(c)

proc readArrayHeader(s: var Scanner): (int, seq[string], char) =
  ## Read array header [N], [N⟨delim⟩], or [N]{field1,field2,...}
  ## Assumes opening [ already consumed
  ## Returns (count, fields, delimiterChar) - delimiterChar is '\0' if not specified
  var countStr = ""
  while s.peek() in Digits:
    countStr.add(s.advance())

  if countStr.len == 0:
    raise newToonDecodeError("Expected number in array header", s.line, s.col)

  var delimiterChar: char = '\0'

  # Check for optional delimiter specification before ]
  let nextChar = s.peek()
  if nextChar notin {']', '{'}:
    # Could be a delimiter character (tab, pipe, comma)
    if nextChar in {'\t', '|', ','}:
      delimiterChar = s.advance()

  if s.peek() != ']':
    raise newToonDecodeError("Expected ] in array header", s.line, s.col)
  discard s.advance()  # consume ]

  let count = parseInt(countStr)
  var fields: seq[string] = @[]

  # Check for optional {fields}
  if s.peek() == '{':
    discard s.advance()  # consume {
    var currentField = ""
    while true:
      let c = s.peek()
      case c
      of '}':
        discard s.advance()
        if currentField.len > 0:
          fields.add(currentField.strip())
        break
      of '"':
        # Quoted field name - read until closing quote
        discard s.advance()  # consume opening "
        var quotedField = ""
        while s.peek() != '"' and s.peek() != '\0':
          if s.peek() == '\\' and s.peek(1) == '"':
            discard s.advance()  # skip backslash
            quotedField.add(s.advance())  # add quote
          else:
            quotedField.add(s.advance())
        if s.peek() == '"':
          discard s.advance()  # consume closing "
        currentField = quotedField
      of ',', '\t', '|':
        # Use the active delimiter from header, or default to comma
        if delimiterChar == '\0' or c == delimiterChar or c == ',':
          discard s.advance()
          fields.add(currentField.strip())
          currentField = ""
        else:
          currentField.add(s.advance())
      of '\0':
        raise newToonDecodeError("Unterminated field list in array header", s.line, s.col)
      else:
        currentField.add(s.advance())

  return (count, fields, delimiterChar)

proc readKey(s: var Scanner): string =
  ## Read an unquoted key (up to colon, but stops before [ for array headers)
  result = ""
  while true:
    let c = s.peek()
    case c
    of ':', '\n', '\0', '[':
      break
    else:
      result.add(s.advance())
  result = result.strip()

proc readValue(s: var Scanner): string =
  ## Read a value until end of line or delimiter
  result = ""
  while true:
    let c = s.peek()
    case c
    of '\n', '\0':
      break
    of ',', '|':
      # Could be delimiter - stop here
      break
    of '\t':
      # Check if this might be a tab delimiter
      break
    else:
      result.add(s.advance())
  result = result.strip()

# T028-T032: Main tokenization
proc nextToken*(s: var Scanner): Token =
  ## Get the next token from input

  # Check for pending list marker (after returning indent)
  if s.pendingListMarker:
    s.pendingListMarker = false
    return Token(kind: tkListMarker, line: s.line, col: s.lastIndent + 1)

  # At end of input
  if s.pos >= s.input.len:
    return Token(kind: tkEof, line: s.line, col: s.col)

  # At start of line - handle indentation
  if s.atLineStart:
    s.atLineStart = false
    s.expectingValue = false  # Reset at line start

    # Check for newline
    if s.peek() == '\n':
      discard s.advance()
      s.atLineStart = true
      return Token(kind: tkNewline, line: s.line - 1, col: 1)

    # Read indentation
    let indent = s.readIndent()
    s.lastIndent = indent

    # Check for list marker
    if s.peek() == '-' and (s.peek(1) == ' ' or s.peek(1) == '\n' or s.peek(1) == '\0'):
      discard s.advance()  # consume -
      s.skipWhitespaceInLine()
      if indent > 0:
        # Return indent first, set flag to return list marker next
        s.pendingListMarker = true
        return Token(kind: tkIndent, indent: indent, line: s.line, col: 1)
      return Token(kind: tkListMarker, line: s.line, col: s.col - 1)

    if indent > 0:
      return Token(kind: tkIndent, indent: indent, line: s.line, col: 1)

  s.skipWhitespaceInLine()

  # Check for end of input after whitespace
  if s.pos >= s.input.len:
    return Token(kind: tkEof, line: s.line, col: s.col)

  let startLine = s.line
  let startCol = s.col
  let c = s.peek()

  case c
  of '\n':
    discard s.advance()
    s.atLineStart = true
    return Token(kind: tkNewline, line: startLine, col: startCol)

  of '-':
    if s.peek(1) == ' ' or s.peek(1) == '\n' or s.peek(1) == '\0':
      discard s.advance()
      s.skipWhitespaceInLine()
      return Token(kind: tkListMarker, line: startLine, col: startCol)
    # Otherwise treat as part of value - fall through to read value
    var value = ""
    while true:
      let ch = s.peek()
      case ch
      of ':', '\n', '\0', ',', '|', '\t':
        break
      else:
        value.add(s.advance())
    value = value.strip()
    s.skipWhitespaceInLine()
    if s.peek() == ':':
      return Token(kind: tkKey, value: value, line: startLine, col: startCol)
    return Token(kind: tkValue, value: value, line: startLine, col: startCol)

  of ':':
    discard s.advance()
    s.expectingValue = true
    return Token(kind: tkColon, line: startLine, col: startCol)

  of '"':
    discard s.advance()  # consume opening quote
    let value = s.readQuotedString()
    # Check if this is a key (followed by colon or array header)
    s.skipWhitespaceInLine()
    if s.peek() == ':' or s.peek() == '[':
      return Token(kind: tkKey, value: value, quoted: true, line: startLine, col: startCol)
    return Token(kind: tkQuotedString, value: value, line: startLine, col: startCol)

  of '[':
    discard s.advance()
    let (count, fields, delimChar) = s.readArrayHeader()
    return Token(kind: tkArrayHeader, count: count, fields: fields, delimiterChar: delimChar, line: startLine, col: startCol)

  of ',':
    discard s.advance()
    return Token(kind: tkDelimiter, delimiterChar: ',', line: startLine, col: startCol)

  of '|':
    discard s.advance()
    return Token(kind: tkDelimiter, delimiterChar: '|', line: startLine, col: startCol)

  of '\t':
    discard s.advance()
    return Token(kind: tkDelimiter, delimiterChar: '\t', line: startLine, col: startCol)

  else:
    # Read key or value
    var value = ""
    if s.expectingValue:
      # Reading a value - include colons, stop at newline/delimiter
      while true:
        let ch = s.peek()
        case ch
        of '\n', '\0', ',', '|', '\t':
          break
        else:
          value.add(s.advance())
      value = value.strip()
      s.expectingValue = false
      return Token(kind: tkValue, value: value, line: startLine, col: startCol)
    else:
      # Reading a key - stop at colon or [
      while true:
        let ch = s.peek()
        case ch
        of ':', '\n', '\0', ',', '|', '\t', '[':
          break
        else:
          value.add(s.advance())

      value = value.strip()

      # Check if followed by [ (array header attached to key)
      s.skipWhitespaceInLine()
      if s.peek() == '[':
        # Return key first, array header will be read on next call
        return Token(kind: tkKey, value: value, line: startLine, col: startCol)

      # Check if followed by colon (it's a key)
      if s.peek() == ':':
        return Token(kind: tkKey, value: value, line: startLine, col: startCol)

      # Otherwise it's a value
      return Token(kind: tkValue, value: value, line: startLine, col: startCol)
