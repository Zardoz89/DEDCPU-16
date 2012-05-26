module lem1802_fontview;
import gtk.Main, gtk.Builder, gtk.Widget, gtk.Window, gdk.Event, gtk.Container;
import gtk.MainWindow, gtk.AboutDialog;
import gtk.FileFilter, gtk.Expander, gtk.RadioButton, gtk.ToggleButton;
import gtk.Button, gtk.Label, gtk.MenuBar, gtk.MenuItem;
import gtkc.gtktypes;

import std.c.process, std.stdio, std.conv;

import ui.file_chooser;
import dcpu.ram_io;

string filename;  // Open file
TypeHexFile type; // Type of file
Window mainwin;   // Main window

ushort[255] font;

extern (C) void on_close (Event event, Widget widget) {
  Main.exit(0);
}

extern (C) void on_mnu_open_activate  (Event event, Widget widget) {
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
      writeln(font);
    }
  }
  opener.hide();
  opener.destroy();
}

void main(string[] args) {
  Main.init(args);

  auto builder = new Builder ();

  if (! builder.addFromFile ("./src/ui/fview.ui")) {
    writefln("Oops, could not create Builder object, check your builder file ;)");
    exit(1); 
  }
  
  mainwin = cast(Window)builder.getObject ("win_fontview");
  if (mainwin is null) {
    writefln("No window?");
    exit(1); 
  }

  builder.connectSignals (null);

  mainwin.show ();
  
  Main.run();
}
