## Unit tests for TOON encoder module
## T046-T049: Encoder tests

import unittest
import std/[strutils, tables, os]
import ../../src/toon/types
import ../../src/toon/encoder

# T046: Encoder tests for primitives
suite "encode primitives":
  test "encode null":
    let v = newToonNull()
    check encode(newToonObject({"x": v})) == "x: null"

  test "encode boolean true":
    let v = newToonBool(true)
    check encode(newToonObject({"x": v})) == "x: true"

  test "encode boolean false":
    let v = newToonBool(false)
    check encode(newToonObject({"x": v})) == "x: false"

  test "encode integer":
    let v = newToonInt(42)
    check encode(newToonObject({"x": v})) == "x: 42"

  test "encode negative integer":
    let v = newToonInt(-42)
    check encode(newToonObject({"x": v})) == "x: -42"

  test "encode zero":
    let v = newToonInt(0)
    check encode(newToonObject({"x": v})) == "x: 0"

  test "encode float":
    let v = newToonFloat(3.14)
    let result = encode(newToonObject({"x": v}))
    check "x: 3.14" in result

  test "encode string simple":
    let v = newToonString("hello")
    check encode(newToonObject({"x": v})) == "x: hello"

  test "encode string with spaces":
    let v = newToonString("hello world")
    check encode(newToonObject({"x": v})) == "x: hello world"

  test "encode string needs quoting - empty":
    let v = newToonString("")
    check encode(newToonObject({"x": v})) == "x: \"\""

  test "encode string needs quoting - leading space":
    let v = newToonString(" hello")
    check encode(newToonObject({"x": v})) == "x: \" hello\""

  test "encode string needs quoting - keyword":
    let v = newToonString("true")
    check encode(newToonObject({"x": v})) == "x: \"true\""

  test "encode string needs quoting - number":
    let v = newToonString("42")
    check encode(newToonObject({"x": v})) == "x: \"42\""

# T047: Encoder tests for objects
suite "encode objects":
  test "encode simple object":
    let v = newToonObject({"name": newToonString("Ada"), "age": newToonInt(42)})
    let result = encode(v)
    check "name: Ada" in result
    check "age: 42" in result

  test "encode nested object":
    let inner = newToonObject({"city": newToonString("London")})
    let v = newToonObject({"address": inner})
    let result = encode(v)
    check "address:" in result
    check "  city: London" in result

  test "encode deeply nested object":
    let c = newToonObject({"val": newToonInt(1)})
    let b = newToonObject({"c": c})
    let a = newToonObject({"b": b})
    let v = newToonObject({"a": a})
    let result = encode(v)
    check "a:" in result
    check "  b:" in result
    check "    c:" in result
    check "      val: 1" in result

  test "encode empty object":
    let v = newToonObject()
    check encode(v) == ""

  test "encode preserves key order":
    let v = newToonObject({"z": newToonInt(1), "a": newToonInt(2), "m": newToonInt(3)})
    let result = encode(v)
    let zPos = result.find("z:")
    let aPos = result.find("a:")
    let mPos = result.find("m:")
    check zPos < aPos
    check aPos < mPos

# T048: Encoder tests for arrays
suite "encode arrays":
  test "encode inline array":
    let v = newToonArray([newToonInt(1), newToonInt(2), newToonInt(3)])
    check encode(newToonObject({"nums": v})) == "nums: 1, 2, 3"

  test "encode inline array strings":
    let v = newToonArray([newToonString("a"), newToonString("b")])
    check encode(newToonObject({"items": v})) == "items: a, b"

  test "encode inline array mixed":
    let v = newToonArray([newToonInt(1), newToonString("hello"), newToonBool(true)])
    let result = encode(newToonObject({"mix": v}))
    check result == "mix: 1, hello, true"

  test "encode array with quoted string":
    let v = newToonArray([newToonString("a,b"), newToonString("c")])
    let result = encode(newToonObject({"items": v}))
    check result == "items: \"a,b\", c"

  test "encode empty array":
    let v = newToonArray()
    check encode(newToonObject({"arr": v})) == "arr: null"

  test "encode list array":
    var v = newToonArray()
    v.arrayVal.add(newToonObject({"name": newToonString("Ada")}))
    v.arrayVal.add(newToonObject({"name": newToonString("Bob")}))
    let result = encode(newToonObject({"people": v}))
    check "people:" in result
    check "- name: Ada" in result
    check "- name: Bob" in result

  test "encode nested array":
    let inner = newToonArray([newToonInt(1), newToonInt(2)])
    let outer = newToonArray([inner])
    let result = encode(newToonObject({"matrix": outer}))
    check "matrix:" in result
    check "- 1, 2" in result

