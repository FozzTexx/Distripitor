/* Copyright 2016 by Chris Osborn <fozztexx@fozztexx.com>
 * http://insentricity.com
 *
 * $Id$
 */

#import "Barcode.h"

#include <string.h>
#include <math.h>

#define MAXSTRIPWIDTH_MM	16.8
#define MAXSTRIPLENGTH_MM	241
#define MINBITWIDTH_MM		0.15
#define MINBITHEIGHT_MM		0.20

typedef struct __attribute__ ((packed)) {
  uint8_t data_sync;
  uint16_t expansion1;
  uint16_t length;
  uint8_t checksum;
  char strip_id[6];
  uint8_t sequence;
  uint8_t type;
  uint16_t expansion;
  uint8_t op_sys;
  uint8_t num_files;
} BarcodeFields;

typedef struct __attribute__ ((packed)) {
  uint8_t cauzin_type;
  uint8_t file_type;
  unsigned int length:24;
  char name[];
} BarcodeFileEntry;

typedef enum {
  StripStandard = 0,
  StripSpecialKey = 1,
} StripType;

typedef enum {
  OSGeneric = 0,
  OSCOLOS = 1,
  OSAppleDOS33 = 0x10,
  OSAppleProDOS = 0x11,
  OSAppleCPM2 = 0x12,
  OSMSDOS = 0x14,
  OSMacintosh = 0x15,
  OSReserved = 0x20,
} OpSys;

@implementation Barcode

-(id) init
{
  return [self initWithData:nil];
}

-(id) initWithData:(CLData *) aData
{
  [super init];
  data = [aData retain];
  density = 4;
  stripWidth = MAXSTRIPWIDTH_MM;
  [self calculatePixelWidth];
  bitmap = nil;
  return self;
}

-(void) dealloc
{
  [data release];
  [bitmap release];
  [super dealloc];
  return;
}

/* Barcode maximum width is 16.8mm - is narrower possible? */
/* Header height is 6mm */
/* Maximum length is 241mm including header */
/* Smallest dibit is 0.30mm W x 0.25mm H */
/* There's no required aspect ratio for a dibit, so how to calculate
   height? A predefined table? */
-(void) calculatePixelWidth
{
  double pxw;
  int rows;


  pixelWidth = 14; /* bits required for edge marks plus two parity dibits, 2 pixels each */
  pixelWidth += density * 8; /* 4 bits per nibble and 2 pixels per bit */
  pxw = stripWidth / pixelWidth;
  
  if (pxw < MINBITWIDTH_MM) {
    pixelWidth = stripWidth / MINBITWIDTH_MM;
    pixelWidth -= 14;
    density = pixelWidth / 8;
    pixelWidth = density * 8 + 14;
  }

  byteWidth = (pixelWidth + 7) / 8;
  rows = ([data length] * 2) / density;
  /* FIXME - leave room for headers */

  [bitmap release];
  bitmap = [[CLMutableData alloc] initWithLength:rows * byteWidth];

  bitHeight = stripWidth / pixelWidth;
  bitHeight *= MINBITHEIGHT_MM / MINBITWIDTH_MM;
  
  return;  
}

-(void) setDensity:(CLUInteger) aValue
{
  density = aValue;
  if (density < 4)
    density = 4;
  [self calculatePixelWidth];
  return;
}

-(void) insertPixelsAt:(int) aRow
{
  int i, j;
  unsigned char *bptr;
  int byte;
  int len;


  len = (pxlen + 1) * byteWidth;
  if (len > [bitmap length])
    [bitmap increaseLengthBy:byteWidth * 20];
  
  bptr = [bitmap mutableBytes] + aRow * byteWidth;
  len = (pxlen - aRow) * byteWidth;
  memmove(bptr + byteWidth, bptr, len);
  pxlen++;
  
  for (i = 0; i < pixelWidth; i += 8) {
    for (byte = j = 0; j < 8; j++) {
      byte <<= 1;
      if (i + j < pixelWidth)
	byte |= !pxbuf[i + j];
    }
    *(bptr + i / 8) = byte;
  }
  
  return;
}

-(void) appendPixels
{
  [self insertPixelsAt:pxrow];
  return;
}

-(void) appendData
{
  int parity, parlen, parpos;


  pxbuf[0] = pxbuf[1] = 0;
  pxbuf[2] = 1;
  pxbuf[3] = pxrow & 1;
  pxbuf[4] = !pxbuf[3];
  pxbuf[pixelWidth - 5] = pxbuf[pixelWidth - 4] = 1;
  pxbuf[pixelWidth - 3] = pxbuf[pixelWidth - 2] = 0;
  pxbuf[pixelWidth - 1] = pxbuf[4];

  for (parity = parpos = 0, parlen = density * 2; parpos < parlen; parpos++)
    parity += pxbuf[parpos * 4 + 7];
  pxbuf[pixelWidth - 7] = parity & 1;
  pxbuf[pixelWidth - 6] = !pxbuf[pixelWidth - 7];

  for (parity = parpos = 0, parlen = density * 2; parpos < parlen; parpos++)
    parity += pxbuf[parpos * 4 + 9];
  pxbuf[5] = parity & 1;
  pxbuf[6] = !pxbuf[5];

  [self appendPixels];
	
  return;
}

