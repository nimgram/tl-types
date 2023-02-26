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

import pkg/stint
import utils, stream
import pkg/tlparser, pkg/tlparser/internals
import std/strutils, std/tables, std/options, std/strformat
import std/macros
import pkg/zippy, std/json, std/base64

const 
 VECTOR_CID_BYTES = @[21'u8, 196, 181, 28]
 GZIP_PACKED_CID_BYTES = @[161'u8, 207, 114, 48]
 COMPRESSION_THRESHOLD = when defined(nocompression): 0 else: 512

type 
   TLStructure* = ref object of RootObj
    genericArgument: TLStructureGenericArgument
    flag: TLStructureFlagType

   TLStructureInt* = ref object of TLStructure

   TLStructureLong* = ref object of TLStructure

   TLStructureFloat* = ref object of TLStructure

   TLStructureDouble* = ref object of TLStructure

   TLStructureBytes* = ref object of TLStructure

   TLStructureString* = ref object of TLStructure

   TLStructureGenericArgument* = ref object of TLStructure

   TLStructureVector* = ref object of TLStructureGenericArgument
    bare: bool
   
   TLStructureTrue* = ref object of TLStructure

   TLStructureInt128* = ref object of TLStructure
   
   TLStructureInt256* = ref object of TLStructure

   TLStructureFlag* = ref object of TLStructure

   TLStructureFlagType* = ref object of TLStructure
    bits: range[0'i32..int32.high]
    flagName: string

   TLStructureConstructor* = ref object of TLStructure

   TLStructureConstructorGenericReference* = ref object of TLStructureConstructor

   TLStructureConstructorBoxed* = ref object of TLStructureConstructor
    sub: string

   TLStructureConstructorBare* = ref object of TLStructureConstructorBoxed
    name: string
    constructorId: uint32
    parameters: OrderedTable[string, TLStructure]
    function: bool
    useAnyType: string
    
   TLStructureObject* = ref object of TLStructure

   TL* = ref object of RootObj

   TLString* = ref object of TL
    value: string

   TLConstructor* = ref object of TL
    structure: TLStructureConstructorBare
    values: TableRef[string, TL]

   TLInt* = ref object of TL
    value: uint32

   TLLong* = ref object of TL
    value: uint64

   TLFloat* = ref object of TL
    value: float32

   TLDouble* = ref object of TL
    value: float64

   TLBigInteger*[bits: static[int]] = ref object of TL
    value: StUint[bits]

   TLBytes* = ref object of TL
    value: seq[uint8]

   TLVector* = ref object of TL
    value: seq[TL]

   TLInt128* = TLBigInteger[128]

   TLInt256* = TLBigInteger[256]

   TLBool* = ref object of TL
    value: bool

   TLFlag* = ref object of TL
    value: range[0'i32..int32.high]
   
   TLObject* = ref object of TL
    expectedObject: TLStructure
    actualObject: TL

const apiData = slurp("tl/api.tl")
const mtprotoData = slurp("tl/mtproto.tl")
const LAYER_VERSION* = findLayerVersion(apiData)

proc parseTL(tl: string, data1: var Table[string, TLStructureConstructorBare], data2: var Table[uint32, TLStructureConstructorBare])

proc parse(): (Table[string, TLStructureConstructorBare], Table[uint32, TLStructureConstructorBare]) =
    parseTL(mtprotoData, result[0], result[1])
    parseTL(apiData, result[0], result[1])

var constructorFromName: Table[string, TLStructureConstructorBare]
var constructorFromID: Table[uint32, TLStructureConstructorBare]

template initTL() =
    if constructorFromID.len <= 0:
        (constructorFromName, constructorFromID) = parse()

proc typeToTLStructure(tlType: TLParameterType, data: Table[string, TLStructureConstructorBare]): TLStructure =
    if tlType of TLParameterTypeSpecified:
        let parameter = tlType.TLParameterTypeSpecified
        if parameter.type.genericReference:
            return TLStructureConstructorGenericReference()
            
        if parameter.type.bare:
            case parameter.type.name:
            of "int128":
                result = TLStructureInt128()
            of "int256":
                result = TLStructureInt256()
            of "bytes":
                result = TLStructureBytes()
            of "int":
                result = TLStructureInt()
            of "long":
                result = TLStructureLong()
            of "float":
                result = TLStructureFloat()
            of "double":
                result = TLStructureDouble()
            of "true":
                result = TLStructureTrue()
            of "string":
                result = TLStructureString()
            
            else:
                let typeName = parameter.type.namespaces.join(".") & parameter.type.name
                if not data.contains(typeName):
                    raise newException(FieldDefect, "")
                result = data[typeName]
        else:
            let namespacess = parameter.type.namespaces.join(".")
            let typeName = namespacess & (if namespacess.len > 0: "." else: "") & parameter.type.name
            
            if typeName == "Object":
                result = TLStructureObject()
            else:
                ######### CHECK
                result = TLStructureConstructorBoxed(sub: typeName)
        
        var genericArgument = parameter.type.genericArgument
        var obj = result
        while genericArgument.isSome():
            if genericArgument.get().name.toLower != "vector":
                raise newException(FieldDefect, "Generic arguments different from vectors are not supported at the moment")
            
            obj.genericArgument = TLStructureVector(bare: genericArgument.get().bare)

            if genericArgument.get().genericArgument.isSome(): 
                genericArgument = genericArgument.get().genericArgument 
                obj = obj.genericArgument 
            else: 
                genericArgument = none(TLType)

        if parameter.flag.isSome():
                result.flag = TLStructureFlagType(bits: parameter.flag.get.index, flagName: parameter.flag.get.parameterName)
    elif tlType of TLParameterTypeFlag:
            return TLStructureFlag()


proc parseTL(tl: string, data1: var Table[string, TLStructureConstructorBare], data2: var Table[uint32, TLStructureConstructorBare]) =
    
    
    for constructor in parseNew(tl).all():
        
        let namespacessub = constructor.type.namespaces.join(".")

        let sub = namespacessub &  (if namespacessub.len > 0: "." else: "") & constructor.type.name
        let namespaces = constructor.namespaces.join(".")
        let name = namespaces & (if namespaces.len > 0: "." else: "") & constructor.name
        var tconstructor = TLStructureConstructorBare(sub: sub, name: constructor.name, constructorId: constructor.id, function: if constructor.section == Functions: true else: false)
        # Parameters generation
        for parameter in constructor.parameters:
            if parameter.anytype:
                tconstructor.useAnyType = parameter.name
                continue
            
            let name = parameter.name

            tconstructor.parameters[name] = typeToTLStructure(parameter.parameterType.get, data1)

        data1[name] = tconstructor

        data2[constructor.id] = tconstructor

proc initTLConstructor*(name: string): TLConstructor =
    initTL()
    if not constructorFromName.contains(name):
        raise newException(ValueError, "Invalid constructor name")

    return TLConstructor(structure: constructorFromName[name], values: newTable[string, TL]())

proc updateFlag(self: TLConstructor, flagName: string, bits: int32, remove = false) =
    if flagName notin self.values:
        self.values[flagName] = TLFlag(value: 0)
    if remove:
        # TODO: fix if needed
        self.values[flagName].TLFlag.value = self.values[flagName].TLFlag.value and not(1'i32 shl bits)
    else:
        self.values[flagName].TLFlag.value = self.values[flagName].TLFlag.value or 1'i32 shl bits

proc remove*(self: TLConstructor, key: string) =
    if key notin self.values:
        return

    self.values.del(key)
    if not isNil(self.structure.parameters[key].flag):
        self.updateFlag(self.structure.parameters[key].flag.flagName, self.structure.parameters[key].flag.bits, true)

proc getReturnType*(self: TLConstructor): TLStructure =
    if not self.structure.function:
        raise newException(ValueError, "Constructor is not a function")
    if self.structure.useAnyType.len > 0:
        if self.structure.sub == self.structure.useAnyType:
            for key, parameter in self.structure.parameters:
                if parameter of TLStructureConstructorGenericReference:
                    if key notin self.values:
                        raise newException(FieldDefect, "The constructor is using a generic reference as the return type, but the expected constructor has not been set yet")
                    return getReturnType(self.values[key].TLConstructor)
                    
    result = typeToTLStructure(parseParameterType(self.structure.sub), constructorFromName)
    doAssert not(result of TLStructureObject)
    doAssert isNil(result.flag)

template valueErr(): ref Exception =
    newException(ValueError, "Invalid object value")    

proc preCheck(self: TLConstructor, key: string, value: TL) = 
    
    var val = self.structure.parameters[key]
    if self.structure.parameters[key] of TLStructureObject:
        if not isNil(self.values[key].TLObject.expectedObject):
            val = self.values[key].TLObject.expectedObject


    if value of TLBytes or value of TLString:
        if not(val of TLStructureString or val of TLStructureBytes):
            raise valueErr()
    elif value of TLInt:
        if not(val of TLStructureInt):
            raise valueErr()
    elif value of TLLong:
        if not(val of TLStructureLong):
            raise valueErr()
    elif value of TLFloat:
        if not(val of TLStructureFloat):
            raise valueErr()
    elif value of TLFloat:
        if not(val of TLStructureDouble):
            raise valueErr()
    elif value of TLInt128:
        if not(val of TLStructureInt128):
            raise valueErr()
    elif value of TLInt256:
        if not(val of TLStructureInt256):
            raise valueErr()
    elif value of TLBool:
        if not(val of TLStructureConstructorBoxed and val.TLStructureConstructorBoxed.sub == "Bool") and not(val of TLStructureTrue):
            raise valueErr()
        if (val of TLStructureTrue and isNil(val.flag)):
            raise newException(ValueError, "The true type can't be used without flags at the moment")
    elif value of TLConstructor:
        let value = value.TLConstructor
        if val of TLStructureConstructorBare:
            if value.structure.name != val.TLStructureConstructorBare.name:
                raise newException(ValueError, "Expecting constructor with name " & val.TLStructureConstructorBare.name & ", but got " & value.structure.name)
        elif not value.structure.function and val of TLStructureConstructorBoxed:
            if value.structure.sub != val.TLStructureConstructorBoxed.sub:
                raise newException(ValueError, "Constructor must be dependent of boxed type " & val.TLStructureConstructorBoxed.sub)
        elif val of TLStructureConstructorGenericReference:
            discard
        else:
            raise valueErr()        
    else:
        raise newException(ValueError, "Unsupported value")

proc `[]=`*(self: TLConstructor, key: string, value: TLStructure) =
    doAssert self.structure.parameters[key] of TLStructureObject
    doAssert isNil(value.flag)
    doAssert not(value of TLStructureObject)
    self.values[key] = TLObject(expectedObject: value) 


proc `[]=`*(self: TLConstructor, key: string, value: TL) =
    if value of TLVector:
        raise newException(ValueError, "TLVector is not accepted here")
    if key notin self.structure.parameters:
        raise newException(ValueError, &"Constructor doesn't contain the following key: {key}")
    if not isNil(self.structure.parameters[key].genericArgument) and self.structure.parameters[key].genericArgument of TLStructureVector:
        raise newException(ValueError, "Expecting value to be a vector, got a single object") 
    preCheck(self, key, value)
    
    var needUpdateFlag = key notin self.values

    if value of TLBool:
        if not(self.structure.parameters[key] of TLStructureTrue):
            if self.structure.parameters[key] of TLStructureObject:
                if value.TLBool.value:
                    self.values[key].TLObject.actualObject = initTLConstructor("boolTrue")
                else:
                    self.values[key].TLObject.actualObject = initTLConstructor("boolFalse")

            else:
                if value.TLBool.value:
                    self.values[key] = initTLConstructor("boolTrue")
                else:
                    self.values[key] = initTLConstructor("boolFalse")

        else:
            if not value.TLBool.value:
                self.remove(key)
                return
            self.values[key] = TLBytes()   
    elif self.structure.parameters[key] of TLStructureObject:
        self.values[key].TLObject.actualObject = value
    else:
        self.values[key] = value
    
    if needUpdateFlag and not(isNil(self.structure.parameters[key].flag)):
        self.updateFlag(self.structure.parameters[key].flag.flagName, self.structure.parameters[key].flag.bits)
        #self.updateFlag(self.structure.parameters[key].flag.flagName, self.structure.parameters[key].flag.bits, true)

proc vCheck(obj: TLConstructor, structure: TLStructure, key: string, value: seq[TL]) = 
    
    if isNil(structure.genericArgument) or not(structure.genericArgument of TLStructureVector):
        raise newException(ValueError, "Nested Vector: Too many levels")
    
    if value.len > 0 and value[0] of TLVector:
        vCheck(obj, structure.genericArgument, key, value[0].TLVector.value) 
    else:
        if not isNil(structure.genericArgument.genericArgument) and structure.genericArgument.genericArgument of TLStructureVector:
            raise newException(ValueError, "Nested Vector: Not enough levels")

proc preCheck(self: TLConstructor, structure: TLStructure, key: string, values: seq[TL]) = 
    if isNil(structure.genericArgument) or not(structure.genericArgument of TLStructureVector):
        raise newException(ValueError, "Nested Vector: Too many levels")
    
    var vectorUse = false
    
    for value in values:
        if value of TLVector:
            vectorUse = true
            preCheck(self, structure.genericArgument, key, value.TLVector.value)
        else:
            preCheck(self, key, value)
    
    if not vectorUse and not isNil(structure.genericArgument.genericArgument) and structure.genericArgument.genericArgument of TLStructureVector:
        raise newException(ValueError, "Nested Vector: Not enough levels")



proc `[]=`*(self: TLConstructor, key: string, values: seq[TL]) =
    if key notin self.structure.parameters:
        raise newException(ValueError, &"Constructor doesn't contain the following key: {key}")
    if isNil(self.structure.parameters[key].genericArgument) or not(self.structure.parameters[key].genericArgument of TLStructureVector):
        raise newException(ValueError, "Expecting value to be a single object, got a vector")
    var needUpdateFlag = key notin self.values

    preCheck(self, self.structure.parameters[key], key, values)
    self.values[key] = TLVector(value: values)
    if needUpdateFlag and not(isNil(self.structure.parameters[key].flag)):
        self.updateFlag(self.structure.parameters[key].flag.flagName, self.structure.parameters[key].flag.bits)

proc encode*(self: TLConstructor, withCid = true): seq[uint8] 

proc bytesEncode*(data: seq[uint8]): seq[uint8] = 

    if len(data) <= 253:
        result.add(uint8(len(data)) & data)
    else:
        result.add(uint8(254) & toBytes(uint32(len(data)), MTPROTO_ENDIAN)[0..2] & data)

    while len(result) mod 4 != 0:
      result.add(uint8(0))

proc encode(structure: TLStructure, value: TL): seq[uint8] =
    if value of TLVector:
        if not structure.genericArgument.TLStructureVector.bare:
            result.add(VECTOR_CID_BYTES)
        result.add(toBytes(uint32(value.TLVector.value.len), MTPROTO_ENDIAN))

        for e in value.TLVector.value:
            result.add(encode(structure, e,))
    else:
        if structure of TLStructureObject:
            if isNil(value) or isNil(value.TLObject.expectedObject) or isNil(value.TLObject.actualObject):
                raise newException(FieldDefect, "Empty Object type, please assign an expected object before")
            
            var tmpData = encode(value.TLObject.expectedObject, value.TLObject.actualObject)
            
            if COMPRESSION_THRESHOLD > 0 and tmpData.len > COMPRESSION_THRESHOLD:
                let packed = GZIP_PACKED_CID_BYTES & bytesEncode(compress(tmpData))
                if packed.len < tmpData.len:
                    tmpData = packed
            result.add(tmpData)
        if structure of TLStructureInt:
            result.add(toBytes(value.TLInt.value, MTPROTO_ENDIAN))
        elif structure of TLStructureLong:
            result.add(toBytes(value.TLLong.value, MTPROTO_ENDIAN))
        elif structure of TLStructureFloat:
            result.add(toBytes(cast[uint32](value.TLFloat.value), MTPROTO_ENDIAN))
        elif structure of TLStructureDouble:
            result.add(toBytes(cast[uint64](value.TLDouble.value), MTPROTO_ENDIAN))
        elif structure of TLStructureBytes or structure of TLStructureString:
            if value of TLBytes:
                return bytesEncode(value.TLBytes.value)
            else:
                return bytesEncode(cast[seq[uint8]](value.TLString.value))
        elif structure of TLStructureTrue:
            discard
        elif structure of TLStructureInt128:
            result.add(toBytes(value.TLInt128.value, MTPROTO_ENDIAN))
        elif structure of TLStructureInt256:
            result.add(toBytes(value.TLInt256.value, MTPROTO_ENDIAN))
        elif structure of TLStructureFlag:
            result.add(toBytes(uint32(value.TLFlag.value), MTPROTO_ENDIAN))
        elif structure of TLStructureConstructor:
            let useCid = structure of TLStructureConstructorGenericReference or (structure of TLStructureConstructorBoxed and not(structure of TLStructureConstructorBare))
            result.add(encode(value.TLConstructor, useCid))


proc encode*(self: TLConstructor, withCid = true): seq[uint8] =
    if isNil(self.structure):
        raise newException(ValueError, "Invalid object")


    if withCid:
        result.add(toBytes(self.structure.constructorId, MTPROTO_ENDIAN))

    for key, parameter in self.structure.parameters:
        if not isNil(parameter.flag):
            if key notin self.values:
                # Skip the encoding of this object because it is optional and has not been defined
                continue
        elif parameter of TLStructureFlag and key notin self.values:
            result.add(newSeq[uint8](4))
            continue
        else:
            if key notin self.values:
                raise newException(ValueError, &"The following required parameter was not defined: {key}")
        result.add(encode(parameter, self.values[key]))

proc tl*(stream: TLStream): TLConstructor 
proc decode*(self: TLConstructor, stream: TLStream) 

proc bytesDecode(stream: TLStream): seq[uint8] = 
    let len = stream.readBytes(1)
    var paddingLen = uint32(0)

    if len[0] <= 253:
        result = stream.readBytes(uint(len[0]))
        paddingLen = uint32(len[0]+1)
    else:
        paddingLen = fromBytes(uint32, (stream.readBytes(3) & 0), MTPROTO_ENDIAN)
        result = stream.readBytes(paddingLen)
        paddingLen += 4
    while int64(paddingLen) mod int64(4) != int64(0):
        inc paddingLen
        doAssert stream.readBytes(1)[0] == uint8(0), "Unexpected end of padding bytes"


proc decode(structure: TLStructure, genericArgument: TLStructureVector, value: var TL, stream: TLStream) =
    if not isNil(genericArgument):
        if isNil(value) or not(value of TLVector):
            value = TLVector(value: newSeq[TL]())
        if not genericArgument.bare:
            doAssert stream.readBytes(4) == VECTOR_CID_BYTES
        let length = fromBytes(uint32, stream.readBytes(4), MTPROTO_ENDIAN)
        for i in 0..<length:
            var newValue: TL 
            decode(structure, genericArgument.genericArgument.TLStructureVector, newValue, stream)
            value.TLVector.value.add(newValue)
    else:
        if structure of TLStructureObject:       
            var gzip = false
            if stream.readBytesSafe(4) == GZIP_PACKED_CID_BYTES: 
                gzip = true
                discard stream.readBytes(4)
            if isNil(value.TLObject.expectedObject):
                value.TLObject.actualObject = tl((if gzip: newTLStream(uncompress(bytesDecode(stream))) else: stream))
                value.TLObject.expectedObject = TLStructureConstructorBoxed(sub: value.TLObject.actualObject.TLConstructor.structure.sub)
            else:
                decode(value.TLObject.expectedObject, (if not isNil(value.TLObject.expectedObject.genericArgument): value.TLObject.expectedObject.genericArgument.TLStructureVector else: nil), value.TLObject.actualObject, (if gzip: newTLStream(uncompress(bytesDecode(stream))) else: stream))
        elif structure of TLStructureInt:
            value = TLInt(value: fromBytes(uint32, stream.readBytes(4), MTPROTO_ENDIAN))
        elif structure of TLStructureLong:
            value = TLLong(value: fromBytes(uint64, stream.readBytes(8), MTPROTO_ENDIAN))
        elif structure of TLStructureFloat:
            value = TLFloat(value: cast[float32](fromBytes(uint32, stream.readBytes(4), MTPROTO_ENDIAN)))
        elif structure of TLStructureDouble:
            value = TLDouble(value: cast[float64](fromBytes(uint64, stream.readBytes(8), MTPROTO_ENDIAN)))
        elif structure of TLStructureBytes:
            value = TLBytes(value: bytesDecode(stream))
        elif structure of TLStructureString:
            value = TLString(value: cast[string](bytesDecode(stream)))
        elif structure of TLStructureInt128:
            value = TLInt128(value: fromBytes(UInt128, stream.readBytes(16), MTPROTO_ENDIAN))
        elif structure of TLStructureInt256:
            value = TLInt256(value: fromBytes(UInt256, stream.readBytes(32), MTPROTO_ENDIAN))
        elif structure of TLStructureConstructorBare:
            value = TLConstructor(structure: structure.TLStructureConstructorBare, values: newTable[string, TL]())
            decode(value.TLConstructor, stream)
        elif structure of TLStructureConstructorBoxed or structure of TLStructureConstructorGenericReference:
            value = tl(stream)
            if structure of TLStructureConstructorBoxed:
                doAssert structure.TLStructureConstructorBoxed.sub == value.TLConstructor.structure.sub


proc tl*(stream: TLStream): TLConstructor =
    initTL()
    let cid = fromBytes(uint32, stream.readBytes(4), MTPROTO_ENDIAN)
    result = TLConstructor(structure: constructorFromID[cid], values: newTable[string, TL]())
    decode(result, stream)

proc decode*(self: TLConstructor, stream: TLStream) =
    if isNil(self.structure):
        raise newException(ValueError, "Invalid object")

    for key, parameter in self.structure.parameters:
        if not isNil(parameter.flag):
            if parameter.flag.flagName notin self.values:
                raise newException(UnpackDefect, &"Attempting to read optional parameter '{key}' before reading the flag '{parameter.flag.flagName}'")
            if (int(self.values[parameter.flag.flagName].TLFlag.value) and (1 shl int(parameter.flag.bits))) == 0:
                continue
            elif parameter of TLStructureTrue:
                self.values[key] = TLBytes()
                continue
        if not(parameter of TLStructureObject):
            self.values[key] = nil
        else:
            if key notin self.values:
                self.values[key] = TLObject()
        
        decode(parameter, parameter.genericArgument.TLStructureVector, self.values[key], stream)

proc has*(self: TLConstructor, key: string): bool =
    ## Check if the constructor has the specified parameter and if a value has been assigned
    if key notin self.structure.parameters:
        return false
    if key notin self.values:
        return false
    return true

proc name*(self: TLConstructor): string =
    ## Get the name (structure definition) of the constructor
    return self.structure.name

proc tlToType*[T](tl: TL, structure: TLStructure): T =
    var tl = tl
    if tl of TLObject:
        tl = tl.TLObject.actualObject
    when T is seq[uint8]:
        return tl.TLBytes.value
    elif T is string:
        return cast[string](tl.TLString.value)
    elif T is uint32 or T is int32:
        when T is uint32:
            return tl.TLInt.value
        else:
            return cast[int32](tl.TLInt.value)
    elif T is uint64 or T is int64:
        when T is uint64:
            return tl.TLLong.value
        else:
            return cast[int64](tl.TLLong.value)
    elif T is float32:
        return tl.TLFloat.value
    elif T is float64:
        return tl.TLDouble.value
    elif T is UInt128:
        return tl.TLInt128.value
    elif T is UInt256:
        return tl.TLInt256.value
    elif T is bool:
        if not(structure of TLStructureTrue):
            if tl of TLConstructor and tl.TLConstructor.structure.name == "boolTrue":
                return true
            elif tl of TLBool:
                return tl.TLBool.value
        elif structure of TLStructureTrue:
            quit(1)
        else:
            raise newException(ValueError, "Expecting parameter of constructor to be bool, got a different type")
    elif T is TLConstructor:
         return tl.TLConstructor

proc tlVectorToSeq[T](typ: typedesc[seq[T]], vector: TLVector, structure: TLStructure): seq[T] =
    when T is seq and T isnot seq[uint8]:
        for value in vector.value:
            result.add(tlVectorToSeq(T, value.TLVector, structure))
    else:
        for value in vector.value:
            result.add(tlToType[T](value, structure))

template getTl[T](tl: TL, structure: TLStructure): T =
    when T is seq and T isnot seq[uint8]:
        tlVectorToSeq(typedesc[T], tl.TLVector, structure)
    else:
        tlToType[T](tl, structure)

proc getValue*[T](self: TLConstructor, key: string): T =
    ## Get the value of a parameter of the specified constructor
    
    if key notin self.structure.parameters:
        raise newException(FieldDefect, &"This constructor does not contain the '{key}' parameter")
    when T is bool:
        if self.structure.parameters[key] of TLStructureTrue:
            if key in self.values: return true else: return false
    if key notin self.values:
        raise newException(FieldDefect, &"The value of the parameter '{key}' has not been assigned yet")
    return getTl[T](self.values[key], self.structure.parameters[key])

proc toJson*(self: TLConstructor): JsonNode 

proc tlToJson(tl: TL, structure: TLStructure): JsonNode = 
    if tl of TLInt:
        return %*getTl[uint32](tl, structure)
    elif tl of TLLong:
        return %*getTl[uint64](tl, structure)
    elif tl of TLFloat:
        return %*getTl[float32](tl, structure)
    elif tl of TLDouble:
        return %*getTl[float64](tl, structure)
    elif tl of TLBytes:
        return %*encode(getTl[seq[uint8]](tl, structure))
    elif tl of TLString:
        return %*getTl[string](tl, structure)
    elif tl of TLConstructor:
        if tl.TLConstructor.structure.sub == "Bool":
            return %*(if tl.TLConstructor.structure.name == "boolTrue": true else: false)
        return %*toJson(tl.TLConstructor)
    elif tl of TLInt128:
        return %*encode(toBytes(getTl[UInt128](tl, structure), MTPROTO_ENDIAN))
    elif tl of TLInt256:
        return %*encode(toBytes(getTl[UInt256](tl, structure), MTPROTO_ENDIAN))
    elif tl of TLBool:
        if tl.TLBool.value:
            return %*true
        else:
            return %*false
    elif tl of TLObject:
        if isNil(tl.TLObject.actualObject):
            raise newException(ValueError, "Object value is not assigned")
        else:
            return tlToJson(tl.TLObject.actualObject, structure)
proc jsonSeq(node: JsonNode, vector: TLVector, structure: TLStructure) =
    for value in vector.value:
        if value of TLVector:
            var arr = newJArray()
            jsonSeq(arr, value.TLVector, structure)
            node.add(arr)
        else:
            node.add(tlToJson(value, structure))

proc toJson*(self: TLConstructor): JsonNode = 
    result = newJObject()
    result["_"] = %*self.structure.name
    for key, parameter in self.structure.parameters:
        if key notin self.values:
            if isNil(parameter.flag):
                result[key] = newJNull()
                continue
            else:
                if parameter of TLStructureTrue:
                    result[key] = %*false
                else:
                    result[key] = newJNull()
                continue
        if parameter of TLStructureFlag:
            continue
        if not isNil(parameter.genericArgument):
            result[key] = newJArray()
            jsonSeq(result[key], self.values[key].TLVector, self.structure.parameters[key])
        else:
            if parameter of TLStructureTrue:
                result[key] = %*true
            else:
                result[key] = tlToJson(self.values[key], self.structure.parameters[key])

template `%*`*(self: TLConstructor): JsonNode =
    toJson(self)

proc `$`*(self: TLConstructor): string =
    return pretty(toJson(self))

proc toTL*[T: string|seq[uint8]|uint32|int32|uint64|int64|float32|float64|UInt128|UInt256|bool|TLConstructor](value: T): TL =
    when T is string:
        return TLString(value: value)
    elif T is seq[uint8]:
        return TLBytes(value: value)
    elif T is uint32:
        return TLInt(value: value)
    elif T is int32:
        return TLInt(value: cast[uint32](value))
    elif T is uint64:
        return TLLong(value: value)
    elif T is int64:
        return TLLong(value: cast[uint64](value))
    elif T is float32:
        return TLFloat(value: value)
    elif T is float64:
        return TLDouble(value: value)
    elif T is UInt128:
        return TLInt128(value: value)
    elif T is UInt256:
        return TLInt256(value: value) 
    elif T is bool:
        return TLBool(value: value)
    elif T is TLConstructor:
        return value


proc toTL*[T](values: seq[T]): TL =
  when values is seq[uint8]:
    return toTL[seq[uint8]](values)
  else:
    result = new TLVector
    for value in values:
        result.TLVector.value.add(toTL(value))

type 
   TLParam* = ref object of RootObj

   TLParamStructure* = ref object of TLParam
    value: TLStructure

   TLParamValue* = ref object of TLParam
    value: TL

proc initTLConstructor*(name: string, values: seq[(string, TLParam)]): TLConstructor =
    result = initTLConstructor(name)
    for value in values:
        if value[1] of TLParamValue:
            if value[1].TLParamValue.value of TLVector:
                result[value[0]] = value[1].TLParamValue.value.TLVector.value
            else:
                result[value[0]] = value[1].TLParamValue.value
        else:
            result[value[0]] = value[1].TLParamStructure.value

proc convert*[T](value: T): TLParam =
    when value is TLStructure:
        return TLParamStructure(value: value).TLParam
    else:
        return TLParamValue(value: toTL(value)).TLParam

macro tl*(constructorName: string, kwargs: untyped): untyped =
  var code = "initTLConstructor(\"" & constructorName.strVal & "\", @["
  if kwargs.kind == nnkCurly or kwargs.kind == nnkTableConstr:
    for a in kwargs:
      if a.kind == nnkExprEqExpr or a.kind == nnkExprColonExpr:
        code.add(&"(\"{a[0]}\", convert({a[1].toStrLit()})),")
      else:
        error("Unsupported object")
  else:
    error("Unsupported object")
  code.add("])")
  return parseStmt code
