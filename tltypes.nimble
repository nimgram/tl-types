# Package

version       = "0.2.0"
author        = "dadadani"
description   = "TL Types for Nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.0"
requires "stint"
requires "zippy >= 0.9.7"
requires "https://github.com/nimgram/tl-parser"

proc gen = 
    selfExec("r --hints:off builder.nim")

task gen, "generate tl code file":
    gen()

before install:    
   gen()