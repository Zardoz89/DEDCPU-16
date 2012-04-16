/**
 * DEDCPU-16 companion Disassembler
 */
import std.stdio, std.conv, std.getopt;

import disassembler;

enum TypeHexFile {lraw, braw, ahex, hex8}; /// Type of machine code file

/**
 * Load a file with a image of a RAM
 * Params:
 *  type = Type of file
 *  file = Name and path of the file
 * Returns a array with a raw binary image of the file
 */
ushort[] load_ram(TypeHexFile type, const string filename )
in {
  assert (filename.length >0);    
} body {
  auto f = File(filename, "r");

  scope(exit) {f.close();}
   
  ushort[] img = new ushort[0];
  
  ulong i;
  if (type == TypeHexFile.lraw) { // RAW little-endian binary file
    for (;i < 0x10000 && !f.eof; i++) {
      ubyte[2] word = void;
      f.rawRead(word);

      img ~= cast(ushort) (word[0] | word[1] << 8); // Swap endianes
    }
  } else if (type == TypeHexFile.braw) { // RAW big-endian binary file
    for (;i < 0x10000 && !f.eof; i++) {
      ubyte[2] word = void;
      f.rawRead(word);
      
      img ~= cast(ushort) (word[1] | word[0] << 8);
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

int main (string[] args) {
  
  if (args.length < 2) {
    writeln("Moar arguments!");
    return -1;
  }

  set_assembly(load_ram(TypeHexFile.lraw, args[1]));
  string[] dis = get_diassamble();

  foreach (line; dis) {
    writeln (line);
  }

  return 0;
}