module lem1802_fontview;

import std.c.process, std.stdio, std.conv, std.math;

import gtkc.gtktypes;
import gtk.Main, gtk.Builder;
import gtk.Widget, gtk.Window, gtk.MainWindow, gtk.Dialog, gtk.AboutDialog;
import gtk.Button, gtk.Label, gtk.MenuBar, gtk.MenuItem, gtk.ToggleButton;
import gtk.SpinButton, gtk.Adjustment, gtk.AccelGroup;
import gtk.DrawingArea;
import gdk.Event, gtk.Container, gdk.RGBA;

import cairo.Context, cairo.Surface;

import ui.file_chooser, ui.dialog_slice;
import dcpu.ram_io;

string filename;            // Open file
TypeHexFile type;           // Type of file
Window mainwin;             // Main window

ushort[256] font;           // Font data
size_t selected;            // Selected gryph

DrawingArea dwa;            // Drawing widget
enum FONT_GLYPHS = 128;
enum G_WIDTH  = 4;
enum G_HEIGHT = 8;
enum uint MATRIX_WIDTH  = 32;
enum uint MATRIX_HEIGHT = 4;
enum RECT_SIZE = 4;
enum CELL_HEIGHT = RECT_SIZE*G_HEIGHT;
enum CELL_WIDTH  = RECT_SIZE*G_WIDTH;
enum double min_width  = G_WIDTH*RECT_SIZE*MATRIX_WIDTH +30; // Min width of drawing widget
enum double min_height = G_HEIGHT*RECT_SIZE*MATRIX_HEIGHT +3; // Min height of drawing widget

Label lbl_pos;              // Label with selected glyph position
Label lbl_bin;              // Label with binary representation of selected glyph
Label lbl_hex;              // Label with hex representation of selected glyph
Label lbl_dec;              // Label with decimal representation of selected glyph

//bool updating;            // Updating data form out to the editor ?
DrawingArea glyph_editor;   // Glyph editor
//ToggleButton[16][2] editor; // Editor toggle buttons

AboutDialog win_about;      // About dialog

size_t file_size;           // Original File size

/**
 * Close the App when it's clicked menu exit option
 */
extern (C) export void on_mnu_exit_activate (Event event, Widget widget) {
  Main.quit();
}

/**
 * Show About dialog
 */
extern (C) export void on_mnu_about_activate (Event event, Widget widget) {
  win_about.run();
  win_about.hide();
}

/**
 * Click over Previus button
 */
extern (C) export void on_but_prev_clicked (Event event, Widget widget) {
  selected = (selected -1) % 128;
  lbl_pos.setLabel(to!string(selected));
  update_editor();
  dwa.queueDraw();
}

/**
 * Click over Previus button
 */
extern (C) export void on_but_next_clicked (Event event, Widget widget) {
  selected = (selected +1) % 128;
  lbl_pos.setLabel(to!string(selected));
  update_editor();
  dwa.queueDraw();
}

/**
 * Reset all data (new font)
 */
extern (C) export void on_mnu_new_activate (Event event, Widget widget) {
  filename = "";
  selected = 0;
  font[] = 0;
  update_editor();
  dwa.queueDraw();
}


/**
 * Show the Open file Dialog and try to load it
 */
