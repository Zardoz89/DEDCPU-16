/**
 * DCPU-16 computer hardware
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.hardware;

public import dcpu.machine, dcpu.cpu;

abstract class Hardware {
private:
  long n_bus_ticks_60hz;/// Number of bus clock ticks need to do a event at 60Hz
  bool f_floor_ceil;    /// do floor or ceil to calc n_bus_ticks
  long count_ticks;     /// Count bus clock ticks
  
protected:
  bool f_hwi;           /// Has at least one time receive a hardware interrupt
  static enum BaseFreq = 60; // Base frecuency
  
  static uint id;        /// Hardware ID
  static ushort ver;     /// Hardware Version
  static uint vendor;    /// Hardware manufacturer

public:
  
  /**
   * Sets Hardware ID, version and vendor
   * It must be override by new hardware
   */
  static this() {
    id     = 0;
    ver    = 0;
    vendor = 0;
  }

  /// Returns the LSB from Device ID
  static ushort id_lsb () @property {
    return cast(ushort)(id & 0xFFFF);
  }

  /// Returns the MSB from Device ID
  static ushort id_msb () @property {
    return cast(ushort)(id >> 16);
  }

  /// Returns the LSB from Device Vendor
  static ushort vendor_lsb () @property {
    return cast(ushort)(vendor & 0xFFFF);
  }

  /// Returns the MSB from Device Vendor
  static ushort vendor_msb () @property {
    return cast(ushort)(vendor >> 16);
  }

  /// Returns the Device Version
  static ushort dev_ver() @property {
    return ver;
  }

  /**
   * What to do when the emulation start
   */
  void init() {
    f_hwi = false;
  }

  /**
   * What to do when the emualtion end
   */
  void end() {
    
  }

  /**
   * What to do when a Hardware interrupt to this hardware, has receive
   * Params:
   *  state   = CPU editable actual state
   *  ram     = RAM of the machine
   */
  void interrupt(ref CpuInfo state, ref ushort[0x10000] ram) {
    f_hwi = true;
  }

  /**
   * What to do each bus clock tick (at 100 khz)
   * Params:
   *  state   = CPU editable actual state
   *  cpu     = CPU
   *  ram     = RAM of the machine
   */
  void bus_clock_tick(ref CpuInfo state, ref DCpu cpu, ref ushort[0x10000] ram) {
    import std.math;
    debug {
      import std.stdio;
    }
    if (f_hwi) {
      debug {
        stderr.writeln("Bus Tick: ",count_ticks);
      }
      if (++count_ticks >= n_bus_ticks_60hz) { // Do 60Hz tick event
        if (f_floor_ceil) { // Round up or down to try be more acurrate to 60Hz (aprox 60,006hz)
          n_bus_ticks_60hz = cast(long)floor(100000.0 / BaseFreq);
        } else {
          n_bus_ticks_60hz = cast(long)ceil(100000.0 / BaseFreq);
        }
        f_floor_ceil = !f_floor_ceil;
        tick_60hz(state, cpu, ram);
        count_ticks = 0;
      }
    }
  }

  /**
   * What to do each clock tick (at 60 hz)
   * Params:
   *  state   = CPU editable actual state
   *  cpu     = CPU
   *  ram     = RAM of the machine
   */
  void tick_60hz(ref CpuInfo state, ref DCpu cpu, ref ushort[0x10000] ram) {
    
  }

  
}