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

import stint, options, ../encode, ../decode, zippy

type
    TL* = ref object of RootObj
        constructorID: uint32

    TLObject* = ref object of TL
    TLFunction* = ref object of TL

    FlagBit* = range[0'i32..int32.high]

    TLTrue* = ref object of TLObject
    TLFalse* = ref object of TLObject

    GZipContent* = ref object of TLObject
        value*: TL

    CoreMessage* = ref object
        msgID*: uint64
        seqNo*: uint32
        lenght: uint32
        body*: TL

    MessageContainer* = ref object of TLObject
        messages*: seq[CoreMessage]

    RPCException* = ref object of CatchableError
        errorCode*: int32
        errorMessage*: string

proc TLEncode*(obj: TL): seq[uint8]

proc TLDecode*(stream: TLStream): TL

proc TLEncode*(self: CoreMessage): seq[uint8] =
    result.add(self.msgID.TLEncode())
    result.add(self.seqNo.TLEncode())
    let body = TLEncode(self.body)
    result.add(TLEncode(uint32(len(body))))
    result.add(body)

proc TLDecodeCoreMessage(stream: TLStream): CoreMessage =
    result = new CoreMessage
    result.msgID = TLDecode[uint64](stream)
    result.seqNo = TLDecode[uint32](stream)
    result.lenght = TLDecode[uint32](stream)
    result.body = TLDecode(newTLStream(stream.readBytes(result.lenght)))


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
    for _ in countup(1, TLDecode[int32](self)):
        result.add(TLDecode(self))
