# Package

version       = "0.1.0"
author        = "toon-nim contributors"
description   = "TOON (Token-Oriented Object Notation) format library for Nim"
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["bin/tooncli"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0"

# Tasks

task test, "Run all tests":
  exec "nim c -r tests/unit/test_types.nim"
  exec "nim c -r tests/unit/test_utils.nim"
  exec "nim c -r tests/unit/test_scanner.nim"
  exec "nim c -r tests/unit/test_parser.nim"
  exec "nim c -r tests/unit/test_decoder.nim"
  exec "nim c -r tests/unit/test_encoder.nim"
  exec "nim c -r tests/integration/test_roundtrip.nim"
  exec "nim c -r tests/integration/test_cli.nim"

task testUnit, "Run unit tests only":
  exec "nim c -r tests/unit/test_types.nim"
  exec "nim c -r tests/unit/test_utils.nim"
  exec "nim c -r tests/unit/test_scanner.nim"
  exec "nim c -r tests/unit/test_parser.nim"
  exec "nim c -r tests/unit/test_decoder.nim"
  exec "nim c -r tests/unit/test_encoder.nim"

task testIntegration, "Run integration tests only":
  exec "nim c -r tests/integration/test_roundtrip.nim"
  exec "nim c -r tests/integration/test_cli.nim"

task buildCli, "Build the CLI tool":
  exec "nim c -d:release -o:bin/tooncli bin/tooncli.nim"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --outdir:htmldocs src/toon.nim"
