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

proc generateDecode*(file: File, constructors: seq[TLConstructor],
        log: bool = false) =
    if constructors.len <= 0:
        return
    if log: stdout.styledWriteLine(fgCyan, styleBright, "      Info:",
      fgDefault,
      resetStyle, " Generating TLDecode")
    file.write("\n\nproc TLDecode*(stream: TLStream): TL =")
    file.write("\n    case TLDecode[uint32](stream):")

    for constructor in constructors:
        let constructorName = generateStylizedName(constructor.name,
                constructor.namespaces)
        file.write(&"\n    of uint32({constructor.id}):\n        result = {constructorName}(constructorID: uint32({constructor.id}))")
        for parameter in constructor.parameters:
            if parameter.anytype:
                continue
            var codeType = ""
            var decodeCode = ""
            var flagCode = ""
            if parameter.parameterType.get() of TLParameterTypeSpecified:
                let typeConverted = parameter.parameterType.get().TLParameterTypeSpecified
                let typeName = &"{generateStylizedName(typeConverted.type.name, typeConverted.type.namespaces)}I"
                if (typeConverted.type.bare or
                        typeConverted.type.name.toLower == "bool") and
                        typeConverted.type.name.toLower != "future_salt":
                    codeType = &"[{generateFixedType(typeConverted.type.name)}](stream)"
                else:
                    codeType = &"(stream)"
                if typeConverted.type.genericArgument.isSome() and codeType != "":
                    if typeConverted.type.genericArgument.get().name.toLower() == "vector":
                        if (typeConverted.type.bare or
                                typeConverted.type.name.toLower == "bool" or
                                typeConverted.type.genericReference) and
                                        typeConverted.type.name.toLower != "future_salt":
                            decodeCode = &"TLDecodeVector{codeType}"
                        else:
                            decodeCode = &"cast[seq[{typeName}]](TLDecodeVector{codeType})"


                    else:
                        echo "WARNING: Found a genericArgument that is not vector, skipping."
                        continue
                else:
                    if (typeConverted.type.bare or
                            typeConverted.type.genericReference or
                            typeConverted.type.name.toLower == "bool") and
                            typeConverted.type.name.toLower != "future_salt":
                        decodeCode = &"TLDecode{codeType}"
                    else:
                        decodeCode = &"{typeName}(TLDecode{codeType})"
                if typeConverted.flag.isSome():
                    flagCode = &"if (result.{constructorName}.{typeConverted.flag.get.parameterName} and (1 shl {typeConverted.flag.get.index})) != 0:"
                    if typeConverted.type.name.toLower != "true":
                        decodeCode = &"{decodeCode}.some()"
                    else:
                        decodeCode = &"true"
            elif parameter.parameterType.get() of TLParameterTypeFlag:
                decodeCode = "FlagBit(TLDecode[int32](stream))"
            else:
                echo "WARNING: Found unknown type, skipping."
                continue
            if flagCode != "":
                file.write(&"\n        {flagCode} result.{constructorName}.{parameter.name} = {decodeCode}")
            else:
                file.write(&"\n        result.{constructorName}.{parameter.name} = {decodeCode}")
    file.write("""
    
    of uint32(0xbc799737): return TLFalse(constructorID: uint32(0xbc799737)) 
    of uint32(0x997275b5): return TLTrue(constructorID: uint32(0x997275b5)) 
    of uint32(0x3072cfa1): return GZipContent(constructorID: 0x3072cfa1, value: TLDecode(newTLStream(uncompress(TLDecode[seq[uint8]](stream)))))
    of uint32(0x73F1F8DC): 
        result = MessageContainer(constructorID: uint32(0x73F1F8DC))
        for _ in countup(1, TLDecode[int32](stream)): result.MessageContainer.messages.add(TLDecodeCoreMessage(stream))""")

    file.write(&"\n    else:\n        raise newException(CatchableError, \"Unable to find the corresponding type for this constructor id.\")")
