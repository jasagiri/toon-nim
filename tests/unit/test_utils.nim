## Unit tests for TOON utils module

import unittest
import ../../src/toon/types
import ../../src/toon/utils

suite "escapeString":
  test "no escaping needed":
    check escapeString("hello") == "hello"
    check escapeString("hello world") == "hello world"

  test "escape backslash":
    check escapeString("a\\b") == "a\\\\b"

  test "escape quote":
    check escapeString("say \"hi\"") == "say \\\"hi\\\""

  test "escape newline":
    check escapeString("line1\nline2") == "line1\\nline2"

  test "escape carriage return":
    check escapeString("a\rb") == "a\\rb"

  test "escape tab":
    check escapeString("a\tb") == "a\\tb"

  test "escape multiple":
    check escapeString("a\nb\tc") == "a\\nb\\tc"

suite "unescapeString":
  test "no escaping":
    check unescapeString("hello") == "hello"

  test "unescape backslash":
    check unescapeString("a\\\\b") == "a\\b"

  test "unescape quote":
    check unescapeString("say \\\"hi\\\"") == "say \"hi\""

  test "unescape newline":
    check unescapeString("line1\\nline2") == "line1\nline2"

  test "unescape carriage return":
    check unescapeString("a\\rb") == "a\rb"

  test "unescape tab":
    check unescapeString("a\\tb") == "a\tb"

  test "invalid escape raises":
    expect ToonDecodeError:
      discard unescapeString("invalid\\x")

  test "unterminated escape raises":
    expect ToonDecodeError:
      discard unescapeString("trailing\\")

suite "hasEscapableChars":
  test "no escapable chars":
    check not hasEscapableChars("hello")
    check not hasEscapableChars("hello world")

  test "has newline":
    check hasEscapableChars("hello\nworld")

  test "has tab":
    check hasEscapableChars("hello\tworld")

  test "has backslash":
    check hasEscapableChars("path\\to\\file")

  test "has quote":
    check hasEscapableChars("say \"hi\"")

suite "needsQuoting":
  test "empty string needs quoting":
    check needsQuoting("")

  test "leading whitespace needs quoting":
    check needsQuoting(" hello")

  test "trailing whitespace needs quoting":
    check needsQuoting("hello ")

  test "true keyword needs quoting":
    check needsQuoting("true")
    check needsQuoting("TRUE")
    check needsQuoting("True")

  test "false keyword needs quoting":
    check needsQuoting("false")

  test "null keyword needs quoting":
    check needsQuoting("null")

  test "number string needs quoting":
    check needsQuoting("42")
    check needsQuoting("3.14")
    check needsQuoting("-5")

  test "leading zero needs quoting":
    check needsQuoting("05")
    check needsQuoting("-05")

  test "hyphen start needs quoting":
    check needsQuoting("-hello")

  test "colon needs quoting":
    check needsQuoting("key:value")

  test "quote needs quoting":
    check needsQuoting("say \"hi\"")

  test "bracket needs quoting":
    check needsQuoting("array[0]")
    check needsQuoting("{object}")

  test "comma delimiter needs quoting":
    check needsQuoting("a,b", dlComma)

  test "tab delimiter needs quoting":
    check needsQuoting("a\tb", dlTab)

  test "pipe delimiter needs quoting":
    check needsQuoting("a|b", dlPipe)

  test "normal string no quoting":
    check not needsQuoting("hello")
    check not needsQuoting("hello-world")
    check not needsQuoting("hello_world")

suite "quoteString":
  test "simple string":
    check quoteString("hello") == "\"hello\""

  test "string with quotes":
    check quoteString("say \"hi\"") == "\"say \\\"hi\\\"\""

  test "string with newline":
    check quoteString("line1\nline2") == "\"line1\\nline2\""

suite "isValidIdentifier":
  test "valid identifiers":
    check isValidIdentifier("name")
    check isValidIdentifier("_name")
    check isValidIdentifier("name123")
    check isValidIdentifier("_name_123")
    check isValidIdentifier("Name")
    check isValidIdentifier("NAME")

  test "invalid identifiers":
    check not isValidIdentifier("")
    check not isValidIdentifier("123name")
    check not isValidIdentifier("name-with-dash")
    check not isValidIdentifier("name.with.dot")
    check not isValidIdentifier("name with space")

suite "parsePrimitive":
  test "parse null":
    let (kind, val) = parsePrimitive("null")
    check kind == vkNull

  test "parse true":
    let (kind, val) = parsePrimitive("true")
    check kind == vkBool
    check val == "true"

  test "parse false":
    let (kind, val) = parsePrimitive("false")
    check kind == vkBool
    check val == "false"

  test "parse integer":
    let (kind, val) = parsePrimitive("42")
    check kind == vkInt
    check val == "42"

  test "parse negative integer":
    let (kind, val) = parsePrimitive("-42")
    check kind == vkInt
    check val == "-42"

  test "parse float":
    let (kind, val) = parsePrimitive("3.14")
    check kind == vkFloat
    check val == "3.14"

  test "parse string":
    let (kind, val) = parsePrimitive("hello")
    check kind == vkString
    check val == "hello"

  test "parse with whitespace":
    let (kind, val) = parsePrimitive("  hello  ")
    check kind == vkString
    check val == "hello"

suite "splitDelimited":
  test "split by comma":
    let parts = splitDelimited("a,b,c", dlComma)
    check parts == @["a", "b", "c"]

  test "split by tab":
    let parts = splitDelimited("a\tb\tc", dlTab)
    check parts == @["a", "b", "c"]

  test "split by pipe":
    let parts = splitDelimited("a|b|c", dlPipe)
    check parts == @["a", "b", "c"]

  test "split with whitespace":
    let parts = splitDelimited(" a , b , c ", dlComma)
    check parts == @["a", "b", "c"]

  test "split with quoted values":
    let parts = splitDelimited("\"a,b\",c", dlComma)
    check parts.len == 2
    check parts[0] == "\"a,b\""
    check parts[1] == "c"

  test "split empty":
    let parts = splitDelimited("", dlComma)
    check parts == @[""]

  test "single value":
    let parts = splitDelimited("single", dlComma)
    check parts == @["single"]

suite "indentation":
  test "countIndent":
    check countIndent("hello") == 0
    check countIndent("  hello") == 2
    check countIndent("    hello") == 4
    check countIndent("") == 0

  test "getIndentLevel":
    check getIndentLevel("hello", 2) == 0
    check getIndentLevel("  hello", 2) == 1
    check getIndentLevel("    hello", 2) == 2
    check getIndentLevel("      hello", 2) == 3
    check getIndentLevel("    hello", 4) == 1

  test "makeIndent":
    check makeIndent(0, 2) == ""
    check makeIndent(1, 2) == "  "
    check makeIndent(2, 2) == "    "
    check makeIndent(1, 4) == "    "

  test "detectIndentSize":
    let lines = @["root:", "  child:", "    grandchild:"]
    check detectIndentSize(lines) == 2

    let lines4 = @["root:", "    child:"]
    check detectIndentSize(lines4) == 4
