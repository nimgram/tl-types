# Nimgram
# Copyright (C) 2020-2023 Daniele Cortesi <https://github.com/dadadani>
# This file is part of Nimgram, under the MIT License
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import strutils, sugar

proc generateStylizedName*(name: string, namespaces: seq[string]): string =
    let namespaces = collect:
        var cnt = 0
        for namespace in namespaces:
            if cnt > 1: toLowerAscii(namespace) else: capitalizeAscii(namespace)
    if name.toLower() == "bool":
        return name.toLower
    return join(namespaces & capitalizeAscii(name))

proc escapeName*(name: string): string =
    result = name
    if result in ["type", "out", "static"]:
        result = "`" & result & "`"

proc generateFixedType*(t: string): string =
    return t.multiReplace(("int128",
                    "UInt128"), ("int256", "UInt256"), ("bytes", "seq[uint8]"),
                            ("int", "uint32"), ("long",
            "uint64"), ("float", "float32"), ("double", "float64"), ("true",
                    "bool"), ("Bool", "bool"), ("future_salt", "FutureSaltI"))

const LAYER_DEFINITION = "LAYER"

proc findLayerVersion*(tldata: string): int =
  ## Find the layer version from the TL schema
  for line in split(tldata, "\n"):
    if line.startsWith("//"):
      let index = line.find(LAYER_DEFINITION)
      if index != -1:
        return parseInt(line[index+LAYER_DEFINITION.len..line.high].strip())
  raise newException(FieldDefect, "Unable to find layer version")
