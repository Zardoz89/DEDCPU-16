/**
 * DCPU-16 hardware timer clock
 *
 * See_Also:
 *  http://dcpu.com/highnerd/rc_1/clock.txt
 */
module dcpu.clock;

import std.math;
import dcpu.hardware;

class TimerClock: Hardware {

protected:
  ushort ticks;       /// How many clock ticks sinze the last call
  ushort divisor;     /// Clock divider
  ushort int_msg;     /// Interrupt mesg to send to the CPU
  long n_bus_ticks;   /// Number of bus clock ticks ot do a clock tick
  bool f_floor_Ceil;  /// do floor or ceil to calc n_bus_ticks
  
  static enum BaseFreq = 60; // Max frecuency
public:

  static this() {
    id     = 0x12d0b402;
    ver    = 1;
    vendor = 0; // Not yet
  }

  this(ref Machine machine) {
    super(machine);
  }

  /**
   * What to do when it's loaded
   */
  override void init() {
    f_hwi = false;
    int_msg = 0;
    divisor = 0;
    ticks = 0;
  }

  /**
   * What to do when a Hardware interrupt to this hardware, has receive
   */
  override void interrupt() {
    //synchronized (m) { //Accesing to CPU registers
      switch (m.cpu.a) {
        case 0:
          divisor = m.cpu.b;
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
          m.cpu.c = ticks;
          break;
        case 2:
          int_msg = m.cpu.b;
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
   */
  override void bus_clock_tick() {
    if (f_hwi && divisor > 0) {
      if (n_bus_ticks > 0) {
        n_bus_ticks--;
      } else { // Do tick
        ticks++;
        if (f_floor_Ceil) { // swaps from floor or ceil to try be more acurrated clock
          n_bus_ticks = cast(long)floor(100000.0 / BaseFreq / divisor);
        } else {
          n_bus_ticks = cast(long)ceil(100000.0 / BaseFreq / divisor);
        }
        f_floor_Ceil = !f_floor_Ceil;

        // Send Interrupt to DCPU
        if (int_msg > 0) {
          //synchronized (m.cpu) {
            m.cpu.hardware_int(int_msg);
          //}
        }
        
      }
    }
  }
  
}