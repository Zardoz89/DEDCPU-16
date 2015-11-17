module ui.file_chooser;

import gtk.Main, gtk.Builder, gtk.Widget, gtk.Window, gdk.Event, gtk.Container;
import gtk.FileFilter, gtk.Expander, gtk.RadioButton, gtk.ToggleButton;
import gtk.Button;

import std.conv;

public import gtkc.gtktypes, gtk.FileChooserDialog;
import dcpu.ram_io;

/**
 * Custom FileChooserDialog that select a file for open or save data for FCPU-16
 */
class FileOpener : FileChooserDialog {
private:
  Builder builder;          /// Builder used to load from xml file the file options widget
  Container foptions;
  FileFilter[] filters;     /// File filters

  RadioButton rbut_hexdump; /// Radio button Hexdecimal Dump file
  RadioButton rbut_dat;     /// Radio button Assembler DATs file
  RadioButton rbut_base2;   /// Radio button for list of base 2 numbers
  RadioButton rbut_raw;     /// Radio buttion Binary RAW file

  RadioButton rbut_big;     /// Radio button for RAW big endian file
  RadioButton rbut_little;  /// Radio button for RAW little endian file

public:

  TypeHexFile type = TypeHexFile.hexd;

  /**
   * Params:
   *  father  = Father Window
   *  open    = TRUE if is choosing a file to open it. FALSE to save a file
   */
  this (Window father, bool open = true) {
    if (open) {
      super("Open file", father, FileChooserAction.OPEN, ["Open", "Cancel"], [ResponseType.ACCEPT, ResponseType.CANCEL]);
    } else {
      super("Save file", father, FileChooserAction.SAVE, ["Save", "Cancel"], [ResponseType.ACCEPT, ResponseType.CANCEL]);
    }

    builder = new Builder ();
    if (! builder.addFromFile ("./src/ui/file_chooser.ui")) {
      throw new Exception("Can't find file file_chooser.ui");
    }

    // Create file filters
    filters ~= new FileFilter();
    filters[0].setName("Hexdump file (*.hex)");
    filters[0].addPattern("*.hex");
    filters ~= new FileFilter();
    filters[1].setName("Assembler file (*.dasm|*.dasm16|*.asm)");
    filters[1].addPattern("*.dasm");
    filters[1].addPattern("*.dasm16");
    filters[1].addPattern("*.asm");
    filters ~= new FileFilter();
    filters[2].setName("Base2 dump (*.txt)");
    filters[2].addPattern("*.txt");
    filters ~= new FileFilter();
    filters[3].setName("Raw file (*.bin|*.raw)");
    filters[3].addPattern("*.bin");
    filters[3].addPattern("*.raw");
    filters ~= new FileFilter();
    filters[4].setName("All files");
    filters[4].addPattern("*");

    foreach (ref f; filters) // And add it
      this.addFilter(f);

    this.setCurrentFolderUri("/home/");

    // Get File options widget
    foptions = cast(Container) builder.getObject ("file_options");
    if (foptions is null) {
      throw new Exception("Can't find file_options widget");
    }

    foptions.reparent(this);
    this.setExtraWidget(foptions);

    // Try to grab radiobuttons
    rbut_hexdump = cast(RadioButton) builder.getObject ("rbut_hexdump");
    if (rbut_hexdump is null) {
      throw new Exception("Can't find rbut_hexdump widget");
    }
    rbut_dat = cast(RadioButton) builder.getObject ("rbut_dat");
    if (rbut_dat is null) {
      throw new Exception("Can't find rbut_dat widget");
    }
    rbut_base2 = cast(RadioButton) builder.getObject ("rbut_base2");
    if (rbut_base2 is null) {
      throw new Exception("Can't find rbut_base2 widget");
    }
    rbut_raw = cast(RadioButton) builder.getObject ("rbut_raw");
    if (rbut_raw is null) {
      throw new Exception("Can't find rbut_raw widget");
    }

    // Big & little endian
    rbut_big = cast(RadioButton) builder.getObject ("rbut_big");
    if (rbut_big is null) {
      throw new Exception("Can't find rbut_big widget");
    }
    rbut_little = cast(RadioButton) builder.getObject ("rbut_little");
    if (rbut_little is null) {
      throw new Exception("Can't find rbut_little widget");
    }

    // Setup buttons and state
    type = TypeHexFile.dat;
    rbut_dat.setActive(true);


    // Set what to do to the radio buttons
    rbut_hexdump.addOnToggled( (ToggleButton rbut) {
      if(rbut.getActive()) {
        rbut_big.setSensitive(false);
        rbut_little.setSensitive(false);
        this.setFilter(filters[0]);
        type = TypeHexFile.hexd;
      }
    });

    rbut_dat.addOnToggled( (ToggleButton rbut) {
      if(rbut.getActive()) {
        rbut_big.setSensitive(false);
        rbut_little.setSensitive(false);
        this.setFilter(filters[1]);
        type = TypeHexFile.dat;
      }
    });

    rbut_raw.addOnToggled( (ToggleButton rbut) {
      if(rbut.getActive()) {
        rbut_big.setSensitive(true);
        rbut_little.setSensitive(true);
        rbut_big.setActive(false);
        rbut_little.setActive(true);
        this.setFilter(filters[3]);
        type = TypeHexFile.lraw;
      }
    });

    rbut_base2.addOnToggled( (ToggleButton rbut) {
      if(rbut.getActive()) {
        rbut_big.setSensitive(false);
        rbut_little.setSensitive(false);
        this.setFilter(filters[2]);
        type = TypeHexFile.b2;
      }
    });

    rbut_big.addOnToggled( (ToggleButton rbut) {
      if(rbut.getActive()) {
        type = TypeHexFile.braw;
      }
    });

    rbut_little.addOnToggled( (ToggleButton rbut) {
      if(rbut.getActive()) {
        type = TypeHexFile.lraw;
      }
    });

  }

}
