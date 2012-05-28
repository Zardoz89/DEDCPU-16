/**
 * DEDCPU-16 Binary file converter
 */
import std.stdio, std.getopt, std.algorithm, std.string, std.conv;

import core.thread, std.c.stdlib;


import dcpu.ram_io;

void showhelp() {
  stderr.writeln(import("help_bconv.txt"));
}

int main (string[] args) {
  if (args.length < 3) { // No params
    showhelp();
    return -1;
  }
  
  bool help; // Show help
  size_t start; size_t end = ushort.max;
  TypeHexFile ifile_fmt; // Input file format
  TypeHexFile ofile_fmt = TypeHexFile.hexd; // Output file format
  
  // Process arguements 
  getopt(
    args,
    "b", &start,
    "e", &end,
    "itype|i", &ifile_fmt,
    "otype|o", &ofile_fmt,
    "h|?", &help);

  if (help) {
    showhelp();
    return 0;
  }
  
  string ifilename = args[1];
  string ofilename = args[2];
  
  if (ifilename.length == 0) {
    stderr.writeln("Missing input file");
    return -1;
  }

  if (ofilename.length == 0) {
    stderr.writeln("Missing output file");
    return -1;
  }
  
  ushort[] data;
  // Load data
  if (ifile_fmt == TypeHexFile.lraw) {
    data = load_lraw(ifilename);
  } else if (ifile_fmt == TypeHexFile.braw) {
    data = load_braw(ifilename);
  } else if (ifile_fmt == TypeHexFile.ahex) {
    try {
      data = load_ahex(ifilename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file?");
      return -1;
    }
  } else if (ifile_fmt == TypeHexFile.hexd) {
    try {
      data = load_hexd(ifilename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file? ", e.msg);
      return -1;
    }
  } else if (ifile_fmt == TypeHexFile.b2) {
    try {
      data = load_b2(ifilename);
    } catch (ConvException e){
      stderr.writeln("Error: Bad file format\nCould be a binary file? ", e.msg);
      return -1;
    }
  } else {
    stderr.writeln("Error: Invalid input format");
    return -1;
  }

  end = end < data.length ? end : data.length; // Clamp between 0 to 0xFFFF
  start = start < ushort.max ? start : ushort.max;
  if (start > end || start > data.length || start == end) {
    stderr.writeln("Error: Invalid ranges");
    stderr.writeln("\tBegin: ", start,"\n\tEnd: ", end,"\n\tData dump size: ",data.length);
    return -1;
  }
  data = data[start..end]; // Slice

  // Save data
  try {
    if (ofile_fmt == TypeHexFile.lraw) {
      save_lraw(ofilename, data);
    } else if (ofile_fmt == TypeHexFile.braw) {
      save_braw(ofilename, data);
    } else if (ofile_fmt == TypeHexFile.ahex) {
      save_ahex(ofilename, data);
    } else if (ofile_fmt == TypeHexFile.hexd) {
      save_hexd(ofilename, data);
    } else if (ofile_fmt == TypeHexFile.b2) {
      save_b2(ofilename, data);
    } else if (ofile_fmt == TypeHexFile.dat) {
      save_dat(ofilename, data);
    } else {
      stderr.writeln("Error: Invalid output format");
      return -1;
    }
  } catch (Exception e) {
    stderr.writeln("Error: Coulnd save output data\n", e.msg);
    return -1;
  }

  return 0;
}
