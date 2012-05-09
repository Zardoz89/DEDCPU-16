/**
 * DCPU-16 computer
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.machine;

import dcpu.hardware, dcpu.cpu;

/**
 * Machine RAM encasulated in a class to get synchronized protection when
 * accesing to ram
 */
final class Ram {
  ushort[0x10000] ram;
}

// It contains:
//  -DCPU-16 CPU
//  -0x10000 words of 16 bit of RAM
//  -Some quanty of hardware attached

struct Machine {
  DCpu cpu;
  shared Ram ram;
  Hardware[] hard;

  void init() {
    cpu = new DCpu(this);
    ram = new shared(Ram);
    
  }
}
