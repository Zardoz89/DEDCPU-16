/**
 * DCPU-16 CPU
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.cpu;

/+
import std.array, std.random;
//import std.string, std.conv, std.stdio;
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

/**
 * CPU public information of his actual state
 */
struct CpuInfo {
  union {
    struct {ushort a, b, c, x, y, z, i, j;}
    ushort[8] registers;    /// General registers
  }

  ushort pc;                /// Program Counter register
  ushort sp;                /// Stack Pointer register
  ushort ex;                /// Excess register
  ushort ia;                /// Interrupt Address register

  bool read_queue = true;   /// FrontPop interrupt queue ?
  bool wait_hwd;            /// Waiting because to end an Interrup to Hardware

  bool f_fire;              /// CPU cath fire
  
  bool skip;                /// Skip next instrucction
  CpuState state;           /// Actual state of CPU
  ushort word;              /// Value of [PC] when begin ready state
  int cycles;               /// Cycles to do in execute

}

final class DCpu {
  private:
  Random gen;       // Used when get fire
  /**
   * Operator
   * Params:
   *  opt = Type of operator (OpA or OpB)
   */
  final class Operator(string opt) {
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

      if (!info.skip)
      switch (op) {         // Read it
        case Operand.A:     // General Registers
        case Operand.B:
        case Operand.C:
        case Operand.X:
        case Operand.Y:
        case Operand.Z:
        case Operand.I:
        case Operand.J:
          val = info.registers[op];
          break;

        case Operand.Aptr:  // General Registers Pointer
        case Operand.Bptr:
        case Operand.Cptr:
        case Operand.Xptr:
        case Operand.Yptr:
        case Operand.Zptr:
        case Operand.Iptr:
        case Operand.Jptr:
          ptr = info.registers[op- Operand.Aptr];
          //synchronized (machine) {
            val = machine.ram[ptr];
          //}
          break;

        case Operand.Aptr_word: // [Reg + next word litreal]
        case Operand.Bptr_word:
        case Operand.Cptr_word:
        case Operand.Xptr_word:
        case Operand.Yptr_word:
        case Operand.Zptr_word:
        case Operand.Iptr_word:
        case Operand.Jptr_word:
          //synchronized (machine) {
            ptr = cast(ushort)(info.registers[op- Operand.Aptr_word] + machine.ram[info.pc +1]);
            val = machine.ram[ptr];
          //}
          break;

        case Operand.POP_PUSH: // a Pop [SP++] | b PUSH [--SP]
          static if (opt == "OpA") {
            //synchronized (machine) { // To read the value
              val =  machine.ram[cast(ushort)(info.sp++)];
            //}
          } else { // TODO Need confirmation if this is correct
            //synchronized (machine) {
              val =  machine.ram[cast(ushort)(info.sp-1)];
            //}
          }
          break;

        case Operand.PEEK: // [SP]
          //synchronized (machine) {
            ptr = info.sp;
            val =  machine.ram[info.sp];
          //}
          break;

        case Operand.PICK_word: // [SP + next word litreal]
          //synchronized (machine) {
            ptr = cast(ushort)(info.sp + machine.ram[info.pc +1]);
            val = machine.ram[ptr];
          //}
          break;

        case Operand.SP: // SP
          val = info.sp;
          break;

        case Operand.PC: // PC
          val = info.pc;
          break;

        case Operand.EX: // EXcess
          val = info.ex;
          break;

        case Operand.NWord_ptr: // Ptr [next word literal ]
          //synchronized (machine) {
            ptr = machine.ram[info.pc +1];
            val = machine.ram[ptr];
          //}
          break;

        case Operand.NWord: // next word literal
          //synchronized (machine) {
            ptr = cast(ushort)(info.pc +1);
            val = machine.ram[ptr];
          //}
          break;

        default: // Literal
          static if (opt == "OpA") {
            val = cast(ushort)((op -1) - Operand.Literal); //(op - (Operand.Literal +1));
          } else {
            assert(false, "This code never should be executed. Operator B can't have literals");
          }
      }

