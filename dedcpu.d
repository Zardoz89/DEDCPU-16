import std.stdio, std.array, std.string, std.conv;

struct DCpu16 {
  ushort ram[0x10000];
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }
  ushort pc;
  ushort sp = 0xFFFF;
  ushort o;
  bool skip_next_instruction;
  ulong cicles = 0;
};

DCpu16 cpu;

/**
 * Decode paramaters from a o b parameter
 * Params:
 *  paramvalue = 6 bit value of a instruction parameter
 *  *literal = Were to store the literal value
 *  *use_cicles = How many cicles needed to read the paramenter
 * Returns: A pointer to the value (RAM memory, literal, register)
 */
ushort* decode_parameter(ubyte paramvalue, ushort* literal, ushort* use_cicles)
in {
  assert(literal !is null, "Literal can't be NULL");
  assert(use_cicles !is null, "use_cicles can't be NULL");
} body {
  switch (paramvalue) {
      case 0x00:
      case 0x01:
      case 0x02:
      case 0x03:
      case 0x04:
      case 0x05:
      case 0x06:
      case 0x07: // Register x
    return &cpu.registers[paramvalue];
      case 0x08:
      case 0x09:
      case 0x0A:
      case 0x0B:
      case 0x0C:
      case 0x0D:
      case 0x0E:
      case 0x0F: // Register pointer [x]
    return &cpu.ram[cpu.registers[paramvalue-0x08]];
      case 0x10:
      case 0x11:
      case 0x12:
      case 0x13:
      case 0x14:
      case 0x15:
      case 0x16:
      case 0x17: // Register pointer with added word
    *use_cicles +=1;
    return &cpu.ram[cpu.registers[paramvalue- 0x10] + cpu.ram[cpu.pc++]];
      case 0x18: // POP
    return &cpu.ram[cpu.sp++];
      case 0x19: // PEEK
    return &cpu.ram[cpu.sp];
      case 0x1A: // PUSH
    return &cpu.ram[--cpu.sp];
      case 0x1B: // SP
    return &cpu.sp;
      case 0x1C: // PC
    return &cpu.pc;
      case 0x1D: // Overflow register
    return &cpu.o;
      case 0x1E: // next word pointer
    *use_cicles +=1;
    return &cpu.ram[cpu.ram[cpu.pc++]];
      case 0x1F: // word literal
    *use_cicles +=1;
    return &cpu.ram[cpu.pc++];
      default: // literal
    *literal = paramvalue - 0x20;
    return literal;
  }
}

