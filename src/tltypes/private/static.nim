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

import pkg/stint, std/options, ../encode, ../decode, pkg/zippy, std/json

type
    TL* = ref object of RootObj
        constructorID: uint32

    TLObject* = ref object of TL
    TLFunction* = ref object of TL

    FlagBit* = range[0'i32..int32.high]

    TLTrue* = ref object of TLObject
    TLFalse* = ref object of TLObject
    
    TLVector* = ref object of TLObject
        elements*: seq[TL]

    TLLong* = ref object of TLObject
        value*: uint64

    TLInt* = ref object of TLObject
        value*: uint32

    GZipContent* = ref object of TLObject
        value*: TL

    FutureSalt* = ref object of TLObject
        validSince*: uint32
        validUntil*: uint32
        salt*: uint64

    FutureSalts* = ref object of TLObject
        reqMsgID*: uint64
        now*: uint64
        salts*: seq[FutureSalt]

    CoreMessage* = ref object
        msgID*: uint64
        seqNo*: uint32
        length: uint32
        body*: TL
    
    RPCResult* = ref object of TLObject
        reqMsgID*: uint64
        result*: TL

    MessageContainer* = ref object of TLObject
        messages*: seq[CoreMessage]

    RPCException* = ref object of CatchableError
        errorCode*: int32
        errorMessage*: string

proc TLEncode*(obj: TL): seq[uint8]

proc TLDecode*(stream: sink TLStream): TL

proc TLEncode*(self: CoreMessage): seq[uint8] =
    result.add(self.msgID.TLEncode())
    result.add(self.seqNo.TLEncode())
    let body = TLEncode(self.body)
    result.add(TLEncode(uint32(len(body))))
    result.add(body)

proc TLDecodeCoreMessage*(stream: TLStream): CoreMessage =
    result = new CoreMessage
    result.msgID = TLDecode[uint64](stream)
    result.seqNo = TLDecode[uint32](stream)
    result.length = TLDecode[uint32](stream)
    result.body = TLDecode(newTLStream(stream.readBytes(result.length)))


proc seqNo*(isRelated: bool, currentInt: int): int =
    var related = 1
    if not isRelated:
        related = 0
    var seqno = currentInt + abs(2 * not related)
    return seqno

proc TLDecodeVector*(
    self: TLStream, enableIdDecode: bool = true): seq[TL] =
    ## Implementation of vector decoding for TL objects.

    if enableIdDecode:
        doAssert TLDecode[uint32](self) == VECTOR_CID, "Type is not a Vector"
    for _ in 1..TLDecode[int32](self):
        result.add(TLDecode(self))

proc `%*`*(obj: TL): JsonNode

proc `%*`*(arr: seq[TL]): JsonNode =
    result = newJArray()
    for obj in arr:
        result.add(tl.`%*`obj)