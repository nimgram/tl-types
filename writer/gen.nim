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

import tlparser
import constructors, setid, encode, decode, namebyid, json

type TLWriterConfig* = object
    enableTypes*: bool
    enableFunctions*: bool
    generateSetConstructorID*: bool
    generateNameByConstructorID*: bool
    generateEncode*: bool
    generateDecode*: bool
    generateJson*: bool

const PREFIX_CODE = """# Nimgram
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

include static

# Layer version of this schema
const LAYER_VERSION* = """

proc generateNimCode*(file: File, tl: seq[TLConstructor],
        config: TLWriterConfig, layer: int, log: bool = false) =
    file.write(PREFIX_CODE, $layer)

    if config.enableTypes: generateConstructors(file, tl, Types, log)
    if config.enableFunctions: generateConstructors(file, tl, Functions)
    if config.generateSetConstructorID and config.enableTypes and
            config.enableFunctions: generateSetConstructorID(file, tl, log)
    if config.generateNameByConstructorID and config.enableTypes and
            config.enableFunctions: generateNameByConstructorID(file, tl, log)
    if config.generateEncode: generateEncode(file, tl, log)
    if config.generateDecode and config.enableTypes and
            config.enableFunctions: generateDecode(file, tl, log)
    if config.generateJson: generateJson(file, tl, log  )