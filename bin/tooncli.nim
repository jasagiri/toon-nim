## TOON CLI Tool
## Converts between TOON and JSON formats

import std/[parseopt, strutils, os, json, terminal, tables]
import ../src/toon

const
  Version = "0.1.0"
  HelpText = """
tooncli - TOON Format CLI Converter v""" & Version & """

Usage: tooncli [OPTIONS] [FILE]

Convert between TOON and JSON formats.

Arguments:
  FILE                Input file (use '-' for stdin)

Options:
  -h, --help          Show this help message
  -v, --version       Show version number
  -j, --json          Output as JSON
  -t, --toon          Output as TOON
  -o, --output FILE   Write output to file instead of stdout
  --pretty            Pretty-print JSON output (default)
  --compact           Compact JSON output
  --indent N          Indentation size for TOON output (default: 2)
  --delimiter TYPE    Array delimiter: comma, tab, pipe (default: comma)
  --sort-keys         Sort object keys alphabetically
  --fold-keys         Enable key folding (collapse nested single-key objects)
  --expand-paths      Enable path expansion (expand dotted keys to nested objects)
  --strict            Enable strict mode parsing
  --lenient           Enable lenient mode parsing (default)

Examples:
  tooncli data.toon --json           # Convert TOON to JSON
  tooncli data.json --toon           # Convert JSON to TOON
  tooncli data.toon -o out.json      # Write to file
  echo "name: Ada" | tooncli - --json # Read from stdin
"""

type
  OutputFormat = enum
    ofAuto, ofJson, ofToon

  CliOptions = object
    inputFile: string
    outputFile: string
    outputFormat: OutputFormat
    prettyJson: bool
    indent: int
    delimiter: Delimiter
    sortKeys: bool
    foldKeys: bool
    expandPaths: bool
    strict: bool

proc parseArgs(): CliOptions =
  result = CliOptions(
    inputFile: "",
    outputFile: "",
    outputFormat: ofAuto,
    prettyJson: true,
    indent: 2,
    delimiter: dlComma,
    sortKeys: false,
    foldKeys: false,
    expandPaths: false,
    strict: false
  )

  var p = initOptParser()
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      # Handle standalone "-" as stdin argument, not an option
      if p.key == "" and p.val == "":
        if result.inputFile == "":
          result.inputFile = "-"
        else:
          stderr.writeLine("Error: Multiple input files not supported")
          quit(1)
        continue
      case p.key.toLowerAscii
      of "h", "help":
        echo HelpText
        quit(0)
      of "v", "version":
        echo "tooncli v" & Version
        quit(0)
      of "j", "json":
        result.outputFormat = ofJson
      of "t", "toon":
        result.outputFormat = ofToon
      of "o", "output":
        result.outputFile = p.val
      of "pretty":
        result.prettyJson = true
      of "compact":
        result.prettyJson = false
      of "indent":
        try:
          result.indent = parseInt(p.val)
        except ValueError:
          stderr.writeLine("Error: Invalid indent value: " & p.val)
          quit(1)
      of "delimiter":
        case p.val.toLowerAscii
        of "comma": result.delimiter = dlComma
        of "tab": result.delimiter = dlTab
        of "pipe": result.delimiter = dlPipe
        else:
          stderr.writeLine("Error: Unknown delimiter: " & p.val)
          quit(1)
      of "sort-keys":
        result.sortKeys = true
      of "fold-keys":
        result.foldKeys = true
      of "expand-paths":
        result.expandPaths = true
      of "strict":
        result.strict = true
      of "lenient":
        result.strict = false
      else:
        stderr.writeLine("Error: Unknown option: " & p.key)
        quit(1)
    of cmdArgument:
      if result.inputFile == "":
        result.inputFile = p.key
      else:
        stderr.writeLine("Error: Multiple input files not supported")
        quit(1)

