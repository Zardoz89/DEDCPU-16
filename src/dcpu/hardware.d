/**
 * DCPU-16 computer hardware
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.hardware;

public import dcpu.machine, dcpu.cpu;

class Hardware {
  protected:
  shared Machine m;

  bool f_hwi; ///Has at least one time receive a hardware interrupt 

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

  protected this(ref Machine machine) {
    m = cast(shared) machine;
    init();
  }

  /**
   * What to do when it's loaded
   */
  abstract void init();

  /**
   * What to do when a Hardware interrupt to this hardware, has receive
   */
  abstract void interrupt();

  /**
   * What to do each clock tick (at 100 khz)
   */
  abstract void bus_clock_tick();
}