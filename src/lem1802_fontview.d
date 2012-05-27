module lem1802_fontview;
import gtk.Main, gtk.Builder, gtk.Widget, gtk.Window, gdk.Event, gtk.Container;
import gtk.MainWindow, gtk.AboutDialog;
import gtk.Button, gtk.Label, gtk.MenuBar, gtk.MenuItem, gtk.ToggleButton;
import gtkc.gtktypes, glib.ListG;

import gtk.DrawingArea, gdk.Drawable;
import gdk.Color;
import cairo.Context, cairo.Surface;

import std.c.process, std.stdio, std.conv, std.math;

import ui.file_chooser;
import dcpu.ram_io;

string filename;            // Open file
TypeHexFile type;           // Type of file
Window mainwin;             // Main window

ushort[256] font;           // Font data
size_t selected;            // Selected gryph

DrawingArea dwa;            // Drawing widget
enum double min_width = 4*4*32+30;  // Min width of drawing widget
enum double min_height = 8*4*4+3;   // Min height of drawing widget

Label lbl_pos;              // Label with selected glyph position

ToggleButton[16][2] editor; // Editor toggle buttons

/**
 * Close the App when it's clicked the close byutton or menu exit option
 */
extern (C) void on_close (Event event, Widget widget) {
  Main.exit(0);
}

/**
 * Click over Previus button
 */
extern (C) void on_but_prev_clicked (Event event, Widget widget) {
  selected = (selected -1) % 128;
  lbl_pos.setLabel(to!string(selected));
  updated_editor();
  dwa.queueDraw();
}

/**
 * Click over Previus button
 */
extern (C) void on_but_next_clicked (Event event, Widget widget) {
  selected = (selected +1) % 128;
  lbl_pos.setLabel(to!string(selected));
  updated_editor();
  dwa.queueDraw();
}

/**
 * Muestra la ventanta de selecionar un fichero y lo abre
 */
extern (C) void on_mnu_open_activate (Event event, Widget widget) {
  auto opener = new FileOpener(mainwin);
  auto response = opener.run();
  if (response == ResponseType.GTK_RESPONSE_ACCEPT) {
    filename = opener.getFilename();
    type = opener.type;

    ushort[] tmp;
    if (filename !is null && filename.length > 0){
      switch (type) {
        case TypeHexFile.lraw:
          tmp = load_lraw(filename);
          break;

        case TypeHexFile.braw:
          tmp = load_braw(filename);
          break;
          
        case TypeHexFile.dat:
          tmp = load_dat(filename);
          break;

        case TypeHexFile.b2:
          tmp = load_ram!(TypeHexFile.b2)(filename);
          break;
          
        case TypeHexFile.hexd:
        default:
          tmp = load_hexd(filename);
          //break;
      }
      
      if (tmp.length >= 255) {
        font[0..$] = tmp[0..255];
      } else {
        font[0..tmp.length] = tmp[0..tmp.length];
        font[tmp.length..$] = 0;
      }
      // Updates GUI
      selected = 0;
      updated_editor();
      dwa.queueDraw();
    }
  }
  opener.hide();
  opener.destroy();
}

/**
 * Update the state of the editor buttons
 */
void updated_editor() {
  for (int x; x < 2; x++) {
    for (int y; y < 16; y++) {
      editor[x][y].setActive(( font[selected*2+x] & (1<<y)) != 0);
    }
  }
}

/**
 * Meta-function that gets all glyph editor buttons
 */
string get_editor_buttons() {
  string r;
  for (int x; x < 2; x++) {
    for (int y; y <16; y++) {
      r ~= "editor[" ~ to!string(x) ~"][" ~ to!string(y) ~"] = ";
      r ~= "cast(ToggleButton)  builder.getObject(\"p";
      if (x == 0) {
        r ~= "l"~ to!string(y);
      } else {
        r ~= "u"~ to!string(y);
      }
      r ~= "\"); ";
    }
  }

  return r;
}

