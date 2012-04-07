import std.stdio, std.array, std.string, std.conv, std.getopt;
import std.c.stdlib, std.c.stdio;

import core.sys.posix.termios;
import core.sys.posix.unistd;
alias core.stdc.stdio.fileno fileno;
alias core.stdc.stdio.stdin stdin;

/**
 * CPU representation
 */
struct DCpu16 {
  ushort ram[0x10000];
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }
  ushort pc;
  ushort sp = 0;
  ushort o;
  bool skip_next_instruction;
  ulong cycles = 0;
};

DCpu16 cpu;

termios  ostate; // Old state of stdin

/**
 * Decode paramaters from a o b parameter
 * Params:
 *  paramvalue = 6 bit value of a instruction parameter
 *  literal = Were to store the literal value
 *  use_cycles = How many cycles needed to read the paramenter
 * Returns: A reference to the value (RAM memory, literal, register)
 */
ref ushort decode_parameter(ubyte paramvalue, ref ushort literal, ref ushort use_cycles) {
  switch (paramvalue) {
      case 0x00:
      case 0x01:
      case 0x02:
      case 0x03:
      case 0x04:
      case 0x05:
      case 0x06:
      case 0x07: // Register x
    return cpu.registers[paramvalue];
      case 0x08:
      case 0x09:
      case 0x0A:
      case 0x0B:
      case 0x0C:
      case 0x0D:
      case 0x0E:
      case 0x0F: // Register pointer [x]
    return cpu.ram[cpu.registers[paramvalue-0x08]];
      case 0x10:
      case 0x11:
      case 0x12:
      case 0x13:
      case 0x14:
      case 0x15:
      case 0x16:
      case 0x17: // Register pointer with added word
    use_cycles++;
    return cpu.ram[cpu.registers[paramvalue- 0x10] + cpu.ram[cpu.pc++]];
      case 0x18: // POP
    return cpu.ram[cpu.sp++];
      case 0x19: // PEEK
    return cpu.ram[cpu.sp];
      case 0x1A: // PUSH
    return cpu.ram[--cpu.sp];
      case 0x1B: // SP
    return cpu.sp;
      case 0x1C: // PC
    return cpu.pc;
      case 0x1D: // Overflow register
    return cpu.o;
      case 0x1E: // next word pointer
    use_cycles++;
    return cpu.ram[cpu.ram[cpu.pc++]];
      case 0x1F: // word literal
    use_cycles++;
    return cpu.ram[cpu.pc++];
      default: // literal
    literal = paramvalue - 0x20;
    return literal;
  }
}

/**
 * Runs a instruction
 */
void run_instruction() {
  ushort use_cycles = 1;
  // Get first word
  ushort first_word = cpu.ram[cpu.pc++];
  // Decode operation
  ubyte opcode = first_word & 0xF;
  ubyte parama = (first_word >> 4) & 0x3F;
  ubyte paramb = (first_word >> 10) & 0x3F;
  writef(" (%04X) ", first_word);

  if (opcode == 0x0) {
    // Non basic instruction - Decode parameter
    ushort param_literal = void;
    ushort* param_value = &decode_parameter(paramb, param_literal, use_cycles);

    if (cpu.skip_next_instruction) {
      cpu.skip_next_instruction = false;
      cpu.cycles += use_cycles;
      return ;
    }
    
    // Decode operation
    switch (parama) {
        case 0x01: // JSR
      write("JSR");
      use_cycles++;
      cpu.sp--;
      cpu.ram[cpu.sp] = cpu.pc;
      cpu.pc = *param_value;
      cpu.cycles += use_cycles;
      break;
        default: // Nothing
      throw new Exception("Unknow Instruction");
    }
  } else { // Decode parameters
    // These are here just incase the parameter is a short literal
    ushort parama_literal, paramb_literal;
    
    // It will need a different place to store short literals 
    ushort* parama_value = &decode_parameter(parama, parama_literal, use_cycles);
    ushort* paramb_value = &decode_parameter(paramb, paramb_literal, use_cycles);

    if (cpu.skip_next_instruction) {
      cpu.skip_next_instruction = false;
      cpu.cycles += use_cycles;
      return ;
    }
    
    // Decode operation
    switch (opcode) {
        case 0x1: // SET
      write("SET");
      *parama_value = *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0x2: // ADD
      write("ADD");
      use_cycles++;
      if (*parama_value + *paramb_value > 0xFFFF) {
        cpu.o = 0x0001;
      }
      *parama_value = *parama_value + *paramb_value & 0xFFFF;
      cpu.cycles += use_cycles;
      break;
      
        case 0x3: // SUB
      write("SUB");
      use_cycles++;
      auto val = cast(ushort) (*parama_value - *paramb_value);
      if (val < 0) {
        cpu.o = 0xFFFF;
        *parama_value = -val;
      } else {
        *parama_value = val;
      }
      cpu.cycles += use_cycles;
      break;
      
        case 0x4: // MUL
      write("MUL");
      use_cycles++;
      uint value = *parama_value * *paramb_value;
      cpu.o = (value >> 16) & 0xFFFF;
      *parama_value = cast(ushort) value ;
      cpu.cycles += use_cycles;
      break;
      
        case 0x5: // DIV
      write("DIV");
      use_cycles +=2;
      if (*paramb_value == 0) {
        cpu.o = 0;
        *parama_value = 0;
      } else {
        auto value = ((*parama_value << 16) / *paramb_value) & 0xFFFF;
        cpu.o = cast(ushort) value;
        *parama_value = cast(ushort)(*parama_value / *paramb_value);
      }
      cpu.cycles += use_cycles;
      break;
      
        case 0x6: // MOD
      write("MOD");
      use_cycles +=2;
      if (*paramb_value == 0) {
        *parama_value = 0;
      } else {
        *parama_value = *parama_value % *paramb_value;
      }
      cpu.cycles += use_cycles;
      break;
      
        case 0x7: // SHL
      write("SHL");
      use_cycles++;
      uint val = *parama_value << *paramb_value;
      cpu.o = cast(ushort)(val >> 16);
      *parama_value = cast(ushort)val;
      cpu.cycles += use_cycles;
      break;
      
        case 0x8: // SHR
      write("SHR");
      use_cycles++;
      uint val = (*parama_value << 16) >> *paramb_value;
      cpu.o = val & 0xFFFF;
      *parama_value = *parama_value >> *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0x9: // AND
      write("AND");
      *parama_value = *parama_value & *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0xA: // bOR
      write("BOR");
      *parama_value = *parama_value | *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0xB: // XOR
      write("XOR");
      *parama_value = *parama_value ^ *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0xC: // IFEqual
      write("IFE");
      use_cycles++;
      cpu.skip_next_instruction = *parama_value != *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0xD: // IFNot equal
      write("IFN");
      use_cycles++;
      cpu.skip_next_instruction = *parama_value == *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        case 0xE: // IFGreat
      write("IFG");
      use_cycles++;
      cpu.skip_next_instruction = *parama_value <= *paramb_value;
      cpu.cycles += use_cycles;
      break;
      
        default: // 0xF IFBits set
      write("IFB");
      use_cycles++;
      cpu.skip_next_instruction = (*parama_value & *paramb_value) == 0;
      cpu.cycles += use_cycles;
    }
  }
}


