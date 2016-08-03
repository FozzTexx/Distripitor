/* Copyright 2016 by Chris Osborn <fozztexx@fozztexx.com>
 * http://insentricity.com
 *
 * $Id$
 */

#import <ClearLake/ClearLake.h>

@interface Barcode:CLObject
{
  CLData *data;
  CLUInteger density;
  CLUInteger pixelWidth;
  double stripWidth, stripHeight; /* in mm */
  CLMutableData *bitmap;
  CLUInteger byteWidth;

  char *pxbuf;
  int pxcol, pxrow;
}

-(id) init;
-(id) initWithData:(CLData *) aData;
-(void) dealloc;

-(void) calculatePixelWidth;
-(void) setDensity:(CLUInteger) aValue;

-(void) print;

@end
