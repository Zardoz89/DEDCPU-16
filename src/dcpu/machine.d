/**
 * DCPU-16 computer
 *
 * See_Also:
 *  http://pastebin.com/raw.php?i=Q4JvQvnM
 */
module dcpu.machine;

public import dcpu.hardware, dcpu.cpu;

// It contains:
//  -DCPU-16 CPU
//  -0x10000 words of 16 bit of RAM
//  -Some quanty of hardware attached

final class Machine {
  DCpu cpu;
  ushort[0x10000] ram;
  Hardware[] dev;

  void init() {
    cpu = new DCpu(this);
    
  }
}
