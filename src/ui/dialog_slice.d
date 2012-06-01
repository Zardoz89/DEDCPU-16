module ui.dialog_slice;

import gtk.Main, gtk.Builder, gtk.Widget, gtk.Window, gdk.Event;
import gtk.Container, gtk.Table;
import gtk.Label, gtk.Button, gtk.SpinButton;

import std.conv, std.algorithm;

public import gtkc.gtktypes, gtk.Dialog;

/**
 * Custom FileChooserDialog that select a file for open or save data for FCPU-16
 */
class dialog_slice : Dialog{
private:
  Builder builder;            /// Builder used to load from xml file the file options widget

  Label lbl_text;             /// Label showing informative text

  Label lbl_maxsize;          /// Max size (max diference) of the slice
  Label lbl_size;             /// Actual size (diference) of the slice
  SpinButton spin_begin;      /// Spin button selecting the begin address of a slice
  SpinButton spin_end;        /// Spin button selecting the end address of a slice

  size_t max_dif;             /// Max diference between adresses
  Adjustment adjust_beg_addr;  /// Controls begin address spin button
  Adjustment adjust_end_addr;  /// Controls end address spin button

public:

  /**
   * See: gtk.Dialog;
   * Params:
   *  text    = Texto to be showed over the controls describing what the user are to do
   *  size    = Max size of the slice selection
   */
  this (string title, Window parent, GtkDialogFlags flags, string text, size = 255 ) {
    this(title, parent, flags, [StockID.OK, StockID.Cancel], [ResponseType.GTK_RESPONSE_ACCEPT, ResponseType.GTK_RESPONSE_CANCEL]);

    max_dif = size;
    
    // Adds the text label
    lbl_text = new Label(text);
    this.getContentArea().packStart(lbl_text, false, true, 0);

    // Load widgets from file
    builder = new Builder ();
    if (! builder.addFromFile ("./src/ui/slice.ui")) {
      throw new Exception("Can't find file slice.ui");
    }
    
    // Gets every object
    auto table= cast(Table) builder.getObject ("table");
    if (table is null) {
      throw new Exception("Can't find table widget");
    }

    Label lbl_maxsize= cast(Label) builder.getObject ("lbl_maxsize");
    if (lbl_maxsize is null) {
      throw new Exception("Can't find lbl_maxsize widget");
    }

    Label lbl_size= cast(Label) builder.getObject ("lbl_size");
    if (lbl_size is null) {
      throw new Exception("Can't find lbl_size widget");
    }

    SpinButton spin_begin= cast(SpinButton) builder.getObject ("spin_begin");
    if (spin_begin is null) {
      throw new Exception("Can't find spin_begin widget");
    }

    SpinButton spin_end= cast(SpinButton) builder.getObject ("spin_end");
    if (spin_end is null) {
      throw new Exception("Can't find spin_end widget");
    }

    // Set and assigns attributes of each widget *******************************
    // Attach table container to the Dialog
    table.reparent(this);
    his.getContentArea().packEnd(table, false, true, 0);

    // Show max size and actual size
    lbl_maxsize.setText(to!string(max_dif));
    lbl_size.setText(to!string(max_dif) ~ words ~ " - "~to!string(floor(max_dif/2))~" glyphs");

    // Create the adjusment objects and assign it to the spin buttons
    adjust_beg_addr = new Adjustment(0, 0, size -1, 1 , 10, 0);
    adjust_end_addr = new Adjustment(1, 1, size , 1 , 10, 0);

    spin_begin.configure(adjust_beg_addr, 0, 0);
    spin_end.configure(adjust_end_addr, 0, 0);

    // Signal handlers *********************************************************
    // Begin of slice being edited
    adjust_beg_addr.addOnValueChanged( (Adjustment ad) {
      adjust_end_addr.setLower(min(ad.getValue() +1, max_dif));
      adjust_end_addr.setUpper(min(ad.getValue() +255, max_dif));
      if (adjust_end_addr.getValue() < (ad.getValue() +1)) {
        adjust_end_addr.setValue(ad.getValue() +1);
      }
      auto s = adjust_end_addr.getValue() - adjust_beg_addr.getValue() +1;
      lbl_size.setLabel(to!string(s)~" words"
         ~ " - "~to!string(floor(s/2))~" glyphs");
    });

    // End of slice being edited
    adjust_end_addr.addOnValueChanged( (Adjustment ad) {
      adjust_end_addr.setLower(adjust_beg_addr.getValue() +1);
      adjust_beg_addr.setUpper(max(ad.getValue() -1, 0));
      if (adjust_beg_addr.getValue() > (ad.getValue() -1)) {
        adjust_beg_addr.setValue(ad.getValue() -1);
      }
      auto s = adjust_end_addr.getValue() - adjust_beg_addr.getValue() +1;
      lbl_size.setLabel(to!string(s)~" words"
         ~ " - "~to!string(floor(s/2))~" glyphs");
    });
    
  }
}