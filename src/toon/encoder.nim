## TOON encoder, specification 4.4.
##
## The form of every value follows from its shape and position (§1.4, §9):
## inline primitive arrays, tabular arrays with nested field groups, keyed
## tabular objects, list form for everything else. The output has LF line
## endings, no blank lines, no trailing spaces and no trailing newline (§12).

import std/[json, math, strutils, tables]
import ./types, ./text

type
  Field = object
    ## One entry of a header's field list; a nested field group when
    ## `children` is not empty (§9.3).
    name: string
    children: seq[Field]

  Encoder = object
    opts: EncodeOptions
    delim: char
    lines: seq[string]

proc isPrimitive(v: ToonValue): bool {.raises: [].} =
  v.kind in {vkNull, vkBool, vkInt, vkFloat, vkString}

proc canonicalNumber(f: float64): string {.raises: [].} =
  ## The shortest round-trip digits of `f` (§2), in plain decimal when
  ## 1e-6 <= |f| < 1e21 and in JSON exponent form otherwise.
  if f == 0.0: return "0"
  # `$` already gives the shortest digits that round-trip; only their layout
  # differs from §2 (`1e+21`, `1000000.0`, `0.0000001`).
  let shortest = $abs(f)
  let ePos = shortest.find('e')
  let mantissa = if ePos < 0: shortest else: shortest[0 ..< ePos]
  var exponent = 0
  if ePos >= 0:
    for c in shortest[ePos + 1 .. ^1]:
      if c in {'0' .. '9'}: exponent = exponent * 10 + (ord(c) - ord('0'))
    if shortest[ePos + 1] == '-': exponent = -exponent
  let dot = mantissa.find('.')
  var digits = mantissa.replace(".", "")
  # The value is 0.<digits> * 10^point.
  var point = (if dot < 0: mantissa.len else: dot) + exponent
  while digits.len > 1 and digits[0] == '0':
    digits = digits[1 .. ^1]
    dec point
  digits = digits.strip(leading = false, chars = {'0'})
  let sign = if f < 0: "-" else: ""
  if abs(f) >= 1e-6 and abs(f) < 1e21:
    if point <= 0:
      sign & "0." & repeat('0', -point) & digits
    elif point >= digits.len:
      sign & digits & repeat('0', point - digits.len)
    else:
      sign & digits[0 ..< point] & "." & digits[point .. ^1]
  else:
    let e = point - 1
    sign & digits[0 .. 0] & (if digits.len > 1: "." & digits[1 .. ^1] else: "") &
      "e" & (if e < 0: "-" else: "+") & $abs(e)

proc needsQuotes(s: string, delim: char, atRoot: bool): bool {.raises: [].} =
  ## The conditions of §7.2.
  if s.len == 0: return true
  if s[0] in {' ', '\t'} or s[^1] in {' ', '\t'}: return true
  if s in ["true", "false", "null"]: return true
  if isNumericLike(s): return true
  if s[0] in {'-', '#'}: return true
  if atRoot and s.startsWith(Bom): return true
  for c in s:
    if c in {':', '"', '\\', '[', ']', '{', '}', '\x00' .. '\x1F'} or c == delim:
      return true
  false

proc primitive(e: Encoder, v: ToonValue, atRoot = false): string
    {.raises: [ToonEncodeError].} =
  case v.kind
  of vkNull: "null"
  of vkBool: (if v.boolVal: "true" else: "false")
  of vkInt: $v.intVal
  of vkFloat:
    if v.floatVal.classify in {fcNan, fcInf, fcNegInf}: "null"
    else: canonicalNumber(v.floatVal)
  of vkString:
    if not isWellFormedUtf8(v.strVal):
      raise newToonEncodeError("string is not well-formed UTF-8 " &
                               "(an unpaired surrogate cannot be encoded): " &
                               v.strVal.escape)
    if needsQuotes(v.strVal, e.delim, atRoot): quoted(v.strVal) else: v.strVal
  of vkArray, vkObject: ""

proc key(k: string): string {.raises: [ToonEncodeError].} =
  if not isWellFormedUtf8(k):
    raise newToonEncodeError("key is not well-formed UTF-8: " & k.escape)
  encodedKey(k)

