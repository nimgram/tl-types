# Nimgram
# Copyright (C) 2020-2022 Daniele Cortesi <https://github.com/dadadani>
# This file is part of Nimgram, under the MIT License
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import strutils, sequtils
import tlparser, writer/gen
import terminal

const LAYER_DEFINITION = "LAYER"

proc findLayerVersion(tldata: string): int =
  ## Find the layer version from the TL schema
  for line in split(tldata, "\n"):
    if line.startsWith("//"):
      let index = line.find(LAYER_DEFINITION)
      if index != -1:
        return parseInt(line[index+LAYER_DEFINITION.len..line.high].strip())
  raise newException(FieldDefect, "Unable to find layer version")

proc main* =

  stdout.styledWriteLine(fgCyan, styleBright, "   Building", fgDefault,
      resetStyle, " constructors")

  stdout.styledWriteLine(fgCyan, styleBright, "      Info:", fgDefault,
      resetStyle, " Reading constructors of mtproto.tl")

  let mtprotoTL = parseNew(readFile("tl/mtproto.tl")).all().toSeq()

  stdout.styledWriteLine(fgCyan, styleBright, "      Info:", fgDefault,
      resetStyle, " Reading constructors of api.tl")

  let apiData = readFile("tl/api.tl")

  stdout.styledWriteLine(fgCyan, styleBright, "      Info:", fgDefault,
      resetStyle, " Finding layer version of the schema")

  let layerVersion = findLayerVersion(apiData)

  var constructors = mtprotoTL & parseNew(apiData).all().toSeq()

  stdout.styledWriteLine(fgCyan, styleBright, "      Info:", fgDefault,
      resetStyle, " Trying to open tl.nim")

  let file = open("src/tltypes/private/tl.nim", fmWrite)

  stdout.styledWriteLine(fgCyan, styleBright, "      Info:", fgDefault,
      resetStyle, " Initializing code generation")

  generateNimCode(file, constructors, TLWriterConfig(enableTypes: true,
      enableFunctions: true, generateSetConstructorID: true,
      generateEncode: true, generateDecode: true,
      generateNameByConstructorID: true), layerVersion, true)

when isMainModule:
  main()
