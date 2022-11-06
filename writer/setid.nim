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

import tlparser, strutils, strformat, utils, terminal


proc generateSetConstructorID*(file: File, constructors: seq[TLConstructor],
        log: bool = false) =
    if constructors.len <= 0:
        return
    if log: stdout.styledWriteLine(fgCyan, styleBright, "      Info:",
      fgDefault,
      resetStyle, " Generating SetConstructorID")
    file.write("\n\nproc setConstructorID*[T: TL](obj: T): T =")

    var prefixOperator = "when"

    for constructor in constructors:
        file.write(&"\n    {prefixOperator} T is {generateStylizedName(constructor.name, constructor.namespaces)}:\n        obj.constructorID = uint32({constructor.id})")
        prefixOperator = "elif"

    file.write("""
    
    elif T is TLTrue:
        obj.constructorID = uint32(0x997275b5)
    elif T is TLFalse:
        obj.constructorID = uint32(0xbc799737)
    elif T is GZipContent:
        obj.constructorID = uint32(0x3072cfa1)
    elif T is MessageContainer:
        obj.constructorID = uint32(0x73f1f8dc)
    elif T is FutureSalt:
        obj.constructorID = uint32(0x0949d9dc)
    elif T is FutureSalts:
        obj.constructorID = uint32(0xae500895)
    elif T is RPCResult:
        obj.constructorID = uint32(0xf35c6d01)
    elif T is TLVector:
        obj.constructorID = uint32(0x1cb5c415)
    elif T is TLInt:
        obj.constructorID = uint32(4)
    elif T is TLLong:
        obj.constructorID = uint32(8)""")


    file.write(&"\n    else:\n        raise newException(CatchableError, \"Unable to find the corresponding id for this type, please check it is not a generic one.\")")
    file.write("\n    return obj")

