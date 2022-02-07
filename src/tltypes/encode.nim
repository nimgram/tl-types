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

import endians
import stint
import private/stream


proc TLEncode*(integer: int32|uint32|int64|uint64|float32|float64|UInt128|UInt256): seq[uint8] =
    ## Serialize integers

    when cpuEndian != MTPROTO_ENDIAN:
        when sizeof(integer) == 16 or sizeof(integer) == 32:
            return toBytes(integer, MTPROTO_ENDIAN)[0..sizeof(integer)-1]
        elif sizeof(integer) == 4:
            var res: array[0..sizeof(integer)-1, uint8]
            swapEndian32(addr res, unsafeAddr integer)
            result = res[0..sizeof(integer)-1]
        elif sizeof(integer) == 8:
            var res: array[0..sizeof(integer)-1, uint8]
            swapEndian64(addr res, unsafeAddr integer)
            result = res[0..sizeof(integer)-1]
    else:
        return cast[array[0..sizeof(integer)-1, uint8]](integer)[0..sizeof(integer)-1]

proc TLEncode*(bl: bool): seq[uint8] =
    ## Serialize bool

    if bl: return TLEncode(uint32(TRUE_CID)) else: return TLEncode(uint32(FALSE_CID))

proc TLEncode*(data: seq[uint8]): seq[uint8] =
    ## Serialize bytes

    if len(data) <= 253:
        result.add(uint8(len(data)) & data)
        while len(result) mod 4 != 0:
            result.add(uint8(0))
    else:
        result.add(uint8(254) & TLEncode(int32(len(data)))[0..2] & data)
        while len(result) mod 4 != 0:
            result.add(uint8(0))

template TLEncode*(data: string): seq[uint8] =
    TLEncode(cast[seq[uint8]](data))

proc TLEncodeVector*[T](x: seq[T]): seq[uint8] =
    ## Serialize vector

    result.add(TLEncode(int32(VECTOR_CID)) & TLEncode(int32(len(x))))
    for obj in x:
        result = result & TLEncode(obj)
