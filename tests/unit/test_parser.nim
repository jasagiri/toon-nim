## Unit tests for TOON parser module
## T022: Parser tests - tests for parsing tokens into ToonValue

import unittest
import ../../src/toon/types
import ../../src/toon/parser

suite "Parser primitives":
  test "parse null":
    let v = parseToon("value: null")
    check v.kind == vkObject
    check v["value"].kind == vkNull

  test "parse true":
    let v = parseToon("flag: true")
    check v["flag"].kind == vkBool
    check v["flag"].getBool() == true

  test "parse false":
    let v = parseToon("flag: false")
    check v["flag"].kind == vkBool
    check v["flag"].getBool() == false

  test "parse TRUE (case insensitive)":
    let v = parseToon("flag: TRUE")
    check v["flag"].kind == vkBool
    check v["flag"].getBool() == true

  test "parse integer":
    let v = parseToon("num: 42")
    check v["num"].kind == vkInt
    check v["num"].getInt() == 42

  test "parse negative integer":
    let v = parseToon("num: -42")
    check v["num"].kind == vkInt
    check v["num"].getInt() == -42

  test "parse float":
    let v = parseToon("num: 3.14")
    check v["num"].kind == vkFloat
    check v["num"].getFloat() == 3.14

  test "parse negative float":
    let v = parseToon("num: -3.14")
    check v["num"].kind == vkFloat
    check v["num"].getFloat() == -3.14

  test "parse scientific notation":
    let v = parseToon("num: 1.5e10")
    check v["num"].kind == vkFloat
    check v["num"].getFloat() == 1.5e10

  test "parse string":
    let v = parseToon("msg: hello world")
    check v["msg"].kind == vkString
    check v["msg"].getStr() == "hello world"

  test "parse empty string value":
    let v = parseToon("msg:")
    check v["msg"].kind == vkNull

  test "parse quoted string":
    let v = parseToon("msg: \"hello world\"")
    check v["msg"].kind == vkString
    check v["msg"].getStr() == "hello world"

suite "Parser objects":
  test "simple object":
    let v = parseToon("name: Ada\nage: 42")
    check v.kind == vkObject
    check v.len == 2
    check v["name"].getStr() == "Ada"
    check v["age"].getInt() == 42

  test "nested object":
    let toon = """
person:
  name: Ada
  age: 42
"""
    let v = parseToon(toon)
    check v["person"].kind == vkObject
    check v["person"]["name"].getStr() == "Ada"
    check v["person"]["age"].getInt() == 42

  test "deeply nested object":
    let toon = """
a:
  b:
    c:
      d: value
"""
    let v = parseToon(toon)
    check v["a"]["b"]["c"]["d"].getStr() == "value"

  test "sibling objects":
    let toon = """
person1:
  name: Ada
person2:
  name: Bob
"""
    let v = parseToon(toon)
    check v["person1"]["name"].getStr() == "Ada"
    check v["person2"]["name"].getStr() == "Bob"

  test "object preserves key order":
    let toon = """
z: 1
a: 2
m: 3
"""
    let v = parseToon(toon)
    let keys = v.keys()
    check keys[0] == "z"
    check keys[1] == "a"
    check keys[2] == "m"

suite "Parser inline arrays":
  test "inline array comma":
    let v = parseToon("nums: 1, 2, 3")
    check v["nums"].kind == vkArray
    check v["nums"].len == 3
    check v["nums"][0].getInt() == 1
    check v["nums"][1].getInt() == 2
    check v["nums"][2].getInt() == 3

  test "inline array tab":
    let v = parseToon("nums: 1\t2\t3")
    check v["nums"].kind == vkArray
    check v["nums"].len == 3

  test "inline array pipe":
    let v = parseToon("nums: 1|2|3")
    check v["nums"].kind == vkArray
    check v["nums"].len == 3

  test "inline array mixed types":
    let v = parseToon("mix: 1, hello, true, 3.14, null")
    check v["mix"].len == 5
    check v["mix"][0].kind == vkInt
    check v["mix"][1].kind == vkString
    check v["mix"][2].kind == vkBool
    check v["mix"][3].kind == vkFloat
    check v["mix"][4].kind == vkNull

  test "inline array with quoted strings":
    let v = parseToon("msgs: \"a,b\", c, d")
    check v["msgs"].len == 3
    check v["msgs"][0].getStr() == "a,b"
    check v["msgs"][1].getStr() == "c"
    check v["msgs"][2].getStr() == "d"

  test "inline array empty":
    let v = parseToon("arr:")
    check v["arr"].kind == vkNull

