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

import strutils, sugar


proc fixName*(name: string): string =
    var caps = false
    for ch in name:
        if ch == '_':
            caps = true
            continue
        if caps:
            caps = false
            result.add(toUpperAscii(ch))
        else:
            result.add(ch)
            

proc generateStylizedName*(name: string, namespaces: seq[string]): string =
    let namespaces = collect:
        var cnt = 0
        for namespace in namespaces:
            if cnt > 1: toLowerAscii(namespace) else: capitalizeAscii(namespace)
    if name.toLower() == "bool":
        return name.toLower
    return join(namespaces & capitalizeAscii(fixName(name)))

proc escapeName*(name: string): string =
    result = fixName(name)
    if result in @["type", "out", "static"]:
        result = "`" & result & "`"

proc generateFixedType*(t: string): string =
    return t.multiReplace(("int128",
                    "UInt128"), ("int256", "UInt256"), ("bytes", "seq[uint8]"),
                            ("int", "uint32"), ("long",
            "uint64"), ("float", "float32"), ("double", "float64"), ("true",
                    "bool"), ("Bool", "bool"), ("future_salt", "FutureSaltI"))
