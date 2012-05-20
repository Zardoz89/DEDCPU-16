import std.stdio, std.array, std.string, std.conv, std.getopt, std.format;

import dcpu.ram_io;
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
  m[0]= new TimerClock(m);
  m.init();
  //m[0].init();

  ushort[] data = void;
  if (file_fmt == TypeHexFile.lraw) {
    data = load_lraw(filename);
  } else if (file_fmt == TypeHexFile.braw) {
    data = load_braw(filename);
  } else if (file_fmt == TypeHexFile.ahex){
    try {
      data = load_ahex(filename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?\n");
      return -1;
    }
  } else {
    try {
      data = load_ram!(TypeHexFile.hexd)(filename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?\n", e.msg);
      return -1;
    }
  }
  m.ram[0..data.length] = data[0..$];
  long i, n;
  auto state = m.cpu_info;
  writeln("i:", i," PC:", format("%04X",state.pc), " A:", state.a, " B:", state.b, " C:", state.c, " X:", state.x, " Y:", state.y, " Z:", state.z, " I:", state.i, " J:", state.j, " ex:", state.ex, " sp:", state.sp);
  foreach (linea; stdin.byLine()) {
    if (linea.length >=2 && linea[0] == 'r') {
      n = parse!long(linea[1..$], 10);
    } else {
      n = 1;
    }
    for(; n> 0; n--) {
      while(!m.tick){}      // Executes a instrucction
      auto state = m.cpu_info;   // Get updated state of CPU
      writeln("i:", i," PC:", format("%04X",state.pc), " A:", state.a, " B:", state.b, " C:", state.c, " X:", state.x, " Y:", state.y, " Z:", state.z, " I:", state.i, " J:", state.j, " ex:", state.ex, " sp:", state.sp);
      i++;
    }
  }

  
  
  return 0;
}
