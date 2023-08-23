# Package

version       = "0.3.0"
author        = "dadadani"
description   = "TL Types for Nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "stint"
requires "zippy >= 0.9.7"
taskRequires "gen", "https://github.com/nimgram/tl-parser#master"

proc gen = 
    selfExec("r --hints:off builder.nim")

task gen, "generate tl code file":
    gen()

before install:    
   exec "nimble gen"