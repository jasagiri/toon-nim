## TOON (Token-Oriented Object Notation) for Nim, specification 4.4.
##
## ```nim
## import toon
##
## let data = decode("name: Ada\nage: 42")
## echo data["name"].getStr()  # Ada
##
## echo encode(newToonObject({"name": newToonString("Ada")}))  # name: Ada
## ```

import toon/[types, decoder, encoder]
export types, decoder, encoder
