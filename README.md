# D DISassembler for DCPU-16 v1.7 #

## Usage: ##
  ./ddis filename [options]
## Options: ##
* __-h__                   Show this message
*  -t or --type *type*  Type of file with memory map. __lraw__ -> little endian raw binary ; __braw__ -> big endian raw binary ; __ahex__ -> ascii hexadecimal file. By default ddis asumes little endian raw binary input file
*  __-c__                   Add comments to all lines of the style [address] xxxx ....   where xxxx its the hexadecimal representation of these instruction.
*  __-l__                   Autolabel all jumps (actually only SET PC, ....)

## Notes: ##
File test2.bin it's a Big Endian raw binary file for test disassembling. Don't use it in a emulater because it's a imcoplete code. You can compare ddis output of these file with test2.dasm that it's the source code that generated test2.bin.


# License: #
This project is licensed under the BSD license.

Copyright (c) 2012, Luis Panadero Guardeño
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
   
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
   
3. The names of its contributors may not be used to endorse or promote
   products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

