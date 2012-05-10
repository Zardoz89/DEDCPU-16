/**
 * DCPU-16 CPU
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.cpu;

import std.array;
import dcpu.microcode, dcpu.machine, dcpu.hardware;

/**
 * CPU State
 */
enum CpuState {
  DECO,     /// Decoding an instrucction
  OPA,      /// Get Operator A value
  OPB,      /// Get Operator B value
  EXECUTE   /// Execute the OpCode
}




final class DCpu {
  private:
  Machine machine;          /// Self-reference to the machine
  
  ushort[255] int_queue;    /// Interrupt queue
  bool read_queue = true;   /// FrontPop interrupt queue ?
  bool f_fire;              /// CPU on fire
  bool skip;                /// Skip next instrucction

  // Stores state between clock cycles
  CpuState state;           /// Actual state of CPU
  ushort word;              /// Value of [PC] when begin ready state
  
  ubyte opcode;             /// OpCode
  ubyte ext_opcode;         /// Extendend Opcode if OpCode == 0

  bool do_inmediate = true; /// Do an inmediate operand or next word operand
  ubyte opa;                /// Operand A
  ubyte opb;                /// Operand B
  
  ushort val_a;             /// Value of operand A
  ushort val_b;             /// Value of operand B
  ushort val;               /// Result of an operation
  bool write_val;           /// Must write val to a register or ram
  
  int cycles;               /// Cycles to do in execute

  //shared Ram ram;           /// Ram of computer
  public:
  bool wait_hwd;            /// Need to wait a hardware device?
  
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;
  }

  ushort pc;
  ushort sp;
  ushort ex;
  ushort ia;

  this(ref Machine machine) {
    this.machine = machine;
  }

  /**
   * Steps one cycle
   */
  void step() {
    if (state == CpuState.DECO) { // Feth [PC] and extract operands and opcodes
      synchronized (machine.ram) {
        word = machine.ram.ram[pc];
      }
      
      opcode = decode!"OpCode"(word);
      opa = decode!"OpA"(word);
      opb = decode!"OpB"(word);
      ext_opcode = decode!"ExtOpCode"(word);
      /*mixin(inmediate_opval!"OpA"());
      
      if (opcode == 0) {
        ext_opcode = decode!"ExtOpCode"(word);
        state = CpuState.EXECUTE;
        cycles = -1;  // It will be calculated in Execute mode
        step();       // Jump to Execute state 
        return;
      }

      mixin(inmediate_opval!"OpB"());

      // Execute Operation
      state = CpuState.EXECUTE;
      cycles = -1;  // It will be calculated in Execute mode
      step();       // Jump to Execute state 
      return;*/

      state = CpuState.OPA;
      step(); // Jump to OPA to try to get a not "next word" operand

    } else if (state == CpuState.OPA) { // Get Operand A
      if (do_inmediate) {
        do_inmediate = false;
        mixin(inmediate_opval!"OpA"());
        // If not is a inmediate, the mixin will do return; keeping the flag to false
        // So the next cycle will get the next word operand
        do_inmediate = true;
      } else {
        pc++;
        mixin(nextword_opval!"OpA");
        do_inmediate = true;
      }

      if (opcode == 0) {
        state = CpuState.EXECUTE;
        cycles = -1;  // Say to Execute to calc it
        step();       // Jump to Execute state
      } else {
        state = CpuState.OPB;
        step(); // Jump to OPB to try to get a not "next word" operand
      }
      /*pc++;
      mixin(nextword_opval!"OpA");
      mixin(inmediate_opval!"OpB");
      
      // Execute Operantion
      state = CpuState.EXECUTE;
      cycles = -1;  // It will be calculated in Execute mode
      step();       // Jump to Execute state
      return;*/
      
    } else if (state == CpuState.OPB) { // Get Operand B
      if (do_inmediate) {
        do_inmediate = false;
        mixin(inmediate_opval!"OpB"());
        // If not is a inmediate, the mixin will do return; keeping the flag to false
        do_inmediate = true;
      } else {
        pc++;
        mixin(nextword_opval!"OpB");
        do_inmediate = true;
      }
      
      state = CpuState.EXECUTE;
      cycles = -1;  // It will be calculated in Execute mode
      step();       // Jump to Execute state
      
    } else { // Execute the OpCode
      execute_op(); // I will increase pc when the last cycle is made
    }
    
  }

  /**
   * Send to the CPU a hardware interrupt
   */
  void hardware_int(ushort msg) {
    if (ia != 0) {
      
    }
  }