      //writeln(opt, "=> ", format("0x%04X",val), " ", val, " op:", format("0x%04X",op));
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
      if (!info.skip)
      switch (op) {         // Read it
        case Operand.A:     // General Registers
        case Operand.B:
        case Operand.C:
        case Operand.X:
        case Operand.Y:
        case Operand.Z:
        case Operand.I:
        case Operand.J:
          info.registers[op] = v;
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
        case Operand.NWord_ptr: // Ptr [next word literal ]
        case Operand.PEEK:      // [SP]
        case Operand.PICK_word: // [SP + next word litreal]
          //synchronized (machine) {
            machine.ram[ptr] = v;
          //}
          break;

        case Operand.POP_PUSH: // a Pop [SP++] | b PUSH [--SP]
          static if (opt == "OpB") {
            //synchronized (machine) { // To read the value
              machine.ram[cast(ushort)(--info.sp)] = v;
            //}
            break;
          } else {
            assert (false, "This code must never executed. OpA PUSH can be writted");
          }
          

        case Operand.SP: // SP
          info.sp = v;
          break;

        case Operand.PC: // PC
          info.pc = cast(ushort)(v -1); // Compesate pc++ of execute
          break;

        case Operand.EX: // EXcess
          info.ex = v;
          break;

        default: // Literal and Next_Word literal or pointer
          assert(false, "This code never should be executed. Literasl can be writed");
      }
    }

  }
  
  Machine machine;          /// Self-reference to the machine
  
  ushort[] int_queue;       /// Interrupt queue
  bool new_skip;            /// New value of skip

  // Stores state between clock cycles
  ubyte opcode;             /// OpCode
  ubyte ext_opcode;         /// Extendend Opcode if OpCode == 0

  bool do_inmediate = true; /// Do an inmediate operand or next word operand
  ubyte opa;                /// Operand A
  ubyte opb;                /// Operand B
  
  Operator!"OpA" val_a;     /// Value of operand A
  Operator!"OpB" val_b;     /// Value of operand B
  ushort val;               /// Result of an operation
  bool write_val;           /// Must write val to a register or ram
  
  CpuInfo info;             /// CPU actual state

  public:

  this(ref Machine machine) {
    this.machine = machine;
    gen = Random(unpredictableSeed);
  }

  /**
   * Returns CPU actual mutable state (used by hardware to alter CPU registers and state)
   */
  package ref CpuInfo state() @property {
    return info;
  }

  /**
   * Returns a no muttable copy of CPU actual state
   */
  auto actual_state() @property {
    immutable(CpuInfo) i = info;
    return i;
  }

  /**
   * Steps one cycle
   * Returns: True if executed an instrucction. False if not ended the execution of a instrucction
   */
  bool step() {
    //writeln(to!string(state));
    if (info.f_fire) { // Swap a random bit of a random address
      enum bits = [ 1, 2^^1, 2^^2, 2^^3, 2^^4, 2^^5, 2^^6, 2^^7, 2^^8, 2^^9, 2^^10, 2^^11, 2^^12, 2^^13, 2^^14, 2^^15 ];
      auto rbit = randomCover(bits, gen);
      ushort pos = cast(ushort)uniform(0, ushort.max, gen);
      machine.ram[pos] = cast(ushort)(machine.ram[pos] ^ rbit.front);
    }

    if (info.state == CpuState.DECO) { // Feth [PC] and extract operands and opcodes
      if (int_queue.length > 255) { // Catch fire
        info.f_fire = true;
      }
      if (info.read_queue && !int_queue.empty) { // Try to do a int in the queue
        if (info.ia != 0 ) {
          info.read_queue = false;
          machine.ram[--info.sp] = info.pc; // Push PC and A
          machine.ram[--info.sp] = info.a;
          info.pc = info.ia;
          info.a = int_queue[0];
          int_queue = int_queue[1..$];
        } else {
          // If IA is set to 0, a triggered interrupt does nothing. A queued interrupt is considered triggered when it leaves the queue, not when it enters it.
          int_queue = int_queue[1..$];
        }
      }
    
      //synchronized (machine) {
        info.word = machine.ram[info.pc];
      //}
      
      opcode = decode!"OpCode"(info.word);
      opa = decode!"OpA"(info.word);
      opb = decode!"OpB"(info.word);
      ext_opcode = decode!"ExtOpCode"(info.word);

      info.state = CpuState.OPA;
      return step(); // Jump to OPA to try to get a not "next word" operand

    } else if (info.state == CpuState.OPA) { // Get Operand A
      if (do_inmediate) {
        val_a = new Operator!"OpA"(opa);
        if (val_a.next_word && !info.skip) { // Take a extra cycle
          do_inmediate = false;
          return false;
        } else if (val_a.next_word) {
          info.pc++;
        }
      } else {
        do_inmediate = true;
        info.pc++;
      }

      if (opcode == 0) {
        info.state = CpuState.EXECUTE;
        info.cycles = -1;  // Say to Execute to calc it
        return step();       // Jump to Execute state
      } else {
        info.state = CpuState.OPB;
        return step(); // Jump to OPB to try to get a not "next word" operand
      }
      
    } else if (info.state == CpuState.OPB) { // Get Operand B
      if (do_inmediate) {
        val_b = new Operator!"OpB"(opb);
        if (val_b.next_word && !info.skip) { // Take a extra cycle
          do_inmediate = false;
          return false;
        } else if (val_b.next_word) {
          info.pc++;
        }
      } else {
        do_inmediate = true;
        info.pc++;
      }
      
      info.state = CpuState.EXECUTE;
      info.cycles = -1;  // It will be calculated in Execute mode
      return step();       // Jump to Execute state
      
    } else { // Execute the OpCode
      return execute_op(); // I will increase pc when the last cycle is made
    }

  }

  /**
   * Send to the CPU a hardware interrupt
   */
  void hardware_int(ushort msg) {
    // Asumes that when IA == 0, incoming hardware interrupts are ignored
    if (info.ia != 0 && int_queue.length < 256) {
      int_queue ~= msg;
    }
  }
  