void run_instruction() {
  ushort use_cicles = 1;
  // Get first word
  ushort first_word = cpu.ram[cpu.pc++];
  // Decode operation
  ubyte opcode = first_word & 0xF;
  ubyte parama = (first_word >> 4) & 0x3F;
  ubyte paramb = (first_word >> 10) & 0x3F;
  writef(" (%04X) ", first_word);

  if (cpu.skip_next_instruction) {
    cpu.skip_next_instruction = false;
    cpu.cicles += use_cicles;
    return ;
  }
  if (opcode == 0x0) {
    // Non basic instruction - Decode parameter
    ushort param_literal = void;
    ushort* param_value = decode_parameter(paramb, &param_literal, &use_cicles);
    // Decode operation
    switch (parama) {
        case 0x01: // JSR
      writeln("JSR");
      use_cicles++;
      cpu.sp--;
      cpu.ram[cpu.sp] = cpu.pc;
      cpu.pc = *param_value;
      cpu.cicles += use_cicles;
      break;
        default: // Nothing
        throw new Exception("Unknow Instruction");
    }
  } else { // Decode parameters
    // These are here just incase the parameter is a short literal
    ushort parama_literal, paramb_literal;
    
    // It will need a different place to store short literals 
    ushort* parama_value = decode_parameter(parama, &parama_literal, &use_cicles);
    ushort* paramb_value = decode_parameter(paramb, &paramb_literal, &use_cicles);

    // Decode operation
    switch (opcode) {
        case 0x1: // SET
      writeln("SET");
      *parama_value = *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0x2: // ADD
      writeln("ADD");
      use_cicles++;
      if (*parama_value + *paramb_value > 0xFFFF) {
        cpu.o = 0x0001;
      }
      *parama_value = *parama_value + *paramb_value & 0xFFFF;
      cpu.cicles += use_cicles;
      break;
      
        case 0x3: // SUB
      writeln("SUB");
      use_cicles++;
      auto val = cast(ushort) (*parama_value - *paramb_value);
      if (val < 0) {
        cpu.o = 0xFFFF;
        *parama_value = -val;
      } else {
        *parama_value = val;
      }
      cpu.cicles += use_cicles;
      break;
      
        case 0x4: // MUL
      writeln("MUL");
      use_cicles++;
      uint value = *parama_value * *paramb_value;
      cpu.o = (value >> 16) & 0xFFFF;
      *parama_value = cast(ushort) value ;
      cpu.cicles += use_cicles;
      break;
      
        case 0x5: // DIV
      writeln("DIV");
      use_cicles +=2;
      if (*paramb_value == 0) {
        cpu.o = 0;
        *parama_value = 0;
      } else {
        auto value = ((*parama_value << 16) / *paramb_value) & 0xFFFF;
        cpu.o = cast(ushort) value;
        *parama_value = cast(ushort)(*parama_value / *paramb_value);
      }
      cpu.cicles += use_cicles;
      break;
      
        case 0x6: // MOD
      writeln("MOD");
      use_cicles +=2;
      if (*paramb_value == 0) {
        *parama_value = 0;
      } else {
        *parama_value = *parama_value % *paramb_value;
      }
      cpu.cicles += use_cicles;
      break;
      
        case 0x7: // SHL
      writeln("SHL");
      use_cicles++;
      uint val = *parama_value << *paramb_value;
      cpu.o = cast(ushort)(val >> 16);
      *parama_value = cast(ushort)val;
      cpu.cicles += use_cicles;
      break;
      
        case 0x8: // SHR
      writeln("SHR");
      use_cicles++;
      uint val = (*parama_value << 16) >> *paramb_value;
      cpu.o = val & 0xFFFF;
      *parama_value = *parama_value >> *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0x9: // AND
      writeln("AND");
      *parama_value = *parama_value & *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0xA: // bOR
      writeln("BOR");
      *parama_value = *parama_value | *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0xB: // XOR
      writeln("XOR");
      *parama_value = *parama_value ^ *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0xC: // IFEqual
      writeln("IFE");
      use_cicles++;
      cpu.skip_next_instruction = *parama_value != *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0xD: // IFNot equal
      writeln("IFN");
      use_cicles++;
      cpu.skip_next_instruction = *parama_value == *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        case 0xE: // IFGreat
      writeln("IFG");
      use_cicles++;
      cpu.skip_next_instruction = *parama_value <= *paramb_value;
      cpu.cicles += use_cicles;
      break;
      
        default: // 0xF IFBits set
      writeln("IFB");
      use_cicles++;
      cpu.skip_next_instruction = (*parama_value & *paramb_value) == 0;
      cpu.cicles += use_cicles;
    }
  }
}


int main (string[] args) {
  // Process arguements
  if (args.length > 2 || args.length < 2) {
    writefln("useage: %s input", args[0]);
    return 0;
  }

  // Open input file
  File f;
  try {
    f = File(args[1], "r");
  } catch (Exception e) {
    writeln("failed to open input file");
    return 0;
  }

  // Read words into RAM
  ushort i;
  foreach ( line; f.byLine()) {
    foreach (word; splitter(strip(line))) {
      cpu.ram[i] = parse!ushort(word, 16);
      i++;
    }
  }
  f.close();
  
  // Run
  writeln("Cicles PC   SP   O    A    B    C    X    Y    Z    I    J    Instruction");
  writeln("------ ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------");
  for (;;) {
    stdin.readln();
    writef("%06u ", cpu.cicles);
    writef("%04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X", cpu.pc, cpu.sp, cpu.o, cpu.a, cpu.b, cpu.c, cpu.x, cpu.y, cpu.z, cpu.i, cpu.j);
    run_instruction();
  }
  return 0;
}