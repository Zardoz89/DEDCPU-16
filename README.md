# DEDCPU Toolkit #

This tool-kit consists in a series of small tools related to the development around Notch's DCPU-16 computer.
The tool-kit it's actually increasing it's functionality and usefulness adding some interesting tools, like a converter between binary formats, a disassemblers or LEM1802 font viewer.

## Font viewer for LEM1802 screen ##

It's a graphic tool to load and view fonts for LEM1802 screen. It allow edit and view each glyph and show each glyph in binary, hexadecimal and decimal representations plus a graphic representation of it.

### Usage: ###
  ./lem1802_fontview

## D DISassembler for DCPU-16 v1.7 ##

### Usage: ###
  ./ddis filename [options]
### Options: ###
* __-h__                   Show this message
* __-t__ or __--type__ *type*  Type of file with memory map. __lraw__ -> little endian raw binary ; __braw__ -> big endian raw binary ; __ahex__ -> ascii hexadecimal file ; __dat__ -> Read DATs from a dasm file. By default ddis asumes little endian raw binary input file
* __-c__                   Add comments to all lines of the style [address] xxxx ....   where xxxx its the hexadecimal representation of these instruction.
* __-l__                   Auto-label all jumps (SET PC, .... and JSR ....)
* __-b__*number*           Sets the absolute position were begin to disassembly the file. By default it's 0
* __-e__*number*           Sets the absolute position were end to disassembly the file. By default it's the end of the file.

## Binary file CONVersor for DCPU-16 (any version) ##

### Usage: ###
  ./bconv input_filename output_filename [options]
### Options: ###
* __-h__                   Show this message
* __-i__ or __--itype__ *type* Type of input file with memory map. __lraw__ -> little endian raw binary ; __braw__ -> big endian raw binary ; __ahex__ -> ascii hexadecimal file ; __hexd__ -> ascii hexadecimal dump file. By default bconv assumes little endian raw binary input file.
* __-o__ or __--otype__ *type* Type of output file with memory map. __lraw__ -> little endian raw binary ; __braw__ -> big endian raw binary ; __ahex__ -> ascii hexadecimal file ; __hexd__ -> ascii hexadecimal dump file. By default bconv assumes ascii hexadecimal dump output file.
* __-b__*number*           Sets the absolute position were begin to convert the file. By default it's 0
* __-e__*number*           Sets the absolute position were end to convert the file. By default it's the end of the file.


## Notes: ##
Files tester.hex and tester2.hex are hexadecimal dump files for testing disassemblers and emulators. You have the original dcpu-16 assembly code in tester.dasm and tester2.dasm.

## License: ##
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