suite "Parser list arrays":
  test "simple list":
    let toon = """
items:
- one
- two
- three
"""
    let v = parseToon(toon)
    check v["items"].kind == vkArray
    check v["items"].len == 3
    check v["items"][0].getStr() == "one"
    check v["items"][1].getStr() == "two"
    check v["items"][2].getStr() == "three"

  test "list with mixed types":
    let toon = """
mix:
- 42
- hello
- true
- 3.14
- null
"""
    let v = parseToon(toon)
    check v["mix"].len == 5
    check v["mix"][0].kind == vkInt
    check v["mix"][1].kind == vkString
    check v["mix"][2].kind == vkBool
    check v["mix"][3].kind == vkFloat
    check v["mix"][4].kind == vkNull

  test "nested list":
    let toon = """
outer:
  items:
  - one
  - two
"""
    let v = parseToon(toon)
    check v["outer"]["items"].len == 2

  test "list of objects":
    let toon = """
people:
- name: Ada
  age: 42
- name: Bob
  age: 35
"""
    let v = parseToon(toon)
    check v["people"].len == 2
    check v["people"][0]["name"].getStr() == "Ada"
    check v["people"][0]["age"].getInt() == 42
    check v["people"][1]["name"].getStr() == "Bob"

  test "list with inline arrays":
    let toon = """
data:
- 1, 2, 3
- 4, 5, 6
"""
    let v = parseToon(toon)
    check v["data"].len == 2
    check v["data"][0].kind == vkArray
    check v["data"][0].len == 3

suite "Parser tabular arrays":
  test "tabular array with header":
    let toon = """
users: [2]{id,name}
1, Alice
2, Bob
"""
    let v = parseToon(toon)
    check v["users"].kind == vkArray
    check v["users"].len == 2
    check v["users"][0]["id"].getInt() == 1
    check v["users"][0]["name"].getStr() == "Alice"
    check v["users"][1]["id"].getInt() == 2
    check v["users"][1]["name"].getStr() == "Bob"

  test "tabular array tab delimiter":
    let toon = "users: [2]{id,name}\n1\tAlice\n2\tBob"
    let v = parseToon(toon)
    check v["users"].len == 2
    check v["users"][0]["id"].getInt() == 1

  test "tabular array count only":
    let toon = """
nums: [3]
1
2
3
"""
    let v = parseToon(toon)
    check v["nums"].kind == vkArray
    check v["nums"].len == 3
    check v["nums"][0].getInt() == 1

  test "nested tabular array":
    let toon = """
data:
  items: [2]{a,b}
  1, 2
  3, 4
"""
    let v = parseToon(toon)
    check v["data"]["items"].len == 2

suite "Parser edge cases":
  test "empty input":
    let v = parseToon("")
    check v.kind == vkObject
    check v.len == 0

  test "whitespace only":
    let v = parseToon("   \n   \n   ")
    check v.kind == vkObject
    check v.len == 0

  test "trailing newlines":
    let v = parseToon("name: Ada\n\n\n")
    check v["name"].getStr() == "Ada"

  test "leading newlines":
    let v = parseToon("\n\nname: Ada")
    check v["name"].getStr() == "Ada"

  test "key with special chars quoted":
    let v = parseToon("\"key:with:colons\": value")
    check v["key:with:colons"].getStr() == "value"

  test "value with leading spaces preserved in quotes":
    let v = parseToon("msg: \"  spaced  \"")
    check v["msg"].getStr() == "  spaced  "

  test "consecutive colons in value":
    let v = parseToon("time: 12:30:45")
    check v["time"].getStr() == "12:30:45"

suite "Parser indentation handling":
  test "consistent 2-space indent":
    let toon = """
a:
  b:
    c: val
"""
    let v = parseToon(toon)
    check v["a"]["b"]["c"].getStr() == "val"

  test "consistent 4-space indent":
    let toon = """
a:
    b:
        c: val
"""
    let v = parseToon(toon)
    check v["a"]["b"]["c"].getStr() == "val"

  test "dedent to parent level":
    let toon = """
a:
  b: 1
c: 2
"""
    let v = parseToon(toon)
    check v["a"]["b"].getInt() == 1
    check v["c"].getInt() == 2

  test "dedent multiple levels":
    let toon = """
a:
  b:
    c: 1
d: 2
"""
    let v = parseToon(toon)
    check v["a"]["b"]["c"].getInt() == 1
    check v["d"].getInt() == 2

suite "Parser strict mode":
  test "strict mode rejects inconsistent indent":
    let toon = """
a:
  b: 1
   c: 2
"""
    expect ToonDecodeError:
      discard parseToon(toon, DecodeOptions(strict: true, expandPaths: peNone, indentSize: 2))

  test "strict mode rejects tabs mixed with spaces":
    let toon = "a:\n\tb: 1"
    expect ToonDecodeError:
      discard parseToon(toon, DecodeOptions(strict: true, expandPaths: peNone, indentSize: 2))

suite "Parser lenient mode":
  test "lenient mode accepts inconsistent indent":
    let toon = """
a:
  b: 1
   c: 2
"""
    let v = parseToon(toon, DecodeOptions(strict: false, expandPaths: peNone, indentSize: 2))
    check v["a"]["b"].getInt() == 1

suite "Parser options":
  test "custom indent size":
    let toon = """
a:
    b: val
"""
    let v = parseToon(toon, DecodeOptions(strict: true, expandPaths: peNone, indentSize: 4))
    check v["a"]["b"].getStr() == "val"