proc sameKeys(a, b: ToonValue): bool {.raises: [].} =
  ## The same set of keys, in any order.
  if a.objectVal.len != b.objectVal.len: return false
  for k in a.objectVal.keys:
    if not b.objectVal.hasKey(k): return false
  true

proc columns(values: seq[ToonValue], fields: var seq[Field]): bool {.raises: [].} =
  ## Whether `values` (non-empty objects with one set of keys) form a table
  ## whose every column is uniform-primitive or nested-uniform (§9.3); the
  ## field list, in the first value's key order, goes to `fields`.
  if values.len == 0: return false
  for v in values:
    if v.kind != vkObject or v.objectVal.len == 0 or not sameKeys(v, values[0]):
      return false
  fields = @[]
  for k in values[0].objectVal.keys:
    var column: seq[ToonValue]
    for v in values: column.add v.objectVal.getOrDefault(k)
    var allPrimitive = true
    for c in column:
      if not c.isPrimitive: allPrimitive = false
    if allPrimitive:
      fields.add Field(name: k)
    else:
      var sub: seq[Field]
      if not columns(column, sub): return false
      fields.add Field(name: k, children: sub)
  true

proc delimSymbol(e: Encoder): string {.raises: [].} =
  if e.delim == ',': "" else: $e.delim

proc fieldList(e: Encoder, fields: seq[Field]): string {.raises: [ToonEncodeError].} =
  var parts: seq[string]
  for f in fields:
    parts.add key(f.name) & (if f.children.len > 0: e.fieldList(f.children) else: "")
  "{" & parts.join($e.delim) & "}"

proc cells(e: Encoder, v: ToonValue, fields: seq[Field], into: var seq[string])
    {.raises: [ToonEncodeError].} =
  ## The leaf values of `v`, depth-first in field-list order (§9.3).
  for f in fields:
    let value = v.objectVal.getOrDefault(f.name)
    if f.children.len > 0: e.cells(value, f.children, into)
    else: into.add e.primitive(value)

proc row(e: Encoder, v: ToonValue, fields: seq[Field]): string
    {.raises: [ToonEncodeError].} =
  var parts: seq[string]
  e.cells(v, fields, parts)
  parts.join($e.delim)

proc indent(e: Encoder, depth: int): string {.raises: [].} =
  repeat(' ', depth * e.opts.indentSize)

proc emit(e: var Encoder, depth: int, content: string) {.raises: [].} =
  e.lines.add e.indent(depth) & content

proc isKeyedTable(v: ToonValue, fields: var seq[Field]): bool {.raises: [].} =
  ## Keyed tabular detection (§9.5): two or more entries of uniform objects.
  if v.objectVal.len < 2: return false
  var values: seq[ToonValue]
  for x in v.objectVal.values: values.add x
  columns(values, fields)

proc allPrimitive(items: seq[ToonValue]): bool {.raises: [].} =
  for x in items:
    if not x.isPrimitive: return false
  true

proc keyedTable(e: var Encoder, prefix: string, v: ToonValue, fields: seq[Field],
                depth: int) {.raises: [ToonEncodeError].} =
  ## A keyed tabular object (§9.5) whose header is `prefix` (an encoded key,
  ## or empty at the root).
  e.emit(depth, prefix & "[" & $v.objectVal.len & ":" & e.delimSymbol & "]" &
                e.fieldList(fields) & ":")
  for entry, value in v.objectVal:
    e.emit(depth + 1, key(entry) & ": " & e.row(value, fields))

proc fields(e: var Encoder, obj: ToonValue, depth: int) {.raises: [ToonEncodeError].}
proc listItem(e: var Encoder, v: ToonValue, depth: int) {.raises: [ToonEncodeError].}

