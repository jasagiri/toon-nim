# CLI Usage Guide

Complete reference for the `tooncli` command-line tool.

## Installation

After installing toon-nim:

```bash
nimble install toon_nim
```

The `tooncli` binary will be available in your Nimble bin directory.

## Basic Usage

### Converting TOON to JSON

```bash
tooncli data.toon --json
```

### Converting JSON to TOON

```bash
tooncli data.json --toon
```

### Reading from stdin

```bash
echo "name: Ada" | tooncli --json -
cat data.toon | tooncli --json -
```

### Writing to a file

```bash
tooncli data.toon --json -o=output.json
tooncli data.json --toon --output=output.toon
```

## Command Reference

```
tooncli - TOON Format CLI Converter

Usage: tooncli [OPTIONS] [FILE]

Arguments:
  FILE                Input file (use '-' for stdin)

Options:
  -h, --help          Show help message
  -v, --version       Show version number
  -j, --json          Output as JSON
  -t, --toon          Output as TOON
  -o, --output FILE   Write output to file
  --pretty            Pretty-print JSON (default)
  --compact           Compact JSON output
  --indent N          Indentation size (default: 2)
  --delimiter TYPE    Array delimiter: comma, tab, pipe
  --sort-keys         Sort object keys alphabetically
  --strict            Enable strict mode parsing
```

## Options Details

### Output Format

| Option | Description |
|--------|-------------|
| `--json`, `-j` | Output as JSON format |
| `--toon`, `-t` | Output as TOON format |

If neither is specified, the tool auto-detects based on input file extension.

### JSON Formatting

| Option | Description |
|--------|-------------|
| `--pretty` | Pretty-print JSON with indentation (default) |
| `--compact` | Compact JSON without whitespace |

### TOON Formatting

| Option | Description |
|--------|-------------|
| `--indent N` | Number of spaces per indent level (default: 2) |
| `--delimiter TYPE` | Array delimiter: `comma`, `tab`, or `pipe` |
| `--sort-keys` | Sort object keys alphabetically |

### Parsing Options

| Option | Description |
|--------|-------------|
| `--strict` | Enable strict mode (errors on format violations) |

## Examples

### Basic Conversion

```bash
# TOON to JSON
tooncli config.toon --json

# JSON to TOON
tooncli config.json --toon
```

### Formatting Options

```bash
# Compact JSON output
tooncli data.toon --json --compact

# Custom indentation
tooncli data.json --toon --indent=4

# Tab-delimited arrays
tooncli data.json --toon --delimiter=tab

# Sorted keys
tooncli data.json --toon --sort-keys
```

### Pipeline Usage

```bash
# Process and pipe to another command
tooncli data.toon --json | jq '.users'

# Chain conversions
cat data.json | tooncli --toon - | tooncli --json -

# Use with curl
curl -s https://api.example.com/data | tooncli --toon -
```

### File Operations

```bash
# Convert and save
tooncli input.toon --json -o=output.json

# Batch conversion (using shell)
for f in *.toon; do
  tooncli "$f" --json -o="${f%.toon}.json"
done
```

### Validation

```bash
# Validate TOON in strict mode
tooncli data.toon --strict --json > /dev/null && echo "Valid"

# Check for parsing errors
if tooncli data.toon --json 2>/dev/null; then
  echo "Valid TOON"
else
  echo "Invalid TOON"
fi
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Parse error or invalid input |
| 2 | File not found or I/O error |
| 3 | Invalid command-line options |

## Error Messages

Common error messages and their meaning:

| Error | Cause |
|-------|-------|
| `Parse error at line N, column M` | Syntax error in input |
| `File not found: path` | Input file doesn't exist |
| `Cannot read from stdin` | Stdin not available |
| `Unknown option: --foo` | Invalid command-line option |
