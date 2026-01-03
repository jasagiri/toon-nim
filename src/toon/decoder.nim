## TOON Format Decoder
## Public API for decoding TOON to ToonValue

import std/[os]
import ./types
import ./parser

# T042: decode() public function
proc decode*(input: string, options: DecodeOptions = defaultDecodeOptions): ToonValue =
  ## Decode a TOON format string to ToonValue
  ##
  ## Args:
  ##   input: TOON format string to decode
  ##   options: Decoding options (strict mode, indent size, etc.)
  ##
  ## Returns:
  ##   ToonValue representing the decoded data
  ##
  ## Raises:
  ##   ToonDecodeError: If the input is invalid
  parseToon(input, options)

# T043: decodeFile() public function
proc decodeFile*(path: string, options: DecodeOptions = defaultDecodeOptions): ToonValue =
  ## Decode a TOON format file to ToonValue
  ##
  ## Args:
  ##   path: Path to the TOON file to decode
  ##   options: Decoding options (strict mode, indent size, etc.)
  ##
  ## Returns:
  ##   ToonValue representing the decoded data
  ##
  ## Raises:
  ##   IOError: If the file cannot be read
  ##   ToonDecodeError: If the file content is invalid
  let content = readFile(path)
  decode(content, options)
