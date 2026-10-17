## TOON decoder, specification 4.4.
##
## Lines are prepared once (§12: byte-order mark, CR, trailing spaces, comment
## lines, blank lines, indentation), then read top-down: each scope reads the
## lines at its content depth and leaves the first line it does not own to the
## scope above it.

import std/[strutils, tables, unicode, math, parseutils]
import ./types, ./text

type
  Line = object
    num: int          ## 1-based line number in the input
    depth: int
    content: string   ## the line after its indentation
    blank: bool

  Field = object
    name: string
    children: seq[Field]   ## a nested field group when not empty (§9.3)

  Header = object
    key: string
    hasKey: bool
    length: int            ## -1 when the declared length is unrepresentable
    keyed: bool            ## `[N:]`, a keyed tabular object (§9.5)
    delim: char
    hasFields: bool
    fields: seq[Field]
    rest: string           ## after the colon, trimmed of spaces

  LineKind = enum
    lkHeader, lkKeyValue, lkScalar

  Decoder = object
    strict: bool
    lines: seq[Line]
    pos: int               ## the next line to read
    spans: int             ## header spans open around the reading position

proc fail(line: Line, msg: string) {.noreturn, raises: [ToonDecodeError].} =
  raise newToonDecodeError("line " & $line.num & ": " & msg, line.num)

# --- Lexical helpers ---------------------------------------------------------

proc firstUnquoted(s: string, chars: set[char], start = 0): int {.raises: [].} =
  ## The first position of one of `chars` outside a quoted span (§5.2), or -1.
  var i = start
  var inQuotes = false
  while i < s.len:
    let c = s[i]
    if inQuotes:
      if c == '\\': inc i
      elif c == '"': inQuotes = false
    elif c == '"': inQuotes = true
    elif c in chars: return i
    inc i
  -1

proc splitUnquoted(s: string, delim: char): seq[string] {.raises: [].} =
  ## Splits on unquoted `delim`, keeping empty tokens (§11.2).
  var start = 0
  while true:
    let at = firstUnquoted(s, {delim}, start)
    if at < 0:
      result.add s[start .. ^1]
      return
    result.add s[start ..< at]
    start = at + 1

proc trimSpaces(s: string): string {.raises: [].} =
  s.strip(chars = {Space})

proc quotedAt(line: Line, s: string, start: int, endAt: var int): string
    {.raises: [ToonDecodeError].} =
  ## The quoted token beginning at `s[start]`, unescaped by the decoder column
  ## of §7.1; `endAt` is the position after its closing quote.
  var i = start + 1
  while i < s.len:
    let c = s[i]
    if c == '"':
      endAt = i + 1
      return
    if c != '\\':
      result.add c
      inc i
      continue
    if i + 1 >= s.len: fail(line, "unterminated string")
    case s[i + 1]
    of '\\': result.add '\\'
    of '"': result.add '"'
    of 'n': result.add '\n'
    of 'r': result.add '\r'
    of 't': result.add '\t'
    of 'u':
      if i + 5 >= s.len: fail(line, "\\u needs four hex digits")
      var code = 0
      for k in i + 2 .. i + 5:
        let h = s[k]
        let digit =
          if h in {'0' .. '9'}: ord(h) - ord('0')
          elif h in {'a' .. 'f'}: ord(h) - ord('a') + 10
          elif h in {'A' .. 'F'}: ord(h) - ord('A') + 10
          else: fail(line, "\\u needs four hex digits")
        code = code * 16 + digit
      if code >= 0xD800 and code <= 0xDFFF:
        fail(line, "a \\u escape names a surrogate")
      result.add $Rune(code)
      i += 6
      continue
    else: fail(line, "invalid escape \\" & s[i + 1])
    i += 2
  fail(line, "unterminated string")

proc wholeQuoted(line: Line, token: string): string {.raises: [ToonDecodeError].} =
  ## A token that begins with `"` must end with its closing quote (§7.4).
  var endAt = 0
  result = quotedAt(line, token, 0, endAt)
  if endAt != token.len:
    fail(line, "characters after a closing quote")

proc numberOf(line: Line, t: string): ToonValue {.raises: [ToonDecodeError].} =
  ## A token matching the number grammar of §4. Integers within int64 stay
  ## integers; others become float64, and a magnitude beyond float64 errors.
  if '.' notin t and 'e' notin t and 'E' notin t:
    let negative = t[0] == '-'
    var magnitude: uint64 = 0
    var fits = true
    for c in t:
      if c == '-': continue
      let digit = uint64(ord(c) - ord('0'))
      if magnitude > (high(uint64) - digit) div 10:
        fits = false
        break
      magnitude = magnitude * 10 + digit
    if fits:
      if not negative and magnitude <= uint64(high(int64)):
        return newToonInt(int64(magnitude))
      if negative and magnitude <= uint64(high(int64)) + 1:
        return newToonInt(if magnitude == 0: 0'i64
                          else: -int64(magnitude - 1) - 1)
  var f: float
  discard parseFloat(t, f)
  if f.classify in {fcInf, fcNegInf}:
    fail(line, "number beyond the float64 range: " & t)
  newToonFloat(f)

