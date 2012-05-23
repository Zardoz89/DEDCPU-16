/**
 * DCPU-16 hardware timer clock
 *
 * See_Also:
 *  http://dcpu.com/highnerd/rc_1/clock.txt
 */
module dcpu.clock;

import dcpu.hardware;

class TimerClock: Hardware {

protected:
  ushort ticks;       /// How many clock ticks sinze the last call
  ushort interval;    /// Clock divider
  ushort int_msg;     /// Interrupt mesg to send to the CPU
  long count;         /// Count clock ticks
  
public:

  static this() {
    id     = 0x12d0b402;
    ver    = 1;
    vendor = 0; // Not yet
  }

  /**
   * What to do when it's loaded in the dcpu machine
   */
  override void init() {
    super.init();
    int_msg = 0;
    interval = 0;
    ticks = 0;
    count = 0;
  }

  /**
   * What to do when a Hardware interrupt to this hardware, has receive
   * Params:
   *  state   = CPU editable actual state
   *  ram     = RAM of the machine
   */
  override void interrupt(ref CpuInfo state, ref ushort[0x10000] ram) {
    super.interrupt(state, ram);
    switch (state.a) {
      case 0:
        interval = state.b;
        break;
      case 1:
        state.c = ticks;
        break;
      case 2:
        int_msg = state.b;
        break;
      default:
        // Do nothing
    }
    ticks = 0;
  }

  /**
   * What to do each clock tick (at 60 hz)
   * Params:
   *  state   = CPU editable actual state
   *  cpu     = CPU
   *  ram     = RAM of the machine
   */
  override void tick_60hz (ref CpuInfo state, ref DCpu cpu, ref ushort[0x10000] ram) {
    if (f_hwi && interval != 0) {      
      if (++count >= interval) {
        debug {
          import std.stdio;
          stderr.writeln("\t60hz tick: ", count, " to: ",interval, " ticks: ", ticks);
        }
        ticks++;
        count = 0;
        if (int_msg > 0) { // Send Interrupt to DCPU
          cpu.hardware_int(int_msg);
        }
        
      }
    }
  }
  
}