-(void) appendByte:(int) byte
{
  int clen;
  

  for (clen = 0; clen < 8; clen++) {
    pxbuf[pxcol * 2 + 7] = byte & 1;
    pxbuf[pxcol * 2 + 8] = !pxbuf[pxcol * 2 + 7];
    byte >>= 1;
    pxcol++;
    if (pxcol == density * 4) {
      [self appendData];
      pxrow++;
      pxcol = 0;
    }
  }

  return;
}

-(void) prependHeader
{
  int len;
  int i, c, clen;

  
  pxrow = 0;
  
  memset(pxbuf, 1, pixelWidth);
  for (i = 0; i < 2; i++) {
    pxbuf[i] = 0;
    pxbuf[pixelWidth - 4 + i] = 0;
  }
  for (i = 0; i < 6; i++) {
    pxbuf[4 + i] = 0;
    pxbuf[pixelWidth - 12 + i] = 0;
  }
  for (i = 0; i < density - 4; i++) {
    pxbuf[12 + i * 4] = pxbuf[13 + i * 4] = 0;
    pxbuf[pixelWidth - 16 - i * 4] = pxbuf[pixelWidth - 15 - i * 4] = 0;
  }

  len = ceil(2 / bitHeight);
  for (i = 0; i < len; i++, pxrow++)
    [self appendPixels];

  for (i = 0; i < density * 4; i += 8) {
    c = 0x80;
    for (clen = 0; clen < 8; clen++) {
      pxbuf[(i + clen) * 2 + 7] = c & 1;
      pxbuf[(i + clen) * 2 + 8] = !pxbuf[(i + clen) * 2 + 7];
      c >>= 1;
    }
  }

  len = ceil(4 / bitHeight);
  for (i = 0; i < len; i++, pxrow++)
    [self appendData];

  return;
}

-(void) print
{
  const unsigned char *bp;
  int c;
  int i, j;
  int clen;
  CLMutableData *mData;
  BarcodeFields *fields;
  BarcodeFileEntry *entry;
  CLString *filename;
  
  
  /* FIXME - make array of barcodes if there is too much data */

  pxbuf = malloc(pixelWidth);
  [self prependHeader];
  
  mData = [[CLMutableData alloc] initWithLength:sizeof(BarcodeFields)];
  fields = [mData mutableBytes];
  memset(fields, 0, sizeof(BarcodeFields));

  strncpy(fields->strip_id, "TICKET", 6);
  fields->sequence = 1;
  //fields->expansion = htole16(0x80);
  fields->op_sys = OSGeneric;
  fields->num_files = 1;

  {
    /* FIXME - loop through all files */
    clen = [mData length];
    filename = @"GoldenTicket.txt";
    i = sizeof(BarcodeFileEntry) + strlen([filename UTF8String]) + 2;
    [mData increaseLengthBy:i];
    entry = [mData mutableBytes] + clen;
    entry->cauzin_type = 0;
    entry->file_type = 0x00;
    entry->length = [data length];
    strcpy(entry->name, [filename UTF8String]);
    entry->name[strlen(entry->name)] = 0x00;

    /* Block Expand length goes right after filename & terminator */
    entry->name[strlen(entry->name) + 1] = 0;
  }

  [mData appendData:data];
  
  c = 0;
  bp = [mData bytes];
  for (i = 6, j = [mData length]; i < j; i++)
    c = ((c & 0xff) + *(bp + i) + (c >> 8)) & 0x1ff;

  fields = [mData mutableBytes];
  fields->length = [mData length] -
    (((size_t) &fields->checksum) - ((size_t) fields));
  fields->checksum = 0x100 - c;
  
  pxcol = 0;
  bp = [mData bytes];
  for (i = 0, j = [mData length]; i < j; i++)
    [self appendByte:*(bp + i)];

  if (pxcol)
    [self appendData];

  /* FIXME - add CRC */

  free(pxbuf);

  stripHeight = bitHeight * pxlen;
  fprintf(stderr, "Bit size: %fmm x %fmm\n", stripWidth / pixelWidth, bitHeight);
  fprintf(stderr, "Strip size: %fmm x %fmm\n", stripWidth, stripHeight);
  
  printf("P4\n");
  printf("%i %i\n", pixelWidth, pxlen);
  fwrite([bitmap bytes], [bitmap length], 1, stdout);
  
  return;
}

@end