proc primitiveOf(line: Line, token: string): ToonValue {.raises: [ToonDecodeError].} =
  ## A primitive token (§4).
  let t = trimSpaces(token)
  if t.len > 0 and t[0] == '"':
    return newToonString(wholeQuoted(line, t))
  case t
  of "true": newToonBool(true)
  of "false": newToonBool(false)
  of "null": newToonNull()
  else:
    if isNumberToken(t): numberOf(line, t) else: newToonString(t)

proc keyOf(line: Line, token: string): string {.raises: [ToonDecodeError].} =
  ## A key token before a colon (§7.4); an empty token is the empty key.
  let t = trimSpaces(token)
  if t.len > 0 and t[0] == '"': wholeQuoted(line, t) else: t

proc classify(s: string): LineKind {.raises: [].} =
  ## Classes 4–6 of §5.2.
  let colon = firstUnquoted(s, {':'})
  if colon < 0: return lkScalar
  let bracket = firstUnquoted(s, {'['})
  if bracket >= 0 and bracket < colon: lkHeader else: lkKeyValue

proc isListItem(s: string): bool {.raises: [].} =
  s == "-" or s.startsWith("- ")

# --- Headers (§6) ------------------------------------------------------------

proc fieldList(line: Line, s: string, i: var int, delim: char, strict: bool):
    seq[Field] {.raises: [ToonDecodeError].} =
  ## The field list opening at `s[i] == '{'`; `i` ends after its `}`.
  inc i
  var seen: seq[string]
  while true:
    while i < s.len and s[i] == Space: inc i
    var name: string
    if i < s.len and s[i] == '"':
      var endAt = 0
      name = quotedAt(line, s, i, endAt)
      i = endAt
      if i >= s.len or s[i] != '{':
        while i < s.len and s[i] == Space: inc i
    else:
      let start = i
      while i < s.len and s[i] notin {delim, '{', '}'}:
        if s[i] in {',', '|', '\t'}:
          fail(line, "a field list holds a delimiter its bracket segment does not declare")
        if s[i] == '"':
          # A quoted span inside a name runs to its closing quote (§5.2).
          inc i
          while i < s.len and s[i] != '"':
            if s[i] == '\\': inc i
            inc i
          if i >= s.len: break
        inc i
      let raw = s[start ..< i]
      if i < s.len and s[i] == '{' and raw.len > 0 and raw[^1] in {' ', '\t'}:
        fail(line, "whitespace between a field name and its nested field group")
      name = trimSpaces(raw)
      if name.len == 0:
        fail(line, "an empty field entry or a nameless nested group")
    var children: seq[Field]
    if i < s.len and s[i] == '{':
      children = fieldList(line, s, i, delim, strict)
    if strict and name in seen:
      fail(line, "field name repeated in one field list: " & name)
    seen.add name
    result.add Field(name: name, children: children)
    while i < s.len and s[i] == Space: inc i
    if i >= s.len: fail(line, "unmatched brace in a field list")
    if s[i] == delim:
      inc i
    elif s[i] == '}':
      inc i
      return
    else:
      fail(line, "malformed field list")

proc headerOf(line: Line, s: string, strict: bool): Header {.raises: [ToonDecodeError].} =
  ## An array-header line (§5.2 class 4), which must match §6.
  let bracket = firstUnquoted(s, {'['})
  let keyText = s[0 ..< bracket]
  if keyText.len > 0:
    if keyText[^1] in {' ', '\t'}:
      fail(line, "whitespace between a key and its bracket segment")
    result.key = if keyText[0] == '"': wholeQuoted(line, keyText) else: keyText
    result.hasKey = true
  var i = bracket + 1
  let start = i
  while i < s.len and s[i] in {'0' .. '9'}: inc i
  let digits = s[start ..< i]
  if digits.len == 0 or (digits.len > 1 and digits[0] == '0'):
    fail(line, "malformed length in a bracket segment")
  result.length = 0
  for c in digits:
    if result.length > (high(int) - 9) div 10:
      result.length = -1
      break
    result.length = result.length * 10 + (ord(c) - ord('0'))
  if i < s.len and s[i] == ':':
    result.keyed = true
    inc i
  result.delim = ','
  if i < s.len and s[i] in {'\t', '|'}:
    result.delim = s[i]
    inc i
  if i >= s.len or s[i] != ']':
    fail(line, "malformed bracket segment")
  inc i
  if i < s.len and s[i] == '{':
    result.fields = fieldList(line, s, i, result.delim, strict)
    result.hasFields = true
  if i >= s.len or s[i] != ':':
    fail(line, "a header needs a colon right after its bracket segment or field list")
  result.rest = trimSpaces(s[i + 1 .. ^1])
  if result.keyed and not result.hasFields:
    fail(line, "a keyed header needs a field list")
  if result.hasFields and result.rest.len > 0:
    fail(line, "content after the colon of a header with a field list")

