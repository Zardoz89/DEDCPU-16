/**
 * RAM dump loader
 */
module dcpu.ram_loader;

import std.c.stdlib, std.stdio, std.bitmanip, std.conv;

enum TypeHexFile {lraw, braw, ahex, hex8}; /// Type of machine code file

/**
 * Load a file with a image of a RAM
 * Params:
 *  type = Type of file
 *  file = Name and path of the file
 * Returns a array with a raw binary image of the file
 */
ushort[] load_ram(TypeHexFile type)(const string filename )
in {
  assert (filename.length >0);
} body {
  auto f = File(filename, "r");

  scope(exit) {f.close();}

  ushort[] img = new ushort[0];

  ulong i;
  static if (type == TypeHexFile.lraw || type == TypeHexFile.braw) { // RAW binary file
    for (;i < 0x10000 && !f.eof; i++) {
      ubyte[2] word = void;
      f.rawRead(word);
      static if (type == TypeHexFile.lraw) { // little-endian
        img ~= littleEndianToNative!ushort(word);
      } else {
        img ~= bigEndianToNative!ushort(word);
      }
    }
  } else if (type == TypeHexFile.ahex) { // plain ASCII hex file
    foreach ( line; f.byLine()) { // each line only have a hex 16-bit word
      if (i >= 0x1000)
        break;
      img ~= parse!ushort(line, 16);
      i++;
    }
  } else {
    throw new Exception("Not implemented file type");
  }
  return img;
}

alias load_ram!(TypeHexFile.lraw) load_lraw;
alias load_ram!(TypeHexFile.braw) load_braw;
alias load_ram!(TypeHexFile.ahex) load_ahex;