private:

  /**
   * Execute a OpCode
   */
  void execute_op() {
    bool new_skip;   // New value of skip
    
    if (opcode != 0 && cycles < 0) { // Execute Not extended opcode
      if (!skip) {
        write_val = true;
        switch (opcode) {
          case OpCode.SET:
            val = val_a;
            cycles = 1;
            break;

          case OpCode.ADD:
            uint tmp = val_b + val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = tmp > 0xFFFF; // Overflow
            cycles = 2;
            break;

          case OpCode.SUB:
            ushort neg_a = !val_a +1; // Comp 2 negation of val_a
            uint tmp = val_b + neg_a;
            val = cast(ushort)(tmp & 0xFFFF);
            if ( val & 0x800 ) { // val < 0
              ex = 0xFFFF; // Underflow
            } else {
              ex = 0;
            }
            cycles = 2;
            break;

          case OpCode.MUL:
            uint tmp = val_b * val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp >> 16);
            cycles = 2;
            break;

          case OpCode.MLI: // Mul with sign
            int tmp = cast(short)val_b * cast(short)val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp >> 16);
            cycles = 2;
            break;

          case OpCode.DIV:
            if (val_a == 0) {
              val = 0;
            } else {
            uint tmp = val_b / val_a;
            uint tmp2 = (val_b << 16) / val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp2 & 0xFFFF);
            }
            cycles = 3;
            break;

          case OpCode.DVI: // Div with sign
            if (val_a == 0) {
              val = 0;
            } else {
            int tmp = cast(short)val_b / cast(short)val_a;
            int tmp2 = (cast(short)val_b << 16) / cast(short)val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp2 & 0xFFFF);
            }
            cycles = 3;
            break;

          case OpCode.MOD:
            if (val_a == 0) {
              val = 0;
            } else {
              val = val_b % val_a;
            }
            cycles = 3;
            break;

          case OpCode.MDI: // Mod with sign
            if (val_a == 0) {
              val = 0;
            } else {
              val = cast(short)val_b % cast(short)val_a;
            }
            cycles = 3;
            break;

          case OpCode.AND:
            val = val_b & val_a;
            cycles = 1;
            break;

          case OpCode.BOR:
            val = val_b | val_a;
            cycles = 1;
            break;

          case OpCode.XOR:
            val = val_b ^ val_a;
            cycles = 1;
            break;

          case OpCode.SHR: // Logical Shift
            uint tmp = val_b >>> val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex  = cast(ushort)(tmp << 16);
            cycles = 1;
            break;

          case OpCode.ASR: // Arthmetic shift
            uint tmp = val_b >> val_a;
            val = cast(ushort)(tmp & 0xFFFF);
            ex  = cast(ushort)(tmp << 16);
            cycles = 1;
            break;

          case OpCode.SHL:
            uint tmp = val_b >>> (16 - val_a);
            val = cast(ushort)(tmp << 16);
            ex  = cast(ushort)(tmp & 0xFFFF);
            cycles = 1;
            break;

          case OpCode.IFB:
            cycles = 2;
            write_val = false;
            new_skip = ((val_b & val_a) != 0); // Skip next instrucction
            break;

          case OpCode.IFC:
            cycles = 2;
            write_val = false;
            new_skip = ((val_b & val_a) == 0);
            break;

          case OpCode.IFE:
            new_skip = (val_b == val_a);
            write_val = false;
            cycles = 2;
            break;

          case OpCode.IFN:
            cycles = 2;
            write_val = false;
            new_skip = (val_b != val_a);
            break;

          case OpCode.IFG:
            cycles = 2;
            write_val = false;
            new_skip = (val_b > val_a);
            break;

          case OpCode.IFA:
            cycles = 2;
            write_val = false;
            new_skip = (cast(short)val_b > cast(short)val_a);
            break;

          case OpCode.IFL:
            cycles = 2;
            write_val = false;
            new_skip = (val_b < val_a);
            break;

          case OpCode.IFU:
            cycles = 2;
            write_val = false;
            new_skip = (cast(short)val_b < cast(short)val_a);
            break;

          case OpCode.ADX:
            uint tmp = val_b + val_a + ex;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = tmp > 0xFFFF; // Overflow
            cycles = 3;
            break;

          case OpCode.SBX:
            ushort neg_a = !val_a +1; // Comp 2 negation of val_a
            uint tmp = val_b + neg_a + ex;
            val = cast(ushort)(tmp & 0xFFFF);
            if ( val & 0x800 ) { // val < 0
              ex = 0xFFFF; // Underflow
            } else {
              ex = 0;
            }
            cycles = 3;
            break;

          case OpCode.STI:
            val = val_a;
            i++;
            j++;
            cycles = 2;
            break;

          case OpCode.STD:
            val = val_a;
            i--;
            j--;
            cycles = 2;
            break;

          default: // Unknow OpCode
            // Do Nothing (I should do a random OpCode ?)
            write_val = false;
            cycles = 1;
        }
        
      } else { // Skip next basic OpCode instrucction
        cycles = 1;
        write_val = false;
        switch (opcode) { // Skipe chained branchs
          case OpCode.IFB:
          case OpCode.IFC:
          case OpCode.IFE:
          case OpCode.IFN:
          case OpCode.IFG:
          case OpCode.IFA:
          case OpCode.IFL:
          case OpCode.IFU:
            new_skip = true;
            break;
            
          default:
            new_skip = false;
        }
      }
      return;
    } else if (cycles < 0) { // Extended OpCode
      write_val = false;
      if (!skipe) {
        switch (ext_opcode) {
          case ExtOpCode.JSR:
            synchronized (machine.ram) {
              machine.ram.ram[--sp] = cast(ushort)(pc +1);
            }
            pc = val_a;
            cycles = 3;
            break;

          case ExtOpCode.INT: // TODO Interrupcion software
            cycles = 4;
            break;

          case ExtOpCode.IAG:
            write_val = true;
            val = ia;
            cycles = 1;
            break;

          case ExtOpCode.IAS:
            ia = val_a;
            cycles = 1;
            break;

          case ExtOpCode.RFI:
            read_queue = true;
            synchronized (machine.ram) {
              a  = machine.ram.ram[sp++];
              pc = machine.ram.ram[sp++];
            }
            cycles = 3;
            break;

          case ExtOpCode.IAQ:
            read_queue = val_a == 0; // if val_a != 0 Not read the interrupt queue
            cycles = 2;
            break;

          case ExtOpCode.HWN: // TODO
            cycles = 2;
            break;

          case ExtOpCode.HWQ: // TODO
            cycles = 4;
            break;

          case ExtOpCode.HWI: // TODO
            cycles = 4; // Or more
            break;

          default: // Unknow OpCode
            // Do Nothing (I should do a random OpCode ?)
            cycles = 1;
        }
      } else {
        cycles = 1;
        new_skip = false;
      }

    }

    if (wait_hwd) // Some hardware when receive a HWI can make to wait more cycles
      cycles--;
      
    if (cycles == 0) { // Only increment PC and set Ready when cycle count == 0
      if (skip) {
        skip = new_skip;
      } else {
        
        if (opcode != 0 && write_val) { // Basic OpCode
          // OpB <= OpA Operation OpA = val
          // TODO
        } else if (write_val) {         // Extended OpCode
          // OpA <= val
          // TODO
        }
      }
      state = CpuState.DECO;
      pc++;
    }
    
  }
}

