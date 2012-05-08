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
  OPB,    /// Waiting to the next clock tick to feth Operator B value
  EXECUTE /// Execute the OpCode
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

  // Stores state between clock cycles
  CpuState state;           /// Actual state of CPU
  ushort word;              /// Value of [PC] when begin ready state
  ubyte opcode;             /// OpCode
  ubyte ext_opcode;         /// Extendend Opcode if OpCode == 0
  ubyte opa;                /// Operand A
  ubyte opb;                /// Operand B
  ushort val_a;             /// Value of operand A
  ushort val_b;             /// Value of operand B
  int cycles;               /// Cycles to do in execute

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
          val_a = registers[op_a];
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
          synchronized (ram) {
            val_a = ram.ram[registers[op_a- Operand.Aptr]];
          }
          break;

        case Operand.POP_PUSH: // Pop [SP++]
          synchronized (ram) {
            val_a = ram.ram[sp++];
          }
          break;

        case Operand.PEEK: // [SP]
          synchronized (ram) {
            val_a = ram.ram[sp];
          }
          break;

        case Operand.SP: // SP
          val_a = sp;
          break;

        case Operand.PC: // PC
          val_a = pc;
          break;
        
        case Operand.EX: // EXcess
          val_a = ex;
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

        default: // Literal
          val_a = op_a - Operand.Literal -1;
      }

      if (opcode == 0) {
        ext_opcode = decode!"ExtOpCode"(word);
        state = CpuState.EXECUTE;
        cycles = -1; // It will be calculated in Execute mode
        step(); // Jump to Execute state 
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
          val_b = registers[op_b];
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
          synchronized (ram) {
            val_b = ram.ram[registers[op_b- Operand.Aptr]];
          }
          break;

        case Operand.POP_PUSH: // Push [--SP]
          synchronized (ram) {
            val_b = ram.ram[--sp];
          }
          break;

        case Operand.PEEK: // [SP]
          synchronized (ram) {
            val_b = ram.ram[sp];
          }
          break;

        case Operand.SP: // SP
          val_b = sp;
          break;

        case Operand.PC: // PC
          val_b = pc;
          break;
        
        case Operand.EX: // EXcess
          val_b = ex;
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
        default:    
          assert(false, "This code should never executed");
      }

      // Execute Operantion
      state = CpuState.EXECUTE;
      cycles = -1; // It will be calculated in Execute mode
      step(); // Jump to Execute state 
      return;

    } else if (state == CpuState.OPA) { // Get ram[pc]
      pc++;
      // TODO
      // Test opb to do EXECUTE or OPB
    } else if (state == CpuState.OPB) { // Get ram[pc]
      pc++;
      // TODO
      state == CpuState.EXECUTE;
      cycles = -1;
      step();
    } else { // Execute
      // TODO
      pc++:
      state = CpuState.READY;
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