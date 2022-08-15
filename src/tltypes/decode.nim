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


import private/stream
export stream
import std/endians
import pkg/stint

proc TLDecode*[T: int32|uint32|int64|uint64|float32|float64|UInt128|UInt256|bool|seq[
    uint8]|string](self: TLStream): T =
  ## Decode primitives types

  when T is bool:
    var cid = TLDecode[uint32](self)
    if cid == TRUE_CID: return true
    if cid == FALSE_CID: return false
    raise newException(CatchableError, "Invalid constructor id")
  elif T is string:
    return cast[string](TLDecode[seq[uint8]](self))
  elif T is seq[uint8]:
    let len = self.readBytes(1)
    var paddingLen = int32(0)

    if len[0] <= 253:
      result = self.readBytes(uint(len[0]))
      paddingLen = int32(len[0]+1)
    else:
      paddingLen = TLDecode[int32](newTLStream(self.readBytes(3) & 0))
      result = self.readBytes(uint(paddingLen))
      paddingLen = paddingLen+4
    while int64(paddingLen) mod int64(4) != int64(0):
      inc paddingLen
      doAssert self.readBytes(1)[0] == uint8(0), "Unexpected end of padding bytes"
  else:
    var buf = self.readBytes(uint(sizeof(T)))
    when cpuEndian != MTPROTO_ENDIAN:
      when sizeof(T) == 4:
        swapEndian32(addr result, addr buf[0])
      elif sizeof(T) == 8:
        swapEndian64(addr result, addr buf[0])
      elif sizeof(T) == 16 or sizeof(T) == 32:
        result = fromBytes(T, buf, MTPROTO_ENDIAN)
    else:
      copyMem(addr result, addr buf[0], sizeof(T))




proc TLDecodeVector*[T](
    self: TLStream, enableIdDecode: bool = true): seq[T] =
  ## Decode a Vector.
  ## This is a generic type, meaning that it will use an existing procedure to actually decode every type

  if enableIdDecode:
    doAssert TLDecode[uint32](self) == VECTOR_CID, "Type is not a Vector"
  for _ in countup(1, TLDecode[int32](self)):
    result.add(TLDecode[T](self))
