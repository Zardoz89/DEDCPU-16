/**
 * DEDCPU-16 companion Disassembler
 */
import std.stdio, std.getopt, std.algorithm, std.string, std.conv;

import core.thread, std.c.stdlib;


import dcpu.disassembler, dcpu.ram_loader;



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
  
  if (file_fmt == TypeHexFile.lraw) {
    set_assembly(load_ram!(TypeHexFile.lraw)(filename));
  } else if (file_fmt == TypeHexFile.braw) {
    set_assembly(load_ram!(TypeHexFile.braw)(filename));
  } else {
    set_assembly(load_ram!(TypeHexFile.ahex)(filename));
  }
  
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