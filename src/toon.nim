## TOON Format Library for Nim
## Token-Oriented Object Notation - compact, human-readable JSON encoding
##
## Usage:
##   import toon
##
##   # Decode TOON to ToonValue
##   let data = decode("name: Ada\nage: 42")
##   echo data["name"].getStr()  # Ada
##
##   # Encode ToonValue to TOON
##   let obj = newToonObject({"name": newToonString("Ada")})
##   echo encode(obj)  # name: Ada

# Re-export types
import toon/types
export types

# Re-export utilities (selective)
import toon/utils
export utils.escapeString, utils.unescapeString
export utils.needsQuoting, utils.quoteString
export utils.isValidIdentifier
export utils.splitDelimited
export utils.makeIndent

# Re-export decoder
import toon/decoder
export decoder.decode, decoder.decodeFile

# Re-export encoder
import toon/encoder
export encoder.encode, encoder.encodeToFile

# Re-export parser (for advanced usage)
import toon/parser
export parser.parseToon
