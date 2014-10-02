/**
 * DCPU-16 hardware timer clock
 *
 * See_Also:
 *  http://dcpu.com/highnerd/rc_1/clock.txt
 */
module dcpu.lem1802;

import std.math;
import dcpu.hardware;

import std.stdio;

/+
class TimerClock: Hardware {

protected:
  /// Default font
  enum ushort[256] default_font = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]; // TODO
  
  /// Default color palette
  enum ushort[16] default_palette = [0x000, 0x00a, 0x0a0, 0x0aa, 0xa00, 0xa0a, 0xa50, 0xaaa,
                                     0x555, 0x55f, 0x5f5, 0x5ff, 0xf55, 0xf5f, 0xff5, 0xfff];
  
  ubyte border_color;       /// Border color
  
  ushort video_addr;        /// Were map VRAM
  ushort font_addr;         /// Were map font ram
  ushort pal_addr;          /// Were map pallete ram

  ushort[256] font;         /// Font ram
  ushort[384] video;        /// Video ram
  ushort[16] pal;           /// Palette ram

  bool show_logo;
  
public:

  static this() {
    id     = 0x7349f615;
    ver    = 1802;
    vendor = 0x1c6c8b36; // NYA ELEKTRISKA
  }

  /**
   * What to do when it's loaded in the dcpu machine
   */
  override void init() {
    f_hwi = false;
    n_bus_ticks = cast(long)floor(100000.0 / BaseFreq);
    show_logo = false;
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
      case 0: // MEM_MAP_SCREEN
        if (state.b != 0)  {
          show_logo = video_addr == 0;
        }
        video_addr = state.b;
        break;
        
      case 1: // MEM_MAP_FONT
        font_addr = state.b;
        break;
        
      case 2: // MEM_MAP_PALETTE
        pal_addr = state.b;
        break;
        
      case 3: // SET_BORDER_COLOR
        border_color = state.b & 0xF;
        break;
        
      case 4: // MEM_DUMP_FONT
        ushort e = cast(ushort)(default_font.length + state.b);
        if (e > state.b) {
          ram[state.b..e] = default_font[0..$];
        } else {
          ushort b = 0x10000 - state.b;
          ram[state.b..$] = default_font[0..b];
          ram[0..e] = default_font[b..$];
        }
        break;
        
      case 5: // MEM_DUMP_PALETTE
        ushort e = cast(ushort)(default_palette.length + state.b);
        if (e > state.b) {
          ram[state.b..e] = default_palette[0..$];
        } else {
          ushort b = 0x10000 - state.b;
          ram[state.b..$] = default_palette[0..b];
          ram[0..e] = default_palette[b..$];
        }
        break;

      default:
        // Do nothing
    }
  }

  /**
   * What to do each clock tick (at 60 hz)
   * Params:
   *  state   = CPU editable actual state
   *  cpu     = CPU
   *  ram     = RAM of the machine
   */
  override
  void tick_60hz(ref CpuInfo state, ref DCpu cpu, ref ushort[0x10000] ram) {
    if (video_addr != 0) {
      // Update video ram
      ushort emap = cast(ushort)(video_addr+ video.length);
      if (emap > video_addr) {
        video[0..$] = ram[video_addr..emap];
      } else {
        ushort bmap = 0x10000 - video_addr;
        video[0..bmap] = ram[video_addr..$];
        video[bmap..$] = ram[0..bmap];
      }

      // Update font ram
      if (font_addr != 0) {
        emap = cast(ushort)(font_addr+ font.length);
        if (emap > font_addr) {
          font[0..$] = ram[font_addr..emap];
        } else {
          ushort bmap = 0x10000 - font_addr;
          font[0..bmap] = ram[font_addr..$];
          font[bmap..$] = ram[0..bmap];
        }
      }

      // Update palette ram
      if (pal_addr != 0) {
        emap = cast(ushort)(pal_addr+ pal.length);
        if (emap > pal_addr) {
          pal[0..$] = ram[pal_addr..emap];
        } else {
          ushort bmap = 0x10000 - pal_addr;
          pal[0..bmap] = ram[pal_addr..$];
          pal[bmap..$] = ram[0..bmap];
        }
      }
    }
  }
}

+/