proc leafCount(fields: seq[Field]): int {.raises: [].} =
  for f in fields:
    result += (if f.children.len > 0: leafCount(f.children) else: 1)

# --- Line preparation (§12) --------------------------------------------------

proc prepare(input: string, opts: DecodeOptions): seq[Line] {.raises: [ToonDecodeError].} =
  if not isWellFormedUtf8(input):
    raise newToonDecodeError("input is not well-formed UTF-8")
  let text = if input.startsWith(Bom): input[Bom.len .. ^1] else: input
  var num = 0
  for raw in text.split('\n'):
    inc num
    var s = raw
    if s.endsWith('\r'): s.setLen(s.len - 1)
    s = s.strip(leading = false, chars = {Space})
    var k = 0
    while k < s.len and s[k] == Space: inc k
    if k < s.len and s[k] == '#': continue
    if s.len == 0:
      result.add Line(num: num, blank: true)
      continue
    var spaces, tabs, j = 0
    while j < s.len and s[j] in {' ', '\t'}:
      if s[j] == ' ': inc spaces else: inc tabs
      inc j
    let line = Line(num: num, content: s[j .. ^1])
    if line.content.len == 0:
      if opts.strict: fail(line, "a line of only tabs and spaces")
      result.add Line(num: num, blank: true)
      continue
    var depth: int
    if opts.strict:
      if tabs > 0: fail(line, "a tab in indentation")
      if spaces mod opts.indentSize != 0:
        fail(line, "indentation is not a multiple of " & $opts.indentSize & " spaces")
      depth = spaces div opts.indentSize
    else:
      depth = tabs + spaces div opts.indentSize
    var prepared = line
    prepared.depth = depth
    result.add prepared

# --- Reading -----------------------------------------------------------------

proc peek(d: Decoder): int {.raises: [].} =
  ## The index of the next non-blank line, or -1.
  var i = d.pos
  while i < d.lines.len and d.lines[i].blank: inc i
  if i < d.lines.len: i else: -1

proc take(d: var Decoder, i: int): Line {.raises: [ToonDecodeError].} =
  ## Reads line `i`; a blank line before it inside a header span errors in
  ## strict mode (§12) and is ignored otherwise (§14.4 #4).
  if d.strict and d.spans > 0:
    for k in d.pos ..< i:
      fail(d.lines[k], "a blank line inside an array or table")
  d.pos = i + 1
  d.lines[i]

proc contentDepth(d: Decoder, c: int): tuple[depth, floor: int] {.raises: [ToonDecodeError].} =
  ## The content depth of a nested scope expected at `c`: -1 when the scope is
  ## empty. A deeper first line is a depth jump (§8): an error in strict mode,
  ## the new content depth otherwise (§14.4 #5), with `floor` the depth below
  ## which the scope ends.
  let i = d.peek()
  if i < 0 or d.lines[i].depth < c: return (-1, c)
  let m = d.lines[i].depth
  if m > c and d.strict:
    fail(d.lines[i], "indented deeper than its scope (expected depth " & $c & ")")
  (m, c)

proc atDepth(line: Line, depth, floor: int) {.raises: [ToonDecodeError].} =
  ## A line read inside a scope whose content stands at `depth`.
  if line.depth > depth:
    fail(line, "indented deeper than its scope")
  if line.depth < depth:
    fail(line, "shallower than the first line of its scope")

proc checkCount(line: Line, declared, actual: int, strict: bool)
    {.raises: [ToonDecodeError].} =
  if strict and declared != actual:
    fail(line, "declared length " & (if declared < 0: "beyond range" else: $declared) &
               " but found " & $actual)

