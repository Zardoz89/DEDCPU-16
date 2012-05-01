/**
 * DEDCPU-16 companion Disassembler
 */
import std.stdio, std.conv, std.getopt, std.algorithm;
import std.string;
import core.thread;
import std.c.stdlib;

import dcpu.disassembler;

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
  
  void showHelp() {
    writeln(import("help_ddis.txt"));
    exit(0);
  }

  if (args.length < 2) {
    writeln(import("help_ddis.txt"));
    return -1;
  }

  string filename = args[1]; 
  args = args[0] ~ args[2..$];
  bool comment, labels;
  TypeHexFile file_fmt; // Use binary or textual format
  
  // Process arguements 
  getopt(
    args,
    "c", &comment,
    "l", &labels,
    "type|t", &file_fmt,
    "h", &showHelp);
    
  if (filename.length == 0) {
    writeln("Missing input file\n Use dedcpu -ifilename");
    return 0;
  }
  
  set_assembly(load_ram(file_fmt, filename));
  string[ushort] dis = get_diassamble(comment, labels);
  // Auto labeling
  if (labels) {
    foreach (key, ref line ;dis) {
      if (line.length > 24 && line[16..26] == "SET PC, 0x" ) {
        ushort jmp = parse!ushort(line[26..$], 16);
        if (jmp in dis) {
          line = line[0..24] ~ format(" lb%04X ", jmp) ~ line[32..$];
          dis[jmp] = format(":lb%04X ", jmp) ~ dis[jmp][8..$];
        }
      }
    }
  }

  // Sort by address
  ushort[] addresses = dis.keys;
  sort!("a<b") (addresses);
  foreach (key ; addresses) {
    //writefln ("%04X - %s", key[0], dis[key]);
    writeln(dis[key]);
  }
  
  return 0;
}