extern (C) export void on_mnu_open_activate (Event event, Widget widget) {
  auto opener = new FileOpener(mainwin);
  auto response = opener.run();
  if (response == ResponseType.ACCEPT) {
    filename = opener.getFilename();
    type = opener.type;

    ushort[] tmp;
    if (filename !is null && filename.length > 0){
      try {
        tmp = load_ram(type, filename);
      } catch (Exception e) {
        stderr.writeln("Error: Couldn't open file\n", e.msg);
      }

      if (tmp.length > 256) { // Contains something more that a LEM1802 font
        file_size = tmp.length;
        auto d = new dialog_slice("LEM1802 Font View", mainwin, GtkDialogFlags.MODAL,
            "The file contains more data that a font for the LEM1802.
You must select a range of data that you desire to load like a font.", file_size, 255, false);
        d.show();
        auto r = d.run();
        d.hide();
        if ( r == ResponseType.ACCEPT) {
          size_t slice = cast(size_t)(d.size);
          size_t b = cast(size_t)d.bottom_address;
          size_t e = cast(size_t)d.top_address;
          e++;

          if (((e-b+1)%2) != 0 && (e-b > 2)) {
            e--; // Clamp the last half glyph selected
            slice--;
          }

          font[0..slice] = tmp[b..e];
          font[slice..$] = 0;
        }
      } else {
        font[0..tmp.length] = tmp[0..tmp.length];
        font[tmp.length..$] = 0;
      }
      // Updates GUI
      selected = 0;
      update_editor();
      dwa.queueDraw();
    }
  }
  opener.hide();
  opener.destroy();
}

/**
 * Show the Save file Dialog and try to save it
 */
extern (C) export void on_mnu_saveas_activate (Event event, Widget widget) {
  auto opener = new FileOpener(mainwin, false);
  auto response = opener.run();
  if (response == ResponseType.ACCEPT) {
    filename = opener.getFilename();
    type = opener.type;
    stderr.writeln("Type :", type);
    // Save data
    try {
      save_ram(type, filename, font);
    } catch (Exception e) {
      stderr.writeln("Error: Couldn't save data\n", e.msg);
    }
  }

  opener.hide();
  opener.destroy();
}

/**
 * Update the state of the editor buttons
 */
void update_editor() {
  glyph_editor.queueDraw();
  update_glyph_lbl(); // Update labels at same time
}

/**
 * Updates binary, hex and decimal representation of selected glyph
 */
void update_glyph_lbl() {
  import std.string;
  lbl_bin.setLabel("0b"~format("%016b",font[selected*2])~"\n"~ "0b"~format("%016b",font[selected*2+1]));
  lbl_hex.setLabel("0x"~format("%04X",font[selected*2])~"\n"~ "0x"~format("%04X",font[selected*2+1]));
  lbl_dec.setLabel(to!string(font[selected*2])~"\n"~to!string(font[selected*2+1]));
}

void main(string[] args) {
  int old_w, old_h;
  Main.init(args);

  auto builder = new Builder ();

  if (! builder.addFromFile ("./src/ui/fview.ui")) {
    writefln("Oops, could not create Builder object, check your builder file ;)");
    exit(1);
  }

  // Get reference to Objects
  mainwin = cast(Window) builder.getObject ("win_fontview");
  if (mainwin is null) {
    writefln("Can't find win_fontview widget");
    exit(1);
  }
  auto accelgroup = cast(AccelGroup) builder.getObject ("accelgroup1");
  if (accelgroup is null) {
    writefln("Can't find accelgroup1 widget");
    exit(1);
  }
  mainwin.addAccelGroup(accelgroup);

  win_about = cast(AboutDialog) builder.getObject ("win_about");
  if (mainwin is null) {
    writefln("Can't find win_about widget");
    exit(1);
  }


  dwa = cast(DrawingArea) builder.getObject("dwa_general");
  if (dwa is null) {
    writefln("Can't find dwa_general widget");
    exit(1);
  }

  lbl_pos = cast(Label) builder.getObject("lbl_pos");
  if (lbl_pos is null) {
    writefln("Can't find lbl_pos widget");
    exit(1);
  }
  lbl_bin = cast(Label) builder.getObject ("lbl_bin");
  if (lbl_bin is null) {
    writefln("Can't find lbl_bin widget");
    exit(1);
  }
  lbl_hex = cast(Label) builder.getObject ("lbl_hex");
  if (lbl_hex is null) {
    writefln("Can't find lbl_hex widget");
    exit(1);
  }
  lbl_dec = cast(Label) builder.getObject ("lbl_dec");
  if (lbl_dec is null) {
    writefln("Can't find lbl_dec widget");
    exit(1);
  }

  glyph_editor = cast(DrawingArea) builder.getObject ("glyph_editor");
  if (glyph_editor is null) {
    writefln("Can't find glyph_editor widget");
    exit(1);
  }

  dwa.overrideBackgroundColor( GtkStateFlags.NORMAL, new RGBA(0, 0, 0));
  glyph_editor.overrideBackgroundColor( GtkStateFlags.NORMAL, new RGBA(0, 0, 0));
  // Here we assing event handlers --------------------------------------------

  // Closing the window ends the program
  mainwin.addOnDestroy ( (Widget w) {
    Main.quit();
  });

  // Select a Glyph
  dwa.addOnButtonPress ( (Event event, Widget widget) {
    if (event !is null) {
      GtkAllocation size;
      widget.getAllocation(size);

      double x = event.button().x *(min_width / size.width);   // Scales coords to be the same
      double y = event.button().y *(min_height / size.height); // always with diferent geometry

      x = floor(x / (G_WIDTH*RECT_SIZE  +1));
      y = floor(y / (G_HEIGHT*RECT_SIZE +1));
      selected = (to!size_t(x+ y*MATRIX_WIDTH) % FONT_GLYPHS);

      lbl_pos.setLabel(to!string(selected));
      dwa.queueDraw();
      update_editor();

      return true;
    }
    return false;
  });

  // Draws Glyphs viewer
  dwa.addOnDraw( (Scoped!Context cr, Widget widget) {
    GtkAllocation size;
    widget.getAllocation(size);

    // Calcs factor scale
    double scale_x = size.width / min_width;
    double scale_y = size.height / min_height;
    cr.scale(scale_x, scale_y);

    // Draw font on a 32x4 matrix. Each font[i] is half glyph
    cr.save();
    for (size_t i; i< font.length; i++) {
      auto hcell_x = i % (2*MATRIX_WIDTH);
      auto cell_y = i / (2*MATRIX_WIDTH);
      auto x_org = hcell_x*CELL_WIDTH/2 + floor(hcell_x/2.0);
      auto y_org = cell_y * (CELL_HEIGHT+1);

      for (ushort p; p < 16; p++) { // And loops each pixel of a half glyph
        if(( font[i] & (1<<p)) != 0) {
          int l_oct = 1 - (p / 8);
          double x = l_oct * RECT_SIZE;
          x += x_org;

          double y = (p % 8) * RECT_SIZE;
          y += y_org;

          cr.rectangle(x, y, RECT_SIZE, RECT_SIZE);
          cr.setSourceRgb(1.0, 1.0, 1.0);
          cr.fill();
        }
      }
    }
    cr.restore();

    // Draw lines around gryphs
    cr.save();
      cr.setSourceRgb(1.0, 0, 0);
      cr.setLineWidth(1.0);
      for (auto y = CELL_HEIGHT +1 ; y< (CELL_HEIGHT+1)*MATRIX_HEIGHT; y+=CELL_HEIGHT+1) {
        cr.moveTo(0, y);
        cr.lineTo(min_width, y);
      }
      for (auto x = CELL_WIDTH+1; x< (CELL_WIDTH+1)*MATRIX_WIDTH; x+=CELL_WIDTH+1) {
        cr.moveTo(x, 0);
        cr.lineTo(x, min_height);
      }
      cr.stroke();

    cr.restore();

    // Draw rectangle around selected glyph
    cr.save();
      cr.setSourceRgb(0, 1.0, 0);
      cr.setLineWidth(1.5);
      double x = (selected%MATRIX_WIDTH)*G_WIDTH*RECT_SIZE + (selected%MATRIX_WIDTH);
      double y = floor(selected / MATRIX_WIDTH)*(CELL_HEIGHT+1);
      cr.rectangle(x, y, RECT_SIZE*G_WIDTH, RECT_SIZE*G_HEIGHT);
      cr.stroke();

      cr.restore();
    return false;
  });

  // Draws Glyph editor
  glyph_editor.addOnDraw( (Scoped!Context cr, Widget widget) {
    GtkAllocation size;
    widget.getAllocation(size);
    /+

      //cr.scale(scale_x, scale_y);
      cr.translate(0, 0);

    // Calcs factor scale
    double scale_x = size.width / min_width;
    double scale_y = size.height / min_height;
+/

    // Draw lines around gryphs
    cr.save();
      cr.setSourceRgb(0.5, 0.5, 0.5);
      cr.setLineWidth(1.0);
      for (auto y = 20.0; y< 21*8; y+=21) {
        cr.moveTo(0, y);
        cr.lineTo(size.width, y);
      }
      for (auto x = 20.0; x< 21*4; x+=21) {
        cr.moveTo(x, 0);
        cr.lineTo(x, size.height);
      }
      cr.stroke();
    cr.restore();

    // Paints selected Glyph
    cr.save();
    for (int x; x < 2; x++) {
      for (int y; y < 16; y++) {
        if (( font[selected*2+x] & (1<<y)) != 0) {
          auto pos_x = (x*2 + 1 - floor(cast(double)(y/8)) ) * 21;
          cr.rectangle(pos_x, (y%8)*21, 20, 20);
          cr.setSourceRgb(1.0, 1.0, 1.0);
          cr.fill();
        }
      }
    }
    cr.restore();

    return false;
  });

  // Update the changes of edited glyph
  glyph_editor.addOnButtonPress( (Event event, Widget widget) {
    if (event !is null) {
      auto x = cast(ushort) floor(event.button().x / (20.0 +1));
      auto y = cast(ushort) floor(event.button().y / (20.0 +1));

      if ( x < 1) { // First column
        font[selected*2] = font[selected*2] ^ cast(ushort)(1<<(y+8));
      } else if ( x < 2) { // Second column
        font[selected*2] = font[selected*2] ^ cast(ushort)(1<<y);
      } else if ( x < 3) { // Third column
        font[selected*2 +1] = font[selected*2 +1] ^ cast(ushort)(1<<(y+8));
      } else if ( x < 4) { // Fourth column
        font[selected*2 +1] = font[selected*2 +1] ^ cast(ushort)(1<<y);
      }

      dwa.queueDraw();
      update_editor();

      return true;
    }
    return false;
    /*
      for (int x; x < 2; x++) {
      for (int y; y <16; y++) {
        auto pos = 1<<y;
        r ~= "editor["~to!string(x)~"]["~to!string(y)~"]";
        r ~= ".addOnClicked( (Button b) {";
        r ~= " if (!updating) {";
        if (x != 1) {
          r ~= "  font[selected*2] = font[selected*2] ^ "~to!string(pos)~";";
        } else {
          r ~= "  font[selected*2 +1] = font[selected*2 +1] ^ "~to!string(pos)~";";
        }
        r ~= " dwa.queueDraw(); update_glyph_lbl;";
        r ~= " }";
        r ~= "});";
      }
    }
    */
  });

  builder.connectSignals (null); // This connect signals defiend on the builder with "extern (C) export" edifned functions
  mainwin.show ();

  Main.run();
}