proc detectFormat(content: string, filename: string): OutputFormat =
  ## Auto-detect input format from content or filename
  # Check filename extension first
  if filename.endsWith(".json"):
    return ofToon  # If input is JSON, output TOON
  elif filename.endsWith(".toon"):
    return ofJson  # If input is TOON, output JSON

  # Try to detect from content
  let trimmed = content.strip()
  if trimmed.len > 0:
    if trimmed[0] == '{' or trimmed[0] == '[':
      return ofToon  # JSON input -> TOON output
    else:
      return ofJson  # TOON input -> JSON output

  ofJson  # Default

proc readInput(filename: string): string =
  ## Read input from file or stdin
  if filename == "-":
    # Read from stdin
    var lines: seq[string] = @[]
    while not stdin.endOfFile:
      lines.add(stdin.readLine())
    lines.join("\n")
  elif filename == "":
    # No input file
    stderr.writeLine("Error: No input file specified")
    stderr.writeLine("Use --help for usage information")
    quit(1)
  else:
    if not fileExists(filename):
      stderr.writeLine("Error: File not found: " & filename)
      quit(1)
    readFile(filename)

proc toonValueToJsonNode(v: ToonValue): JsonNode =
  ## Convert ToonValue to JsonNode
  case v.kind
  of vkNull: newJNull()
  of vkBool: newJBool(v.boolVal)
  of vkInt: newJInt(v.intVal)
  of vkFloat: newJFloat(v.floatVal)
  of vkString: newJString(v.strVal)
  of vkArray:
    var arr = newJArray()
    for item in v.arrayVal:
      arr.add(toonValueToJsonNode(item))
    arr
  of vkObject:
    var obj = newJObject()
    for key, val in v.objectVal:
      obj[key] = toonValueToJsonNode(val)
    obj

proc jsonNodeToToonValue(j: JsonNode): ToonValue =
  ## Convert JsonNode to ToonValue
  case j.kind
  of JNull: newToonNull()
  of JBool: newToonBool(j.getBool())
  of JInt: newToonInt(j.getInt())
  of JFloat: newToonFloat(j.getFloat())
  of JString: newToonString(j.getStr())
  of JArray:
    var arr = newToonArray()
    for item in j:
      arr.arrayVal.add(jsonNodeToToonValue(item))
    arr
  of JObject:
    var obj = newToonObject()
    for key, val in j.pairs:
      obj.objectVal[key] = jsonNodeToToonValue(val)
    obj

proc main() =
  let opts = parseArgs()

  # Read input
  let content = readInput(opts.inputFile)

  # Determine output format
  var outputFormat = opts.outputFormat
  if outputFormat == ofAuto:
    outputFormat = detectFormat(content, opts.inputFile)

  # Convert
  var output: string
  try:
    case outputFormat
    of ofJson:
      # TOON to JSON
      let decodeOpts = DecodeOptions(
        strict: opts.strict,
        expandPaths: if opts.expandPaths: peSafe else: peNone,
        indentSize: opts.indent
      )
      let toonVal = decode(content, decodeOpts)
      let jsonNode = toonValueToJsonNode(toonVal)
      if opts.prettyJson:
        output = jsonNode.pretty()
      else:
        output = $jsonNode
    of ofToon:
      # JSON to TOON
      let jsonNode = parseJson(content)
      let toonVal = jsonNodeToToonValue(jsonNode)
      let encodeOpts = EncodeOptions(
        indent: opts.indent,
        delimiter: opts.delimiter,
        keyFolding: if opts.foldKeys: kfSafe else: kfNone,
        sortKeys: opts.sortKeys
      )
      output = encode(toonVal, encodeOpts)
    of ofAuto:
      # Should not reach here
      output = content

  except ToonDecodeError as e:
    stderr.writeLine("Error: " & e.msg)
    quit(1)
  except JsonParsingError as e:
    stderr.writeLine("Error: Invalid JSON - " & e.msg)
    quit(1)
  except CatchableError as e:
    stderr.writeLine("Error: " & e.msg)
    quit(1)

  # Write output
  if opts.outputFile != "":
    writeFile(opts.outputFile, output)
  else:
    echo output

when isMainModule:
  main()
