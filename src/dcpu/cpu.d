/**
 * DCPU-16 CPU
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.cpu;

import std.array, std.conv, std.stdio;
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
  
  /**
   * Operator
   * Params:
   *  opt = Type of operator (OpA or OpB)
   */
  class Operator(string opt) {
    static assert (opt == "OpA" || opt == "OpB", "Invalid operator");

  private:
    ushort val;     // Value read
    ushort op;      // Operand Type
    ushort ptr;     // Where are pointing the pointer
    bool _next_word; // Uses the next word and so need a extra cycle

  public:
    this(ubyte op) {
      this.op = op;
      switch (op) {           // Need to read the next word ?
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
          _next_word = true;
          break;
        default:
          _next_word = false;
      }

      if (!skip)
      switch (op) {         // Read it
        case Operand.A:     // General Registers
        case Operand.B:
        case Operand.C:
        case Operand.X:
        case Operand.Y:
        case Operand.Z:
        case Operand.I:
        case Operand.J:
          val = registers[op];
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
          ptr = registers[op- Operand.Aptr];
          synchronized (machine) {
            val = machine.ram[ptr];
          }
          break;

        case Operand.Aptr_word: // [Reg + next word litreal]
        case Operand.Bptr_word:
        case Operand.Cptr_word:
        case Operand.Xptr_word:
        case Operand.Yptr_word:
        case Operand.Zptr_word:
        case Operand.Iptr_word:
        case Operand.Jptr_word:
          synchronized (machine) {
            ptr = cast(ushort)(registers[op- Operand.Aptr_word] + machine.ram[pc +1]);
            val = machine.ram[ptr];
          }
          break;

        case Operand.POP_PUSH: // a Pop [SP++] | b PUSH [--SP]
          static if (opt == "OpA") {
            synchronized (machine) { // To read the value
              val =  machine.ram[sp++];
            }
          } else { // TODO Need confirmation if this is correct
            synchronized (machine) {
              val =  machine.ram[sp-1];
            }
          }
          break;

        case Operand.PEEK: // [SP]
          synchronized (machine) {
            ptr = sp;
            val =  machine.ram[sp];
          }
          break;

        case Operand.PICK_word: // [SP + next word litreal]
          synchronized (machine) {
            ptr = cast(ushort)(sp + machine.ram[pc +1]);
            val = machine.ram[ptr];
          }
          break;

        case Operand.SP: // SP
          val = sp;
          break;

        case Operand.PC: // PC
          val = pc;
          break;

        case Operand.EX: // EXcess
          val = ex;
          break;

        case Operand.NWord_ptr: // Ptr [next word literal ]
          synchronized (machine) {
            ptr = machine.ram[pc +1];
            val = machine.ram[ptr];
          }
          break;

        case Operand.NWord: // next word literal
          synchronized (machine) {
            ptr = cast(ushort)(pc +1);
            val = machine.ram[ptr];
          }
          break;

        default: // Literal
          static if (opt == "OpA") {
            val = op - Operand.Literal -1;
          } else {
            assert(false, "This code never should be executed. Operator B can't have literals");
          }
      }
    }

    /**
     * Uses next word, so need to increase PC value ?
     */
    @property bool next_word()  {
      return _next_word;
    }
    /**
     * Returns: Value of the operator
     */
    ushort read () @property {
      return val;
    }

    /**
     * Writes the new value to his place
     */
    void write(ushort v) @property {
      if (!skip)
      switch (op) {         // Read it
        case Operand.A:     // General Registers
        case Operand.B:
        case Operand.C:
        case Operand.X:
        case Operand.Y:
        case Operand.Z:
        case Operand.I:
        case Operand.J:
          registers[op] = v;
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
        case Operand.Aptr_word: // [Reg + next word litreal]
        case Operand.Bptr_word:
        case Operand.Cptr_word:
        case Operand.Xptr_word:
        case Operand.Yptr_word:
        case Operand.Zptr_word:
        case Operand.Iptr_word:
        case Operand.Jptr_word:
        case Operand.PEEK: // [SP]
        case Operand.PICK_word: // [SP + next word litreal]
          synchronized (machine) {
            machine.ram[ptr] = v;
          }
          break;

        case Operand.POP_PUSH: // a Pop [SP++] | b PUSH [--SP]
          static if (opt == "OpB") {
            synchronized (machine) { // To read the value
              machine.ram[--sp] = v;
            }
            break;
          } else {
            assert (false, "This code must never executed. OpA PUSH can be writted");
          }
          

        case Operand.SP: // SP
          sp = v;
          break;

        case Operand.PC: // PC
          pc = v;
          break;

        case Operand.EX: // EXcess
          ex = v;
          break;

        default: // Literal and Next_Word literal or pointer
          assert(false, "This code never should be executed. Literasl can be writed");
      }
    }

  }
  
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
  
  Operator!"OpA" val_a;     /// Value of operand A
  Operator!"OpB" val_b;     /// Value of operand B
  ushort val;               /// Result of an operation
  bool write_val;           /// Must write val to a register or ram
  
  int cycles;               /// Cycles to do in execute

  
  
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
    writeln(to!string(state));
    if (state == CpuState.DECO) { // Feth [PC] and extract operands and opcodes
      synchronized (machine) {
        word = machine.ram[pc];
      }
      
      opcode = decode!"OpCode"(word);
      opa = decode!"OpA"(word);
      opb = decode!"OpB"(word);
      ext_opcode = decode!"ExtOpCode"(word);

      state = CpuState.OPA;
      step(); // Jump to OPA to try to get a not "next word" operand

    } else if (state == CpuState.OPA) { // Get Operand A
      if (do_inmediate) {
        val_a = new Operator!"OpA"(opa);
        if (val_a.next_word) { // Take a extra cycle
          do_inmediate = false;
          return;
        }
      } else {
        do_inmediate = true;
        pc++;
      }

      if (opcode == 0) {
        state = CpuState.EXECUTE;
        cycles = -1;  // Say to Execute to calc it
        step();       // Jump to Execute state
      } else {
        state = CpuState.OPB;
        step(); // Jump to OPB to try to get a not "next word" operand
      }
      
    } else if (state == CpuState.OPB) { // Get Operand B
      if (do_inmediate) {
        val_b = new Operator!"OpB"(opb);
        if (val_b.next_word) { // Take a extra cycle
          do_inmediate = false;
          return;
        }
      } else {
        do_inmediate = true;
        pc++;
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
            val = val_a.read;
            cycles = 1;
            break;

          case OpCode.ADD:
            uint tmp = val_b.read + val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = tmp > 0xFFFF; // Overflow
            cycles = 2;
            break;

          case OpCode.SUB:
            ushort neg_a = !val_a.read +1; // Comp 2 negation of val_a
            uint tmp = val_b.read + neg_a;
            val = cast(ushort)(tmp & 0xFFFF);
            if ( val & 0x800 ) { // val < 0
              ex = 0xFFFF; // Underflow
            } else {
              ex = 0;
            }
            cycles = 2;
            break;

          case OpCode.MUL:
            uint tmp = val_b.read * val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp >> 16);
            cycles = 2;
            break;

          case OpCode.MLI: // Mul with sign
            int tmp = cast(short)val_b.read * cast(short)val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp >> 16);
            cycles = 2;
            break;

          case OpCode.DIV:
            if (val_a.read == 0) {
              val = 0;
            } else {
            uint tmp = val_b.read / val_a.read;
            uint tmp2 = (val_b.read << 16) / val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp2 & 0xFFFF);
            }
            cycles = 3;
            break;

          case OpCode.DVI: // Div with sign
            if (val_a.read == 0) {
              val = 0;
            } else {
            int tmp = cast(short)val_b.read / cast(short)val_a.read;
            int tmp2 = (cast(short)val_b.read << 16) / cast(short)val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = cast(ushort)(tmp2 & 0xFFFF);
            }
            cycles = 3;
            break;

          case OpCode.MOD:
            if (val_a.read == 0) {
              val = 0;
            } else {
              val = val_b.read % val_a.read;
            }
            cycles = 3;
            break;

          case OpCode.MDI: // Mod with sign
            if (val_a.read == 0) {
              val = 0;
            } else {
              val = cast(short)val_b.read % cast(short)val_a.read;
            }
            cycles = 3;
            break;

          case OpCode.AND:
            val = val_b.read & val_a.read;
            cycles = 1;
            break;

          case OpCode.BOR:
            val = val_b.read | val_a.read;
            cycles = 1;
            break;

          case OpCode.XOR:
            val = val_b.read ^ val_a.read;
            cycles = 1;
            break;

          case OpCode.SHR: // Logical Shift
            uint tmp = val_b.read >>> val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex  = cast(ushort)(tmp << 16);
            cycles = 1;
            break;

          case OpCode.ASR: // Arthmetic shift
            uint tmp = val_b.read >> val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            ex  = cast(ushort)(tmp << 16);
            cycles = 1;
            break;

          case OpCode.SHL:
            uint tmp = val_b.read >>> (16 - val_a.read);
            val = cast(ushort)(tmp << 16);
            ex  = cast(ushort)(tmp & 0xFFFF);
            cycles = 1;
            break;

          case OpCode.IFB:
            cycles = 2;
            write_val = false;
            new_skip = ((val_b.read & val_a.read) != 0); // Skip next instrucction
            break;

          case OpCode.IFC:
            cycles = 2;
            write_val = false;
            new_skip = ((val_b.read & val_a.read) == 0);
            break;

          case OpCode.IFE:
            new_skip = (val_b.read == val_a.read);
            write_val = false;
            cycles = 2;
            break;

          case OpCode.IFN:
            cycles = 2;
            write_val = false;
            new_skip = (val_b.read != val_a.read);
            break;

          case OpCode.IFG:
            cycles = 2;
            write_val = false;
            new_skip = (val_b.read > val_a.read);
            break;

          case OpCode.IFA:
            cycles = 2;
            write_val = false;
            new_skip = (cast(short)val_b.read > cast(short)val_a.read);
            break;

          case OpCode.IFL:
            cycles = 2;
            write_val = false;
            new_skip = (val_b.read < val_a.read);
            break;

          case OpCode.IFU:
            cycles = 2;
            write_val = false;
            new_skip = (cast(short)val_b.read < cast(short)val_a.read);
            break;

          case OpCode.ADX:
            uint tmp = val_b.read + val_a.read + ex;
            val = cast(ushort)(tmp & 0xFFFF);
            ex = tmp > 0xFFFF; // Overflow
            cycles = 3;
            break;

          case OpCode.SBX:
            ushort neg_a = !val_a.read +1; // Comp 2 negation of val_a
            uint tmp = val_b.read + neg_a + ex;
            val = cast(ushort)(tmp & 0xFFFF);
            if ( val & 0x800 ) { // val < 0
              ex = 0xFFFF; // Underflow
            } else {
              ex = 0;
            }
            cycles = 3;
            break;

          case OpCode.STI:
            val = val_a.read;
            i++;
            j++;
            cycles = 2;
            break;

          case OpCode.STD:
            val = val_a.read;
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
      if (!skip) {
        switch (ext_opcode) {
          case ExtOpCode.JSR:
            synchronized (machine) {
              machine.ram[--sp] = cast(ushort)(pc +1);
            }
            pc = val_a.read;
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
            ia = val_a.read;
            cycles = 1;
            break;

          case ExtOpCode.RFI:
            read_queue = true;
            synchronized (machine) {
              a  = machine.ram[sp++];
              pc = machine.ram[sp++];
            }
            cycles = 3;
            break;

          case ExtOpCode.IAQ:
            read_queue = val_a.read == 0; // if val_a != 0 Not read the interrupt queue
            cycles = 2;
            break;

          case ExtOpCode.HWN: // Number od devices
            a = cast(ushort)machine.dev.length;
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

    if (!wait_hwd) // Some hardware when receive a HWI can make to wait more cycles
      cycles--;
      
    if (cycles == 0) { // Only increment PC and set Ready when cycle count == 0
      if (skip) {
        skip = new_skip;
      } else {
        if (opcode != 0 && write_val) { // Basic OpCode
          // OpB <= OpA Operation OpA = val
          val_b.write = val;
        } else if (write_val) {         // Extended OpCode
          // OpA <= val
          val_a.write = val;
        }
      }
      state = CpuState.DECO;
      pc++;
    }
    
  }
}

