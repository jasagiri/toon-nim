## Unit tests for TOON decoder module
## T023-T026: Decoder tests - public API for decoding TOON to ToonValue

import unittest
import std/os
import ../../src/toon/types
import ../../src/toon/decoder

# T023: Decoder tests for primitives
suite "decode primitives":
  test "decode null":
    let v = decode("val: null")
    check v["val"].isNull()

  test "decode boolean true":
    let v = decode("val: true")
    check v["val"].getBool() == true

  test "decode boolean false":
    let v = decode("val: false")
    check v["val"].getBool() == false

  test "decode positive integer":
    let v = decode("val: 42")
    check v["val"].getInt() == 42

  test "decode zero":
    let v = decode("val: 0")
    check v["val"].getInt() == 0

  test "decode negative integer":
    let v = decode("val: -99")
    check v["val"].getInt() == -99

  test "decode large integer":
    let v = decode("val: 9223372036854775807")
    check v["val"].getInt() == 9223372036854775807'i64

  test "decode float":
    let v = decode("val: 3.14159")
    check v["val"].getFloat() == 3.14159

  test "decode negative float":
    let v = decode("val: -2.718")
    check v["val"].getFloat() == -2.718

  test "decode scientific notation":
    let v = decode("val: 6.022e23")
    check v["val"].kind == vkFloat

  test "decode string unquoted":
    let v = decode("val: hello world")
    check v["val"].getStr() == "hello world"

  test "decode string quoted":
    let v = decode("val: \"hello world\"")
    check v["val"].getStr() == "hello world"

  test "decode string with escapes":
    let v = decode("val: \"line1\\nline2\"")
    check v["val"].getStr() == "line1\nline2"

  test "decode string with tab escape":
    let v = decode("val: \"a\\tb\"")
    check v["val"].getStr() == "a\tb"

  test "decode string with backslash escape":
    let v = decode("val: \"path\\\\file\"")
    check v["val"].getStr() == "path\\file"

  test "decode string with quote escape":
    let v = decode("val: \"say \\\"hi\\\"\"")
    check v["val"].getStr() == "say \"hi\""

# T024: Decoder tests for objects
suite "decode objects":
  test "decode simple object":
    let toon = """
name: Ada
age: 42
"""
    let v = decode(toon)
    check v.kind == vkObject
    check v["name"].getStr() == "Ada"
    check v["age"].getInt() == 42

  test "decode nested object":
    let toon = """
person:
  name: Ada
  address:
    city: London
    zip: 12345
"""
    let v = decode(toon)
    check v["person"]["name"].getStr() == "Ada"
    check v["person"]["address"]["city"].getStr() == "London"
    check v["person"]["address"]["zip"].getInt() == 12345

  test "decode object preserves order":
    let toon = """
z: 1
y: 2
x: 3
"""
    let v = decode(toon)
    let k = v.keys()
    check k == @["z", "y", "x"]

  test "decode object with empty value":
    let toon = """
present:
absent: null
"""
    let v = decode(toon)
    # Per TOON spec, "key:" with nothing after is empty object, not null
    check v["present"].kind == vkObject
    check v["present"].keys().len == 0
    check v["absent"].kind == vkNull

  test "decode object with quoted key":
    let v = decode("\"my key\": value")
    check v["my key"].getStr() == "value"

  test "decode object with special key":
    let v = decode("\"key:colon\": value")
    check v["key:colon"].getStr() == "value"

# T025: Decoder tests for arrays (inline, list, tabular)
# Note: TOON spec requires explicit array headers for inline arrays
suite "decode inline arrays":
  test "decode comma-separated":
    # TOON requires array header for inline arrays
    let v = decode("nums[3]: 1, 2, 3")
    check v["nums"].kind == vkArray
    check v["nums"].len == 3
    check v["nums"][0].getInt() == 1
    check v["nums"][2].getInt() == 3

  test "decode tab-separated":
    let v = decode("nums[3\t]: 1\t2\t3")
    check v["nums"].len == 3

  test "decode pipe-separated":
    let v = decode("nums[3|]: 1|2|3")
    check v["nums"].len == 3

  test "decode mixed types inline":
    let v = decode("mix[4]: 1, hello, true, 3.14")
    check v["mix"][0].kind == vkInt
    check v["mix"][1].kind == vkString
    check v["mix"][2].kind == vkBool
    check v["mix"][3].kind == vkFloat

  test "decode inline with quoted delimiter":
    let v = decode("vals[2]: \"a,b\", c")
    check v["vals"].len == 2
    check v["vals"][0].getStr() == "a,b"

  test "value without array header is string":
    # Per TOON spec, commas in values without array header are literal
    let v = decode("note: a,b")
    check v["note"].kind == vkString
    check v["note"].getStr() == "a,b"

