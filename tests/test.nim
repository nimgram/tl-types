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

import ../src/tltypes, ../src/tltypes/encode, ../src/tltypes/decode
import pkg/stint
import std/options

proc primitivesTest = 
    block:
        let i32 = high(int32)
        let i32encoded = TLEncode(i32)
        let i32decoded = TLDecode[int32](newTLStream(i32encoded))
        doAssert i32decoded == i32, "int32 test is not matching"

    block:
        let i64 = high(int64)
        let i64encoded = TLEncode(i64)
        let i64decoded = TLDecode[int64](newTLStream(i64encoded))
        doAssert i64decoded == i64, "int64 test is not matching"
    
    block:
        let f64 = high(float64)
        let f64encoded = TLEncode(f64)
        let f64decoded = TLDecode[float64](newTLStream(f64encoded))
        doAssert f64decoded == f64, "float64 test is not matching"
    
    block:
        let btest = true
        let bencoded = TLEncode(btest)
        let bdecoded = TLDecode[bool](newTLStream(bencoded))
        doAssert btest == bdecoded and TLDecode[uint32](newTLStream(bencoded)) == uint32(0x997275b5), "bool test is not matching"
    
    block:
        let stest = "nimgramm"
        let sencoded = TLEncode(stest)
        let sdecoded = TLDecode[string](newTLStream(sencoded))
        doAssert sdecoded == stest, "string test is not matching"


        doAssert sencoded[0] == 8, "encoded string len is not matching"
        doAssert char(sencoded[2]) == 'i', "encoded string char check is not matching"
        doAssert sencoded[sencoded.high] == 0, "encoded string padding test failed"
    
    block:        
        let stest = "nimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgramnimgram"
        let sencoded = TLEncode(stest)
        let sdecoded = TLDecode[string](newTLStream(sencoded))

        doAssert stest == sdecoded, "encoded long string is not matching"
        
        doAssert sencoded[0] == 254'u8, "encoded long string len is not matching"
        doAssert sencoded[1] == 38'u8 and sencoded[2] == 1'u8, "encoded long string len is not matching"
        doAssert sencoded[sencoded.high] == 0'u8, "encoded string char check is not matching"

    block:
        let sq = @["nimgram", "client"]
        let sqencoded = TLEncodeVector(sq)
        let sqdecoded = TLDecodeVector[string](newTLStream(sqencoded))
        doAssert sqdecoded == sq, "seq test is not matching"


proc constructorsTest = 
    block: 
        let tls = InvokeWithLayer(layer: 600, query: InputPeerSelf().setConstructorID).setConstructorID
        let tlencoded = TLEncode(tls)
        let tldecoded = tl.TLDecode(newTLStream(tlencoded))
        doAssert tldecoded of InvokeWithLayer, "decoded tl is not of type InvokeWithLayer"
        let tlb = tldecoded.InvokeWithLayer
        doAssert tlb.layer == 600
        doAssert tlb.query of InputPeerSelf, "query is not of type InputPeerSelf"
        
    block:
        let tls = MessageMediaPhoto(ttl_seconds: some(104'u32)).setConstructorID
        let tlencoded = TLEncode(tls)
        let tldecoded = tl.TLDecode(newTLStream(tlencoded))
        doAssert tldecoded of MessageMediaPhoto, "decoded tl is not of type MessageMediaPhoto"
        let tlb = tldecoded.MessageMediaPhoto
        doAssert tlb.ttl_seconds.isSome and tlb.ttl_seconds.get == 104, "flag check failed"
        
when isMainModule:
    echo "Checking primitives"
    primitivesTest()
    echo "Checking constructors"
    constructorsTest()