# Quickstart: toon-nim

Get started with the TOON format library for Nim in under 5 minutes.

## Installation

Add to your `.nimble` file:

```nimble
requires "toon >= 0.1.0"
```

Or install directly:

```bash
nimble install toon
```

## Basic Usage

### Import the Library

```nim
import toon
```

### Decode TOON to Nim Values

```nim
let input = """
name: Ada Lovelace
age: 42
active: true
tags[3]: admin,developer,analyst
"""

let data = decode(input)

# Access values
echo data["name"].getStr()   # Ada Lovelace
echo data["age"].getInt()    # 42
echo data["active"].getBool() # true
echo data["tags"][0].getStr() # admin
```

### Encode Nim Values to TOON

```nim
let data = newToonObject({
  "name": newToonString("Ada Lovelace"),
  "age": newToonInt(42),
  "active": newToonBool(true),
  "tags": newToonArray([
    newToonString("admin"),
    newToonString("developer"),
    newToonString("analyst")
  ])
})

echo encode(data)
# Output:
# name: Ada Lovelace
# age: 42
# active: true
# tags[3]: admin,developer,analyst
```

## CLI Tool

### Install the CLI

```bash
nimble install toon  # CLI is included
```

### Convert TOON to JSON

```bash
# From file
tooncli --json data.toon

# From stdin
echo 'name: Ada' | tooncli --json
# Output: {"name":"Ada"}
```

### Convert JSON to TOON

```bash
echo '{"name":"Ada","age":42}' | tooncli --toon
# Output:
# name: Ada
# age: 42
```

## Working with Files

```nim
# Decode from file
let data = decodeFile("config.toon")

# Encode to file
encodeToFile(data, "output.toon")
```

## JSON Interoperability

```nim
import toon
import std/json

# TOON to JSON
let toonData = decode("name: Ada")
let jsonNode = toonData.toJsonNode()
echo jsonNode.pretty()

# JSON to TOON
let jsonData = parseJson("""{"name":"Ada"}""")
let toonValue = fromJsonNode(jsonData)
echo encode(toonValue)
```

## Error Handling

```nim
import toon

try:
  let data = decode("invalid: [broken")
except ToonDecodeError as e:
  echo "Parse error at line ", e.line, ", column ", e.col
  echo "Details: ", e.msg
```

## Custom Encoding Options

```nim
let options = EncodeOptions(
  indent: 4,                # 4 spaces per level
  delimiter: dlPipe,        # Use | as array delimiter
  keyFolding: kfSafe,       # Enable key folding
  sortKeys: true            # Sort object keys
)

echo encode(data, options)
```

## TOON Format Examples

### Simple Object
```
name: Ada Lovelace
age: 42
active: true
```

### Nested Objects
```
user:
  name: Ada
  address:
    city: London
    country: UK
```

### Arrays (Inline)
```
tags[3]: admin,developer,analyst
numbers[5]: 1,2,3,4,5
```

### Arrays (List Form)
```
items[2]:
  - first item
  - second item
```

### Tabular Data
```
users[3]{id,name,role}:
  1,Ada,admin
  2,Bob,user
  3,Carol,user
```

## Next Steps

- See [Library API](contracts/library-api.md) for full API reference
- See [CLI Interface](contracts/cli-interface.md) for CLI options
- See [Data Model](data-model.md) for type definitions
- Run `tooncli --help` for CLI usage
