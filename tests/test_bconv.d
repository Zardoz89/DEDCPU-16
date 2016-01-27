#!/usr/bin/env rdmd

import std.stdio, std.file, std.process, std.algorithm;
import std.path : buildNormalizedPath;
import std.exception;

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
std.typecons.Tuple!(int, "status", string, "output")[string] test;


int main () {
  auto cwd = getcwd(); // Should be on ./tests/
  auto exe = buildNormalizedPath(cwd, "../bconv");
  version (windows) {
    exe ~= ".exe";
  }

  writeln("CWD : ", cwd);
  writeln("Executable : ", exe);

  mixin (testFromlRawTo("lraw", lrawTo));

  return 0;
}

/// Meta : Generates a single test
string writeTestOut(int number, string iFmt, string oFmt) {
  import std.conv;
  auto post = "_"~iFmt~"_"~oFmt;

  return `
  test["`~ post  ~`"] = execute([exe, "rand_input.`~iFmt~`", "test`~ number.to!string ~`.out", "-i", "`~iFmt~`", "-o", "`~oFmt~`"]);
  enforce(test["`~ post  ~`"].status == 0, "Error executing bconv. lraw->lraw" ~ test["`~ post  ~`"].output);
  writeln("Test from `~iFmt~` to `~oFmt~` \t-> test`~ number.to!string ~`.out running");
  `;
}

/// Meta : Generates a batery of tests
string testFromlRawTo(string iFmt, string[] fmts) {
  string ret = "";
  foreach (int i, string fmt ; lrawTo) {
    ret ~= writeTestOut(i, iFmt, fmt);
  }
  return ret;
}
