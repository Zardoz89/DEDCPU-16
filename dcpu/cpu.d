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

  //shared Ram ram;           /// Ram of computer
  public:
  
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }

  ushort pc;
  ushort sp;
  ushort ex;
  ushort ia;/+

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

      mixin(inmediate_opval!"OpA");

      if (opcode == 0) {
        ext_opcode = decode!"ExtOpCode"(word);
        state = CpuState.EXECUTE;
        cycles = -1;  // It will be calculated in Execute mode
        step();       // Jump to Execute state 
        return;
      }

      mixin(inmediate_opval!"OpB");

      // Execute Operantion
      state = CpuState.EXECUTE;
      cycles = -1;  // It will be calculated in Execute mode
      step();       // Jump to Execute state 
      return;

    } else if (state == CpuState.OPA) { // Get ram[pc]
      pc++;
      
      mixin(nextword_opval!"OpA");
      
      mixin(inmediate_opval!"OpB");
      
      // Execute Operantion
      state = CpuState.EXECUTE;
      cycles = -1;  // It will be calculated in Execute mode
      step();       // Jump to Execute state
      return;
      
    } else if (state == CpuState.OPB) { // Get ram[pc]
      pc++;
      
      mixin(nextword_opval!"OpB");
      
      state = CpuState.EXECUTE;
      cycles = -1;  // It will be calculated in Execute mode
      step();       // Jump to Execute state
      return;
      
    } else { // Execute
      execute_op(); // I will increase pc when the last cycle is made
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
+/

private:

  /**
   * Meta function that try to get OP value or wait for the next cycle
   * Call it with mixin
   * Params:
   *  op    = OpA or OpB operator
   * Returns: A string representation of the code to be generated/executed
   */
  string inmediate_opval(string op)() {
  static assert (op == "OpA" || op == "Opb", "Invalid operator");
    static if (op == "OpA") {
      string val = "val_a";
      op = "op_a";
    } else {
      string val = "val_b";
      op = "op_b";
    }
    string r = r"
    switch ("~op~r") {
      case Operand.A: // General Registers
      case Operand.B:
      case Operand.C:
      case Operand.X:
      case Operand.Y:
      case Operand.Z:
      case Operand.I:
      case Operand.J:
        "~val~r" = registers["~op~r"];
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
          "~val~r" = ram.ram[registers["~op~r"- Operand.Aptr]];
        }
        break;

      case Operand.POP_PUSH: // Pop [SP++]
        synchronized (ram) {
          "~val~r" = ram.ram[sp++];
        }
        break;

      case Operand.PEEK: // [SP]
        synchronized (ram) {
          "~val~r" = ram.ram[sp];
        }
        break;

      case Operand.SP: // SP
        "~val~r" = sp;
        break;

      case Operand.PC: // PC
        "~val~r" = pc;
        break;

      case Operand.EX: // EXcess
        "~val~r" = ex;
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
      ";
      static if (op == "op_a") {
        r ~= r"
        state = CpuState.OPA; // Wait to the next cycle
        return;

      default: // Literal      
         val_a = op_a - Operand.Literal -1;
         }";
      } else {
        r ~= `
        state = CpuState.OPB; // Wait to the next cycle
        return;

      default:
      assert(false, "This code never should be executed. Operator B can't have literals");
      }`;
      }
    
    return r;
  }

   /**
   * Meta function that get OP value from the next word (PC was increased previusly)
   * Call it with mixin
   * Params:
   *  op    = OpA or OpB operator
   * Returns: A string representation of the code to be generated/executed
   */
  string nextword_opval(string op)() {
  static assert (op == "OpA" || op == "Opb", "Invalid operator");
    static if (op == "OpA") {
      string val = "val_a";
      op = "op_a";
    } else {
      string val = "val_b";
      op = "op_b";
    }
    string r = r"
    switch ("~op~r") {
      case Operand.Aptr_word: // Reg. pointer + next word literal
      case Operand.Bptr_word:
      case Operand.Cptr_word:
      case Operand.Xptr_word:
      case Operand.Yptr_word:
      case Operand.Zptr_word:
      case Operand.Iptr_word:
      case Operand.Jptr_word:
        synchronized (ram) {
          "~val~r" = ram.ram[registers["~op~r"- Operand.Aptr_word] + ram.ram[pc] ];
        }
        break;
        
      case Operand.PICK_word: // [SP + next word literal]
        synchronized (ram) {
          "~val~r" = ram.ram[sp + ram.ram[pc]];
        }
        break
        
      case Operand.NWord_ptr: // Ptr [next word literal ]
        synchronized (ram) {
          "~val~r" = ram.ram[ram.ram[pc]];
        }
        break
        
      case Operand.NWord: // next word literal
        synchronized (ram) {
          "~val~` = ram.ram[pc];
        }
        break

      default:
        assert(false, "This code never should be executed. Get Operator value from next word, was called");
      }`;
      
    return r;
  }
/+
  /**
   * Execute a OpCode
   */
  void execute_op() {
    ushort val; 
    
    if (opcode != 0) { // Not extended opcode
      switch (opcode) {
        case OpCode.SET:
          val = val_a;
          break;

        case OpCode.ADD:
          uint tmp = val_b + val_a;
          val = cast(ushort)(tmp & 0xFFFF);
          ex = tmp > 0xFFFF; // Overflow
          break;

        case OpCode.SUB:
          ushort neg_a = !val_a +1; // Comp 2 negation of val_a
          uint tmp = val_b + neg_a;
          val = cast(ushort)(tmp & 0xFFFF);
          if ( (val_a & 0x8000) > 0 && (val_b & 0x8000) > 0 && (tmp & 0x8000) != 0 ) {
            ex = 0xFFFF; // Underflow
          } else {
            ex = 0;
          }
          break;

        case OpCode.MUL:
          uint tmp = val_b * val_a;
          val = cast(ushort)(tmp & 0xFFFF);
          ex = cast(ushort)(tmp >> 16);
          break;
          
        case OpCode.MLI: // Mul with sign
          int tmp = cast(short)val_b * cast(short)val_a;
          val = cast(ushort)(tmp & 0xFFFF);
          ex = cast(ushort)(tmp >> 16);
          break;

        case OpCode.DIV:
          if (val_a == 0) {
            val = 0;
          } else {
          uint tmp = val_b / val_a;
          uint tmp2 = (val_b << 16) / val_a
          val = cast(ushort)(tmp & 0xFFFF);
          ex = cast(ushort)(tmp2 & 0xFFFF);
          }
          break;

        case OpCode.DVI: // Div with sign
          if (val_a == 0) {
            val = 0;
          } else {
          int tmp = cast(short)val_b / cast(short)val_a;
          int tmp2 = (cast(short)val_b << 16) / cast(short)val_a
          val = cast(ushort)(tmp & 0xFFFF);
          ex = cast(ushort)(tmp2 & 0xFFFF);
          }
          break;

        case OpCode.MOD:
          if (val_a == 0) {
            val = 0;
          } else {
            val = val_b % val_a;
          }
          break;

        case OpCode.MDI: // Mod with sign
          if (val_a == 0) {
            val = 0;
          } else {
            val = cast(short)val_b % cast(short)val_a;
          }
          break;

        case OpCode.AND:
          val = val_b & val_a;
          break;

        case OpCode.BOR:
          val = val_b | val_a;
          break;

        case OpCode.XOR:
          val = val_b ^ val_a;
          break;

        case OpCode.SHR:
          val = val_b & val_a;
          break;
      }
    }

  }+/
}