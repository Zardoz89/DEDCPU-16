import std.stdio, std.array, std.string, std.conv, std.getopt, std.format;
import std.c.stdlib, std.c.stdio;
alias std.stdio.stdin dstdin;

import core.sys.posix.termios;
import core.sys.posix.unistd;
alias core.stdc.stdio.fileno fileno;
alias core.stdc.stdio.stdin stdin;

/**
 * CPU representation
 */
struct DCpu16 {
  ushort ram[0x10000];
  
private :
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }
  ushort pc;
  ushort sp = 0;
  ushort o;
  bool skip_next_instruction; 
  ulong cycles = 0;

  string diassembled_inst; // Instruction in string representation
  
  /**
   * Decode paramaters from a o b parameter
   * Params:
   *  paramvalue = 6 bit value of a instruction parameter
   *  literal = Were to store the literal value
   *  use_cycles = How many cycles needed to read the paramenter
   * Returns: A reference to the value (RAM memory, literal, register)
   */
  private ref ushort decode_parameter(ubyte paramvalue, ref ushort literal, ref ushort use_cycles) {
    switch (paramvalue) {
        case 0x00:
      diassembled_inst ~= " A"; return registers[paramvalue];
        case 0x01:
      diassembled_inst ~= " B"; return registers[paramvalue];
        case 0x02:
      diassembled_inst ~= " C"; return registers[paramvalue];
        case 0x03:
      diassembled_inst ~= " X"; return registers[paramvalue];
        case 0x04:
      diassembled_inst ~= " Y"; return registers[paramvalue];
        case 0x05:
      diassembled_inst ~= " Z"; return registers[paramvalue];
        case 0x06:
      diassembled_inst ~= " I"; return registers[paramvalue];
        case 0x07: // Register x
      diassembled_inst ~= " J"; return registers[paramvalue];
      
        case 0x08:
      diassembled_inst ~= " [A]"; return ram[registers[paramvalue-0x08]];
        case 0x09:
      diassembled_inst ~= " [B]"; return ram[registers[paramvalue-0x08]];
        case 0x0A:
      diassembled_inst ~= " [C]"; return ram[registers[paramvalue-0x08]];
        case 0x0B:
      diassembled_inst ~= " [X]"; return ram[registers[paramvalue-0x08]];
        case 0x0C:
      diassembled_inst ~= " [Y]"; return ram[registers[paramvalue-0x08]];
        case 0x0D:
      diassembled_inst ~= " [Z]"; return ram[registers[paramvalue-0x08]];
        case 0x0E:
      diassembled_inst ~= " [I]"; return ram[registers[paramvalue-0x08]];
        case 0x0F: // Register pointer [x]
      diassembled_inst ~= " [J]"; return ram[registers[paramvalue-0x08]];
      
        case 0x10:
      auto writer = appender!string();
      formattedWrite(writer, " [A+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x11:
      auto writer = appender!string();
      formattedWrite(writer, " [b+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x12:
      auto writer = appender!string();
      formattedWrite(writer, " [C+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x13:
      auto writer = appender!string();
      formattedWrite(writer, " [X+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x14:
      auto writer = appender!string();
      formattedWrite(writer, " [Y+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x15:
      auto writer = appender!string();
      formattedWrite(writer, " [Z+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x16:
      auto writer = appender!string();
      formattedWrite(writer, " [I+ %04X]", ram[pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
        case 0x17: // Register pointer with added word
      auto writer = appender!string();
      formattedWrite(writer, " [J+ %04X]", ram[pc]);
      diassembled_inst ~= writer.data;
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[pc++]];
      
        case 0x18: // POP
      diassembled_inst ~= " POP";
      return ram[sp++];
        case 0x19: // PEEK
      diassembled_inst ~= " PEEK";
      return ram[sp];
        case 0x1A: // PUSH
      diassembled_inst ~= " PUSH";
      return ram[--sp];
      
        case 0x1B: // SP
      diassembled_inst ~= " SP";
      return sp;
      
        case 0x1C: // PC
      diassembled_inst ~= " PC";
      return pc;
      
        case 0x1D: // Overflow register
      diassembled_inst ~= " O";
      return o;
      
        case 0x1E: // next word pointer
      auto writer = appender!string();
      formattedWrite(writer, " [%04X]", ram[pc]);
      diassembled_inst ~= writer.data;
      use_cycles++;
      return ram[ram[pc++]];
      
        case 0x1F: // word literal
      auto writer = appender!string();      
      formattedWrite(writer, " %04X", ram[pc]);
      diassembled_inst ~= writer.data;
      use_cycles++;
      return ram[pc++];
      
        default: // literal
      literal = paramvalue - 0x20;
      auto writer = appender!string();
      formattedWrite(writer, " %04X", literal);
      diassembled_inst ~= writer.data;
      return literal;
    }
  }

public:
  /**
   * Runs a instruction
   */
  void run_instruction() {
    ushort use_cycles = 1;
    // Get first word
    ushort first_word = ram[pc++];
    // Decode operation
    ubyte opcode = first_word & 0xF;
    ubyte parama = (first_word >> 4) & 0x3F;
    ubyte paramb = (first_word >> 10) & 0x3F;

    diassembled_inst = "";
    
    if (opcode == 0x0) { // Non basic instruction
      if (skip_next_instruction) {
        skip_next_instruction = false;
        cycles += use_cycles;
        return ;
      }

      ushort param_literal = void;
      ushort* param_value = &decode_parameter(paramb, param_literal, use_cycles);
      
      // Decode operation
      switch (parama) {
          case 0x01: // JSR
        diassembled_inst = "JSR"  ~ diassembled_inst;
        use_cycles++;
        sp--;
        ram[sp] = pc;
        pc = *param_value;
        cycles += use_cycles;
        break;
          default: // Nothing
        throw new Exception("Unknow Instruction");
      }
    } else { // Decode parameters
      if (skip_next_instruction) {
        skip_next_instruction = false;
        cycles += use_cycles;
        return ;
      }
      
      ushort parama_literal, paramb_literal;
      ushort* parama_value = &decode_parameter(parama, parama_literal, use_cycles);
      ushort* paramb_value = &decode_parameter(paramb, paramb_literal, use_cycles);

      // Decode operation
      switch (opcode) {
          case 0x1: // SET
        diassembled_inst = "SET" ~ diassembled_inst;
        *parama_value = *paramb_value;
        cycles += use_cycles;
        break;

          case 0x2: // ADD
        diassembled_inst = "ADD" ~ diassembled_inst;
        use_cycles++;
        if (*parama_value + *paramb_value > 0xFFFF) {
          o = 0x0001;
        }
        *parama_value = *parama_value + *paramb_value & 0xFFFF;
        cycles += use_cycles;
        break;

          case 0x3: // SUB
        diassembled_inst = "SUB" ~ diassembled_inst;
        use_cycles++;
        auto val = cast(ushort) (*parama_value - *paramb_value);
        if (val < 0) {
          o = 0xFFFF;
          *parama_value = -val;
        } else {
          *parama_value = val;
        }
        cycles += use_cycles;
        break;

          case 0x4: // MUL
        diassembled_inst = "MUL" ~ diassembled_inst;
        use_cycles++;
        uint value = *parama_value * *paramb_value;
        o = (value >> 16) & 0xFFFF;
        *parama_value = cast(ushort) value ;
        cycles += use_cycles;
        break;

          case 0x5: // DIV
        diassembled_inst = "DIV" ~ diassembled_inst;
        use_cycles +=2;
        if (*paramb_value == 0) {
          o = 0;
          *parama_value = 0;
        } else {
          auto value = ((*parama_value << 16) / *paramb_value) & 0xFFFF;
          o = cast(ushort) value;
          *parama_value = cast(ushort)(*parama_value / *paramb_value);
        }
        cycles += use_cycles;
        break;

          case 0x6: // MOD
        diassembled_inst = "MOD" ~ diassembled_inst;
        use_cycles +=2;
        if (*paramb_value == 0) {
          *parama_value = 0;
        } else {
          *parama_value = *parama_value % *paramb_value;
        }
        cycles += use_cycles;
        break;

          case 0x7: // SHL
        diassembled_inst = "SHL" ~ diassembled_inst;
        use_cycles++;
        uint val = *parama_value << *paramb_value;
        o = cast(ushort)(val >> 16);
        *parama_value = cast(ushort)val;
        cycles += use_cycles;
        break;

          case 0x8: // SHR
        diassembled_inst = "SHR" ~ diassembled_inst;
        use_cycles++;
        uint val = (*parama_value << 16) >> *paramb_value;
        o = val & 0xFFFF;
        *parama_value = *parama_value >> *paramb_value;
        cycles += use_cycles;
        break;

          case 0x9: // AND
        diassembled_inst = "AND" ~ diassembled_inst;
        *parama_value = *parama_value & *paramb_value;
        cycles += use_cycles;
        break;

          case 0xA: // bOR
        diassembled_inst = "BOR" ~ diassembled_inst;
        *parama_value = *parama_value | *paramb_value;
        cycles += use_cycles;
        break;

          case 0xB: // XOR
        diassembled_inst = "XOR" ~ diassembled_inst;
        *parama_value = *parama_value ^ *paramb_value;
        cycles += use_cycles;
        break;

          case 0xC: // IFEqual
        diassembled_inst = "IFE" ~ diassembled_inst;
        use_cycles++;
        skip_next_instruction = *parama_value != *paramb_value;
        cycles += use_cycles;
        break;

          case 0xD: // IFNot equal
        diassembled_inst = "IFN" ~ diassembled_inst;
        use_cycles++;
        skip_next_instruction = *parama_value == *paramb_value;
        cycles += use_cycles;
        break;

          case 0xE: // IFGreat
        diassembled_inst = "IFG" ~ diassembled_inst;
        use_cycles++;
        skip_next_instruction = *parama_value <= *paramb_value;
        cycles += use_cycles;
        break;

          default: // 0xF IFBits set
        diassembled_inst = "IFB" ~ diassembled_inst;
        use_cycles++;
        skip_next_instruction = (*parama_value & *paramb_value) == 0;
        cycles += use_cycles;
      }
    }
  }

  /**
   * Generate a string representation of a range of RAM
   * Params:
   *  begin = Where the dump begin
   *  end = Where the dump ends
   * Returns: A string representation of a valid range of RAM
   */
  string dump_ram(ushort begin, ushort end)
  in {
    assert(begin <= end, "Invalid RAM range");
  } body {
    string r;
    for (int i; i <= (end - begin); i++) {
      if (i % 4 == 0) {
        if (i != 0)
          r ~= "\n";
          
        auto writer = appender!string();
        formattedWrite(writer, "%04X:", i + begin);
        r ~= writer.data ~ " ";
      }

      auto writer = appender!string();
      formattedWrite(writer, "%04X ", ram[i + begin]);
      r ~= writer.data;
    }

    return r;
  }

  /**
   * Generate a string representation registers status and number of cpu cycles
   * Returns: String representation registers status and number of cpu cycles
   */
  @property string show_state() {
    string r;
    auto writer = appender!string();
    formattedWrite(writer, "%06u %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X",
     cycles, pc, sp, o, a, b, c, x, y, z, i, j);
    r ~= writer.data;
    return r;
  }

  /**
   * Generate a string Hex representation of the actual instruction that PC points
   */
  @property string actual_instruction() {
    string r;
    auto writer = appender!string();
    formattedWrite(writer,"[%04X]", ram[pc]);
    r ~= writer.data;
    return r;
  }

  /**
   * Generate a string of a disassembled instruction
   */
  @property string diassembled() {
    return this.diassembled_inst.idup;
  }
};

termios  ostate; // Old state of stdin

int main (string[] args) {
  string filename;
  bool ascci_fmt = false; // Use binary or textual format

 void showHelp() {
    writeln(import("help.txt"));
    exit(0);
 }
  
  // Process arguements
  getopt(
    args,
    "input|i", &filename,
    "t", &ascci_fmt,
    "h", &showHelp);
    
  if (filename.length == 0) {
    writeln("Missing input file\n Use dedcpu -ifilename");
    return 0;
  }

  DCpu16 cpu;
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
  if (ascci_fmt) { // Textual files from swetland dcpu-16 assembler
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
  
  nstate.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN); // Set No Echo mode
  tcsetattr(fileno(stdin), TCSADRAIN, &nstate); // Set Mode

  // Restore old state
  scope(exit){ tcsetattr(fileno(stdin), TCSADRAIN, &ostate);} // return to original mode
  
  // Run
  writeln("Cycles  PC   SP   O    A    B    C    X    Y    Z    I    J   Instruction");
  writeln("------ ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------");

  bool step = true;
  ulong count, stop = ulong.max;
  while(1) {
    if (step) {
    auto c = fgetc(stdin);
      switch (c) {
          case 'q':
          case 'Q': // Quit
        return(0);
          case 'v':
          case 'V': // Print info head
        writeln("Cycles  PC   SP   O    A    B    C    X    Y    Z    I    J   Instruction");
        writeln("------ ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------");
        continue;
          case 'r':
          case 'R':
        tcsetattr(fileno(stdin), TCSADRAIN, &ostate); // original mode
        count = 0;
        auto input = strip(readln());
        stop = parse!ushort(input, 10); // How many cycles
        step = false;
        tcsetattr(fileno(stdin), TCSADRAIN, &nstate);
        continue;
          case 'm':
          case 'M': {
          tcsetattr(fileno(stdin), TCSADRAIN, &ostate); // original mode
          auto input = strip(readln());
          ushort begin = parse!ushort(input, 16);
          munch(input,"- "); // skip - or whitespaces
          ushort end = parse!ushort(input, 16);
          tcsetattr(fileno(stdin), TCSADRAIN, &nstate);

          if (begin > end)
            continue;
          writeln(cpu.dump_ram(begin, end));
          continue;
        }
          case 's':
          case 'S':
          case '\n':

        write(cpu.show_state, " ", cpu.actual_instruction, " ");
        cpu.run_instruction();
        writeln(cpu.diassembled);
        break;
          default:
      }
    } else if (count < stop) {
      write(cpu.show_state, " ", cpu.actual_instruction, " ");
      cpu.run_instruction();
      writeln(cpu.diassembled);
    } else {
      step = true;
    }
    count++;
  }
  return 0;
}