suite "decode list arrays":
  test "decode simple list":
    let toon = """
items:
- one
- two
- three
"""
    let v = decode(toon)
    check v["items"].kind == vkArray
    check v["items"].len == 3
    check v["items"][0].getStr() == "one"

  test "decode list with mixed types":
    let toon = """
mix:
- 42
- hello
- true
"""
    let v = decode(toon)
    check v["mix"][0].kind == vkInt
    check v["mix"][1].kind == vkString
    check v["mix"][2].kind == vkBool

  test "decode list of objects":
    let toon = """
people:
- name: Ada
  age: 42
- name: Bob
  age: 35
"""
    let v = decode(toon)
    check v["people"].len == 2
    check v["people"][0]["name"].getStr() == "Ada"
    check v["people"][1]["name"].getStr() == "Bob"

  test "decode nested list":
    let toon = """
outer:
  inner:
  - a
  - b
"""
    let v = decode(toon)
    check v["outer"]["inner"].len == 2

suite "decode tabular arrays":
  test "decode tabular with header":
    let toon = """
users: [2]{id,name}
1, Alice
2, Bob
"""
    let v = decode(toon)
    check v["users"].kind == vkArray
    check v["users"].len == 2
    check v["users"][0]["id"].getInt() == 1
    check v["users"][0]["name"].getStr() == "Alice"

  test "decode tabular count only":
    let toon = """
nums: [3]
10
20
30
"""
    let v = decode(toon)
    check v["nums"].len == 3
    check v["nums"][0].getInt() == 10

  test "decode tabular with more fields":
    let toon = """
data: [2]{a,b,c}
1, 2, 3
4, 5, 6
"""
    let v = decode(toon)
    check v["data"][0]["a"].getInt() == 1
    check v["data"][0]["c"].getInt() == 3
    check v["data"][1]["b"].getInt() == 5

  test "decode nested tabular":
    let toon = """
container:
  items: [2]{x,y}
  10, 20
  30, 40
"""
    let v = decode(toon)
    check v["container"]["items"].len == 2

# T026: Decoder tests for error cases
suite "decode error handling":
  test "invalid escape sequence":
    expect ToonDecodeError:
      discard decode("val: \"hello\\x\"")

  test "unterminated string":
    expect ToonDecodeError:
      discard decode("val: \"hello")

  test "invalid array count":
    expect ToonDecodeError:
      discard decode("arr: [abc]")

  test "missing rows for tabular":
    expect ToonDecodeError:
      discard decode("arr: [5]\n1\n2")

  test "mismatched field count":
    expect ToonDecodeError:
      discard decode("data: [2]{a,b,c}\n1, 2\n3, 4")

  test "inconsistent indent strict mode":
    expect ToonDecodeError:
      discard decode("a:\n  b: 1\n   c: 2", defaultDecodeOptions)

  test "error includes line number":
    try:
      discard decode("a: 1\nb: \"unterminated")
      check false  # should not reach here
    except ToonDecodeError as e:
      check e.line == 2

  test "error includes column":
    try:
      discard decode("val: \"\\x\"")
      check false  # should not reach here
    except ToonDecodeError as e:
      check e.col > 0