proc arrayAt(e: var Encoder, prefix: string, items: seq[ToonValue], depth: int,
             tabularAllowed: bool) {.raises: [ToonEncodeError].} =
  ## A non-empty array whose header is `prefix` (an encoded key, or empty)
  ## standing at `depth`.
  let bracket = "[" & $items.len & e.delimSymbol & "]"
  if allPrimitive(items):
    var parts: seq[string]
    for x in items: parts.add e.primitive(x)
    e.emit(depth, prefix & bracket & ": " & parts.join($e.delim))
    return
  var fields: seq[Field]
  if tabularAllowed and columns(items, fields):
    e.emit(depth, prefix & bracket & e.fieldList(fields) & ":")
    for x in items: e.emit(depth + 1, e.row(x, fields))
    return
  e.emit(depth, prefix & bracket & ":")
  for x in items: e.listItem(x, depth + 1)

proc field(e: var Encoder, k: string, v: ToonValue, depth: int)
    {.raises: [ToonEncodeError].} =
  ## One object field at `depth` (§8, §9).
  let name = key(k)
  case v.kind
  of vkArray:
    if v.arrayVal.len == 0: e.emit(depth, name & ": []")
    else: e.arrayAt(name, v.arrayVal, depth, tabularAllowed = true)
  of vkObject:
    var fields: seq[Field]
    if isKeyedTable(v, fields):
      e.keyedTable(name, v, fields, depth)
    else:
      e.emit(depth, name & ":")
      e.fields(v, depth + 1)
  else:
    e.emit(depth, name & ": " & e.primitive(v))

proc fields(e: var Encoder, obj: ToonValue, depth: int) =
  for k, v in obj.objectVal: e.field(k, v, depth)

proc onHyphen(e: var Encoder, first: int, depth: int) {.raises: [].} =
  ## Puts the line `first`, written at `depth` or deeper, after a list-item
  ## hyphen at `depth` (§10).
  e.lines[first] = e.indent(depth) & "- " &
                   e.lines[first].strip(trailing = false, chars = {' '})

proc listItem(e: var Encoder, v: ToonValue, depth: int) =
  ## One element of an array in list form, at item depth `depth` (§9.4, §10).
  case v.kind
  of vkArray:
    # A keyless header on the hyphen line is the item itself: its items stand
    # at depth + 1, and tabular form is not available here (§9.4).
    let first = e.lines.len
    if v.arrayVal.len == 0: e.emit(depth, "[0" & e.delimSymbol & "]:")
    else: e.arrayAt("", v.arrayVal, depth, tabularAllowed = false)
    e.onHyphen(first, depth)
  of vkObject:
    if v.objectVal.len == 0:
      e.emit(depth, "-")
      return
    # The first field stands at depth + 1 on the hyphen line; the others, and
    # the content of a scope it opens, follow from that depth.
    let first = e.lines.len
    e.fields(v, depth + 1)
    e.onHyphen(first, depth)
  else:
    e.emit(depth, "- " & e.primitive(v))

proc encode*(v: ToonValue, opts: EncodeOptions = defaultEncodeOptions): string
    {.raises: [ToonEncodeError].} =
  ## Encodes `v` as a TOON document (specification 4.4).
  ##
  ## Raises ToonEncodeError for a string or key that is not well-formed UTF-8,
  ## and for an indentSize below 1.
  if opts.indentSize < 1:
    raise newToonEncodeError("indentSize must be at least 1")
  var e = Encoder(opts: opts, delim: ($opts.delimiter)[0])
  case v.kind
  of vkObject:
    var fields: seq[Field]
    if isKeyedTable(v, fields): e.keyedTable("", v, fields, 0)
    else: e.fields(v, 0)
  of vkArray:
    if v.arrayVal.len == 0: e.emit(0, "[]")
    else: e.arrayAt("", v.arrayVal, 0, tabularAllowed = true)
  else:
    e.emit(0, e.primitive(v, atRoot = true))
  e.lines.join("\n")

proc encode*(j: JsonNode, opts: EncodeOptions = defaultEncodeOptions): string
    {.raises: [ToonEncodeError].} =
  ## Encodes a JSON value as a TOON document.
  encode(fromJsonNode(j), opts)

proc encodeToFile*(v: ToonValue, path: string,
                   opts: EncodeOptions = defaultEncodeOptions)
    {.raises: [ToonEncodeError, IOError].} =
  ## Encodes `v` and writes the document to `path`.
  writeFile(path, encode(v, opts))
