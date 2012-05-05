/**
 * DEDCPU-16 companion Disassembler
 */
import std.stdio, std.getopt, std.algorithm, std.string, std.conv;

import core.thread, std.c.stdlib;


import dcpu.disassembler, dcpu.ram_loader;



int main (string[] args) {
  ushort[] data;
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
  
  if (file_fmt == TypeHexFile.lraw) {
    data = load_ram!(TypeHexFile.lraw)(filename);
  } else if (file_fmt == TypeHexFile.braw) {
    data = load_ram!(TypeHexFile.braw)(filename);
  } else {
    data = load_ram!(TypeHexFile.ahex)(filename);
  }
  
  string[ushort] dis = range_diassamble(data, comment, labels);

  // Sort by address
  ushort[] addresses = dis.keys;
  sort!("a<b") (addresses);
  foreach (key ; addresses) {
    //writefln ("%04X - %s", key[0], dis[key]);
    writeln(dis[key]);
  }
  
  return 0;
}