import std.stdio, std.math, std.getopt, std.format;
import imageformats;

// TODO 引数をパースする　がんばってぼかす
void main(string[] args) {
  string mode = "blur"; // mosaic or blur
  int strength = 3;
  string inFileName = "";
  string outFileName = "";

  // parse arguments
  auto helpInformation = getopt(
      args,
      "mode|m", "Choose from mosaic or blur.", &mode,
      "strength|s", "Set filter strength.", &strength,
      "input|i", "Input file name.", &inFileName,
      "output|o", "Output file name.", &outFileName
      );

  // handle -h option
  if(helpInformation.helpWanted) {
    help(helpInformation);
    return;
  // open file, process image, and save file
  } else {
    IFImage inimage  = read_image(inFileName); // autodetect color setting
    IFImage outimage;

    if(mode == "mosaic") mosaic(strength, inimage, outimage);
    // else if(mode == "blur") blur(strength, inimage, outimage);
    // if invalid mode is set
    else {
      help(helpInformation);
      return;
    }

    // save image
    write_image(outFileName, outimage.w, outimage.h,
        outimage.pixels, outimage.c);
  }
}

// show help information
void help(ref GetoptResult helpInformation) {
  defaultGetoptPrinter("bokasu - A blur filter command",
    helpInformation.options);
}

// do mosaic processing
void mosaic(int strength, ref IFImage inimage, ref IFImage outimage) {
  outimage.c = inimage.c;
  outimage.w = inimage.w;
  outimage.h = inimage.h;
  outimage.pixels.length = inimage.pixels.length;
  ulong colorPerPixel    = inimage.pixels.length/(inimage.w*inimage.h);
  int squareSize = strength*2+1;

  ulong fromXY(int x, int y) {
    return colorPerPixel*(x+y*inimage.w);
  }

  for(int y=0; y<inimage.h; y++) {
    for(int x=0; x<inimage.w; x++) {
      for(int i=0; i<colorPerPixel; i++) {
        outimage.pixels[fromXY(x,y)+i] =
         inimage.pixels[fromXY(x-(x%squareSize),y-(y%squareSize))+i];
      }
    }
  }
}
