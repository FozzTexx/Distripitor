/* Copyright 2016 by Chris Osborn <fozztexx@fozztexx.com>
 * http://insentricity.com
 *
 * $Id$
 */

#import "Barcode.h"

int main(int argc, char *argv[])
{
  CLAutoreleasePool *pool;
  int count;
  Barcode *barcode;
  CLData *aData;


  pool = [[CLAutoreleasePool alloc] init];

  count = CLGetArgs(argc, argv, @"");

  if (count < 0 || (argc - count) != 1) {
    if (count < 0 && -count != '-')
      fprintf(stderr, "Bad flag: %c\n", -count);
    fprintf(stderr, "Usage: %s [-flags] <file>\n"
	                "Flags are:\n"
	    , *argv);
    exit(1);
  }

  aData = [CLData dataWithContentsOfFile:[CLString stringWithUTF8String:argv[count]]];
  barcode = [[Barcode alloc] initWithData:aData];
  [barcode setDensity:12];
  [barcode print];
  
  [pool release];
  exit(0);
}