suite "decode options":
  test "default options":
    let v = decode("a: 1")
    check v["a"].getInt() == 1

  test "strict mode":
    let opts = DecodeOptions(strict: true, expandPaths: peNone, indentSize: 2)
    let v = decode("a: 1", opts)
    check v["a"].getInt() == 1

  test "lenient mode":
    let opts = DecodeOptions(strict: false, expandPaths: peNone, indentSize: 2)
    let v = decode("a: 1", opts)
    check v["a"].getInt() == 1

  test "custom indent size":
    let opts = DecodeOptions(strict: true, expandPaths: peNone, indentSize: 4)
    let toon = "a:\n    b: 1"
    let v = decode(toon, opts)
    check v["a"]["b"].getInt() == 1

suite "decodeFile":
  test "decode from file":
    let testFile = getTempDir() / "test_decode.toon"
    writeFile(testFile, "name: Ada\nage: 42")
    defer: removeFile(testFile)

    let v = decodeFile(testFile)
    check v["name"].getStr() == "Ada"
    check v["age"].getInt() == 42

  test "decode file not found":
    expect IOError:
      discard decodeFile("/nonexistent/file.toon")

  test "decode file with options":
    let testFile = getTempDir() / "test_decode2.toon"
    writeFile(testFile, "a:\n    b: val")
    defer: removeFile(testFile)

    let opts = DecodeOptions(strict: true, expandPaths: peNone, indentSize: 4)
    let v = decodeFile(testFile, opts)
    check v["a"]["b"].getStr() == "val"

suite "decode complex structures":
  test "deeply nested mixed":
    let toon = """
config:
  server:
    host: localhost
    port: 8080
    features:
    - auth
    - logging
  users: [2]{name,role}
  admin, superuser
  guest, readonly
"""
    let v = decode(toon)
    check v["config"]["server"]["host"].getStr() == "localhost"
    check v["config"]["server"]["port"].getInt() == 8080
    check v["config"]["server"]["features"].len == 2
    check v["config"]["users"].len == 2
    check v["config"]["users"][0]["name"].getStr() == "admin"

  test "array of arrays":
    let toon = """
matrix:
- 1, 2, 3
- 4, 5, 6
"""
    let v = decode(toon)
    check v["matrix"].len == 2
    check v["matrix"][0].len == 3
    check v["matrix"][0][0].getInt() == 1

  test "object in list in object":
    let toon = """
outer:
  list:
  - inner:
      value: 42
"""
    let v = decode(toon)
    check v["outer"]["list"][0]["inner"]["value"].getInt() == 42

suite "path expansion":
  test "expand simple dotted path":
    let toon = "a.b.c: 42"
    let opts = DecodeOptions(strict: false, expandPaths: peSafe, indentSize: 2)
    let v = decode(toon, opts)
    check v["a"]["b"]["c"].getInt() == 42

  test "expand multiple dotted paths":
    let toon = """
data.name: Alice
data.age: 30
"""
    let opts = DecodeOptions(strict: false, expandPaths: peSafe, indentSize: 2)
    let v = decode(toon, opts)
    check v["data"]["name"].getStr() == "Alice"
    check v["data"]["age"].getInt() == 30

  test "expand with array value":
    # Arrays require explicit header like [3]:
    let toon = "config.items[3]: 1, 2, 3"
    let opts = DecodeOptions(strict: false, expandPaths: peSafe, indentSize: 2)
    let v = decode(toon, opts)
    check v["config"]["items"].len == 3
    check v["config"]["items"][0].getInt() == 1

  test "no expand when peNone":
    let toon = "a.b.c: 42"
    let opts = DecodeOptions(strict: false, expandPaths: peNone, indentSize: 2)
    let v = decode(toon, opts)
    check v.hasKey("a.b.c")
    check v["a.b.c"].getInt() == 42

  test "no expand when segment not identifier":
    let toon = "a.b-c.d: 42"
    let opts = DecodeOptions(strict: false, expandPaths: peSafe, indentSize: 2)
    let v = decode(toon, opts)
    # Should not expand because b-c contains hyphen
    check v.hasKey("a.b-c.d")

  test "expand deep nesting":
    let toon = "a.b.c.d.e: value"
    let opts = DecodeOptions(strict: false, expandPaths: peSafe, indentSize: 2)
    let v = decode(toon, opts)
    check v["a"]["b"]["c"]["d"]["e"].getStr() == "value"
