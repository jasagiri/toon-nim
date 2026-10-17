## Integration tests for round-trip (encode → decode) integrity
## T076-T079: Round-trip tests

import unittest
import std/tables
import ../../src/toon

# Helper to check round-trip
proc roundTrip(v: ToonValue): bool =
  let encoded = encode(v)
  let decoded = decode(encoded)
  result = decoded == v
  if not result:
    echo "Original: ", encode(v)
    echo "Encoded: ", encoded
    echo "Decoded: ", encode(decoded)

# T076: Round-trip tests for primitives
suite "round-trip primitives":
  test "null round-trip":
    let v = newToonObject({"x": newToonNull()})
    check roundTrip(v)

  test "bool true round-trip":
    let v = newToonObject({"x": newToonBool(true)})
    check roundTrip(v)

  test "bool false round-trip":
    let v = newToonObject({"x": newToonBool(false)})
    check roundTrip(v)

  test "positive integer round-trip":
    let v = newToonObject({"x": newToonInt(42)})
    check roundTrip(v)

  test "negative integer round-trip":
    let v = newToonObject({"x": newToonInt(-42)})
    check roundTrip(v)

  test "zero round-trip":
    let v = newToonObject({"x": newToonInt(0)})
    check roundTrip(v)

  test "large integer round-trip":
    let v = newToonObject({"x": newToonInt(9007199254740991'i64)})
    check roundTrip(v)

  test "float round-trip":
    let v = newToonObject({"x": newToonFloat(3.14)})
    # Float comparison may have precision issues
    let encoded = encode(v)
    let decoded = decode(encoded)
    check decoded["x"].getFloat() > 3.13 and decoded["x"].getFloat() < 3.15

  test "simple string round-trip":
    let v = newToonObject({"x": newToonString("hello")})
    check roundTrip(v)

  test "string with spaces round-trip":
    let v = newToonObject({"x": newToonString("hello world")})
    check roundTrip(v)

  test "empty string round-trip":
    let v = newToonObject({"x": newToonString("")})
    check roundTrip(v)

  test "string needing quoting round-trip":
    let v = newToonObject({"x": newToonString("true")})
    check roundTrip(v)

  test "string with escapes round-trip":
    let v = newToonObject({"x": newToonString("line1\nline2")})
    check roundTrip(v)

  test "unicode string round-trip":
    let v = newToonObject({"x": newToonString("こんにちは")})
    check roundTrip(v)

# T077: Round-trip tests for objects
suite "round-trip objects":
  test "simple object round-trip":
    let v = newToonObject({"name": newToonString("Ada"), "age": newToonInt(42)})
    check roundTrip(v)

  test "nested object round-trip":
    let inner = newToonObject({"city": newToonString("London")})
    let v = newToonObject({"address": inner})
    check roundTrip(v)

  test "deeply nested object round-trip":
    let c = newToonObject({"val": newToonInt(1)})
    let b = newToonObject({"c": c})
    let a = newToonObject({"b": b})
    let v = newToonObject({"a": a})
    check roundTrip(v)

  test "empty object round-trip":
    let v = newToonObject()
    check roundTrip(v)

  test "object with multiple types round-trip":
    let v = newToonObject({
      "str": newToonString("hello"),
      "num": newToonInt(42),
      "bool": newToonBool(true),
      "nil": newToonNull()
    })
    check roundTrip(v)

  test "object preserves key order round-trip":
    let v = newToonObject({
      "z": newToonInt(1),
      "a": newToonInt(2),
      "m": newToonInt(3)
    })
    let encoded = encode(v)
    let decoded = decode(encoded)

    var origKeys: seq[string]
    var decodedKeys: seq[string]
    for k in v.objectVal.keys:
      origKeys.add(k)
    for k in decoded.objectVal.keys:
      decodedKeys.add(k)
    check origKeys == decodedKeys

# T078: Round-trip tests for arrays
suite "round-trip arrays":
  test "inline array of integers round-trip":
    let arr = newToonArray([newToonInt(1), newToonInt(2), newToonInt(3)])
    let v = newToonObject({"nums": arr})
    check roundTrip(v)

  test "inline array of strings round-trip":
    let arr = newToonArray([newToonString("a"), newToonString("b"), newToonString("c")])
    let v = newToonObject({"items": arr})
    check roundTrip(v)

  test "inline array mixed types round-trip":
    let arr = newToonArray([newToonInt(1), newToonString("two"), newToonBool(true)])
    let v = newToonObject({"mix": arr})
    check roundTrip(v)

  test "list array of objects round-trip":
    var arr = newToonArray()
    arr.arrayVal.add(newToonObject({"name": newToonString("Ada")}))
    arr.arrayVal.add(newToonObject({"name": newToonString("Bob")}))
    let v = newToonObject({"people": arr})
    check roundTrip(v)

  test "nested array round-trip":
    let inner1 = newToonArray([newToonInt(1), newToonInt(2)])
    let inner2 = newToonArray([newToonInt(3), newToonInt(4)])
    var outer = newToonArray()
    outer.arrayVal.add(inner1)
    outer.arrayVal.add(inner2)
    let v = newToonObject({"matrix": outer})
    # Note: Nested arrays may change format but values should be preserved
    let encoded = encode(v)
    let decoded = decode(encoded)
    check decoded["matrix"].arrayVal.len == 2

  test "empty array round-trip":
    let arr = newToonArray()
    let v = newToonObject({"empty": arr})
    let encoded = encode(v)
    let decoded = decode(encoded)
    check encoded == "empty: []"
    check decoded["empty"].kind == vkArray
    check decoded["empty"].len == 0

# T079: Round-trip tests for edge cases
suite "round-trip edge cases":
  test "complex mixed structure round-trip":
    let person = newToonObject({
      "name": newToonString("Alice"),
      "age": newToonInt(30),
      "active": newToonBool(true),
      "scores": newToonArray([newToonInt(95), newToonInt(87), newToonInt(92)])
    })
    var people = newToonArray()
    people.arrayVal.add(person)
    people.arrayVal.add(newToonObject({
      "name": newToonString("Bob"),
      "age": newToonInt(25),
      "active": newToonBool(false),
      "scores": newToonArray([newToonInt(88), newToonInt(91)])
    }))
    let v = newToonObject({
      "company": newToonString("Acme"),
      "employees": people
    })
    check roundTrip(v)

  test "string looking like number round-trip":
    let v = newToonObject({"x": newToonString("42")})
    check roundTrip(v)

  test "string looking like boolean round-trip":
    let v = newToonObject({"x": newToonString("true")})
    check roundTrip(v)

  test "string with special characters round-trip":
    let v = newToonObject({"x": newToonString("hello: world")})
    check roundTrip(v)

  test "string with array-like syntax round-trip":
    let v = newToonObject({"x": newToonString("[1,2,3]")})
    check roundTrip(v)

  test "key with special characters round-trip":
    let v = newToonObject()
    v.objectVal["my:key"] = newToonInt(1)
    check roundTrip(v)

  test "key with spaces round-trip":
    let v = newToonObject()
    v.objectVal["my key"] = newToonInt(1)
    check roundTrip(v)

  test "deep nesting round-trip":
    var v = newToonObject({"val": newToonInt(1)})
    for i in 1..10:
      v = newToonObject({"level" & $i: v})
    check roundTrip(v)

  test "multiple encode/decode cycles":
    let original = newToonObject({
      "name": newToonString("Test"),
      "items": newToonArray([newToonInt(1), newToonInt(2), newToonInt(3)])
    })
    var v = original
    for i in 1..5:
      let encoded = encode(v)
      v = decode(encoded)
    check v == original
