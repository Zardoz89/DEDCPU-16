/**
 * DEDCPU-16 companion Disassembler
 */
import std.stdio, std.getopt, std.algorithm, std.string, std.conv;

import core.thread, std.c.stdlib;


import dcpu.disassembler, dcpu.ram_loader;

void showhelp() {
  stderr.writeln(import("help_ddis.txt"));
}


int main (string[] args) {
  if (args.length < 2) { // No params
    showhelp();
    return -1;
  }
  
  bool help; // Show help
  bool comment, labels;
  TypeHexFile file_fmt; // Use binary or textual format
  
  // Process arguements 
  getopt(
    args,
    "c", &comment,
    "l", &labels,
    "type|t", &file_fmt,
    "h|?", &help);

  if (help) {
    showhelp();
    return 0;
  }
  
  string filename = args[1];
  
  if (filename.length == 0) {
    stderr.writeln("Missing input file\n");
    return -1;
  }
  
  ushort[] data;
  if (file_fmt == TypeHexFile.lraw) {
    data = load_ram!(TypeHexFile.lraw)(filename);
  } else if (file_fmt == TypeHexFile.braw) {
    data = load_ram!(TypeHexFile.braw)(filename);
  } else {
    try {
      data = load_ram!(TypeHexFile.ahex)(filename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?\n");
      return -1;
    }
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