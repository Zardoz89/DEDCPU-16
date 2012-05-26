module lem1802_fontview;
import gtk.Main, gtk.Builder, gtk.Widget, gtk.Window, gdk.Event, gtk.Container;
import gtk.MainWindow, gtk.AboutDialog, gtk.FileChooserDialog;
import gtk.FileFilter, gtk.Expander, gtk.RadioButton, gtk.ToggleButton;
import gtk.Button, gtk.Label, gtk.MenuBar, gtk.MenuItem;
import gtkc.gtktypes;

import std.c.process, std.stdio, std.conv;

import ui.file_chooser;


extern (C) void on_win_fontview_destroy (Event event, Widget widget) {
  Main.exit(0);
}

void main(string[] args) {
  Main.init(args);

  auto builder = new Builder ();

  if (! builder.addFromFile ("./src/ui/fview.ui")) {
    writefln("Oops, could not create Builder object, check your builder file ;)");
    exit(1); 
  }
  
  Window w = cast(Window)builder.getObject ("win_fontview");
  if (w is null) {
    writefln("No window?");
    exit(1); 
  }

  FileOpener w2 = new FileOpener(w);

  builder.connectSignals (&on_win_fontview_destroy);

  w.show ();
  
  w2.run();
  w2.hide();
  writeln(w2.getFilename() ," " ,w2.type);
  Main.run();
}
