## External specification tests for the rules the official fixtures cannot
## express: their inputs are JSON, which has no NaN, no ill-formed UTF-8 and
## no number beyond float64. IDs are those of docs/quality/spec-traceability.md.

import std/[unittest, json, os]
import ../../src/toon

suite "Host rules of TOON 4.4 that JSON fixtures cannot carry":
  test "HOST-01 (§3): Given NaN and ±Infinity, When encoded, Then each becomes null":
    let v = newToonArray([newToonFloat(NaN), newToonFloat(Inf), newToonFloat(NegInf)])
    check encode(v) == "[3]: null,null,null"

  test "HOST-02 (§3): Given a string holding an unpaired surrogate, When encoded, Then encoding errors":
    # U+D800 written as UTF-8 bytes, as a host string can hold it.
    expect ToonEncodeError:
      discard encode(newToonObject({"s": newToonString("a\xED\xA0\x80b")}))
    expect ToonEncodeError:
      discard encode(newToonObject({"k\xED\xA0\x80": newToonInt(1)}))

  test "HOST-03 (§4): Given ill-formed UTF-8 input, When decoded, Then decoding errors in both modes":
    for strict in [true, false]:
      let opts = DecodeOptions(strict: strict, indentSize: 2)
      expect ToonDecodeError:
        discard decode("name: a\xC3", opts)          # truncated sequence
      expect ToonDecodeError:
        discard decode("name: \xED\xA0\x80", opts)   # surrogate code point
      expect ToonDecodeError:
        discard decode("name: \xC0\xAF", opts)       # overlong form

  test "HOST-04 (§4, README): Given an integer beyond int64, When decoded, Then it is its float64 approximation":
    let v = decode("n: 123456789012345678901")
    check v["n"].kind == vkFloat
    check v["n"].getFloat == 123456789012345678901.0
    check decode("n: -9223372036854775808")["n"].getInt == low(int64)

  test "HOST-05 (§4, README): Given a number beyond float64, When decoded, Then decoding errors":
    expect ToonDecodeError:
      discard decode("n: 1e400")

  test "HOST-06 (§2): Given JSON with an integer beyond int64 and ordered keys, When encoded from JsonNode, Then the order holds and the number is canonical":
    let j = parseJson("""{"z": 1, "a": 100000000000000000000, "m": [1.5, 2]}""")
    check encode(j) == "z: 1\na: 100000000000000000000\nm[2]: 1.5,2"

  test "HOST-07: Given a JSON document, When encoded and decoded, Then the decoded value equals it":
    let j = parseJson("""{"issues": [{"id": "a1", "title": "Fix: x, y", "due": null,
      "blockedBy": [], "labels": ["hcr", "upstream"]}, {"id": "b2", "title": "- dash",
      "due": "2026-10-19", "blockedBy": ["a1"], "labels": []}], "count": 2}""")
    check decode(encode(j)) == fromJsonNode(j)

  test "HOST-08: Given an indentSize below 1, When encoding or decoding, Then it errors":
    expect ToonEncodeError:
      discard encode(newToonObject(), EncodeOptions(indentSize: 0, delimiter: dlComma))
    expect ToonDecodeError:
      discard decode("a: 1", DecodeOptions(strict: true, indentSize: 0))

  test "HOST-09: Given a value, When written with encodeToFile and read with decodeFile, Then the same value returns":
    let path = getTempDir() / ("toon_host_" & $getCurrentProcessId() & ".toon")
    defer: removeFile(path)
    let v = fromJsonNode(parseJson("""{"a": [1, 2], "b": {"c": "x y"}}"""))
    encodeToFile(v, path)
    check readFile(path) == "a[2]: 1,2\nb:\n  c: x y"
    check decodeFile(path) == v
