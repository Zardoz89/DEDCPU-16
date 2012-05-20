/**
 * DCPU-16 computer
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.machine;

public import dcpu.hardware, dcpu.cpu;
import std.range, std.parallelism;

// It contains:
//  -DCPU-16 CPU
//  -0x10000 words of 16 bit of RAM
//  -Some quanty of hardware attached
final class Machine {
  ushort[0x10000] ram;
  DCpu cpu;

package:
  Hardware[ushort] dev;

public:
  /**
   * Inits the DCPU machine
   */
  void init() {
    cpu = new DCpu(this);
    foreach(ref d; dev) // taskPool.parallel(dev)
      d.init();
  }

  // Emulation running *********************************************************
  /**
   * Do a clock tick to the whole machine
   * Returns TRUE if a instruccion has executed
   */
  bool tick() {
    foreach(ref d; dev) {
      d.bus_clock_tick(cpu.state);
    }
    return cpu.step();
  }

  /**
   * Returns the actual status of cpu registers
   */
  @property CpuInfo cpu_info() {
    return cpu.info;
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