int main (string[] args) {
  string filename;
  bool binary_fmt = false; // Use binary or textual format

 void showHelp() {
    writeln("Usage:");
    writeln("./dedcpu -ifilename [-b]");
    writeln("Parameters:");
    writeln("\t-i --i --input : Input file with the machine code");
    writeln("\t-b : Use binary little-endian format of interfect dcpu-emu . By default the emulator read textual files in big-endian made by swetland dcpu-16 assembler");
    writeln();
    writeln("Each time that the user press Enter key, the emulator executes a instruction.");
    writeln("In branch instructions, the emulator will read the next instruction but will no execute if the condition fails.");
    writeln("To end the emulator do Ctrl+C");
    exit(0);
 }
  
  // Process arguements
  getopt(
    args,
    "input|i", &filename,
    "b", &binary_fmt,
    "h", &showHelp);
    
  if (filename.length == 0) {
    writeln("Missing input file\n Use dedcpu -ifilename");
    return 0;
  }

  // Open input file
  File f;
  try {
    f = File(filename, "r");
  } catch (Exception e) {
    writeln("Failed to open input file ", filename);
    return 0;
  }

  // Read words into RAM
  ushort i, ln;
  if (!binary_fmt) { // Textual files from swetland dcpu-16 assembler
    foreach ( line; f.byLine()) {
      foreach (word; splitter(strip(line))) {
        cpu.ram[i] = parse!ushort(word, 16);
        if (ln == 7) writeln();
        writef("%04X ", cpu.ram[i]);
        ln = i % 8;
        i++; 
      }
    }
  } else { // Binary file from DCPU-EMU little-endian format    
    for (;i < 0x10000 && !f.eof; i++) {
      ubyte[2] word = void;
      f.rawRead(word);
      
      if (ln == 7) writeln();
      writef("%02X%02X ", word[1], word[0]);
      cpu.ram[i] = cast(ushort) (word[0] | word[1] << 8); // Swap endianes
      ln = i % 8;
    }
  }
  f.close();
  writeln();

  termios  nstate; // New state for stdin

  // Get actual state of stdin and backup
  tcgetattr(fileno(stdin), &ostate);
  tcgetattr(fileno(stdin), &nstate);
  
  // Set No Echo mode
  nstate.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN);

  
  tcsetattr(fileno(stdin), TCSADRAIN, &nstate); // Set Mode

  // Restore old state
  scope(exit){ tcsetattr(fileno(stdin), TCSADRAIN, &ostate);}       // return to original mode
  
  // Run
  writeln("Cycles PC   SP   O    A    B    C    X    Y    Z    I    J    Instruction");
  writeln("------ ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------");
  for (;;) {
    auto c = fgetc(stdin);
    writef("%06u ", cpu.cycles);
    writef("%04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X", cpu.pc, cpu.sp, cpu.o, cpu.a, cpu.b, cpu.c, cpu.x, cpu.y, cpu.z, cpu.i, cpu.j);
    run_instruction();
    writeln();
  }
  return 0;
}