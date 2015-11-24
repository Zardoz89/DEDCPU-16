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
  b2,     /// Base 2 binary data (0bxxxxxxxx_xxxxxxxx)
  dat     /// Assembly DATs (DAT 0x0000)
  }

/**
 * Load a file with a image of a RAM
 * Params:
 *  type = Type of file
 *  file = Name and path of the file
 * Returns a array with a raw binary image of the file
 */
ushort[] load_ram(TypeHexFile type, const string filename )
in {
  assert (filename.length >0, "Invalid filename");
} body {
  auto f = File(filename, "r");
  scope(exit) {f.close();}

  ushort[] img = new ushort[0];

  ulong i;
  if (type == TypeHexFile.lraw || type == TypeHexFile.braw) { // RAW binary file
    while (i < 0x10000 && !f.eof) {
      ubyte[2] buffer = [0, 0];
      if (f.rawRead(buffer).length == 0) {
        break; // EOF
      }

      if (type == TypeHexFile.lraw) { // little-endian
        img ~= littleEndianToNative!ushort(buffer);
      } else {
        img ~= bigEndianToNative!ushort(buffer);
      }
      i++;
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
      if (line.length < 1 || line[0] == ';') {
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
          img.length = cast(size_t)(tmp +1);

        if (word.length > 3) {
          img[cast(size_t)(tmp)] = parse!ushort(word, 16);
        }
      }
    }
  } else if (type == TypeHexFile.b2) { // plain ASCII list of numbers in base 2 (0bxxxxxxxx_xxxxxxxx)
    import std.algorithm;
    foreach ( line; f.byLine()) { // each line contains one or more words of 16 bit in hexadecimal
      // Keep alone the number in base 2
      line = chompPrefix(chompPrefix(line.strip(' '), "0B"), "0b");
      if (line.length < 16 ) {
        continue; // Skip line because it's a bad line (ushort -> 16 bits)
      }
      auto r = findSplit(line, ['_']);
      line = r[0] ~ r[2]; // Skips '_'

      img ~= parse!ushort(line, 2);
    }
  } else if (type == TypeHexFile.dat) { // assembly file that contains dat lines with code. Only process DAT lines
    foreach ( line; f.byLine()) {
      line = strip(line);
      if (line.length <= 0) {
        continue;
      }
      if (line[0] == '.') { // Handle the '.'
        line = line[1..$];
      }
      // dat dddd|0xhhhh
      if (line.length < 5 || (
            line[0..3] != "dat" && line[0..3] != "DAT" ) ) {
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

void save_ram(TypeHexFile type, const string filename , ushort[] img)
in {
  assert (filename.length >0, "Invalid filename");
  assert (img.length < 0x10000, "Invalid ram image");
} body {
  auto f = File(filename, "w");
  scope(exit) {f.close();}

  if (type == TypeHexFile.lraw || type == TypeHexFile.braw) { // RAW binary file
    foreach (word; img) {
      ubyte[2] dbyte = void;
      if (type == TypeHexFile.lraw) { // little-endian
        dbyte = nativeToLittleEndian!ushort(word);
      } else {
        dbyte = nativeToBigEndian!ushort(word);
      }
      f.rawWrite(dbyte);
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
      if (addr > 6 && ((addr+1) % 8) == 0) {
        f.writeln();
      }
    }
  } else if (type == TypeHexFile.b2) { // plain ASCII list of numbers in base 2 (0bxxxxxxxx_xxxxxxxx)
    foreach (word; img) {
      f.writeln(format("0b%b, ", word));
    }
  } else if (type == TypeHexFile.dat) { // assembly file that contains dat lines with code. Only process DAT lines
    foreach (word; img) {
      f.writeln(format("DAT %04X ", word));
    }
  } else {
    throw new Exception("Not implemented file type");
  }
}

