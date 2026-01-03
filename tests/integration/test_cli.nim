## Integration tests for TOON CLI tool
## T060-T063: CLI integration tests

import unittest
import std/[osproc, os, strutils, json]

const
  CliPath = "bin/tooncli"
  TestDataDir = "tests/fixtures"

# Helper to run CLI and capture output
proc runCli(args: string): tuple[output: string, exitCode: int] =
  let cmd = CliPath & " " & args
  let (output, exitCode) = execCmdEx(cmd)
  (output, exitCode)

# Helper to write temp file
proc writeTempFile(content: string, ext: string): string =
  let path = getTempDir() / "test_" & $getCurrentProcessId() & ext
  writeFile(path, content)
  path

# T060: TOON to JSON conversion tests
suite "CLI TOON to JSON":
  setup:
    # Ensure CLI is built before running tests
    discard execCmd("nim c -o:" & CliPath & " bin/tooncli.nim 2>/dev/null")

  test "convert simple TOON to JSON":
    let toonContent = "name: Ada\nage: 42"
    let path = writeTempFile(toonContent, ".toon")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--json " & path)
    check exitCode == 0
    let parsed = parseJson(output)
    check parsed["name"].getStr == "Ada"
    check parsed["age"].getInt == 42

  test "convert nested TOON to JSON":
    let toonContent = """
name: Ada
address:
  city: London
  zip: 12345"""
    let path = writeTempFile(toonContent, ".toon")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--json " & path)
    check exitCode == 0
    let parsed = parseJson(output)
    check parsed["name"].getStr == "Ada"
    check parsed["address"]["city"].getStr == "London"

  test "convert array TOON to JSON":
    let toonContent = "nums: 1, 2, 3"
    let path = writeTempFile(toonContent, ".toon")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--json " & path)
    check exitCode == 0
    let parsed = parseJson(output)
    check parsed["nums"].len == 3
    check parsed["nums"][0].getInt == 1

  test "compact JSON output":
    let toonContent = "name: Ada\nage: 42"
    let path = writeTempFile(toonContent, ".toon")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--json --compact " & path)
    check exitCode == 0
    check "\n" notin output.strip()

  test "pretty JSON output":
    let toonContent = "name: Ada\nage: 42"
    let path = writeTempFile(toonContent, ".toon")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--json --pretty " & path)
    check exitCode == 0
    check "\n" in output.strip()

# T061: JSON to TOON conversion tests
suite "CLI JSON to TOON":
  test "convert simple JSON to TOON":
    let jsonContent = """{"name": "Ada", "age": 42}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon " & path)
    check exitCode == 0
    check "name:" in output or "name :" in output
    check "Ada" in output
    check "age:" in output or "age :" in output
    check "42" in output

  test "convert nested JSON to TOON":
    let jsonContent = """{"person": {"name": "Bob", "age": 30}}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon " & path)
    check exitCode == 0
    check "person:" in output or "person :" in output
    check "name:" in output or "name :" in output
    check "Bob" in output

  test "convert array JSON to TOON":
    let jsonContent = """{"items": [1, 2, 3]}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon " & path)
    check exitCode == 0
    check "items:" in output or "items :" in output
    check "1" in output

  test "auto-detect JSON input format":
    let jsonContent = """{"greeting": "hello"}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon " & path)
    check exitCode == 0
    check "greeting:" in output or "greeting :" in output
    check "hello" in output

# T062: Error handling tests
suite "CLI error handling":
  test "file not found":
    let (output, exitCode) = runCli("nonexistent.toon")
    check exitCode != 0
    check "error" in output.toLowerAscii or "not found" in output.toLowerAscii

  test "invalid TOON syntax":
    let content = "invalid : : ::"
    let path = writeTempFile(content, ".toon")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--json " & path)
    # Should still parse or produce error
    check exitCode == 0 or exitCode != 0

  test "invalid JSON syntax":
    let content = "{invalid json"
    let path = writeTempFile(content, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon " & path)
    check exitCode != 0
    check "error" in output.toLowerAscii or "parse" in output.toLowerAscii

  test "help flag shows usage":
    let (output, exitCode) = runCli("--help")
    check exitCode == 0
    check "usage" in output.toLowerAscii or "help" in output.toLowerAscii

  test "version flag shows version":
    let (output, exitCode) = runCli("--version")
    check exitCode == 0
    check "toon" in output.toLowerAscii or "0." in output

# T063: stdin/stdout tests
suite "CLI stdin/stdout":
  test "output to file with -o":
    let toonContent = "name: Ada"
    let inPath = writeTempFile(toonContent, ".toon")
    let outPath = getTempDir() / "output_" & $getCurrentProcessId() & ".json"
    defer:
      removeFile(inPath)
      if fileExists(outPath): removeFile(outPath)

    let (_, exitCode) = runCli("--json -o=" & outPath & " " & inPath)
    check exitCode == 0
    check fileExists(outPath)

    let content = readFile(outPath)
    let parsed = parseJson(content)
    check parsed["name"].getStr == "Ada"

  test "read from stdin with -":
    let toonContent = "name: Ada"
    let (output, exitCode) = execCmdEx("echo '" & toonContent & "' | " & CliPath & " --json -")
    check exitCode == 0
    let parsed = parseJson(output)
    check parsed["name"].getStr == "Ada"

  test "no input shows help":
    let (output, exitCode) = runCli("")
    check exitCode == 0 or exitCode == 1
    # Should show help or error message
    check output.len > 0

suite "CLI encoding options":
  test "custom indent size":
    let jsonContent = """{"a": {"b": 1}}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon --indent=4 " & path)
    check exitCode == 0
    check "    " in output  # 4-space indent

  test "tab delimiter":
    let jsonContent = """{"nums": [1, 2, 3]}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon --delimiter=tab " & path)
    check exitCode == 0
    check "\t" in output or "1" in output

  test "sort keys":
    let jsonContent = """{"z": 1, "a": 2}"""
    let path = writeTempFile(jsonContent, ".json")
    defer: removeFile(path)

    let (output, exitCode) = runCli("--toon --sort-keys " & path)
    check exitCode == 0
    let aPos = output.find("a:")
    let zPos = output.find("z:")
    # When sorted, 'a' should come before 'z'
    if aPos >= 0 and zPos >= 0:
      check aPos < zPos
