## TOON CLI Tool
## Converts between TOON and JSON formats

import std/[parseopt, strutils, os, json]
import ../src/toon

const
  Version = "0.2.0"
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
  --indent N          Spaces per indentation level (default: 2)
  --delimiter TYPE    Document delimiter: comma, tab, pipe (default: comma)
  --strict            Strict decoding (default, TOON specification §14)
  --lenient           Non-strict decoding: only the recoveries of §14.4

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
    strict: bool

proc parseArgs(): CliOptions =
  result = CliOptions(
    inputFile: "",
    outputFile: "",
    outputFormat: ofAuto,
    prettyJson: true,
    indent: 2,
    delimiter: dlComma,
    strict: true
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
      let decodeOpts = DecodeOptions(strict: opts.strict, indentSize: opts.indent)
      let jsonNode = decode(content, decodeOpts).toJsonNode()
      if opts.prettyJson:
        output = jsonNode.pretty()
      else:
        output = $jsonNode
    of ofToon:
      # JSON to TOON
      let encodeOpts = EncodeOptions(indentSize: opts.indent, delimiter: opts.delimiter)
      output = encode(parseJson(content), encodeOpts)
    of ofAuto:
      # Should not reach here
      output = content

  except ToonDecodeError as e:
    stderr.writeLine("Error: " & e.msg)
    quit(1)
  except ToonEncodeError as e:
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
