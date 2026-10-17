## Lexical rules shared by the encoder and the decoder: UTF-8 well-formedness,
## the escape table (§7.1), the unquoted-key pattern (§7.3) and the number
## grammars (§4, §7.2).

const
  Space* = ' '
  Bom* = "\xEF\xBB\xBF"

proc isWellFormedUtf8*(s: string): bool {.raises: [].} =
  ## True when `s` is well-formed UTF-8: no overlong forms, no surrogate code
  ## points, nothing above U+10FFFF, no truncated sequence.
  var i = 0
  while i < s.len:
    let c = ord(s[i])
    if c < 0x80:
      inc i
      continue
    var need, lo, hi: int
    if c >= 0xC2 and c <= 0xDF: (need, lo, hi) = (1, 0x80, 0xBF)
    elif c == 0xE0: (need, lo, hi) = (2, 0xA0, 0xBF)
    elif c == 0xED: (need, lo, hi) = (2, 0x80, 0x9F)
    elif c >= 0xE1 and c <= 0xEF: (need, lo, hi) = (2, 0x80, 0xBF)
    elif c == 0xF0: (need, lo, hi) = (3, 0x90, 0xBF)
    elif c == 0xF4: (need, lo, hi) = (3, 0x80, 0x8F)
    elif c >= 0xF1 and c <= 0xF3: (need, lo, hi) = (3, 0x80, 0xBF)
    else: return false
    if i + need >= s.len: return false
    let second = ord(s[i + 1])
    if second < lo or second > hi: return false
    for k in 2 .. need:
      let b = ord(s[i + k])
      if b < 0x80 or b > 0xBF: return false
    i += need + 1
  true

const HexDigits = "0123456789abcdef"

proc quoted*(s: string): string {.raises: [].} =
  ## `s` as a quoted token, escaped by the encoder column of §7.1.
  result = newStringOfCap(s.len + 2)
  result.add '"'
  for c in s:
    case c
    of '\\': result.add "\\\\"
    of '"': result.add "\\\""
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    of '\x00' .. '\x08', '\x0B', '\x0C', '\x0E' .. '\x1F':
      result.add "\\u00"
      result.add HexDigits[ord(c) shr 4]
      result.add HexDigits[ord(c) and 0xF]
    else: result.add c
  result.add '"'

proc isUnquotedKey*(s: string): bool {.raises: [].} =
  ## The pattern `/^[A-Za-z_][A-Za-z0-9_.]*$/` of §7.3.
  if s.len == 0 or s[0] notin {'A' .. 'Z', 'a' .. 'z', '_'}: return false
  for c in s:
    if c notin {'A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '.'}: return false
  true

proc encodedKey*(s: string): string {.raises: [].} =
  ## A key or field name as the encoder writes it (§7.3).
  if isUnquotedKey(s): s else: quoted(s)

proc digitsFrom(s: string, i: var int): int {.raises: [].} =
  ## Advances `i` over ASCII digits; the number of digits passed.
  let start = i
  while i < s.len and s[i] in {'0' .. '9'}: inc i
  i - start

proc isNumberToken*(s: string): bool {.raises: [].} =
  ## The JSON number grammar that decides an unquoted number (§4):
  ## `/^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?$/`.
  var i = 0
  if i < s.len and s[i] == '-': inc i
  if i >= s.len: return false
  if s[i] == '0': inc i
  elif s[i] in {'1' .. '9'}: discard digitsFrom(s, i)
  else: return false
  if i < s.len and s[i] == '.':
    inc i
    if digitsFrom(s, i) == 0: return false
  if i < s.len and s[i] in {'e', 'E'}:
    inc i
    if i < s.len and s[i] in {'+', '-'}: inc i
    if digitsFrom(s, i) == 0: return false
  i == s.len

proc isNumericLike*(s: string): bool {.raises: [].} =
  ## The wider pattern that obliges the encoder to quote a string (§7.2):
  ## `/^[+-]?[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?$/i`.
  var i = 0
  if i < s.len and s[i] in {'+', '-'}: inc i
  if digitsFrom(s, i) == 0: return false
  if i < s.len and s[i] == '.':
    inc i
    if digitsFrom(s, i) == 0: return false
  if i < s.len and s[i] in {'e', 'E'}:
    inc i
    if i < s.len and s[i] in {'+', '-'}: inc i
    if digitsFrom(s, i) == 0: return false
  i == s.len
