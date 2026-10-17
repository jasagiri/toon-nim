## Runs the official TOON conformance fixtures (toon-format/spec) against
## this library. Every case is an external specification test; the run fails
## unless all of them pass.

import std/[json, os, strutils, algorithm, parseutils]
import ../../src/toon

type
  Outcome = object
    file, name, detail: string
    passed: bool

proc isUnquotedNumber(j: JsonNode): bool =
  ## std/json keeps an integer literal beyond int64 as a JString whose `$` is
  ## the bare literal; the flag that marks it is not exported.
  j.kind == JString and ($j).len > 0 and ($j)[0] != '"'

proc numberValue(j: JsonNode): float =
  case j.kind
  of JInt: float(j.getBiggestInt)
  of JFloat: j.getFloat
  else:
    var f: float
    discard parseFloat(j.getStr, f)
    f

proc isNumber(j: JsonNode): bool =
  j.kind in {JInt, JFloat} or j.isUnquotedNumber

proc sameValue(got, expected: JsonNode): bool =
  ## JSON-model equality of the specification (§2): numbers by mathematical
  ## value, objects by their ordered key sequence.
  if got.isNumber or expected.isNumber:
    return got.isNumber and expected.isNumber and
           got.numberValue == expected.numberValue
  if got.kind != expected.kind: return false
  case expected.kind
  of JNull: true
  of JBool: got.getBool == expected.getBool
  of JString: got.getStr == expected.getStr
  of JArray:
    if got.len != expected.len: return false
    for i in 0 ..< expected.len:
      if not sameValue(got[i], expected[i]): return false
    true
  of JObject:
    if got.len != expected.len: return false
    var gotKeys, expectedKeys: seq[string]
    for k, _ in got: gotKeys.add k
    for k, _ in expected: expectedKeys.add k
    if gotKeys != expectedKeys: return false
    for k, v in expected:
      if not sameValue(got[k], v): return false
    true
  of JInt, JFloat: false

proc delimiterOf(s: string): Delimiter =
  case s
  of "\t": dlTab
  of "|": dlPipe
  else: dlComma

proc encodeOptionsOf(t: JsonNode): EncodeOptions =
  result = defaultEncodeOptions
  let o = t{"options"}
  if o.isNil: return
  if o.hasKey("delimiter"): result.delimiter = delimiterOf(o["delimiter"].getStr)
  if o.hasKey("indentSize"): result.indentSize = o["indentSize"].getInt

proc decodeOptionsOf(t: JsonNode): DecodeOptions =
  result = defaultDecodeOptions
  let o = t{"options"}
  if o.isNil: return
  if o.hasKey("strict"): result.strict = o["strict"].getBool
  if o.hasKey("indentSize"): result.indentSize = o["indentSize"].getInt

proc runEncode(t: JsonNode): tuple[passed: bool, detail: string] =
  let shouldError = t{"shouldError"}.getBool(false)
  try:
    let got = encode(fromJsonNode(t["input"]), encodeOptionsOf(t))
    if shouldError: return (false, "expected an error, got " & got.escape)
    let expected = t["expected"].getStr
    if got == expected: (true, "")
    else: (false, "expected " & expected.escape & "\n      got      " & got.escape)
  except ToonEncodeError as e:
    if shouldError: (true, "")
    else: (false, "unexpected error: " & e.msg)

proc runDecode(t: JsonNode): tuple[passed: bool, detail: string] =
  let shouldError = t{"shouldError"}.getBool(false)
  try:
    let got = toJsonNode(decode(t["input"].getStr, decodeOptionsOf(t)))
    if shouldError: return (false, "expected an error, got " & $got)
    if sameValue(got, t["expected"]): (true, "")
    else: (false, "expected " & $t["expected"] & "\n      got      " & $got)
  except ToonDecodeError as e:
    if shouldError: (true, "")
    else: (false, "unexpected error: " & e.msg)

proc main(): int =
  let root = currentSourcePath().parentDir
  var outcomes: seq[Outcome]
  for category in ["encode", "decode"]:
    var files: seq[string]
    for f in walkFiles(root / category / "*.json"): files.add f
    files.sort()
    for f in files:
      for t in parseFile(f)["tests"]:
        let (passed, detail) =
          if category == "encode": runEncode(t) else: runDecode(t)
        outcomes.add Outcome(file: category / f.extractFilename,
                             name: t["name"].getStr, passed: passed, detail: detail)
  var failed = 0
  for o in outcomes:
    if not o.passed:
      inc failed
      echo "[FAIL] ", o.file, ": ", o.name, "\n      ", o.detail
  echo "TOON conformance: ", outcomes.len - failed, " / ", outcomes.len, " passed"
  if failed > 0: 1 else: 0

quit(main())