proc setField(line: Line, obj: ToonValue, key: string, value: ToonValue, strict: bool)
    {.raises: [ToonDecodeError].} =
  ## Duplicate keys error in strict mode (§14.3) and otherwise keep the first
  ## position with the last value (§14.4 #2).
  if strict and obj.objectVal.hasKey(key):
    fail(line, "duplicate key: " & key)
  obj.objectVal[key] = value

proc fillRow(line: Line, fields: seq[Field], cells: seq[string], next: var int,
             obj: ToonValue) {.raises: [ToonDecodeError].} =
  for f in fields:
    if f.children.len > 0:
      let sub = newToonObject()
      fillRow(line, f.children, cells, next, sub)
      obj.objectVal[f.name] = sub
    else:
      obj.objectVal[f.name] = primitiveOf(line, cells[next])
      inc next

proc rowObject(line: Line, h: Header, cells: seq[string]): ToonValue
    {.raises: [ToonDecodeError].} =
  if cells.len != leafCount(h.fields):
    fail(line, "row has " & $cells.len & " cells but the header declares " &
               $leafCount(h.fields) & " fields")
  result = newToonObject()
  var next = 0
  fillRow(line, h.fields, cells, next, result)

proc objectBody(d: var Decoder, obj: ToonValue, depth, floor: int)
    {.raises: [ToonDecodeError].}
proc listItem(d: var Decoder, line: Line, content: string, depth: int): ToonValue
    {.raises: [ToonDecodeError].}

proc tabularRows(d: var Decoder, h: Header, rowDepth: int, at: Line): ToonValue
    {.raises: [ToonDecodeError].} =
  result = newToonArray()
  let (depth, floor) = d.contentDepth(rowDepth)
  if depth >= 0:
    while true:
      let i = d.peek()
      if i < 0 or d.lines[i].depth < floor: break
      let line = d.lines[i]
      if line.depth < depth: atDepth(line, depth, floor)
      if line.depth > depth: break
      # Row disambiguation (§9.3).
      let delimAt = firstUnquoted(line.content, {h.delim})
      let colonAt = firstUnquoted(line.content, {':'})
      if colonAt >= 0 and (delimAt < 0 or colonAt < delimAt): break
      discard d.take(i)
      if result.arrayVal.len == 0: inc d.spans
      result.arrayVal.add rowObject(line, h, splitUnquoted(line.content, h.delim))
    if result.arrayVal.len > 0: dec d.spans
  checkCount(at, h.length, result.arrayVal.len, d.strict)

proc keyedRows(d: var Decoder, h: Header, rowDepth: int, at: Line): ToonValue
    {.raises: [ToonDecodeError].} =
  result = newToonObject()
  var rows = 0
  let (depth, floor) = d.contentDepth(rowDepth)
  if depth >= 0:
    while true:
      let i = d.peek()
      if i < 0 or d.lines[i].depth < floor: break
      let line = d.lines[i]
      atDepth(line, depth, floor)
      let colonAt = firstUnquoted(line.content, {':'})
      if colonAt < 0: fail(line, "an entry row needs a colon after its key")
      discard d.take(i)
      if rows == 0: inc d.spans
      inc rows
      let rest = line.content[colonAt + 1 .. ^1]
      let cells = if trimSpaces(rest).len == 0: @[] else: splitUnquoted(rest, h.delim)
      setField(line, result, keyOf(line, line.content[0 ..< colonAt]),
               rowObject(line, h, cells), d.strict)
    if rows > 0: dec d.spans
  checkCount(at, h.length, rows, d.strict)

proc listItems(d: var Decoder, h: Header, itemDepth: int, at: Line): ToonValue
    {.raises: [ToonDecodeError].} =
  result = newToonArray()
  let (depth, floor) = d.contentDepth(itemDepth)
  if depth >= 0:
    while true:
      let i = d.peek()
      if i < 0 or d.lines[i].depth < floor: break
      let line = d.lines[i]
      atDepth(line, depth, floor)
      if not isListItem(line.content): break
      discard d.take(i)
      if result.arrayVal.len == 0: inc d.spans
      result.arrayVal.add d.listItem(line, line.content, depth)
    if result.arrayVal.len > 0: dec d.spans
  checkCount(at, h.length, result.arrayVal.len, d.strict)

proc headerValue(d: var Decoder, h: Header, depth: int, at: Line): ToonValue
    {.raises: [ToonDecodeError].} =
  ## The value of a header standing at `depth`; its scope is at depth + 1.
  if h.keyed: return d.keyedRows(h, depth + 1, at)
  if h.hasFields: return d.tabularRows(h, depth + 1, at)
  if h.rest.len > 0:
    result = newToonArray()
    for token in splitUnquoted(h.rest, h.delim):
      result.arrayVal.add primitiveOf(at, token)
    checkCount(at, h.length, result.arrayVal.len, d.strict)
    return
  d.listItems(h, depth + 1, at)

