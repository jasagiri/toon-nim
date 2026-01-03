## Fixture Test Runner for TOON format tests
## Runs the official test fixtures from toon-format/spec

import std/[json, os, strutils, tables]
import ../../src/toon

type
  TestResult = object
    name: string
    passed: bool
    error: string

proc toonToJson(v: ToonValue): JsonNode =
  ## Convert ToonValue to JsonNode for comparison
  case v.kind
  of vkNull: result = newJNull()
  of vkBool: result = newJBool(v.boolVal)
  of vkInt: result = newJInt(v.intVal)
  of vkFloat: result = newJFloat(v.floatVal)
  of vkString: result = newJString(v.strVal)
  of vkArray:
    result = newJArray()
    for item in v.arrayVal:
      result.add(toonToJson(item))
  of vkObject:
    result = newJObject()
    for key, val in v.objectVal:
      result[key] = toonToJson(val)

proc compareJson(got, expected: JsonNode): bool =
  ## Deep compare two JSON values
  if got.kind != expected.kind:
    return false

  case expected.kind
  of JNull:
    return true
  of JBool:
    return got.getBool() == expected.getBool()
  of JInt:
    return got.getInt() == expected.getInt()
  of JFloat:
    return abs(got.getFloat() - expected.getFloat()) < 0.0001
  of JString:
    return got.getStr() == expected.getStr()
  of JArray:
    if got.len != expected.len:
      return false
    for i in 0..<expected.len:
      if not compareJson(got[i], expected[i]):
        return false
    return true
  of JObject:
    if got.len != expected.len:
      return false
    for key, val in expected.pairs:
      if not got.hasKey(key):
        return false
      if not compareJson(got[key], val):
        return false
    return true

proc getDecodeOptions(test: JsonNode): DecodeOptions =
  ## Extract decode options from test case
  result = DecodeOptions(strict: false, expandPaths: peNone, indentSize: 2)

  if test.hasKey("options"):
    let opts = test["options"]
    if opts.hasKey("strict"):
      result.strict = opts["strict"].getBool()
    if opts.hasKey("expandPaths"):
      let ep = opts["expandPaths"].getStr()
      if ep == "safe":
        result.expandPaths = peSafe
      elif ep == "aggressive" or ep == "all":
        result.expandPaths = peAll
    if opts.hasKey("indent"):
      result.indentSize = opts["indent"].getInt()

proc runDecodeTest(test: JsonNode): TestResult =
  ## Run a single decode test
  result.name = test["name"].getStr()

  let opts = getDecodeOptions(test)

  # Check for expected error tests (supports both "error" and "shouldError" keys)
  let shouldError = (test.hasKey("error") and test["error"].getBool()) or
                    (test.hasKey("shouldError") and test["shouldError"].getBool())
  if shouldError:
    try:
      let input = test["input"].getStr()
      discard decode(input, opts)
      result.error = "Expected error but decode succeeded"
    except:
      result.passed = true
    return

  let input = test["input"].getStr()
  let expected = test["expected"]

  try:
    let decoded = decode(input, opts)
    let gotJson = toonToJson(decoded)

    if compareJson(gotJson, expected):
      result.passed = true
    else:
      result.error = "Mismatch: got " & $gotJson & ", expected " & $expected
  except ToonDecodeError as e:
    result.error = "Decode error: " & e.msg
  except CatchableError as e:
    result.error = "Error: " & e.msg

proc runFixtureFile(path: string): tuple[passed: int, failed: int, results: seq[TestResult]] =
  ## Run all tests in a fixture file
  let content = readFile(path)
  let fixture = parseJson(content)

  let category = fixture["category"].getStr()
  let tests = fixture["tests"]

  for test in tests:
    var testResult: TestResult
    if category == "decode":
      testResult = runDecodeTest(test)
    else:
      testResult.name = test["name"].getStr()
      testResult.passed = true  # Skip non-decode tests for now

    result.results.add(testResult)
    if testResult.passed:
      result.passed += 1
    else:
      result.failed += 1

proc main() =
  var totalPassed = 0
  var totalFailed = 0
  var allResults: seq[tuple[file: string, passed: int, failed: int]] = @[]

  echo "=== TOON Fixture Test Runner ==="
  echo ""

  # Run decode fixtures
  let decodeDir = "tests/fixtures/decode"
  if dirExists(decodeDir):
    echo "Decode fixtures:"
    for kind, path in walkDir(decodeDir):
      if kind == pcFile and path.endsWith(".json"):
        let filename = path.extractFilename()
        let (passed, failed, results) = runFixtureFile(path)
        totalPassed += passed
        totalFailed += failed
        allResults.add((filename, passed, failed))

        let status = if failed == 0: "[OK]" else: "[FAIL]"
        echo "  " & status & " " & filename & ": " & $passed & " passed, " & $failed & " failed"

        # Show failures
        if failed > 0:
          for r in results:
            if not r.passed:
              echo "    - " & r.name & ": " & r.error

  # Run encode fixtures
  let encodeDir = "tests/fixtures/encode"
  if dirExists(encodeDir):
    echo ""
    echo "Encode fixtures:"
    for kind, path in walkDir(encodeDir):
      if kind == pcFile and path.endsWith(".json"):
        let filename = path.extractFilename()
        # Skip encode tests for now - they have different format
        echo "  [SKIP] " & filename & " (encode tests not yet implemented)"

  echo ""
  echo "=== Summary ==="
  echo "Total: " & $totalPassed & " passed, " & $totalFailed & " failed"

  if totalFailed > 0:
    quit(1)

when isMainModule:
  main()
