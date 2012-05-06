/**
 * DCPU-16 CPU
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.cpu;

import std.array;
//import dcpu.constants, dcpu.machine, dcpu.hardware;

/**
 * CPU State
 */
enum CpuState {
  READY,  /// Ready to init to execute the next instruction
  OPA,    /// Waiting to the next clock tick to feth Operator A value
  OPB     /// Waiting to the next clock tick to feth Operator B value
}

/**
 * Extract a particular information from a instruction
 * Params:
 *  what = Type of data to decode from a instruction
           ("OpCode", "ExtOpCode","OpA" or "OpB")
 *  word = Data to decode. A word and his two next words
 * Returns: Extracted data from a instruction
*/
package ubyte decode(string what)(ushort word) pure {
  // Format is aaaaaabbbbbooooo or aaaaaaooooo00000
  static if (what == "OpCode") {
    return word & 0b00000000_00011111;
  } else if (what == "OpB" || what == "ExtOpCode") {
    return (word >> 5) & 0b00000000_00011111;
  } else if (what == "OpA") {
    return (word >> 10) & 0b00000000_00111111;
  }
}

/+
final class DCpu {
  private:
  
  ushort[255] int_queue;    /// Interrupt queue
  bool read_queue;          /// FrontPop interrupt queue ?
  bool f_fire;              /// CPU on fire

  CpuState state;           /// Actual state of CPU
  ushort word;              /// Value of [PC] when begin ready state
  ubyte opcode;             /// OpCode
  ubyte ext_opcode;         /// Extendend Opcode if OpCode == 0
  ubyte opa;                /// Operand A
  ubyte opb;                /// Operand B

  shared Ram ram;           /// Ram of computer
  public:
  
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }

  ushort pc;
  ushort sp;
  ushort ex;
  ushort ia;

  /**
   * Steps one cycle
   */
  void step() {
    if (state == CpuState.READY) { // Feth [PC] and extract operands
      synchronized (ram) {
        word = ram.ram[pc];
      }
      
      opcode = decode!"OpCode"(word);
      opa = decode!"OpA"(word);
      opb = decode!"OpB"(word);

      switch (op_a) {
        case Operand.A: // General Registers
        case Operand.B:
        case Operand.C:
        case Operand.X:
        case Operand.Y:
        case Operand.Z:
        case Operand.I:
        case Operand.J:
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
          break;

        case Operand.POP_PUSH: // Pop [SP++]
          break;

        case Operand.PEEK: // [SP]
          break;

        case Operand.SP: // SP
          break;

        case Operand.PC: // PC
          break;
        
        case Operand.EX: // EXcess
          break;

        case Operand.Aptr_word:
        case Operand.Bptr_word:
        case Operand.Cptr_word:
        case Operand.Xptr_word:
        case Operand.Yptr_word:
        case Operand.Zptr_word:
        case Operand.Iptr_word:
        case Operand.Jptr_word:
        case Operand.PICK_word:
        case Operand.NWord_ptr:
        case Operand.NWord:
          state = CpuState.OPA; // Wait to the next cycle
          return;
      }

      if (opcode == 0) {
        ext_opcode = decode!"ExtOpCode"(word);

        // TODO Execute Extended OpCode
        return;
      }

      switch (op_b) {
        case Operand.A: // General Registers
        case Operand.B:
        case Operand.C:
        case Operand.X:
        case Operand.Y:
        case Operand.Z:
        case Operand.I:
        case Operand.J:
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
          break;

        case Operand.POP_PUSH: // Pop [SP++]
          break;

        case Operand.PEEK: // [SP]
          break;

        case Operand.SP: // SP
          break;

        case Operand.PC: // PC
          break;

        case Operand.EX: // EXcess
          break;

        case Operand.Aptr_word:
        case Operand.Bptr_word:
        case Operand.Cptr_word:
        case Operand.Xptr_word:
        case Operand.Yptr_word:
        case Operand.Zptr_word:
        case Operand.Iptr_word:
        case Operand.Jptr_word:
        case Operand.PICK_word:
        case Operand.NWord_ptr:
        case Operand.NWord:
          state = CpuState.OPB; // Wait to the next cycle
          return;
      }

      // TODO Execute Operantion
      return;

    } else if (state == CpuState.OPA) { 
      // TODO
    } else {
      // TODO
    }
  }

  /**
   * Send to the CPU a hardware interrupt
   */
  void hardware_int(ushort msg) {
    if (ia != 0) {
      
    }
  }

  
}+/