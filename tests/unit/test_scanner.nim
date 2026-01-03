## Unit tests for TOON scanner module
## T021: Scanner tests - tests for tokenization

import unittest
import ../../src/toon/types
import ../../src/toon/scanner

suite "Token types":
  test "TokenKind enum values exist":
    check tkEof == tkEof
    check tkNewline == tkNewline
    check tkIndent == tkIndent
    check tkKey == tkKey
    check tkColon == tkColon
    check tkValue == tkValue
    check tkQuotedString == tkQuotedString
    check tkListMarker == tkListMarker
    check tkArrayHeader == tkArrayHeader
    check tkDelimiter == tkDelimiter

suite "Scanner basic tokenization":
  test "empty input":
    var s = newScanner("")
    let tok = s.nextToken()
    check tok.kind == tkEof

  test "single key-value":
    var s = newScanner("name: Ada")
    var tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "name"

    tok = s.nextToken()
    check tok.kind == tkColon

    tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "Ada"

    tok = s.nextToken()
    check tok.kind == tkEof

  test "multiple lines":
    var s = newScanner("name: Ada\nage: 42")

    var tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "name"

    tok = s.nextToken()
    check tok.kind == tkColon

    tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "Ada"

    tok = s.nextToken()
    check tok.kind == tkNewline

    tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "age"

    tok = s.nextToken()
    check tok.kind == tkColon

    tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "42"

suite "Scanner indentation":
  test "detect indentation":
    var s = newScanner("parent:\n  child: value")

    var tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "parent"

    tok = s.nextToken()
    check tok.kind == tkColon

    tok = s.nextToken()
    check tok.kind == tkNewline

    tok = s.nextToken()
    check tok.kind == tkIndent
    check tok.indent == 2

    tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "child"

  test "multiple indent levels":
    var s = newScanner("a:\n  b:\n    c: val")

    discard s.nextToken()  # key a
    discard s.nextToken()  # colon
    discard s.nextToken()  # newline

    var tok = s.nextToken()
    check tok.kind == tkIndent
    check tok.indent == 2

    discard s.nextToken()  # key b
    discard s.nextToken()  # colon
    discard s.nextToken()  # newline

    tok = s.nextToken()
    check tok.kind == tkIndent
    check tok.indent == 4

suite "Scanner quoted strings":
  test "simple quoted string":
    var s = newScanner("msg: \"hello world\"")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkQuotedString
    check tok.value == "hello world"

  test "quoted string with escapes":
    var s = newScanner("msg: \"line1\\nline2\"")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkQuotedString
    check tok.value == "line1\nline2"

  test "quoted string with escaped quote":
    var s = newScanner("msg: \"say \\\"hi\\\"\"")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkQuotedString
    check tok.value == "say \"hi\""

  test "quoted string with backslash":
    var s = newScanner("path: \"c:\\\\users\"")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkQuotedString
    check tok.value == "c:\\users"

suite "Scanner list markers":
  test "simple list marker":
    var s = newScanner("items:\n- one\n- two")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon
    discard s.nextToken()  # newline

    var tok = s.nextToken()
    check tok.kind == tkListMarker

    tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "one"

    discard s.nextToken()  # newline

    tok = s.nextToken()
    check tok.kind == tkListMarker

    tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "two"

  test "indented list marker":
    var s = newScanner("obj:\n  items:\n  - one")

    discard s.nextToken()  # key obj
    discard s.nextToken()  # colon
    discard s.nextToken()  # newline
    discard s.nextToken()  # indent
    discard s.nextToken()  # key items
    discard s.nextToken()  # colon
    discard s.nextToken()  # newline

    var tok = s.nextToken()
    check tok.kind == tkIndent
    check tok.indent == 2

    tok = s.nextToken()
    check tok.kind == tkListMarker

suite "Scanner array headers":
  test "simple array header":
    var s = newScanner("data: [3]")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkArrayHeader
    check tok.count == 3

  test "array header with field count":
    var s = newScanner("data: [3]{name,age}")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkArrayHeader
    check tok.count == 3
    check tok.fields == @["name", "age"]

  test "tabular array with fields":
    var s = newScanner("users: [2]{id,name}\n1, Alice\n2, Bob")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkArrayHeader
    check tok.count == 2
    check tok.fields == @["id", "name"]

suite "Scanner delimiters":
  test "comma delimiter":
    var s = newScanner("nums: 1, 2, 3")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "1"

    tok = s.nextToken()
    check tok.kind == tkDelimiter
    check tok.delimiterChar == ','

    tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "2"

  test "tab delimiter":
    var s = newScanner("nums: 1\t2\t3")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "1"

    tok = s.nextToken()
    check tok.kind == tkDelimiter
    check tok.delimiterChar == '\t'

  test "pipe delimiter":
    var s = newScanner("nums: 1|2|3")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "1"

    tok = s.nextToken()
    check tok.kind == tkDelimiter
    check tok.delimiterChar == '|'

suite "Scanner position tracking":
  test "track line and column":
    var s = newScanner("name: Ada\nage: 42")

    var tok = s.nextToken()
    check tok.line == 1
    check tok.col == 1

    discard s.nextToken()  # colon
    tok = s.nextToken()    # value Ada
    check tok.line == 1

    discard s.nextToken()  # newline
    tok = s.nextToken()    # key age
    check tok.line == 2
    check tok.col == 1

suite "Scanner error handling":
  test "unterminated quoted string":
    var s = newScanner("msg: \"hello")
    discard s.nextToken()  # key
    discard s.nextToken()  # colon
    expect ToonDecodeError:
      discard s.nextToken()

  test "invalid escape sequence":
    var s = newScanner("msg: \"hello\\x\"")
    discard s.nextToken()  # key
    discard s.nextToken()  # colon
    expect ToonDecodeError:
      discard s.nextToken()

  test "invalid array header":
    var s = newScanner("data: [abc]")
    discard s.nextToken()  # key
    discard s.nextToken()  # colon
    expect ToonDecodeError:
      discard s.nextToken()

suite "Scanner edge cases":
  test "empty value":
    var s = newScanner("key:")

    var tok = s.nextToken()
    check tok.kind == tkKey

    tok = s.nextToken()
    check tok.kind == tkColon

    tok = s.nextToken()
    check tok.kind == tkEof

  test "whitespace only value":
    var s = newScanner("key:   ")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkEof

  test "key with numbers":
    var s = newScanner("key123: value")

    var tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "key123"

  test "key with underscores":
    var s = newScanner("my_key: value")

    var tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "my_key"

  test "quoted key":
    var s = newScanner("\"my key\": value")

    var tok = s.nextToken()
    check tok.kind == tkKey
    check tok.value == "my key"

  test "comment handling":
    # TOON has no comments, but we test that # is treated as regular content
    var s = newScanner("note: # not a comment")

    discard s.nextToken()  # key
    discard s.nextToken()  # colon

    var tok = s.nextToken()
    check tok.kind == tkValue
    check tok.value == "# not a comment"
