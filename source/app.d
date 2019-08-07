import std.stdio, std.math, std.getopt;
import imageformats;

// TODO 引数をパースする　がんばってぼかす
void main(string[] args) {
  string mode = "blur"; // mosaic or blur or shrink
  int strength = 4;
  string inFileName = "";
  string outFileName = "";
  auto helpInformation = getopt(
      args,
      "mode|m", &mode,
      "strength|s", &strength, // strength of mosaic (or blur or shrink)
      "input|i", &inFileName,
      "output|o", &outFileName
      );
}
