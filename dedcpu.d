import std.stdio, std.array, std.string, std.conv, std.getopt, std.format;
import std.ascii, std.c.stdlib, std.c.stdio;
import core.thread;

import core.sys.posix.termios;
import core.sys.posix.unistd;
alias core.stdc.stdio.fileno fileno;
alias core.stdc.stdio.stdin stdin;

enum TypeHexFile {lraw, braw, ahex, hex8}; /// Type of machine code file

/**
 * CPU representation
 * Params:
 *  f = CPU Frequency
 */
struct DCpu16(double f) {
  enum double Frequency = f; /// In Hertzs
  enum long Period = cast(long) (1000000.0 / Frequency); /// In microseconds
    
private :
  ushort ram[0x10000];
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }
  ushort _pc;
  ushort sp = 0;
  ushort o;

  ubyte keyboard_ptr; // Points to the last character
  bool skip_next_instruction; 
  ulong cycles = 0;

  string diassembled_inst; // Instruction in string representation

  /**
   * Do PC++
   */
  @property ushort PC_plus() {
    Thread.sleep( dur!"msecs"( Period ) );
    return _pc++;
  }

  /**
   * Do ++PC
   */
  @property ushort plus_PC() {
    Thread.sleep( dur!"msecs"( Period ) );
    return ++_pc;
  }

  @property ushort PC() {
    return _pc;
  }
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
      formattedWrite(writer, " [A+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x11:
      auto writer = appender!string();
      formattedWrite(writer, " [b+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x12:
      auto writer = appender!string();
      formattedWrite(writer, " [C+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x13:
      auto writer = appender!string();
      formattedWrite(writer, " [X+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x14:
      auto writer = appender!string();
      formattedWrite(writer, " [Y+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x15:
      auto writer = appender!string();
      formattedWrite(writer, " [Z+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x16:
      auto writer = appender!string();
      formattedWrite(writer, " [I+ %04X]", ram[_pc]);
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
        case 0x17: // Register pointer with added word
      auto writer = appender!string();
      formattedWrite(writer, " [J+ %04X]", ram[_pc]);
      diassembled_inst ~= writer.data;
      use_cycles++; return ram[registers[paramvalue- 0x10] + ram[PC_plus]];
      
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
      return _pc;
      
        case 0x1D: // Overflow register
      diassembled_inst ~= " O";
      return o;
      
        case 0x1E: // next word pointer
      auto writer = appender!string();
      formattedWrite(writer, " [%04X]", ram[_pc]);
      diassembled_inst ~= writer.data;
      use_cycles++;
      return ram[ram[PC_plus]];
      
        case 0x1F: // word literal
      auto writer = appender!string();      
      formattedWrite(writer, " %04X", ram[_pc]);
      diassembled_inst ~= writer.data;
      use_cycles++;
      return ram[PC_plus];
      
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
    ushort first_word = ram[PC_plus];
    // Decode operation
    ubyte o_pcode = first_word & 0xF;
    ubyte parama = (first_word >> 4) & 0x3F;
    ubyte paramb = (first_word >> 10) & 0x3F;

    diassembled_inst = "";
    
    if (o_pcode == 0x0) { // Non basic instruction
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
        ram[sp] = _pc;
        _pc = *param_value;
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
      switch (o_pcode) {
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
   * Load a file with a image of RAM
   * Params:
   *  type = Type of file
   *  file = Name and path of the file
   */
  void load_ram(TypeHexFile type)(const string filename )
  in {
    assert (filename.length >0);    
  } body {
    auto f = File(filename, "r");

    scope(exit) {f.close();}
    
    ulong ln, i;
    static if (type == TypeHexFile.lraw) { // RAW little-endian binary file
      for (;i < 0x10000 && !f.eof; i++) {
        ubyte[2] word = void;
        f.rawRead(word);

        if (ln == 7) writeln();
        writef("%02X%02X ", word[1], word[0]);
        ram[i] = cast(ushort) (word[0] | word[1] << 8); // Swap endianes
        ln = i % 8;
      }
    } else if (type == TypeHexFile.braw) { // RAW big-endian binary file
      for (;i < 0x10000 && !f.eof; i++) {
        ubyte[2] word = void;
        f.rawRead(word);
        
        if (ln == 7) writeln();
        writef("%02X%02X ", word[0], word[1]);
        ram[i] = cast(ushort) (word[1] | word[0] << 8);
        ln = i % 8;
      }
    } else if (type == TypeHexFile.ahex) { // plain ASCII hex file
      foreach ( line; f.byLine()) { // each line only have a hex 16-bit word
        ram[i] = parse!ushort(line, 16);
        if (ln == 7) writeln();
        writef("%04X ", ram[i]);
        ln = i % 8;
        i++; 
      }
    } else {
      throw new Exception("Not implemented file type");
    }
  }

  /**
   * Generate a string representation of a range of RAM
   * Params:
   *  begin = Where the dump begin
   *  end = Where the dump ends
   * Returns: A string representation of a valid range of RAM
   */
  string display_ram(ushort begin, ushort end)
  in {
    assert(begin <= end, "Invalid RAM range");
  } body {
    string r; int i;
    const int cols = 7;
    
    for (; i <= (end - begin); i++) {
      if (i % cols == 0) { // Address
        auto writer = appender!string();
        formattedWrite(writer, "%04X: ", i + begin);
        r = r ~ writer.data ~ " ";
      }
      auto writer = appender!string(); // Word
      formattedWrite(writer, "%04X ", ram[i + begin]);
      r = r ~ writer.data;
      
      if (i!= 0 && ((i+1)%cols) ==0 ) { // Show 8 ascii 7-bit characters
        char[cols*2] chars = void;
        for (int j; j < cols*2; j++) {
          if ((j%2) == 0) {
            chars[j] = cast(char)(ram[i-(cols -(j/2) -1) + begin] >> 8);
          } else {
            chars[j] = cast(char)(ram[i-(cols -(j/2) -1) + begin] & 0xFF);
          }
        }
        
        r ~= " ";
        foreach (ref c; chars) {
          if (c > 0x7F || !isPrintable(c)) {
            r = r ~ "ᛝ";
          } else {
            r = r ~ c;
          }
        }
        r = r ~ "\n";
      }
    }
    
    if ((i%cols) != 0 ) { // Show remaning ascii chars
      for (int remaning = cols-(i%cols); remaning > 0; remaning--) {
        r ~= "     ";
      }
      r ~=" ";
      for (int remaning = i%cols; remaning > 0; remaning--) {
        char c[2];
        c[0] = cast(char)(ram[i-remaning + begin] >> 8);
        c[1] = cast(char)(ram[i-remaning + begin] & 0xFF);
        if (c[0] > 0x7F || !isPrintable(c[0])) {
          c[0] = '.';
        }
        if (c[1] > 0x7F || !isPrintable(c[1])) {
          c[1] = '.';
        }
        r = r ~ c[0] ~ c[1];
      }
      
    }

    
    return r;
  }

  /**
   * Dumps a region of RAM in little endian format
   * Params:
   *  begin = Where the dump begin
   *  end = Where the dump ends
   * Returns: A string representation of a valid range of RAM
   */
  void dump_ram(ushort begin, ushort end)
  in {
    assert(begin <= end, "Invalid RAM range");
  } body {
    auto f = File("dump.bin", "w");
    scope(exit) {f.close();}
    
    ubyte[2] word = void;
    for (int i = begin; i <= end; i++) {
      // word[0] is the lowest byte
      word[0] =cast(ubyte)(ram[i]& 0xFF);
      word[1] =cast(ubyte)(ram[i] >> 8);
      
      f.rawWrite(word);
    }
  }

  /**
   * Writes a tring in keyboard buffer
   * Params:
   *  input = String that contains the text that will we write in the buffer
   */
  void write_keyboard_buffer(string input) {    
    const ushort buffer = 0x9000;
    const ushort b_size = 16;
    if (input.length > 0) {
      foreach(size_t i , char c ; input) {
        ram[buffer+keyboard_ptr] = c;
        keyboard_ptr++;
        keyboard_ptr = keyboard_ptr % b_size;
      }
      ram[buffer+keyboard_ptr] = 0; // NULL character
    }
  }

  /**
   * Generate a string representation registers status and number of cpu cycles
   * Returns: String representation registers status and number of cpu cycles
   */
  @property string show_state() {
    string r;
    auto writer = appender!string();
    formattedWrite(writer, "%06u %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X",
     cycles, _pc, sp, o, a, b, c, x, y, z, i, j);
    r ~= writer.data;
    return r;
  }

  /**
   * Generate a string Hex representation of the actual instruction that PC points
   */
  @property string actual_instruction() {
    string r;
    auto writer = appender!string();
    formattedWrite(writer,"[%04X]", ram[_pc]);
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
  TypeHexFile file_fmt; // Use binary or textual format

  void showHelp() {
    writeln(import("help.txt"));
    exit(0);
  }
  
  // Process arguements 
  getopt(
    args,
    "input|i", &filename,
    "type|t", &file_fmt,
    "h", &showHelp);
    
  if (filename.length == 0) {
    writeln("Missing input file\n Use dedcpu -ifilename");
    return 0;
  }

  DCpu16!100000.0 cpu; // CPU @ 100Khz
  
  // Open input file
  try {
    if (TypeHexFile.lraw == file_fmt) {
      writeln("little endian raw binary");
      cpu.load_ram!(TypeHexFile.lraw)(filename);
    } else if (TypeHexFile.braw == file_fmt) {
      writeln("big endian raw binary");
      cpu.load_ram!(TypeHexFile.braw)(filename);
    } else if (TypeHexFile.ahex == file_fmt) {
      writeln("ascii hexadecimal");
      cpu.load_ram!(TypeHexFile.ahex)(filename);
    } else {
      writeln("Not implemented yet");
      return -1;
    }
  } catch (Exception e) {
    writeln(e.msg,"\n", filename);
    return -1;
  }

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
  bool[ushort] breakpoint; // Sets breakpoints
  
  while(1) {
    if (step) {
    auto c = fgetc(stdin);
      switch (c) {
          case 'q':
          case 'Q': // Quit
        return(0);
        
          case 'b':
          case 'B': // Break point
        tcsetattr(fileno(stdin), TCSADRAIN, &ostate); // original mode
        auto input = strip(readln());
        tcsetattr(fileno(stdin), TCSADRAIN, &nstate);
        ushort pos;
        try {
          pos = parse!ushort(input, 16); // PC value
        } catch (ConvException e) {
          writeln("Invalid value");
          continue;
        }
        if ( pos in breakpoint) {
          writefln("Erasing breakpoint at 0x%04X", pos);
          breakpoint.remove(pos);
        } else {
          writefln("Enabling breakpoint at 0x%04X", pos);
          breakpoint[pos] = true;
        }
        
        continue;
          case 'v':
          case 'V': // Print info head
        writeln("Cycles  PC   SP   O    A    B    C    X    Y    Z    I    J   Instruction");
        writeln("------ ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------");
        continue;
          case 'r':
          case 'R':
        count = 0;
        tcsetattr(fileno(stdin), TCSADRAIN, &ostate); // original mode        
        auto input = strip(readln());
        tcsetattr(fileno(stdin), TCSADRAIN, &nstate);
        if (input== "") { // r0 or r means run forever
          stop = 0;
          step = false;
          continue;
        }
        
        try {
          stop = parse!ushort(input, 10); // How many cycles
        } catch (ConvException e) {
          writeln("Invalid value");
          continue;
        }
        step = false;        
        continue;
          case 'd':
          case 'D': // Memory dump
          case 'm':
          case 'M': // Memory display
        tcsetattr(fileno(stdin), TCSADRAIN, &ostate); // original mode
        auto input = strip(readln());
        tcsetattr(fileno(stdin), TCSADRAIN, &nstate);
        ushort begin, end;
        try {
          begin = parse!ushort(input, 16);
        } catch (ConvException e) {
          writeln("Invalid value");
          continue;
        }

        munch(input,"- "); // skip - or whitespaces
        if (input.length > 0) {
          try {
            end = parse!ushort(input, 16);

          } catch (ConvException e){
            writeln("Invalid value");
            continue;
          }
        } else {
          end = begin;
        }

        if (begin > end)
          continue;
        if (c == 'm' || c == 'M') { // View memory
          writeln(cpu.display_ram(begin, end));
        } else { // Dump memory
          cpu.dump_ram(begin, end);
        }
        continue;

          case 'i':
          case 'I': // Keyboard input to emulated machine
        tcsetattr(fileno(stdin), TCSADRAIN, &ostate); // original mode
        auto input = readln();
        tcsetattr(fileno(stdin), TCSADRAIN, &nstate);
        if (input.length > 16)
          input = input[0..16]; // We only use the first 16 characters
        cpu.write_keyboard_buffer(input);
        continue;
          
          case 's':
          case 'S':
          case '\n':

        write(cpu.show_state, " ", cpu.actual_instruction, " ");
        try {
          cpu.run_instruction();
          writeln(cpu.diassembled);
        } catch (Exception e) {
          writeln(e.toString);
        }
        
        break;
          default:
      }
    } else if (stop == 0 || count < stop) {      
      if (cpu.PC in breakpoint) {
        writeln("Breakpoint reached");
        writeln(cpu.show_state, " ", cpu.actual_instruction, " ");
        step = true;
        continue;
      }

      if (stop != 0) 
        write(cpu.show_state, " ", cpu.actual_instruction, " ");

      try {
        cpu.run_instruction();        
      } catch (Exception e) {
        writeln(e.msg);
        writeln(cpu.show_state, " ", cpu.actual_instruction, " ");
        step = true; // Go to interactive mode to allow memory dumps
      }
      if (stop != 0)
        writeln(cpu.diassembled);
    } else {
      step = true;
    }
    count++;
  }
  return 0;
}
