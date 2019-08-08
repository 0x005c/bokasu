import std.stdio, std.math, std.getopt, std.format, std.conv;
import imageformats;

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
    IFImage source  = read_image(inFileName); // autodetect color setting
    IFImage target;
    target.c = source.c;
    target.w = source.w;
    target.h = source.h;
    target.pixels.length = source.pixels.length;

    if(mode == "mosaic") mosaic(strength, source, target);
    else if(mode == "blur") blur(strength, source, target);
    // if invalid mode is set
    else {
      help(helpInformation);
      return;
    }

    // save image
    write_image(outFileName, target.w, target.h,
        target.pixels, target.c);
  }
}

// show help information
void help(ref GetoptResult helpInformation) {
  defaultGetoptPrinter("bokasu - A blur filter command",
    helpInformation.options);
}

// do mosaic processing
void mosaic(int strength, ref IFImage source, ref IFImage target) {
  ulong colorPerPixel  = source.pixels.length/(source.w*source.h);
  int squareSize = strength*2+1;

  ulong fromXY(int x, int y) {
    return colorPerPixel*(x+y*source.w);
  }

  for(int y=0; y<source.h; y++) {
    for(int x=0; x<source.w; x++) {
      for(int i=0; i<colorPerPixel; i++) {
        target.pixels[fromXY(x,y)+i] =
         source.pixels[fromXY(x-(x%squareSize),y-(y%squareSize))+i];
      }
    }
  }
}

void blur(int strength, ref IFImage source, ref IFImage target) {
  int[] bxs = boxesForGauss(strength,3);
  boxBlur(source, target, (bxs[0]-1)/2);
  boxBlur(source, target, (bxs[1]-1)/2);
  boxBlur(source, target, (bxs[2]-1)/2);
}

int[] boxesForGauss(float sigma, int n) {  // standard deviation, number of boxes
    float wIdeal = sqrt((12*sigma*sigma/n)+1);  // Ideal averaging filter width 
    int wl = to!int(floor(wIdeal));  if(wl%2==0) wl--;
    int wu = wl+2;

    float  mIdeal = (12*sigma*sigma - n*wl*wl - 4*n*wl - 3*n)/(-4*wl - 4);
    int m = to!int(round(mIdeal));

    int[] sizes = new int[n];  for(int i=0; i<n; i++) sizes[i] = i<m?wl:wu;
    return sizes;
}

void boxBlur(ref IFImage source, ref IFImage target, int r) {
  for(int i=0; i<source.pixels.length; i++) target.pixels[i] = source.pixels[i];
  // boxBlurH(target, source, r);
  boxBlurT(source, target, r);
}

void boxBlurH(ref IFImage source, ref IFImage target, int r) {
  float iarr = 1./(r+r+1);
  int colorPerPixel = to!int(source.pixels.length/(source.w*source.h));
  int w = source.w*colorPerPixel;
  int h = source.h;

  for(int i=0; i<h; i++) {
    int ti = i*w, li = ti, ri = ti+r;
    int fv = source.pixels[ti], lv = source.pixels[ti+w-1], val = (r+1)*fv;
    for(int j=0; j<=r; j+=4) {
      val += source.pixels[ri] - fv;
      target.pixels[ti] = to!ubyte(round(val*iarr));
      // ri += colorPerPixel; li += colorPerPixel;
      ri++; li++;
    }
    for(int j=r+1; j<w-r; j+=4) {
      val += source.pixels[ri] - source.pixels[li];
      target.pixels[ti] = to!ubyte(round(val*iarr));
      // ri += colorPerPixel; li += colorPerPixel; ti += colorPerPixel;
      ri++; li++; ti++;
    }
    for(int j=w-r; j<w; j+=4) {
      val += lv - source.pixels[li];
      target.pixels[ti] = to!ubyte(round(val*iarr));
      // li += colorPerPixel; ti += colorPerPixel;
      li++; ti++;
    }
  }
}

void boxBlurT(ref IFImage source, ref IFImage target, int r) {
  float iarr = 1./(r+r+1);
  int colorPerPixel = to!int(source.pixels.length/(source.w*source.h));
  int w = source.w*colorPerPixel;
  int h = source.h;

  for(int i=0; i<w; i++) {
    int ti = i, li = ti, ri = ti+r*w;
    int fv = source.pixels[ti], lv = source.pixels[ti+w*(h-1)], val = (r+1)*fv;
    for(int j=0; j<r; j++) val += source.pixels[ti+j*w];
    for(int j=0; j<=r; j++) {
      val += source.pixels[ri] - fv;
      target.pixels[ti] = to!ubyte(round(val*iarr));
      ri += w; ti += w;
    }
    for(int j=r+1; j<h-r; j++) {
      val += source.pixels[ri] - source.pixels[li];
      target.pixels[ti] = to!ubyte(round(val*iarr));
      li += w; ri += w; ti += w;
    }
    for(int j=w-r; j<w; j++) {
      val += lv - source.pixels[li];
      target.pixels[ti] = to!ubyte(round(val*iarr));
      li += w; ti += w;
    }
  }
}
