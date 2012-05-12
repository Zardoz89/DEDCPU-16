import std.stdio, std.array, std.string, std.conv, std.getopt, std.format;

import dcpu.ram_loader;
import dcpu.machine, dcpu.clock;

void showhelp() {
  stderr.writeln(import("help.txt"));
}

int main (string[] args) {
  if (args.length < 2) { // No params
    showhelp();
    return -1;
  }

  bool help; // Show help
  TypeHexFile file_fmt; // Use binary or textual format
  
  // Process arguements 
  getopt(
    args,
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

  Machine m = new Machine();
  m.init();

  ushort[] data = void;
  if (file_fmt == TypeHexFile.lraw) {
    data = load_ram!(TypeHexFile.lraw)(filename);
  } else if (file_fmt == TypeHexFile.braw) {
    data = load_ram!(TypeHexFile.braw)(filename);
  } else {
    try {
      data = load_ram!(TypeHexFile.ahex)(filename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?");
      return -1;
    }
  }
  m.ram[0..data.length] = cast(shared) data[0..$];

  writeln("PC:", format("%04X",m.cpu.pc), " A:", m.cpu.a, " B:", m.cpu.b, " C:", m.cpu.c, " X:", m.cpu.x, " Y:", m.cpu.y, " Z:", m.cpu.z, " I:", m.cpu.i, " J:", m.cpu.j, " ex:", m.cpu.ex);
  for (int i = 0; i < 100; i++) {
    if (m.cpu.step()) {
      writeln("PC:", format("%04X",m.cpu.pc), " A:", m.cpu.a, " B:", m.cpu.b, " C:", m.cpu.c, " X:", m.cpu.x, " Y:", m.cpu.y, " Z:", m.cpu.z, " I:", m.cpu.i, " J:", m.cpu.j, " ex:", m.cpu.ex);
    }
  }

  
  
  return 0;
}