# T049: Encoder tests for quoting/escaping
suite "encode quoting and escaping":
  test "escape backslash":
    let v = newToonString("path\\file")
    let result = encode(newToonObject({"x": v}))
    check "\\\\" in result

  test "escape newline":
    let v = newToonString("line1\nline2")
    let result = encode(newToonObject({"x": v}))
    check "\\n" in result

  test "escape tab":
    let v = newToonString("a\tb")
    let result = encode(newToonObject({"x": v}))
    check "\\t" in result

  test "escape quote":
    let v = newToonString("say \"hi\"")
    let result = encode(newToonObject({"x": v}))
    check "\\\"" in result

  test "quote key with special chars":
    let v = newToonObject()
    v.objectVal["key:colon"] = newToonInt(1)
    let result = encode(v)
    check "\"key:colon\":" in result

  test "quote key with spaces":
    let v = newToonObject()
    v.objectVal["my key"] = newToonInt(1)
    let result = encode(v)
    check "\"my key\":" in result

suite "encode options":
  test "custom indent size":
    let inner = newToonObject({"b": newToonInt(1)})
    let v = newToonObject({"a": inner})
    let opts = EncodeOptions(indent: 4, delimiter: dlComma, keyFolding: kfNone, sortKeys: false)
    let result = encode(v, opts)
    check "    b: 1" in result

  test "tab delimiter":
    let arr = newToonArray([newToonInt(1), newToonInt(2), newToonInt(3)])
    let v = newToonObject({"nums": arr})
    let opts = EncodeOptions(indent: 2, delimiter: dlTab, keyFolding: kfNone, sortKeys: false)
    let result = encode(v, opts)
    check "1\t2\t3" in result

  test "pipe delimiter":
    let arr = newToonArray([newToonInt(1), newToonInt(2), newToonInt(3)])
    let v = newToonObject({"nums": arr})
    let opts = EncodeOptions(indent: 2, delimiter: dlPipe, keyFolding: kfNone, sortKeys: false)
    let result = encode(v, opts)
    check "1|2|3" in result

  test "sort keys":
    let v = newToonObject({"z": newToonInt(1), "a": newToonInt(2)})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfNone, sortKeys: true)
    let result = encode(v, opts)
    let aPos = result.find("a:")
    let zPos = result.find("z:")
    check aPos < zPos

suite "key folding":
  test "fold simple nested object":
    let c = newToonObject({"c": newToonInt(1)})
    let b = newToonObject({"b": c})
    let v = newToonObject({"a": b})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfSafe, sortKeys: false)
    let result = encode(v, opts)
    check "a.b.c: 1" in result

  test "fold deep nesting":
    let d = newToonObject({"d": newToonInt(42)})
    let c = newToonObject({"c": d})
    let b = newToonObject({"b": c})
    let v = newToonObject({"a": b})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfSafe, sortKeys: false)
    let result = encode(v, opts)
    check "a.b.c.d: 42" in result

  test "no fold when key contains special chars":
    let inner = newToonObject({"b-key": newToonInt(1)})
    let v = newToonObject({"a": inner})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfSafe, sortKeys: false)
    let result = encode(v, opts)
    # Should not fold because b-key contains hyphen
    check "a:" in result
    check "b-key: 1" in result

  test "no fold when multiple keys":
    let inner = newToonObject({"b": newToonInt(1), "c": newToonInt(2)})
    let v = newToonObject({"a": inner})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfSafe, sortKeys: false)
    let result = encode(v, opts)
    # Should not fold because inner has multiple keys
    check "a:" in result

  test "fold with array value":
    let arr = newToonArray([newToonInt(1), newToonInt(2)])
    let inner = newToonObject({"items": arr})
    let v = newToonObject({"data": inner})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfSafe, sortKeys: false)
    let result = encode(v, opts)
    check "data.items: 1, 2" in result

  test "no fold when kfNone":
    let c = newToonObject({"c": newToonInt(1)})
    let b = newToonObject({"b": c})
    let v = newToonObject({"a": b})
    let opts = EncodeOptions(indent: 2, delimiter: dlComma, keyFolding: kfNone, sortKeys: false)
    let result = encode(v, opts)
    # Should not fold
    check "a.b.c" notin result
    check "a:" in result

suite "encodeToFile":
  test "encode to file":
    let v = newToonObject({"name": newToonString("Ada")})
    let path = "/tmp/test_encode.toon"
    encodeToFile(v, path)

    check fileExists(path)

    let content = readFile(path)
    check "name: Ada" in content

    removeFile(path)
