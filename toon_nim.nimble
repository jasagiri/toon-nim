# Package

version       = "0.2.0"
author        = "toon-nim contributors"
description   = "TOON (Token-Oriented Object Notation) 4.4 encoder and decoder for Nim"
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["bin/tooncli"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0"

# Tasks

task conformance, "Run the official TOON conformance fixtures":
  exec "nim c -r --hints:off tests/fixtures/run_fixtures.nim"

task test, "Run all tests":
  exec "nim c -r --hints:off tests/fixtures/run_fixtures.nim"
  exec "nim c -r --hints:off tests/external/test_host_rules.nim"
  exec "nim c -r --hints:off tests/unit/test_types.nim"
  exec "nim c -r --hints:off tests/integration/test_roundtrip.nim"
  exec "nim c -r --hints:off tests/integration/test_cli.nim"

task buildCli, "Build the CLI tool":
  exec "nim c -d:release -o:bin/tooncli bin/tooncli.nim"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --outdir:htmldocs src/toon.nim"
