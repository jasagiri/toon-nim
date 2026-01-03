## Unit tests for TOON types module

import unittest
import std/json
import ../../src/toon/types

suite "ToonValueKind":
  test "all kinds exist":
    check vkNull == vkNull
    check vkBool == vkBool
    check vkInt == vkInt
    check vkFloat == vkFloat
    check vkString == vkString
    check vkArray == vkArray
    check vkObject == vkObject

suite "Delimiter":
  test "delimiter values":
    check $dlComma == ","
    check $dlTab == "\t"
    check $dlPipe == "|"

suite "ToonValue constructors":
  test "newToonNull":
    let v = newToonNull()
    check v.kind == vkNull
    check v.isNull()

  test "newToonBool":
    let t = newToonBool(true)
    let f = newToonBool(false)
    check t.kind == vkBool
    check t.boolVal == true
    check f.boolVal == false
    check t.isBool()

  test "newToonInt":
    let v = newToonInt(42)
    check v.kind == vkInt
    check v.intVal == 42
    check v.isInt()

  test "newToonInt int64":
    let v = newToonInt(9223372036854775807'i64)
    check v.kind == vkInt
    check v.intVal == 9223372036854775807'i64

  test "newToonFloat":
    let v = newToonFloat(3.14)
    check v.kind == vkFloat
    check v.floatVal == 3.14
    check v.isFloat()

  test "newToonString":
    let v = newToonString("hello")
    check v.kind == vkString
    check v.strVal == "hello"
    check v.isString()

  test "newToonArray empty":
    let v = newToonArray()
    check v.kind == vkArray
    check v.len == 0
    check v.isArray()

  test "newToonArray with items":
    let v = newToonArray([newToonInt(1), newToonInt(2)])
    check v.kind == vkArray
    check v.len == 2
    check v[0].intVal == 1
    check v[1].intVal == 2

  test "newToonObject empty":
    let v = newToonObject()
    check v.kind == vkObject
    check v.len == 0
    check v.isObject()

  test "newToonObject with pairs":
    let v = newToonObject({"name": newToonString("Ada"), "age": newToonInt(42)})
    check v.kind == vkObject
    check v.len == 2
    check v["name"].strVal == "Ada"
    check v["age"].intVal == 42

suite "ToonValue accessors":
  test "getBool":
    let v = newToonBool(true)
    check v.getBool() == true

  test "getInt":
    let v = newToonInt(42)
    check v.getInt() == 42

  test "getFloat from float":
    let v = newToonFloat(3.14)
    check v.getFloat() == 3.14

  test "getFloat from int":
    let v = newToonInt(42)
    check v.getFloat() == 42.0

  test "getStr":
    let v = newToonString("hello")
    check v.getStr() == "hello"

  test "isNumber":
    check newToonInt(1).isNumber()
    check newToonFloat(1.0).isNumber()
    check not newToonString("1").isNumber()

  test "hasKey":
    let v = newToonObject({"name": newToonString("Ada")})
    check v.hasKey("name")
    check not v.hasKey("age")

  test "keys":
    let v = newToonObject({"a": newToonInt(1), "b": newToonInt(2)})
    let k = v.keys()
    check k.len == 2
    check "a" in k
    check "b" in k

suite "ToonValue mutators":
  test "add to array":
    var v = newToonArray()
    v.add(newToonInt(1))
    v.add(newToonInt(2))
    check v.len == 2
    check v[0].intVal == 1

  test "set object key":
    var v = newToonObject()
    v["name"] = newToonString("Ada")
    check v["name"].strVal == "Ada"

  test "delete object key":
    var v = newToonObject({"a": newToonInt(1), "b": newToonInt(2)})
    v.delete("a")
    check v.len == 1
    check not v.hasKey("a")
    check v.hasKey("b")

suite "ToonValue equality":
  test "null equality":
    check newToonNull() == newToonNull()

  test "bool equality":
    check newToonBool(true) == newToonBool(true)
    check newToonBool(false) == newToonBool(false)
    check not (newToonBool(true) == newToonBool(false))

  test "int equality":
    check newToonInt(42) == newToonInt(42)
    check not (newToonInt(1) == newToonInt(2))

  test "float equality":
    check newToonFloat(3.14) == newToonFloat(3.14)

  test "string equality":
    check newToonString("hello") == newToonString("hello")
    check not (newToonString("a") == newToonString("b"))

  test "array equality":
    let a = newToonArray([newToonInt(1), newToonInt(2)])
    let b = newToonArray([newToonInt(1), newToonInt(2)])
    let c = newToonArray([newToonInt(1), newToonInt(3)])
    check a == b
    check not (a == c)

  test "object equality":
    let a = newToonObject({"x": newToonInt(1)})
    let b = newToonObject({"x": newToonInt(1)})
    let c = newToonObject({"x": newToonInt(2)})
    check a == b
    check not (a == c)

  test "different kinds not equal":
    check not (newToonInt(1) == newToonString("1"))
    check not (newToonNull() == newToonBool(false))

suite "JSON interoperability":
  test "toJsonNode null":
    let v = newToonNull()
    let j = v.toJsonNode()
    check j.kind == JNull

  test "toJsonNode bool":
    let v = newToonBool(true)
    let j = v.toJsonNode()
    check j.kind == JBool
    check j.getBool() == true

  test "toJsonNode int":
    let v = newToonInt(42)
    let j = v.toJsonNode()
    check j.kind == JInt
    check j.getInt() == 42

  test "toJsonNode float":
    let v = newToonFloat(3.14)
    let j = v.toJsonNode()
    check j.kind == JFloat
    check j.getFloat() == 3.14

  test "toJsonNode string":
    let v = newToonString("hello")
    let j = v.toJsonNode()
    check j.kind == JString
    check j.getStr() == "hello"

  test "toJsonNode array":
    let v = newToonArray([newToonInt(1), newToonInt(2)])
    let j = v.toJsonNode()
    check j.kind == JArray
    check j.len == 2

  test "toJsonNode object":
    let v = newToonObject({"name": newToonString("Ada")})
    let j = v.toJsonNode()
    check j.kind == JObject
    check j["name"].getStr() == "Ada"

  test "fromJsonNode round trip":
    let original = newToonObject({
      "name": newToonString("Ada"),
      "age": newToonInt(42),
      "active": newToonBool(true),
      "score": newToonFloat(95.5),
      "tags": newToonArray([newToonString("a"), newToonString("b")])
    })
    let json = original.toJsonNode()
    let restored = json.fromJsonNode()
    check original == restored

  test "toJson and fromJson":
    let v = newToonObject({"x": newToonInt(1)})
    let jsonStr = v.toJson()
    check jsonStr == """{"x":1}"""
    let restored = fromJson(jsonStr)
    check v == restored

suite "Error types":
  test "ToonDecodeError creation":
    let err = newToonDecodeError("test error", 5, 10)
    check err.msg == "test error"
    check err.line == 5
    check err.col == 10

  test "ToonEncodeError creation":
    let err = newToonEncodeError("encode error", 1, 1)
    check err.msg == "encode error"
    check err.line == 1
    check err.col == 1

suite "Options defaults":
  test "defaultEncodeOptions":
    check defaultEncodeOptions.indent == 2
    check defaultEncodeOptions.delimiter == dlComma
    check defaultEncodeOptions.keyFolding == kfNone
    check defaultEncodeOptions.sortKeys == false

  test "defaultDecodeOptions":
    check defaultDecodeOptions.strict == true
    check defaultDecodeOptions.expandPaths == peNone
    check defaultDecodeOptions.indentSize == 2
