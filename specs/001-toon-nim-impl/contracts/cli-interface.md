# CLI Interface Contract: tooncli

**Version**: 0.1.0
**Date**: 2025-12-08

## Synopsis

```
tooncli [OPTIONS] [FILE]
tooncli --help
tooncli --version
```

## Description

Convert between TOON and JSON formats. Reads from FILE or stdin, writes to stdout.

## Options

### Input/Output Format

| Option | Short | Description |
|--------|-------|-------------|
| `--json` | `-j` | Output as JSON (decode TOON → JSON) |
| `--toon` | `-t` | Output as TOON (encode JSON → TOON) |

If neither `--json` nor `--toon` is specified, the tool auto-detects input format:
- If input starts with `{` or `[`: treat as JSON, output TOON
- Otherwise: treat as TOON, output JSON

### Encoding Options (when outputting TOON)

| Option | Default | Description |
|--------|---------|-------------|
| `--indent=N` | 2 | Spaces per indent level |
| `--delimiter=D` | comma | Array delimiter: comma, tab, pipe |
| `--fold-keys` | off | Enable key folding (a.b.c format) |
| `--sort-keys` | off | Sort object keys alphabetically |

### Decoding Options (when parsing TOON)

| Option | Default | Description |
|--------|---------|-------------|
| `--lenient` | off | Use lenient parsing mode |
| `--expand-paths` | off | Expand dotted keys to nested objects |

### General Options

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help message and exit |
| `--version` | `-v` | Show version number and exit |
| `--pretty` | `-p` | Pretty-print JSON output |
| `--compact` | `-c` | Compact JSON output (no extra whitespace) |
| `--output=FILE` | `-o` | Write output to FILE instead of stdout |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Parse/encoding error |
| 2 | File I/O error |
| 3 | Invalid arguments |

## Input/Output Behavior

### stdin → stdout (default)
```bash
echo 'name: Ada' | tooncli --json
# Output: {"name":"Ada"}
```

### File → stdout
```bash
tooncli --json data.toon
# Output: JSON to stdout
```

### File → File
```bash
tooncli --json data.toon -o data.json
# Output: JSON written to data.json
```

### stdin detection
```bash
cat data.toon | tooncli  # No file argument = read stdin
```

## Examples

### Convert TOON to JSON
```bash
# From file
tooncli --json input.toon

# From stdin
echo 'name: Ada
age: 42' | tooncli --json

# Output:
# {"name":"Ada","age":42}
```

### Convert JSON to TOON
```bash
# From file
tooncli --toon input.json

# From stdin
echo '{"name":"Ada","age":42}' | tooncli --toon

# Output:
# name: Ada
# age: 42
```

### Pretty-print JSON
```bash
tooncli --json --pretty input.toon

# Output:
# {
#   "name": "Ada",
#   "age": 42
# }
```

### Custom TOON formatting
```bash
# Use pipe delimiter and 4-space indent
tooncli --toon --indent=4 --delimiter=pipe input.json

# Enable key folding
tooncli --toon --fold-keys input.json
```

### Auto-detect format
```bash
# Input looks like JSON → output TOON
echo '{"x":1}' | tooncli
# Output: x: 1

# Input looks like TOON → output JSON
echo 'x: 1' | tooncli
# Output: {"x":1}
```

### Error output
```bash
tooncli --json invalid.toon
# stderr: Error at line 3, column 5: Expected colon after key
# exit code: 1
```

## Error Messages

Errors are written to stderr in the format:
```
Error: <message>
```

For parse errors, include location:
```
Error at line <N>, column <M>: <message>
```

### Common Error Messages

| Situation | Message |
|-----------|---------|
| File not found | `Error: Cannot read file 'path': No such file` |
| Invalid JSON | `Error: Invalid JSON at position N` |
| Invalid TOON | `Error at line N, column M: <specific issue>` |
| Invalid option | `Error: Unknown option '--foo'` |
| Missing value | `Error: Option '--indent' requires a value` |

## Version Output

```bash
tooncli --version
# Output: tooncli 0.1.0
```

## Help Output

```bash
tooncli --help
# Output:
# tooncli - Convert between TOON and JSON formats
#
# Usage: tooncli [OPTIONS] [FILE]
#
# Arguments:
#   FILE    Input file (reads from stdin if not provided)
#
# Options:
#   -j, --json          Output as JSON
#   -t, --toon          Output as TOON
#   -p, --pretty        Pretty-print JSON output
#   -c, --compact       Compact JSON output
#   -o, --output=FILE   Write output to FILE
#       --indent=N      Spaces per indent level (default: 2)
#       --delimiter=D   Array delimiter: comma|tab|pipe (default: comma)
#       --fold-keys     Enable key folding
#       --sort-keys     Sort object keys
#       --lenient       Use lenient parsing mode
#       --expand-paths  Expand dotted keys
#   -h, --help          Show this help
#   -v, --version       Show version
#
# Examples:
#   tooncli --json data.toon          Convert TOON to JSON
#   tooncli --toon data.json          Convert JSON to TOON
#   echo '{"x":1}' | tooncli --toon   Convert from stdin
```

## Integration with Unix Tools

### Pipe to jq
```bash
tooncli --json data.toon | jq '.name'
```

### Process multiple files
```bash
for f in *.toon; do
  tooncli --json "$f" > "${f%.toon}.json"
done
```

### Use in shell scripts
```bash
#!/bin/bash
if tooncli --json input.toon > output.json 2>/dev/null; then
  echo "Conversion successful"
else
  echo "Conversion failed" >&2
  exit 1
fi
```
