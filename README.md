# toon-nim

A Nim encoder and decoder for TOON (Token-Oriented Object Notation), a
line-oriented encoding of the JSON data model meant for passing data to LLMs.

`toon-spec: 4.4` — conforms to the [TOON specification](https://github.com/toon-format/spec)
4.4 and passes all 564 of its official conformance fixtures (encode 160,
decode 404). See [Conformance](#conformance).

## Installation

```bash
nimble install https://github.com/jasagiri/toon-nim
```

## Usage

```nim
import std/json
import toon

# JSON in, TOON out
echo encode(parseJson("""{"users": [{"id": 1, "name": "Ada"}, {"id": 2, "name": "Bob"}]}"""))
# users[2]{id,name}:
#   1,Ada
#   2,Bob

# TOON in, a value out
let v = decode("name: Ada\ntags[2]: math,code")
echo v["tags"][1].getStr()    # code
echo v.toJsonNode()           # {"name":"Ada","tags":["math","code"]}
```

### API

| Proc | Purpose |
|---|---|
| `encode(v: ToonValue, opts = defaultEncodeOptions): string` | Encode a value |
| `encode(j: JsonNode, opts = defaultEncodeOptions): string` | Encode a JSON value |
| `encodeToFile(v, path, opts)` | Encode and write a file |
| `decode(input: string, opts = defaultDecodeOptions): ToonValue` | Decode a document |
| `decodeFile(path, opts)` | Read and decode a file |
| `toJsonNode(v)`, `fromJsonNode(j)` | Convert between `ToonValue` and `JsonNode` |

Options (specification §13):

- `EncodeOptions(indentSize: 2, delimiter: dlComma)` — `delimiter` is the
  document delimiter: `dlComma`, `dlTab` or `dlPipe`.
- `DecodeOptions(strict: true, indentSize: 2)` — with `strict = false`, only
  the five recoveries of §14.4 apply.

Errors: `encode` raises `ToonEncodeError` for a string or key that is not
well-formed UTF-8; `decode` raises `ToonDecodeError`, whose `line` is the
1-based input line, on every condition of §14.

`ToonValue` is a variant of null, bool, int (int64), float (float64), string,
array and object (`OrderedTable`, so key order is kept). Constructors are
`newToonNull`, `newToonBool`, `newToonInt`, `newToonFloat`, `newToonString`,
`newToonArray` and `newToonObject`; accessors are `getBool`, `getInt`,
`getFloat`, `getStr`, `[]`, `hasKey`, `keys`, `items` and `pairs`. `==` is the
JSON-model equality of §2.

## CLI

```bash
nimble buildCli
bin/tooncli data.json --toon          # JSON to TOON
bin/tooncli data.toon --json          # TOON to JSON
echo "name: Ada" | bin/tooncli - --json
bin/tooncli data.json --toon --indent=4 --delimiter=tab
bin/tooncli data.toon --json --lenient   # non-strict decoding
```

The format is chosen from the file extension or the first character when
neither `--json` nor `--toon` is given. Run `bin/tooncli --help` for all options.

## Conformance

Declarations the specification asks of an implementation (§13.2):

- **Numbers (§4).** An integer token within int64 decodes to an int; any other
  number token decodes to the nearest float64. A number whose magnitude is
  beyond float64 (`1e400`) is an error. When encoding, an integer beyond int64
  read from `JsonNode` is its float64 approximation, written in the shortest
  round-trip digits of §2. No lossless stringification option is offered.
- **Keys (§2, §15).** Objects are `OrderedTable[string, ToonValue]`: document
  order is kept and every key, including `__proto__`, is an ordinary entry.
- **Bytes (§4).** `decode` takes a Nim `string`, which may hold any bytes, so
  it checks UTF-8 well-formedness and errors on ill-formed input.

Not offered: a validator (§13.3) and serialization hooks (§3).

Each obligation of §13 and §14 is tied to its tests in
[`docs/quality/spec-traceability.md`](docs/quality/spec-traceability.md).

## Testing

```bash
nimble test          # conformance fixtures, host rules, types, round trip, CLI
nimble conformance   # the official fixtures only
```

The fixtures in `tests/fixtures` come unchanged from the specification
repository (MIT); `tests/fixtures/README.md` records the commit.

## License

Apache-2.0. The conformance fixtures are MIT, Copyright (c) 2025-PRESENT
Johann Schopplich.
