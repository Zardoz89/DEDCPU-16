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
  size_t start; size_t end = ushort.max;
  TypeHexFile file_fmt; // Use binary or textual format
  
  // Process arguements 
  getopt(
    args,
    "b", &start,
    "e", &end,
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
    stderr.writeln("Missing input file");
    return -1;
  }
  
  ushort[] data;
  if (file_fmt == TypeHexFile.lraw) {
    data = load_ram!(TypeHexFile.lraw)(filename);
  } else if (file_fmt == TypeHexFile.braw) {
    data = load_ram!(TypeHexFile.braw)(filename);
  } else if (file_fmt == TypeHexFile.ahex){
    try {
      data = load_ram!(TypeHexFile.ahex)(filename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?");
      return -1;
    }
  } else {
    try {
      data = load_ram!(TypeHexFile.hexd)(filename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?", e.msg);
      return -1;
    }
  }

  end = end < data.length ? end : data.length; // Clamp between 0 to 0xFFFF
  start = start < ushort.max ? start : ushort.max;
  if (start > end || start > data.length || start == end) {
    stderr.writeln("Error: Invalid ranges");
    stderr.writeln("\tBegin: ", start,"\n\tEnd: ", end,"\n\tData dump size: ",data.length);
    return -1;
  }
  data = data[start..end]; // Slice
  
  string[ushort] dis = range_diassamble(data, comment, labels, cast(ushort)start);

  if (labels) {
    auto_label(dis);
  }
  
  // Sort by address
  ushort[] addresses = dis.keys;
  sort!("a<b") (addresses);
  foreach (key ; addresses) {
    //writefln ("%04X - %s", key[0], dis[key]);
    writeln(entab(dis[key]));
  }
  
  return 0;
}