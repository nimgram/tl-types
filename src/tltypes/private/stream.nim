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

const MTPROTO_ENDIAN* = littleEndian
const VECTOR_CID* = uint32(0x1cb5c415)
const TRUE_CID* = uint32(0x997275b5)
const FALSE_CID* = uint32(0xbc799737)

type TLStream* = ref object
    ## A stream of bytes
    stream: seq[uint8] ## Sequence of bytes

proc newTLStream*(data: sink seq[uint8]): TLStream =
    ## Create a new TLStream
    return TLStream(stream: data)

proc readBytes*(self: TLStream, n: uint): seq[uint8] =
    ## Read a specified length of bytes
    result = self.stream[0..n-1]
    self.stream = self.stream[n..self.stream.high]

proc len*(self: TLStream): int =
    return self.stream.len

proc readAll*(self: sink TLStream): seq[uint8] =
    ## Read everything remaining
    result = self.stream
    self.stream.setLen(0)

