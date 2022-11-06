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

proc generateJson*(file: File, constructors: seq[TLConstructor],
        log: bool = false) =
    if constructors.len <= 0:
        return
    if log: stdout.styledWriteLine(fgCyan, styleBright, "      Info:",
      fgDefault,
      resetStyle, " Generating Json")
    file.write("\n\nproc `%*`*(obj: TL): JsonNode =")
    file.write("\n    result = newJObject()\n    case obj.constructorID:")

    for constructor in constructors:
        let constructorName = generateStylizedName(constructor.name,
                constructor.namespaces)
        let rawName = join((constructor.namespaces & constructor.name), ".")

        file.write(&"\n    of uint32({constructor.id}):\n        result[\"_\"] = %*\"{rawName}\"")
        for parameter in constructor.parameters:
            if parameter.anytype:
                continue
 
            if parameter.parameterType.get() of TLParameterTypeSpecified:

                let typeConverted = parameter.parameterType.get().TLParameterTypeSpecified
                var bareCode = "tl.`%*`"
                var vectorCode = ""

                if typeConverted.type.bare or typeConverted.type.name.toLower in ["bool", "true"]:
                    bareCode = "`%*`"
                if typeConverted.type.genericArgument.isSome():
                    if typeConverted.type.genericArgument.get().name.toLower() == "vector":
                        vectorCode = "cast[seq[TL]]"
                if typeConverted.flag.isSome() and typeConverted.type.name.toLower != "true":
                    file.write(&"\n        result[\"{parameter.name}\"] = if obj.{constructorName}.{parameter.name}.isSome: {bareCode}{vectorCode}((obj.{constructorName}.{parameter.name}.get())) else: newJNull()")
                else:
                    file.write(&"\n        result[\"{parameter.name}\"] = {bareCode}{vectorCode}(obj.{constructorName}.{parameter.name})")
    file.write("""""")

    file.write(&"\n    else:\n        raise newException(CatchableError, \"Unable to find the corresponding id for this type, please check it is not a generic one and that you have called setConstructorID.\")")