proc nestedObject(d: var Decoder, depth: int): ToonValue {.raises: [ToonDecodeError].} =
  ## The object opened by `key:` standing at `depth` (§8).
  result = newToonObject()
  let (content, floor) = d.contentDepth(depth + 1)
  if content >= 0: d.objectBody(result, content, floor)

proc fieldLine(d: var Decoder, obj: ToonValue, line: Line, content: string, depth: int)
    {.raises: [ToonDecodeError].} =
  ## One field of `obj` standing at `depth`.
  case classify(content)
  of lkHeader:
    let h = headerOf(line, content, d.strict)
    if not h.hasKey:
      fail(line, "a header without a key in an object")
    setField(line, obj, h.key, d.headerValue(h, depth, line), d.strict)
  of lkKeyValue:
    let colon = firstUnquoted(content, {':'})
    let key = keyOf(line, content[0 ..< colon])
    let rest = trimSpaces(content[colon + 1 .. ^1])
    let value =
      if rest.len == 0: d.nestedObject(depth)
      elif rest == "[]": newToonArray()
      else: primitiveOf(line, rest)
    setField(line, obj, key, value, d.strict)
  of lkScalar:
    fail(line, "a line without a colon where a field belongs")

proc objectBody(d: var Decoder, obj: ToonValue, depth, floor: int) =
  while true:
    let i = d.peek()
    if i < 0 or d.lines[i].depth < floor: return
    let line = d.lines[i]
    atDepth(line, depth, floor)
    discard d.take(i)
    d.fieldLine(obj, line, line.content, depth)

proc listItem(d: var Decoder, line: Line, content: string, depth: int): ToonValue =
  ## A list item at item depth `depth` (§9.4, §10).
  if content == "-": return newToonObject()
  let rest = content[1 .. ^1].strip(trailing = false, chars = {Space})
  if rest == "[]": return newToonArray()
  case classify(rest)
  of lkHeader:
    let h = headerOf(line, rest, d.strict)
    if not h.hasKey:
      if h.hasFields:
        fail(line, "a header without a key carries a field list only at the root")
      # The keyless header is the item itself, standing at `depth`.
      return d.headerValue(h, depth, line)
    result = newToonObject()
    setField(line, result, h.key, d.headerValue(h, depth + 1, line), d.strict)
    d.objectBody(result, depth + 1, depth + 1)
  of lkKeyValue:
    # The first field stands at depth + 1 on the hyphen line (§10).
    result = newToonObject()
    d.fieldLine(result, line, rest, depth + 1)
    d.objectBody(result, depth + 1, depth + 1)
  of lkScalar:
    result = primitiveOf(line, rest)

proc ensureEnd(d: Decoder) {.raises: [ToonDecodeError].} =
  let i = d.peek()
  if i >= 0: fail(d.lines[i], "content after the complete root value")

proc document(d: var Decoder): ToonValue {.raises: [ToonDecodeError].} =
  ## Root form discovery (§5).
  let i = d.peek()
  if i < 0: return newToonObject()
  let first = d.lines[i]
  if first.depth != 0: fail(first, "the first line is indented")
  case classify(first.content)
  of lkHeader:
    let h = headerOf(first, first.content, d.strict)
    if not h.hasKey:
      discard d.take(i)
      result = d.headerValue(h, 0, first)
      d.ensureEnd()
      return
  of lkScalar:
    if first.content == "[]":
      discard d.take(i)
      d.ensureEnd()
      return newToonArray()
    var nonBlank = 0
    for line in d.lines:
      if not line.blank: inc nonBlank
    if nonBlank == 1:
      discard d.take(i)
      return primitiveOf(first, first.content)
  of lkKeyValue: discard
  result = newToonObject()
  d.objectBody(result, 0, 0)

proc decode*(input: string, options: DecodeOptions = defaultDecodeOptions): ToonValue
    {.raises: [ToonDecodeError].} =
  ## Decodes a TOON document (specification 4.4).
  ##
  ## Raises ToonDecodeError on every condition of §14; with `strict = false`
  ## the recoveries of §14.4 apply instead.
  if options.indentSize < 1:
    raise newToonDecodeError("indentSize must be at least 1")
  var d = Decoder(strict: options.strict, lines: prepare(input, options))
  d.document()

proc decodeFile*(path: string, options: DecodeOptions = defaultDecodeOptions): ToonValue
    {.raises: [ToonDecodeError, IOError].} =
  ## Decodes the TOON document in the file at `path`.
  decode(readFile(path), options)
