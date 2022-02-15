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

import tlparser, strutils, options, strformat, utils, terminal

proc generateEncode*(file: File, constructors: seq[TLConstructor],
        log: bool = false) =
    if constructors.len <= 0:
        return
    file.write("\n\nproc TLEncode*(obj: TL): seq[uint8] =")
    file.write("\n    case obj.constructorID:")
    if log: stdout.styledWriteLine(fgCyan, styleBright, "      Info:",
      fgDefault,
      resetStyle, " Generating TLEncode")
    for constructor in constructors:
        let objcCode = if constructor.parameters.len >
                0: &"\n        let objc = obj.{generateStylizedName(constructor.name, constructor.namespaces)}" else: ""
        file.write(&"\n    of uint32({constructor.id}):{objcCode}\n        result.add(TLEncode(uint32({constructor.id})))")

        for parameter in constructor.parameters:
            if parameter.parameterType.get() of TLParameterTypeSpecified:
                if parameter.parameterType.get().TLParameterTypeSpecified.flag.isSome():
                    let a = parameter.parameterType.get.TLParameterTypeSpecified.flag.get
                    if parameter.parameterType.get().TLParameterTypeSpecified.type.name.toLower != "true":
                        file.write(&"\n        if objc.{parameter.name}.isSome(): objc.{a.parameterName} = objc.{a.parameterName} or FlagBit(1) shl FlagBit({a.index})")
                    else:
                        file.write(&"\n        if objc.{parameter.name}: objc.{a.parameterName} = objc.{a.parameterName} or FlagBit(1) shl FlagBit({a.index})")

        for parameter in constructor.parameters:
            if parameter.anytype: continue
            var encodeCode = ""
            var encodeType = ""
            if parameter.parameterType.get() of TLParameterTypeSpecified:
                let ptype = parameter.parameterType.get().TLParameterTypeSpecified

                encodeType = &"objc.{parameter.name}"
                if ptype.flag.isSome():
                    encodeCode = &"result.add(TLEncode({encodeType}.get()))"
                else:
                    encodeCode = &"result.add(TLEncode({encodeType}))"
                if ptype.type.genericArgument.isSome() and encodeType != "":
                    if ptype.type.genericArgument.get().name.toLower() == "vector":
                        if ptype.flag.isSome():
                            encodeCode = &"result.add(TLEncodeVector({encodeType}.get()))"
                        else:
                            encodeCode = &"result.add(TLEncodeVector({encodeType}))"
                    else:
                        echo "WARNING: Found a genericArgument that is not vector, skipping."
                        continue
                if ptype.flag.isSome():
                    if ptype.type.name.toLower !=
                            "true": encodeCode = &"if objc.{parameter.name}.isSome(): {encodeCode}" else: encodeCode = ""
            elif parameter.parameterType.get() of TLParameterTypeFlag:
                file.write(&"\n        result.add(TLEncode(objc.{parameter.name}))")
            else:
                echo "WARNING: Found unknown type, skipping."
                continue
            if encodeCode == "": continue
            file.write(&"\n        {encodeCode}")


    file.write("""
    
    of uint32(0x997275b5): result.add(TLEncode(uint32(0x997275b5)))
    of uint32(0xbc799737): result.add(TLEncode(uint32(0xbc799737)))
    of uint32(0x3072cfa1):
        result.add(TLEncode(uint32(0x3072cfa1)))
        result.add(TLEncode(compress(TLEncode(obj.GZipContent.value))))
    of uint32(0x73F1F8DC):
        result = TLEncode(uint32(0x73F1F8DC))
        result.add(TLEncode(uint32(len(obj.MessageContainer.messages))))
        for i in obj.MessageContainer.messages:
            result.add(TLEncode(i))""")

    file.write(&"\n    else:\n        raise newException(CatchableError, \"Unable to find the corresponding id for this type, please check it is not a generic one and that you have called setConstructorID.\")")
