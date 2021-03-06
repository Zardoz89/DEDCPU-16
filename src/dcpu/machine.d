/**
 * DCPU-16 computer
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.machine;

/+
public import dcpu.hardware, dcpu.cpu;
import std.range, std.parallelism;

// It contains:
//  -DCPU-16 CPU
//  -0x10000 words of 16 bit of RAM
//  -Some quanty of hardware attached
final class Machine {
  ushort[0x10000] ram;

package:
  Hardware[ushort] dev;
  DCpu cpu;

public:
  /**
   * Inits the DCPU machine
   */
  void init() {
    cpu = new DCpu(this);
    foreach(ref d; dev) // taskPool.parallel(dev)
      d.init();
  }

  // Emulation *****************************************************************
  /**
   * Do a clock tick to the whole machine
   * Returns TRUE if a instruccion has executed
   */
  bool tick() {
    foreach(ref d; dev) {
      d.bus_clock_tick(cpu.state, cpu, ram);
    }
    return cpu.step();
  }

  /**
   * Returns the actual status of cpu registers
   */
  @property auto cpu_info() {
    return cpu.actual_state;
  }

  /**
   * Set a breakpoint in an address
   * Params:
   *    addr    = Address where set a breakpoint
   * Returns if previusly these adress had a breakpoint
   */
  bool set_breakpoint (ushort addr) {
    // TODO
    return false;
  }

  /**
   * There is a breakpoint in an address
   * Params:
   *    addr    = Address where see if there is a breakpoint
   * Returns TRUE if there is a breakpoint in addr
   */
  bool is_breakpoint (ushort addr) {
    // TODO
    return false;
  }

  // Device handling ***********************************************************
  /**
   * Returns the device number I
   */
  ref Hardware opIndex (size_t index) {
    return dev[cast(ushort)index];
  }

  /**
   * Asigns the device number I
   */
  void opIndexAssign (Hardware val, size_t index) {
    dev[cast(ushort)index] = val;
  }

  /**
   * How many devices are inside the machine
   */
  @property size_t length() {
    return dev.length;
  }

  
  
}

+/

