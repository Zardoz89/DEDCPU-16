/**
 * DEDCPU-16 companion Disassembler library
 */
module disassembler;

import std.stdio, std.array, std.string, std.conv, std.getopt, std.format;

import dcpu.dcpu-16;

public import std.typecons;

private:

ushort[] ram; /// Assembly machine code is stored here
ushort pc;    /// Pointer to machine code 

/**
* Extract a particular information from a instruction
*/
  ubyte decode(string what)(ushort word) {
    static if (what == "OpCode") {
      return word & 0xF;
    } else if (what == "OpA" || what == "ExtOpCode") {
      return (word >> 4) & 0x3F;
    } else if (what == "OpB") {
      return (word >> 10) & 0x3F;
    }
  }

/**
 * Diassamble a instruction
 * Returns a string that contains a diassambled code
 */
string dissamble(ubyte opcode, ubyte ext_opcode,string op_a, string op_b) {
  string ret;

  if (opcode == ExtOpCode) { // Non basic instruction
    // Decode operation
    switch (ext_opcode) {
        case JSR:
      ret = "JSR " ~ op_b;
      return ret;
      
        default: // Not specs/implemented yet
      return "Unknow Instruction";
    }
    
  } else { // Decode operation
    switch (opcode) {
        case SET: // SET
      ret = "SET " ~ op_a ~ ", " ~ op_b;
      return ret;

        case ADD: // ADD
      ret = "ADD " ~ op_a ~ ", " ~ op_b;
      return ret;

        case SUB: // SUB
      ret = "SUB " ~ op_a ~ ", " ~ op_b;
      return ret;

        case MUL: // MUL
      ret = "MUL " ~ op_a ~ ", " ~ op_b;
      return ret;

        case DIV: // DIV
      ret = "DIV " ~ op_a ~ ", " ~ op_b;
      return ret;

        case MOD: // MOD
      ret = "MOD " ~ op_a ~ ", " ~ op_b;
      return ret;

        case SHL: // SHL
      ret = "SHL " ~ op_a ~ ", " ~ op_b;
      return ret;

        case SHR: // SHR
      ret = "SHR " ~ op_a ~ ", " ~ op_b;
      return ret;

        case AND: // AND
      ret = "AND " ~ op_a ~ ", " ~ op_b;
      return ret;

        case OR: // bOR
      ret = "BOR " ~ op_a ~ ", " ~ op_b;
      return ret;

        case XOR: // XOR
      ret = "XOR " ~ op_a ~ ", " ~ op_b;
      return ret;

        case IFE: // IFEqual
      ret = "IFE " ~ op_a ~ ", " ~ op_b;
      return ret;

        case IFN: // IFNot equal
      ret = "IFN " ~ op_a ~ ", " ~ op_b;
      return ret;

        case IFG: // IFGreat
      ret = "IFG " ~ op_a ~ ", " ~ op_b;
      return ret;

        case IFB: //IFBits set
      ret = "IFB " ~ op_a ~ ", " ~ op_b;
      return ret;
      
        default: // Not specs/implemented yet
      return "Unknow Instruction";
    }
  }
}
  
/**
 * Get the result of a type of operand
 */
string operand(string op ) (ubyte operand) {
  auto writer = appender!string();
  switch (operand) {
      case A:   // Register x
    return "A";
      case B:
    return "B";
      case C:
    return "C";
      case X:
    return "X";
      case Y:
    return "Y";
      case Z:
    return "Z";
      case I:
    return "I";
      case J:
    return "J";

      case Aptr: // Register pointer [x]
    return "[A]";
      case Bptr:
    return "[B]";
      case Cptr:
    return "[C]";
      case Xptr:
    return "[X]";
      case Yptr:
    return "[Y]";
      case Zptr:
    return "[Z]";
      case Iptr:
    return "[I]";
      case Jptr:
    return "[J]";

      case Aptr_word: // Register pointer with added word
    formattedWrite(writer, "[A+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Bptr_word:
    formattedWrite(writer, "[B+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Cptr_word:
    formattedWrite(writer, "[C+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Xptr_word:
    formattedWrite(writer, "[X+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Yptr_word:
    formattedWrite(writer, "[Y+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Zptr_word:
    formattedWrite(writer, "[Z+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Iptr_word:
    formattedWrite(writer, "[I+ 0x%04X]", ram[++pc]);
    return writer.data;
      case Jptr_word:
    formattedWrite(writer, "[J+ 0x%04X]", ram[++pc]);
    return writer.data;

      case POP: // POP
    return "POP";
      case PEEK: // PEEK
    return "PEEK";
      case PUSH: // PUSH
    return "PUSH";

      case SP: // SP
    return "SP";

      case PCr: // PC
    return "PC";

      case O: // Overflow register
    return "O";

      case Word_ptr: // next word pointer
    formattedWrite(writer, "[0x%04X]", ram[++pc]);
    return writer.data;

      case Word: // word literal
    formattedWrite(writer, "0x%04X", ram[++pc]);
    return writer.data;

      default: // literal
    formattedWrite(writer, "0x%02X", operand - Literal);
    return writer.data;
  }
}
  
public:

/**
 * Sets assembly machine code to be diassambled
 */
void set_assembly(ushort[] slice) {
  ram = slice;
}

/**
 * Diassamble the assembly machine code
 * Params:
 *  comment = Add comments to assembly code with the addre and hex machine code
 *  labels = auto tab and add labels to jumps
 *  offset = add a offset to addresses of each instruction
 * Returns a asociative array where the key is a pair of addreses that contains
 * the instruction in machine code
 */
string[ushort] get_diassamble(bool comment = false, bool labels = false, ushort offset = 0) {
  string[ushort] ret;
  while(ram.length > pc) {
    ushort word = ram[pc];
    ushort old_pc = pc;
    string inst= dissamble(decode!"OpCode"(word), decode!"ExtOpCode"(word),
                operand!"A"(decode!"OpA"(word)), operand!"B"(decode!"OpB"(word)));
    ushort pos = cast(ushort)(old_pc + offset);
    pc++;
    
    if (comment) { // Add coment  ; [addr] - xxxx ....
      if (labels) {
        ret[pos] = "                " ~ inst;
      } else {
        ret[pos] = inst;
      }

      for(auto i=0; i<(26- inst.length); i++)
        ret[pos] ~= " ";
      auto writer = appender!string();
      formattedWrite(writer, "[%04X] - %04X", pos, ram[pos]);
      ret[pos] ~= ";"~ writer.data;

      for (auto i=pos +1; i <= pc-1; i++) {
        writer = appender!string();
        formattedWrite(writer, " %04X", ram[i]);
        ret[pos] ~= writer.data;
      }
    } else {
      ret[pos] = inst;
    }
  }
  return ret;
}
