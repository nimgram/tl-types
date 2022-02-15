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

import tlparser, strutils, strformat, utils
import options
proc generateConstructors*(file: File, constructors: seq[TLConstructor],
        category: TLSection) =
    file.write("\n\ntype")
    var bareTypesNames = newSeq[string]()

    for constructor in constructors:
        if constructor.section != category:
            continue
        let name = generateStylizedName(constructor.name,
                constructor.namespaces)

        let ofName = if constructor.section == Types: generateStylizedName(
                constructor.type.name, constructor.namespaces) &
                        "I" else: "TLFunction"

        if constructor.section != Functions and not bareTypesNames.contains(ofName):
            bareTypesNames.add(ofName)
            file.write(&"\n\n    {ofName}* = ref object of TLObject")

        file.write(&"\n\n    {name}* = ref object of {ofName}")

        for parameter in constructor.parameters:
            if parameter.anytype:
                continue
            var parameterType = ""

            if parameter.parameterType.get() of TLParameterTypeSpecified:
                var specifiedType = parameter.parameterType.get().TLParameterTypeSpecified
                if specifiedType.type.genericReference:
                    parameterType = "TL"
                else:
                    if not specifiedType.type.bare:
                        parameterType = generateStylizedName(
                                specifiedType.type.name,
                                specifiedType.type.namespaces)
                    else:
                        parameterType = generateFixedType(
                                specifiedType.type.name)
                    if not specifiedType.type.bare and
                            specifiedType.type.name != "Bool":
                        parameterType = &"{parameterType}I"

                    var genericArgument = specifiedType.type.genericArgument
                    while genericArgument.isSome():
                        let name = genericArgument.get().name.replace("vector",
                                "seq").replace("Vector", "seq")

                        parameterType = &"{name}[{parameterType}]"
                        genericArgument = if genericArgument.get().genericArgument.isSome(): genericArgument.get().genericArgument else: none(TLType)

                    if specifiedType.flag.isSome() and specifiedType.type.name.toLower != "true":
                        parameterType = &"Option[{parameterType}]"

            elif parameter.parameterType.get() of TLParameterTypeFlag:
                parameterType = "FlagBit"
            else:
                echo "WARNING: Found unknown type, skipping."
                continue
            if parameter.parameterType.get() of TLParameterTypeFlag:
                file.write(&"\n        {escapeName(parameter.name)}: {parameterType}")
            else:
                file.write(&"\n        {escapeName(parameter.name)}*: {parameterType}")
