# DEDCPU-16 D Emulator for DCPU-16 #
A D based minimal emulator for Notch's DCPU-16 v1.1, written for the fun of it.
DEDCPU-16 aims to be a accurate and quick emulator working of CLI and capable of working like a emulation/debugger back-end for any IDE aimed to programming DCPU-16.

See: [DCPU-16 specs](http://0x10c.com/doc/dcpu-16.txt)

Why: Why not ?

The test.ascii file was made with swetland dcpu-16 assembler
<https://github.com/swetland/dcpu16>

The notch.bin file was made with interfect dcpu-emu assembler
<https://bitbucket.org/interfect/dcpu-emu>

## Usage: ##
    ./dedcpu -ifilename [-ttype]
##Parameters:##
* __-i --i --input__ *file* : Input file with memory map
* __-t --t --type__ *lraw|braw|ahex* : Type of file with memory map. *lraw* -> little endian raw binary ; *braw* -> big endian raw binary ; *ahex* -> ascii hexadecimal file

## Commands: ##
* __q__               -> End emulation
* __s__ or Enter key  -> Step one instruction
* __r__ *number*      -> Runs number instructions without stop. 0 for running forever (Ctrl+C to abort)
* __m__ *begin[-end]* -> Display a chunk of RAM from begin to end address of RAM (address in hex). If end it's omitted, only show RAM value at begin address.
* __d__ *begin[-end]* -> Dumps a chunk of RAM to a __dump.bin__ file in little endian raw binary. Same semantics that __'m'__
* __i__ *text*        -> Sends text to keyboard input buffer in emulated machine
* __v__               -> Show a label showing the meaning of each column

In branch instructions, the emulator will read the next instruction but will no execute if the condition fails.

__NOTE__: video_test.bin writes in video ram (0x8000) forever. It test video ram and cooperative multitasking. This program is know that not runs in some emulators.

Based over DCPU-16 C Emulator of Karl Hobley turbodog10(at)yahoo.co.uk

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

