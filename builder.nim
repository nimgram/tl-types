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

import strutils, sequtils
import tlparser

const LAYER_DEFINITION = "LAYER"

proc findLayerVersion(tldata: string): int =
  ## Find the layer version from the TL schema
  for line in split(tldata, "\n"):
    if line.startsWith("//"):
      let index = line.find(LAYER_DEFINITION)
      if index != -1:
        return parseInt(line[index+LAYER_DEFINITION.len..line.high].strip())
  raise newException(FieldDefect, "Unable to find layer version")


