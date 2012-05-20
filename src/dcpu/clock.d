/**
 * DCPU-16 hardware timer clock
 *
 * See_Also:
 *  http://dcpu.com/highnerd/rc_1/clock.txt
 */
module dcpu.clock;

import std.math;
import dcpu.hardware;

import std.stdio;

class TimerClock: Hardware {

protected:
  ushort ticks;       /// How many clock ticks sinze the last call
  ushort divisor;     /// Clock divider
  ushort int_msg;     /// Interrupt mesg to send to the CPU
  long n_bus_ticks;   /// Number of bus clock ticks ot do a clock tick
  long count;
  bool f_floor_Ceil;  /// do floor or ceil to calc n_bus_ticks
  
  static enum BaseFreq = 60; // Max frecuency
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
    f_hwi = false;
    int_msg = 0;
    divisor = 0;
    ticks = 0;
  }

  /**
   * What to do when a Hardware interrupt to this hardware, has receive
   * Params:
   *  state   = CPU editable actual state
   *  ram     = RAM of the machine
   */
  override void interrupt(ref CpuInfo state, ref ushort[0x10000] ram) {
    //synchronized (m) { //Accesing to CPU registers
      switch (state.a) {
        case 0:
          divisor = state.b;
          if (divisor > 0) {
            if (f_floor_Ceil) { //
              n_bus_ticks = cast(long)floor(100000.0 / BaseFreq / divisor);
            } else {
              n_bus_ticks = cast(long)ceil(100000.0 / BaseFreq / divisor);
            }
            f_floor_Ceil = !f_floor_Ceil;
          }
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
    //}
    
    ticks = 0;
    f_hwi = true;
  }

  /**
   * What to do each clock tick (at 100 khz)
   * Params:
   *  state   = CPU editable actual state
   *  cpu     = CPU
   *  ram     = RAM of the machine
   */
  override void bus_clock_tick (ref CpuInfo state, ref DCpu cpu, ref ushort[0x10000] ram) {
    if (f_hwi && divisor > 0) {
      stderr.writeln("\tbus tick: ", count, " to: ",n_bus_ticks, " ticks: ", ticks);
      if (count < n_bus_ticks) {
        count++;
      } else { // Do tick
        ticks++;
        count = 0;
        // Send Interrupt to DCPU
        if (int_msg > 0) {
          //synchronized (cpu) {
            cpu.hardware_int(int_msg);
          //}
        }
        
      }
    }
  }
  
}