/**
 * DCPU-16 cpu constants and some generic functions
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.microcode;

/// Valid basic OpCodes
enum OpCode: ubyte {
  ExtOpCode=0x00,   /// Switch to special OpCodes
  SET,              /// SETs b to a
  ADD,              /// b = b + a
  SUB,              /// b = b - a
  MUL,              /// b = b * a
  MLI,              /// b = b * a with sign
  DIV,              /// b = b / a
  DVI,              /// b = b / a with sign
  MOD,              /// b = b % a
  MDI,              /// b = b % a with sign
  AND,              /// b = b & a
  BOR,              /// b = b | a
  XOR,              /// b = b ^ a
  SHR,              /// b = b >>> a (logical shift)
  ASR,              /// b = b >> a (arithmetic shift)
  SHL,              /// b = b << a
  IFB,              /// Next instrucction if ( b & a ) != 0
  IFC,              /// Next instrucction if ( b & a ) == 0
  IFE,              /// Next instrucction if b == a
  IFN,              /// Next instrucction if b != a
  IFG,              /// Next instrucction if b > a
  IFA,              /// Next instrucction if b > a signed
  IFL,              /// Next instrucction if b < a
  IFU,              /// Next instrucction if b < a signed
  ADX=0x1a,         /// b = b + a + EX
  SBX=0x1b,         /// b = b - a + EX
  STI=0x1e,         /// sets b = a ; I++ ; J++
  STD=0x1f          /// sets b = a ; I-- ; J---
};

/// Valid ExtendedOpCode
enum ExtOpCode : ubyte {
  JSR=0x01,   /// Pushes the addres of the next isntruction to the stack, then sets PC to a
  INT=0x08,   /// Trigger a software interrupt with message A
  IAG,        /// sets a = IA
  IAS,        /// sets IA = a
  RFI,        /// Return From Interrupt
  IAQ=0x0c,   /// Queueing of interrupts if a != 0
  HWN=0x10,   /// Sets a to number of devices
  HWQ=0x11,   /// Retrive information about hardware device a
  HWI=0x12    /// Sends an interrupt to hrdware a
};

/// Operand type/value
enum Operand : ubyte {
  /** General Registers */
  A = 0x00,
  B = 0x01,
  C = 0x02,
  X = 0x03,
  Y = 0x04,
  Z = 0x05,
  I = 0x06,
  J = 0x07,
  /** [register] */
  Aptr = 0x08,
  Bptr = 0x09,
  Cptr = 0x0A,
  Xptr = 0x0B,
  Yptr = 0x0C,
  Zptr = 0x0D,
  Iptr = 0x0E,
  Jptr = 0x0F,
  /** [register + next word] */
  Aptr_word = 0x10,
  Bptr_word = 0x11,
  Cptr_word = 0x12,
  Xptr_word = 0x13,
  Yptr_word = 0x14,
  Zptr_word = 0x15,
  Iptr_word = 0x16,
  Jptr_word = 0x17,
  /** Stack */
  POP_PUSH = 0x18,  /// PUSH if is 'b' operator. POP if is a 'a' operator
  PEEK     = 0x19,  /// [SP]
  PICK_word= 0x1a,  /// [SP + next word]
  /** Not general registers */
  SP = 0x1b,         /// Stack Pointer value
  PC = 0x1c,        /// Program Counter value
  EX = 0x1d,        /// Excess register value
  NWord_ptr = 0x1e, /// [next word]
  NWord = 0x1f,     /// next_word literal
  Literal = 0x20    /// literal from -1 to 30 (only if is 'a' operator)
};

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