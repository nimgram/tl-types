# Nimgram
# Copyright (C) 2020-2022 Daniele Cortesi <https://github.com/dadadani>
# This file is part of Nimgram, under the MIT License
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import ../src/tltypes
import pkg/stint

proc test =
    #let t = newTLStream(@[17'u8, 248, 239, 167, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0])
    #echo tl(t)
    var t = tl("updateMessagePollVote", {"poll_id": 3333'u64, "user_id": 3135'u64, options: @[@[135'u8, 13'u8], @[131'u8]], "qts": 104'u32})
    doAssert t.encode() == [201'u8,149,99,16,5,13,0,0,0,0,0,0,63,12,0,0,0,0,0,0,21,196,181,28,2,0,0,0,2,135,13,0,1,131,0,0,104,0,0,0]

    t = tl(newTLStream(@[13'u8,13,155,218,105,43,0,0,94,72,66,36,223,175,208,184,35,0,0,0]))
    doAssert t.name == "invokeWithLayer"
    doAssert t.getValue[:TLConstructor]("query").getValue[:TLConstructor]("ttl").getValue[:uint32]("days") == 35
    t = tl("coreMessage", {msg_id=13'u64, seqno=2'u32, bytes=3'u32, body=getReturnType(t)})
    t["body"] = toTL(false)

    doAssert tl(newTLStream(t.encode())).getValue[:bool]("body") == false
    
    t = tl(newTLStream(@[220'u8, 248, 241, 115, 1, 0, 0, 0, 96, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 25, 186, 114, 62]))
    doAssert t.name == "msg_container"
    doAssert t.getValue[:seq[TLConstructor]]("messages")[0].name == "coreMessage"
    doAssert t.getValue[:seq[TLConstructor]]("messages")[0].getValue[:TLConstructor]("body").name == "logOut"


    t = tl(newTLStream(@[236'u8,90,201,131,4,53,20,54,1,0,0,0,1,19,0,0,1,20,0,0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,127,251,255,255,255,255,255,255,255,255,255,255,255,255,255,255,127,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,127]))
    doAssert t.name == "p_q_inner_data"
    doAssert t.getValue[:UInt128]("nonce") == stuint(Int128.high, 128)
    doAssert t.getValue[:UInt256]("new_nonce") == stuint(Int256.high, 256)

when isMainModule:
    test()