void main(string[] args) {
  int old_w, old_h;
  Main.init(args);

  auto builder = new Builder ();

  if (! builder.addFromFile ("./src/ui/fview.ui")) {
    writefln("Oops, could not create Builder object, check your builder file ;)");
    exit(1); 
  }
  
  mainwin = cast(Window) builder.getObject ("win_fontview");
  if (mainwin is null) {
    writefln("Can't find win_fontview widget");
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
  
  auto glyph_editor = cast(Widget) builder.getObject ("glyph_editor");
  if (glyph_editor !is null) {
    glyph_editor.modifyFg(GtkStateType.NORMAL, Color.black);
  }
  
  dwa.modifyBg(GtkStateType.NORMAL, Color.black);
  
  mixin(get_editor_buttons()); // Get all editor buttons

  dwa.addOnButtonPress ( (GdkEventButton *event, Widget widget) {
    if (event !is null) {
      Drawable dr = dwa.getWindow();
      int width;
      int height;
      dr.getSize(width, height);
    
      double x = event.x *(min_width / width);   // Scales coords to be the same
      double y = event.y *(min_height / height); // always with diferent geometry

      x = floor(x / (4.0*4.0 +1));
      y = floor(y / (8.0*4.0 +1));
      selected = (to!size_t(x+ y*32)%128);

      writeln(selected);
      lbl_pos.setLabel(to!string(selected));
      dwa.queueDraw();
      updated_editor();
      
      return true;
    }
    return false;
  });

  // TODO Add a event for each editor button that updates array element data
  
  dwa.addOnExpose( (GdkEventExpose* event, Widget widget) {
    Drawable dr = dwa.getWindow();

    int width;
    int height;

    dr.getSize(width, height);

    // Calcs sizes ans factor scale    
    double scale_x = width / min_width;
    double scale_y = height / min_height;
    
    auto cr = new Context (dr);

    if (event !is null) {
      // clip to the area indicated by the expose event so that we only redraw
      // the portion of the window that needs to be redrawn
      cr.rectangle(event.area.x, event.area.y,
        event.area.width, event.area.height);
      cr.clip();
    
    
      cr.scale(scale_x, scale_y);
      cr.translate(0, 0);

      debug { // Test Pattern
        cr.rectangle(0, 0, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
        cr.rectangle(4, 4, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
        cr.rectangle(8, 8, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
        cr.rectangle(12, 12, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();

        cr.rectangle(17, 16, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
        cr.rectangle(21, 20, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
        cr.rectangle(25, 24, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
        cr.rectangle(29, 28, 4, 4);
        cr.setSourceRgb(1.0, 1.0, 1.0);
        cr.fill();
      }

      // Draw font
      cr.save();
      for (size_t i; i< font.length; i++) {
        for (ushort p; p < 16; p++) { // Y loops each pixel of a glyph
          if(( font[i] & (1<<p)) != 0) {
            double x = (1.0 - floor(p / 8.0))*4.0;
            x += (i%64)*8 + floor((i%64) / 2.0);
            double y = (p % 8)*4.0;
            y += floor(i / 64.0)*33;
            cr.rectangle(x, y, 4, 4);
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
        for (auto y = 33.0; y< 33*4; y+=33) {
          cr.moveTo(0, y);
          cr.lineTo(min_width, y);
        }
        for (auto x = 17.0; x< 17*32; x+=17) {
          cr.moveTo(x, 0);
          cr.lineTo(x, min_height);
        }
        cr.stroke();

      cr.restore();

      // Draw rectangle around selected glyph
      cr.save();
        cr.setSourceRgb(0, 1.0, 0);
        cr.setLineWidth(1.5);
        double x = (selected%32)*16 + (selected%32);
        double y = floor(selected / 32.0)*33;
        cr.rectangle(x, y, 4*4, 8*4);
        cr.stroke();

      cr.restore();
    }
    return false;
  });

  builder.connectSignals (null);
  mainwin.show ();
  
  Main.run();
}
