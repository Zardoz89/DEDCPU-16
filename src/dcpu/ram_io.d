/**
 * RAM dump loader/saver
 */
module dcpu.ram_io;

import std.c.stdlib, std.stdio, std.bitmanip, std.conv, std.array, std.string;

/// Type of machine code file
enum TypeHexFile {
  lraw,   /// Little-endian raw binary file
  braw,   /// Big-endian raw binary file
  ahex,   /// Hexadecimal ASCII file
  hexd,   /// Hexadecimal ASCII dump file
  dat     /// Assembly DATs
  }; 

/**
 * Load a file with a image of a RAM
 * Params:
 *  type = Type of file
 *  file = Name and path of the file
 * Returns a array with a raw binary image of the file
 */
ushort[] load_ram(TypeHexFile type)(const string filename )
in {
  assert (filename.length >0, "Invalid filename");
} body {
  auto f = File(filename, "r");
  scope(exit) {f.close();}

  ushort[] img = new ushort[0];

  ulong i;
  static if (type == TypeHexFile.lraw || type == TypeHexFile.braw) { // RAW binary file
    for (;i < 0x10000 && !f.eof; i++) {
      ubyte[2] word = void;
      f.rawRead(word);
      static if (type == TypeHexFile.lraw) { // little-endian
        img ~= littleEndianToNative!ushort(word);
      } else {
        img ~= bigEndianToNative!ushort(word);
      }
    }
  } else if (type == TypeHexFile.ahex) { // plain ASCII hex file
    foreach ( line; f.byLine()) { // each line only have a hex 16-bit word
      if (i >= 0x1000)
        break;
      img ~= parse!ushort(line, 16);
      i++;
    }
  } else if (type == TypeHexFile.hexd) { // plain ASCII hex dump file
    foreach ( line; f.byLine()) { // each line contains one or more words of 16 bit in hexadecimal
      if (line[0] == ';') {
        continue; // Skip line, becasue it's a comment
      }
      
      auto words = split(strip(line));      
      if (words.length < 2 || words[0].length < 4) {
        throw new Exception("Bad format. Expected Addr: hexdata");
      }
      
      if (words[0][0..2] == "0x" || words[0][0..2] == "0X")
        words[0] = words[0][2..$];
      ushort addr = parse!ushort(words[0], 16);
      
      i=0;
      foreach (word; words[1..$]) {
        auto tmp = addr + i++;
        if (tmp >= 0x10000) // Out of bounds
          throw new Exception("Bad format. Data out of bounds " ~ format("0x%04X", tmp));
        
        if (img.length <= tmp)
          img.length = tmp +1;
        
        if (word.length > 3) {
          img[tmp] = parse!ushort(word, 16);          
        }
      }
    }
  } else if (type == TypeHexFile.dat) { // assembly file that contains dat lines with code. Only process DAT lines
    foreach ( line; f.byLine()) {
      line = strip(line);
      // dat dddd or dat 0xhhhh
      if (line.length < 5 || line[0..3] != "dat" && line[0..3] != "DAT") {
        continue; // Skip line
      }
      
      auto words = split(line[4..$], ",");
      if (words.length < 1 ) {
        throw new Exception("Bad format. DAT without data");
      }
     
      foreach (word; words) {
        if (img.length >= 0x10000) // Out of bounds
          throw new Exception("Bad format. Data out of bounds " ~ format("0x%04X", img.length));
        word = strip(word);
        if (word.length > 3 && (word[0..2] == "0x" || word[0..2] == "0X")) {
          word = word[2..$];
          img ~= parse!ushort(word, 16);
        } else if (word.length > 1) {
          img ~= parse!ushort(word, 10);
        }
      }
    }
  } else {
    throw new Exception("Not implemented file type");
  }
  return img;
}

alias load_ram!(TypeHexFile.lraw) load_lraw;
alias load_ram!(TypeHexFile.braw) load_braw;
alias load_ram!(TypeHexFile.ahex) load_ahex;
alias load_ram!(TypeHexFile.hexd) load_hexd;

void save_ram(TypeHexFile type)(const string filename , ushort[] img)
in {
  assert (filename.length >0, "Invalid filename");
  assert (img.length < 0x10000, "Invalid ram image");
} body {
  auto f = File(filename, "w");
  scope(exit) {f.close();}

  static if (type == TypeHexFile.lraw || type == TypeHexFile.braw) { // RAW binary file
    for(ind = 0; ind < img.length; ind += 2) {
      ubyte[2] dword = [img[ind], 0];
      if (ind +1 < img.length)
         dword[1] = img[ind +1];
         
      static if (type == TypeHexFile.lraw) { // little-endian
        dword = nativeToLittleEndian!ushort(dword);
      } else {
        dword = nativeToBigEndian!ushort(dword);
      }
      f.write(dword);
    }
  } else if (type == TypeHexFile.ahex) { // plain ASCII hex file
    foreach ( word; img) { // each line only have a hex 16-bit word
      f.writeln(format("%04X", word));
    }
  } else if (type == TypeHexFile.hexd) { // plain ASCII hex dump file
    foreach (addr ,word; img) {
      if ((addr % 8) == 0) {
        f.write(format("0x%04X: ", addr));
      }
      f.write(format("%04X ", word));
      if (addr != 0 && ((addr-1) % 8) == 0) {
        f.writeln();
      }
    }
  } else {
    throw new Exception("Not implemented file type");
  }
}
