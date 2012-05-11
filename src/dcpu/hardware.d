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
  shared DCpu cpu;
  shared Ram ram;

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

  protected this(ref Machine machine) {
    m = cast(shared) machine;
    cpu = cast(shared) m.cpu;
    ram = m.ram;
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