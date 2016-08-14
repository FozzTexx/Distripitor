/* Copyright 2016 by Chris Osborn <fozztexx@fozztexx.com>
 * http://insentricity.com
 *
 * This file is part of Distripitor.
 *
 * ninepin is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * ninepin is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with ninepin; see the file COPYING. If not see
 * <http://www.gnu.org/licenses/>.
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
