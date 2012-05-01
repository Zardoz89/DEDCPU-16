/**
 * DCPU-16 cpu disassembler
 */
module dcpu.disassembler;

import std.stdio, std.array, std.string, std.conv, std.getopt;
// import std.format;
import dcpu.constants;

public import std.typecons;

private:

ushort[] ram; /// Assembly machine code is stored here
ushort pc;    /// Pointer to machine code 

/**
 * Extract a particular information from a instruction
 * Params:
 *  what = Type of data to decode from a instruction
           ("OpCode", "ExtOpCode","OpA" or "OpB")
 *  word = Data to decode. A word and his two next words
 * Returns: Extracted data from a instruction
*/
ubyte decode(string what)(ushort word) pure {
  // Format is aaaaaabbbbbooooo or aaaaaaooooo00000
  static if (what == "OpCode") {
    return word & 0b00000000_00011111;
  } else if (what == "OpB" || what == "ExtOpCode") {
    return (word >> 5) & 0b00000000_00011111;
  } else if (what == "OpA") {
    return (word >> 10) & 0b00000000_00111111;
  }
}

/**
 * Diassamble a instruction
 * Params:
 *  words    = Instruction to disassemble (A word and his two next words)
 *  n_words  = Size of disassambled instruction
 * Returns: A string that contains a diassambled code
 */
string disassamble(ushort[] words, out ushort n_words) {
  ubyte opcode = decode!"OpCode"(words[0]);
  n_words = 1;
  string op_a = operand!"OpA"(words, n_words);
  if (opcode == OpCode.ExtOpCode) { // Non basic instruction
    opcode = decode!"ExtOpCode"(words[0]);
    foreach (s; __traits(allMembers, ExtOpCode)) {
      if (opcode == mixin("ExtOpCode." ~ s)) {
        return s ~ " " ~ op_a;
      }
    }
    return ";Unknow Extended OpCode";
    
  } else { // Decode operation
    string op_b = operand!"OpB"(words, n_words);
    foreach (s; __traits(allMembers, OpCode)) {
      if (opcode == mixin("OpCode." ~ s)) {
        return s ~ " " ~ op_b ~ " " ~ op_a;
      }
    }
    return ";Unknow OpCode";
  }
}
  
/**
 * Give the string representation of a operand
 * Params:
 *  op        = Operand type ("OpA" o "OpB")
 *  words     = Next words to initial world
 *  n_words   = Add 1 if uses "next word".
 * Returns: A string that contains operand representation
 */
string operand(string op ) (ushort[] words, ref ushort n_words) {
  //assert (words.length >= 3);
  ushort operand = decode!op(words[0]);
  auto writer = appender!string();
  switch (operand) {
      case Operand.A:   // Register x
    return "A";
      case Operand.B:
    return "B";
      case Operand.C:
    return "C";
      case Operand.X:
    return "X";
      case Operand.Y:
    return "Y";
      case Operand.Z:
    return "Z";
      case Operand.I:
    return "I";
      case Operand.J:
    return "J";

      case Operand.Aptr: // Register pointer [x]
    return "[A]";
      case Operand.Bptr:
    return "[B]";
      case Operand.Cptr:
    return "[C]";
      case Operand.Xptr:
    return "[X]";
      case Operand.Yptr:
    return "[Y]";
      case Operand.Zptr:
    return "[Z]";
      case Operand.Iptr:
    return "[I]";
      case Operand.Jptr:
    return "[J]";

      case Operand.Aptr_word: // Register pointer with added word
    n_words++;
    static if (op == "OpB") {
      return format("[A+ 0x%04X]", words[1]);
    } else {
      return format("[A+ 0x%04X]", words[0]);
    }
    
      case Operand.Bptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[B+ 0x%04X]", words[1]);
    } else {
      return format("[B+ 0x%04X]", words[0]);
    }
    //formattedWrite(writer, "[B+ 0x%04X]", ram[++pc]);
    //return writer.data;
    
      case Operand.Cptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[C+ 0x%04X]", words[1]);
    } else {
      return format("[C+ 0x%04X]", words[0]);
    }
    
      case Operand.Xptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[X+ 0x%04X]", words[1]);
    } else {
      return format("[X+ 0x%04X]", words[0]);
    }
    
      case Operand.Yptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[Y+ 0x%04X]", words[1]);
    } else {
      return format("[Y+ 0x%04X]", words[0]);
    }
    
      case Operand.Zptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[Z+ 0x%04X]", words[1]);
    } else {
      return format("[Z+ 0x%04X]", words[0]);
    }
    
      case Operand.Iptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[I+ 0x%04X]", words[1]);
    } else {
      return format("[I+ 0x%04X]", words[0]);
    }
    
      case Operand.Jptr_word:
    n_words++;
    static if (op == "OpB") {
      return format("[J+ 0x%04X]", words[1]);
    } else {
      return format("[J+ 0x%04X]", words[0]);
    }

      case Operand.POP_PUSH: // POP
    static if (op == "OpB") {
      return "PUSH";
    } else {
      return "POP";
    }

      case Operand.PEEK:
    return "PEEK";
    
      case Operand.PICK_word:
    n_words++;
    static if (op == "OpB") {
      return format("[SP+ 0x%04X]", words[1]);
    } else {
      return format("[SP+ 0x%04X]", words[0]);
    }
    
      case Operand.SP: // SP
    return "SP";

      case Operand.PC: // PC
    return "PC";

      case Operand.EX: // Overflow register
    return "EX";

      case Operand.NWord_ptr: // next word pointer
    n_words++;
    static if (op == "OpB") {
      return format("[0x%04X]", words[1]);
    } else {
      return format("[0x%04X]", words[0]);
    }

      case Operand.NWord: // word literal
    n_words++;
    static if (op == "OpB") {
      return format("0x%04X", words[1]);
    } else {
      return format("0x%04X", words[0]);
    }

      default: // literal
    return format("0x%02X", operand - Operand.Literal -1); // -1 to 30

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
    ushort n_words;
    string inst;
    if (pc < ram.length -3) {
      inst= disassamble(ram[pc..pc+4], n_words);
    } else {
      inst= disassamble(ram[pc..$], n_words);
    }

    ushort pos = cast(ushort)(old_pc + offset);
    pc += n_words;
    
    if (comment) { // Add coment  ; [addr] - xxxx ....
      if (labels) {
        ret[pos] = "                " ~ inst;
      } else {
        ret[pos] = inst;
      }

      for(auto i=0; i<(26- inst.length); i++)
        ret[pos] ~= " ";
      auto writer = appender!string();
      ret[pos] ~= ";" ~ format("[%04X] - %04X ", pos, ram[pos]);
      //formattedWrite(writer, "[%04X] - %04X", pos, ram[pos]);
      //ret[pos] ~= ";"~ writer.data;

      for (auto i=pos +1; i <= pc-1; i++) {
        writer = appender!string();
        ret[pos] ~= format("%04X ", ram[i]);
        //formattedWrite(writer, " %04X", ram[i]);
        //ret[pos] ~= writer.data;
      }
    } else {
      ret[pos] = inst;
    }
  }
  return ret;
}