private:

  /**
   * Execute a OpCode
   */
  bool execute_op() {    
    if (opcode != 0 && info.cycles < 0) { // Execute Not extended opcode
      if (!info.skip) {
        write_val = true;
        switch (opcode) {
          case OpCode.SET:
            val = val_a.read;
            info.cycles = 1;
            break;

          case OpCode.ADD:
            uint tmp = val_b.read + val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            info.ex = tmp > 0xFFFF; // Overflow
            info.cycles = 2;
            break;

          case OpCode.SUB:
            int tmp = val_b.read - val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            if ( val & 0x800 ) { // val < 0
              info.ex = 0xFFFF; // Underflow
            } else {
              info.ex = 0;
            }
            info.cycles = 2;
            break;

          case OpCode.MUL:
            uint tmp = val_b.read * val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            info.ex = cast(ushort)(tmp >> 16);
            info.cycles = 2;
            break;

          case OpCode.MLI: // Mul with sign
            int tmp = cast(short)val_b.read * cast(short)val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            info.ex = cast(ushort)(tmp >> 16);
            info.cycles = 2;
            break;

          case OpCode.DIV:
            if (val_a.read == 0) {
              val = 0;
            } else {
            uint tmp = val_b.read / val_a.read;
            uint tmp2 = (val_b.read << 16) / val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            info.ex = cast(ushort)(tmp2 & 0xFFFF);
            }
            info.cycles = 3;
            break;

          case OpCode.DVI: // Div with sign
            if (val_a.read == 0) {
              val = 0;
            } else {
            int tmp = cast(short)val_b.read / cast(short)val_a.read;
            int tmp2 = (cast(short)val_b.read << 16) / cast(short)val_a.read;
            val = cast(ushort)(tmp & 0xFFFF);
            info.ex = cast(ushort)(tmp2 & 0xFFFF);
            }
            info.cycles = 3;
            break;

          case OpCode.MOD:
            if (val_a.read == 0) {
              val = 0;
            } else {
              val = val_b.read % val_a.read;
            }
            info.cycles = 3;
            break;

          case OpCode.MDI: // Mod with sign
            if (val_a.read == 0) {
              val = 0;
            } else {
              val = cast(short)val_b.read % cast(short)val_a.read;
            }
            info.cycles = 3;
            break;

          case OpCode.AND:
            val = val_b.read & val_a.read;
            info.cycles = 1;
            break;

          case OpCode.BOR:
            val = val_b.read | val_a.read;
            info.cycles = 1;
            break;

          case OpCode.XOR:
            val = val_b.read ^ val_a.read;
            info.cycles = 1;
            break;

          case OpCode.SHR: // Logical Shift
            uint tmp  = val_b.read >>> val_a.read;
            auto tmp2 = (val_b.read << 16) >> val_a.read;
            val = cast(ushort)(tmp  & 0xFFFF);
            info.ex  = cast(ushort)(tmp2 & 0xFFFF);
            info.cycles = 1;
            break;

          case OpCode.ASR: // Arthmetic shift
            int tmp2 = ((cast(short)val_b.read <<16) >>> cast(short)val_a.read);
            auto tmp = cast(short)val_b.read >> cast(short)val_a.read;
            val = cast(ushort)(tmp  & 0xFFFF);
            info.ex  = cast(ushort)(tmp2 & 0xFFFF);
            info.cycles = 1;
            break;

          case OpCode.SHL:
            uint tmp = (val_b.read << val_a.read) >> 16;
            val = cast(ushort)(val_b.read << val_a.read);
            info.ex  = cast(ushort)(tmp & 0xFFFF);
            info.cycles = 1;
            break;

          case OpCode.IFB:
            info.cycles = 2;
            write_val = false;
            new_skip = !((val_b.read & val_a.read) != 0); // Skip next instrucction
            break;

          case OpCode.IFC:
            info.cycles = 2;
            write_val = false;
            new_skip = !((val_b.read & val_a.read) == 0);
            break;

          case OpCode.IFE:
            new_skip = !(val_b.read == val_a.read);
            write_val = false;
            info.cycles = 2;
            break;

          case OpCode.IFN:
            info.cycles = 2;
            write_val = false;
            new_skip = !(val_b.read != val_a.read);
            break;

          case OpCode.IFG:
            info.cycles = 2;
            write_val = false;
            new_skip = !(val_b.read > val_a.read);
            break;

          case OpCode.IFA:
            info.cycles = 2;
            write_val = false;
            new_skip = !(cast(short)val_b.read > cast(short)val_a.read);
            break;

          case OpCode.IFL:
            info.cycles = 2;
            write_val = false;
            new_skip = !(val_b.read < val_a.read);
            break;

          case OpCode.IFU:
            info.cycles = 2;
            write_val = false;
            new_skip = !(cast(short)val_b.read < cast(short)val_a.read);
            break;

          case OpCode.ADX:
            uint tmp = val_b.read + val_a.read + info.ex;
            val = cast(ushort)(tmp & 0xFFFF);
            info.ex = tmp > 0xFFFF; // Overflow
            info.cycles = 3;
            break;

          case OpCode.SBX:
            int tmp = val_b.read - val_a.read + info.ex;
            val = cast(ushort)(tmp & 0xFFFF);
            if ( val & 0x800 ) { // val < 0
              info.ex = 0xFFFF; // Underflow
            } else {
              info.ex = 0;
            }
            info.cycles = 3;
            break;

          case OpCode.STI:
            val = val_a.read;
            info.i++;
            info.j++;
            info.cycles = 2;
            break;

          case OpCode.STD:
            val = val_a.read;
            info.i--;
            info.j--;
            info.cycles = 2;
            break;

          default: // Unknow OpCode
            // Do Nothing (I should do a random OpCode ?)
            write_val = false;
            info.cycles = 1;
        }
        
      } else { // Skip next basic OpCode instrucction
        info.cycles = 1;
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
      
    } else if (info.cycles < 0) { // Extended OpCode
      write_val = false;
      new_skip = false;
      if (!info.skip) {
        switch (ext_opcode) {
          case ExtOpCode.JSR:
            //synchronized (machine) {
              machine.ram[--info.sp] = cast(ushort)(info.pc +1);
            //}
            info.pc = cast(ushort)(val_a.read -1); // Compesate later pc++
            info.cycles = 3;
            break;

          case ExtOpCode.HCF:
            info.cycles = 9;
            info.f_fire = true;
            break;

          case ExtOpCode.INT: // Software Interruption
            info.cycles = 4;
            // NOTE This implementations asumes that INTs bypass the queue
            if (info.ia != 0) {
              info.read_queue = false;
              machine.ram[--info.sp] = cast(ushort)(info.pc +1); // Push PC and A
              machine.ram[--info.sp] = info.a;
              info.pc = cast(ushort)(info.ia -1);
            }
            break;

          case ExtOpCode.IAG: // Get IA
            write_val = true;
            val = info.ia;
            info.cycles = 1;
            break;

          case ExtOpCode.IAS: // Set IA
            info.ia = val_a.read;
            info.cycles = 1;
            break;

          case ExtOpCode.RFI: // Return From Interrupt
            info.read_queue = true;
            //synchronized (machine) {
              info.a  = machine.ram[info.sp++];
              info.pc = cast(ushort)(machine.ram[info.sp++] -1);
            //}
            info.cycles = 3;
            break;

          case ExtOpCode.IAQ: // Enable pop front of interrupt queue
            info.read_queue = val_a.read == 0; // if val_a != 0 Not read the interrupt queue
            info.cycles = 2;
            break;

          case ExtOpCode.HWN: // Number of devices
            write_val = true;
            val = cast(ushort)machine.dev.length;
            info.cycles = 2;
            break;

          case ExtOpCode.HWQ: // Get Hardware IDs
            info.cycles = 4;
            if (val_a.read in machine.dev) {
              auto dev = machine.dev[val_a.read];
              info.a = dev.id_lsb;
              info.b = dev.id_msb;
              info.c = dev.dev_ver;
              info.x = dev.vendor_lsb;
              info.y = dev.vendor_msb;
            } else { // Unspecific behaviour
              info.a = info.b = info.c = info.x = info.y = 0xFFFF;
            }
            break;

          case ExtOpCode.HWI: // Send a hardware interrupt to device A
            info.cycles = 4; // Or more
            if (val_a.read in machine.dev) {
              machine.dev[val_a.read].interrupt(info, machine.ram);
            }
            break;

          default: // Unknow OpCode
            // Do Nothing (I should do a random OpCode ?)
            info.cycles = 1;
        }
      } else {
        info.cycles = 1;
        new_skip = false;
      }

    }

    if (!info.wait_hwd) // Some hardware when receive a HWI can make to wait more cycles
      info.cycles--;
      
    if (info.cycles == 0) { // Only increment PC and set Ready when cycle count == 0
      if (!info.skip) {
        if (opcode != 0 && write_val) { // Basic OpCode
          // OpB <= OpA Operation OpA = val
          val_b.write = val;
        } else if (write_val) {         // Extended OpCode
          // OpA <= val
          val_a.write = val;
        }
      }
      info.skip = new_skip;
      info.state = CpuState.DECO;
      info.pc++;
      return true;
    }
    return false;
  }
}
+/