/**
   * Meta function that try to get OP value or wait for the next cycle
   * Call it with mixin
   * Params:
   *  opt   = OpA or OpB operator
   * Returns: A string representation of the code to be generated/executed
   */
  string inmediate_opval(string opt)() {
  static assert (opt == "OpA" || opt == "OpB", "Invalid operator");
    static if (opt == "OpA") {
      string val = "val_a";
      string op = "opa";
    } else {
      string val = "val_b";
      string op = "opb";
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
        if (!skip)
        synchronized (machine.ram) {
          "~val~r" = machine.ram.ram[registers["~op~r"- Operand.Aptr]];
        }
        break;

      case Operand.POP_PUSH: // Pop [SP++]
        if (!skip)
        synchronized (machine.ram) {
          "~val~r" = machine.ram.ram[sp++];
        }
        break;

      case Operand.PEEK: // [SP]
        if (!skip)
        synchronized (machine.ram) {
          "~val~r" = machine.ram.ram[sp];
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
      static if (opt == "op_a") {
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
   *  opt   = OpA or OpB operator
   * Returns: A string representation of the code to be generated/executed
   */
  string nextword_opval(string opt)() {
  static assert (opt == "OpA" || opt == "OpB", "Invalid operator");
    static if (opt == "OpA") {
      string val = "val_a";
      string op = "opa";
    } else {
      string val = "val_b";
      string op = "opb";
    }
    string r = r"
  if (!skip)
    switch ("~op~r") {
      case Operand.Aptr_word: // Reg. pointer + next word literal
      case Operand.Bptr_word:
      case Operand.Cptr_word:
      case Operand.Xptr_word:
      case Operand.Yptr_word:
      case Operand.Zptr_word:
      case Operand.Iptr_word:
      case Operand.Jptr_word:
        synchronized (machine.ram) {
          "~val~r" = machine.ram.ram[registers["~op~r"- Operand.Aptr_word] + machine.ram.ram[pc] ];
        }
        break;

      case Operand.PICK_word: // [SP + next word literal]
        synchronized (machine.ram) {
          "~val~r" = machine.ram.ram[sp + machine.ram.ram[pc]];
        }
        break;

      case Operand.NWord_ptr: // Ptr [next word literal ]
        synchronized (machine.ram) {
          "~val~r" = machine.ram.ram[machine.ram.ram[pc]];
        }
        break;

      case Operand.NWord: // next word literal
        synchronized (machine.ram) {
          "~val~` = machine.ram.ram[pc];
        }
        break;

      default:
        assert(false, "This code never should be executed. Get Operator value from next word, was called");
      }`;

    return r;
  }

/+
void main () {
  import std.stdio;
  writeln(nextword_opval!"OpA"());
}+/