#!/usr/bin/env rdmd

import std.stdio, std.file, std.process, std.algorithm;
import std.path : buildNormalizedPath;
import std.typecons : Tuple;
import std.exception;

string cwd, exe;

/// Tests reading from lraw to X
enum lrawTo= [
  "lraw",
  "braw",
  "ahex",
  "hexd",
  "b2",
  "dat",
];

/// Test execution result
Tuple!(int, "status", string, "output")[string] test;


int main () {
  cwd = getcwd(); // Should be on root dir of repository
  version (windows) {
    exe = buildNormalizedPath(cwd, "./bconv") ~  ".exe";
  } else {
    exe = buildNormalizedPath(cwd, "./bconv");
  }

  writeln("CWD : ", cwd);
  writeln("Executable : ", exe);

  foreach (int i, string fmt ; lrawTo) {
    doTestOut(i, "lraw", fmt);
  }

  return 0;
}

/// Execute a single test
void doTestOut(int number, string iFmt, string oFmt) {
  import std.conv;
  auto post = "_"~iFmt~"_"~oFmt;
  auto inpFilename = buildNormalizedPath( cwd, "./tests/rand_input." ~ iFmt);
  auto outFilename = "test" ~ number.to!string ~ ".out";
  auto testFilename = buildNormalizedPath( cwd, "./tests/rand_input." ~ oFmt);

  // Execute the program
  test[post] = execute([exe, inpFilename, outFilename, "-i", iFmt, "-o", oFmt]);
  enforce(test[post].status == 0, "Error executing bconv. "~iFmt~" to "~oFmt~" : " ~ test[post].output);
  writeln("Test from "~iFmt~" to "~oFmt~" \t-> test" ~ number.to!string ~ ".out running");

  // Opening the ouput file and referecne file
  auto fTest = File(testFilename, "r");
  scope(exit) {
    fTest.close();
  }

  auto fOut = File(outFilename, "r");
  scope(exit) {
    fOut.close();
  }

  auto outData = fOut.byChunk(4096).joiner;
  auto testData = fTest.byChunk(4096).joiner;

  // Compare both files
  int pos = 0;
  foreach (ubyte test; testData) {
    ubyte outbyte = outData.front;
    enforce (outbyte == test, "Output files is different!\n Expected value " ~ test.to!string ~ " at pos: " ~ pos.to!string ~
        " but obtained " ~ outbyte.to!string);

    outData.popFront;
    pos++;
  }
}

