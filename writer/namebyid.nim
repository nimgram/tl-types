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

import tlparser, strformat, utils, terminal


proc generateNameByConstructorID*(file: File, constructors: seq[
        TLConstructor], log: bool = false) =
    if constructors.len <= 0:
        return
    if log: stdout.styledWriteLine(fgCyan, styleBright, "      Info:",
      fgDefault,
      resetStyle, " Generating NameByConstructorID")
    file.write("\n\nproc nameByConstructorID*(obj: TL): string =")
    file.write("\n    case obj.constructorID:")
    for constructor in constructors:

        file.write(&"\n    of uint32({constructor.id}): return \"{generateStylizedName(constructor.name, constructor.namespaces)}\"")
    file.write("""
    
    of uint32(0xbc799737): return "TLFalse"
    of uint32(0x997275b5): return "TLTrue"
    of uint32(0x3072cfa1): return "GZipContent"
    of uint32(0x73F1F8DC): return "MessageContainer"""")

    file.write(&"\n    else:\n        raise newException(CatchableError, \"Unable to find the corresponding type for this constructor id.\")")
