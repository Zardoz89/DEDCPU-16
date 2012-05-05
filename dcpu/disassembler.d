/**
 * DCPU-16 cpu disassembler
 */
module dcpu.disassembler;

import std.stdio, std.array, std.string, std.conv, std.getopt;
// import std.format;
import dcpu.constants;

public import std.typecons;

private:
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
 * Give the string representation of a operand
 * Params:
 *  op        = Operand type ("OpA" o "OpB")
 *  words     = First instruction word and the word that could contain the "next word" value
 *  n_words   = Add 1 if uses "next word".
 * Returns: A string that contains operand representation
 */
string operand(string op ) (ushort[] words, ref ushort n_words)
in {
  assert(words.length >= 2, "Need first word of instruction and the word that could contain the \"next word\" value");
} body{
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
    return format("[A+ 0x%04X]", words[1]);
    
      case Operand.Bptr_word:
    n_words++;
    return format("[B+ 0x%04X]", words[1]);

      case Operand.Cptr_word:
    n_words++;
    return format("[C+ 0x%04X]", words[1]);

    
      case Operand.Xptr_word:
    n_words++;
    return format("[X+ 0x%04X]", words[1]);

    
      case Operand.Yptr_word:
    n_words++;
    return format("[Y+ 0x%04X]", words[1]);

    
      case Operand.Zptr_word:
    n_words++;
    return format("[Z+ 0x%04X]", words[1]);
    
      case Operand.Iptr_word:
    n_words++;
    return format("[I+ 0x%04X]", words[1]);

    
      case Operand.Jptr_word:
    n_words++;
    return format("[J+ 0x%04X]", words[1]);


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
    return format("[SP+ 0x%04X]", words[1]);

    
      case Operand.SP: // SP
    return "SP";

      case Operand.PC: // PC
    return "PC";

      case Operand.EX: // Overflow register
    return "EX";

      case Operand.NWord_ptr: // next word pointer
    n_words++;
    return format("[0x%04X]", words[1]);

      case Operand.NWord: // word literal
    n_words++;
    return format("0x%04X", words[1]);

      default: // literal
    return format("%d", operand - Operand.Literal -1); // -1 to 30
  }
}
  
public:

/**
 * Diassamble ONE instruction
 * Params:
 *  words    = Instruction to disassemble (A word and his two next words)
 *  n_words  = Size of disassambled instruction
 * Returns: A string that contains a diassambled code
 */
string disassamble(ushort[] words, out ushort n_words)
in {
  assert(words.length >= 3, "Instructions can ben 3 words long");
}body {
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
    return format("DAT 0x%04X", words[0]);//";Unknow Extended OpCode";

  } else { // Decode operation
    ushort[] tmp;
    tmp ~= words[0];
    tmp ~= words[n_words];
    string op_b = operand!"OpB"(tmp, n_words);
    foreach (s; __traits(allMembers, OpCode)) {
      if (opcode == mixin("OpCode." ~ s)) {
        return s ~ " " ~ op_b ~ ", " ~ op_a;
      }
    }
    return format("DAT 0x%04X", words[0]);//";Unknow Extended OpCode";
  }
}

/**
 * Diassamble a slice of binary data
 * Params:
 *  data    = Slice of DCPU-16 binary data
 *  comment = Add comments to assembly code with the addre and hex machine code
 *  labels  = auto tab and add labels to jumps
 *  offset  = add a offset to addresses of each instruction
 * Returns a asociative array where the key is a pair of addreses that contains
 * the instruction in machine code
 */
string[ushort] range_diassamble(in ushort[]data, bool comment = false, bool labels = false, ushort offset = 0)
in {
  assert(data.length > 0, "Can't disassamble empty data");
} body {
  ushort[] slice;
  if (slice.length > ushort.max) { // Chop to maximun data addresable
    slice = data[0..ushort.max+1].dup;
  } else {
    slice = data.dup;
  }

  string[ushort] ret;
  ushort n_words = 1;
  for(ushort pos=0; pos < slice.length; pos+=n_words) {
    ushort word = slice[pos];
    string inst;

    if (pos < slice.length -3 && slice.length >= 3) {
      inst= disassamble(slice[pos..pos+3], n_words); // Disamble one instruction and jump pos to the next instruction
    } else {
      ushort[] tmp = slice[pos..$] ~ cast(ushort[])[0, 0];
      inst= disassamble(tmp, n_words);
    }

    if (labels) { // Appends a 15 wide space
      ret[cast(ushort)(pos + offset)] = "                " ~ inst;
    } else {
      ret[cast(ushort)(pos + offset)] = inst;
    }
    
    if (comment) { // Add coment  like ; [addr] - xxxx ....
      for(auto i=0; i<(26- inst.length); i++)
        ret[cast(ushort)(pos + offset)] ~= " ";
      ret[cast(ushort)(pos + offset)] ~= ";" ~ format("[%04X] - %04X ", pos + offset, slice[pos]);

      for (auto i=pos +1; i < pos + n_words && i < slice.length; i++) {
        ret[cast(ushort)(pos + offset)] ~= format("%04X ", slice[i]);
      }
    }
  }

  if (labels) {
    foreach (key, ref line ;ret) {
      if (line.length >= 26 && line[16..26] == "SET PC, 0x" ) {
        ushort jmp = parse!ushort(line[26..$], 16);
        if (jmp in ret) {
          if (comment) {
            line = line[0..24] ~ format(" lb%04X ", jmp) ~ line[32..$];
          } else {
            line = line[0..24] ~ format(" lb%04X ", jmp);
          }
          ret[jmp] = format(":lb%04X ", jmp) ~ ret[jmp][8..$];
        }
      }
    }
  }
  
  return ret;
}