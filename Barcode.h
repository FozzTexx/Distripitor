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

#import <ClearLake/ClearLake.h>

@interface Barcode:CLObject
{
  CLData *data;
  CLUInteger density;
  CLUInteger pixelWidth;
  double stripWidth, stripHeight; /* in mm */
  double bitHeight;
  CLMutableData *bitmap;
  CLUInteger byteWidth;

  char *pxbuf;
  int pxcol, pxrow, pxlen;
}

-(id) init;
-(id) initWithData:(CLData *) aData;
-(void) dealloc;

-(void) calculatePixelWidth;
-(void) setDensity:(CLUInteger) aValue;

-(void) print;

@end
