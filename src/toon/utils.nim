## TOON Format Utilities
## String processing and escape sequence handling

import std/[strutils, parseutils]
import ./types

# T016: Escape/unescape utilities

const
  EscapeChars* = {'\\', '"', '\n', '\r', '\t'}
  SpecialChars* = {'\n', '\r', '\t', '\\', '"'}

proc escapeString*(s: string): string =
  ## Escape special characters in a string for TOON output
  ## Only these 5 escape sequences are valid: \\ \" \n \r \t
  result = newStringOfCap(s.len)
  for c in s:
    case c
    of '\\': result.add("\\\\")
    of '"': result.add("\\\"")
    of '\n': result.add("\\n")
    of '\r': result.add("\\r")
    of '\t': result.add("\\t")
    else: result.add(c)

proc unescapeString*(s: string): string =
  ## Unescape a TOON string (process escape sequences)
  ## Raises ToonDecodeError for invalid escape sequences
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    if s[i] == '\\':
      if i + 1 >= s.len:
        raise newToonDecodeError("Unterminated escape sequence at end of string")
      case s[i + 1]
      of '\\': result.add('\\')
      of '"': result.add('"')
      of 'n': result.add('\n')
      of 'r': result.add('\r')
      of 't': result.add('\t')
      else:
        raise newToonDecodeError("Invalid escape sequence: \\" & s[i + 1])
      i += 2
    else:
      result.add(s[i])
      i += 1

proc hasEscapableChars*(s: string): bool =
  ## Check if string contains characters that need escaping
  for c in s:
    if c in SpecialChars:
      return true
  false

# T017: String quoting detection

proc needsQuoting*(s: string, delimiter: Delimiter = dlComma): bool =
  ## Determine if a string value needs to be quoted in TOON output
  ## A string must be quoted if it:
  ## - Is empty
  ## - Has leading/trailing whitespace
  ## - Equals true, false, or null
  ## - Matches numeric patterns or has forbidden leading zeros
  ## - Contains: colon, quote, backslash, brackets, braces, control chars
  ## - Contains the active delimiter
  ## - Starts with hyphen (-)

  if s.len == 0:
    return true

  # Leading/trailing whitespace
  if s[0] in Whitespace or s[^1] in Whitespace:
    return true

  # Reserved keywords
  let lower = s.toLowerAscii()
  if lower in ["true", "false", "null"]:
    return true

  # Check if it looks like a number
  if s.len > 0 and (s[0] in Digits or (s[0] == '-' and s.len > 1 and s[1] in Digits)):
    var num: float
    if parseFloat(s, num) == s.len:
      return true
    # Leading zeros (like "05")
    if s[0] == '0' and s.len > 1 and s[1] in Digits:
      return true
    if s.len > 1 and s[0] == '-' and s[1] == '0' and s.len > 2 and s[2] in Digits:
      return true

  # Starts with hyphen (list marker conflict)
  if s[0] == '-':
    return true

  # Check for special characters
  let delimChar = case delimiter
    of dlComma: ','
    of dlTab: '\t'
    of dlPipe: '|'

  for c in s:
    if c in {':',  '"', '\\', '[', ']', '{', '}', delimChar}:
      return true
    # Control characters
    if ord(c) < 32:
      return true

  false

proc quoteString*(s: string): string =
  ## Quote and escape a string for TOON output
  result = "\""
  result.add(escapeString(s))
  result.add("\"")

proc isValidIdentifier*(s: string): bool =
  ## Check if string is a valid TOON identifier (for key folding)
  ## Pattern: ^[A-Za-z_][A-Za-z0-9_]*$
  if s.len == 0:
    return false
  if s[0] notin {'A'..'Z', 'a'..'z', '_'}:
    return false
  for i in 1..<s.len:
    if s[i] notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      return false
  true

proc parsePrimitive*(s: string): (ToonValueKind, string) =
  ## Parse a primitive value and determine its type
  ## Returns (kind, value) where value is the processed string
  let trimmed = s.strip()

  if trimmed.len == 0:
    return (vkString, "")

  # Check for keywords
  let lower = trimmed.toLowerAscii()
  if lower == "null":
    return (vkNull, "")
  if lower == "true":
    return (vkBool, "true")
  if lower == "false":
    return (vkBool, "false")

  # Try to parse as number
  if trimmed[0] in Digits or (trimmed[0] == '-' and trimmed.len > 1):
    # Check for integer
    var intVal: int64
    if parseBiggestInt(trimmed, intVal) == trimmed.len:
      return (vkInt, trimmed)

    # Check for float
    var floatVal: float
    if parseFloat(trimmed, floatVal) == trimmed.len:
      return (vkFloat, trimmed)

  # Default to string
  return (vkString, trimmed)

proc splitDelimited*(s: string, delimiter: Delimiter): seq[string] =
  ## Split a string by the given delimiter, respecting quotes
  result = @[]
  let delimChar = case delimiter
    of dlComma: ','
    of dlTab: '\t'
    of dlPipe: '|'

  var current = ""
  var inQuotes = false
  var i = 0

  while i < s.len:
    let c = s[i]
    if c == '"' and (i == 0 or s[i-1] != '\\'):
      inQuotes = not inQuotes
      current.add(c)
    elif c == delimChar and not inQuotes:
      result.add(current.strip())
      current = ""
    else:
      current.add(c)
    i += 1

  result.add(current.strip())

proc detectIndentSize*(lines: seq[string]): int =
  ## Detect the indentation size from a sequence of lines
  ## Returns 2 as default if no indentation found
  result = 2
  for line in lines:
    if line.len > 0 and line[0] == ' ':
      var spaces = 0
      for c in line:
        if c == ' ':
          spaces += 1
        else:
          break
      if spaces > 0:
        if result == 2 or spaces < result:
          result = spaces
        return

proc countIndent*(line: string): int =
  ## Count leading spaces in a line
  result = 0
  for c in line:
    if c == ' ':
      result += 1
    else:
      break

proc getIndentLevel*(line: string, indentSize: int): int =
  ## Get the indentation level of a line
  let spaces = countIndent(line)
  spaces div indentSize

proc makeIndent*(level: int, indentSize: int = 2): string =
  ## Create an indentation string
  repeat(' ', level * indentSize)
