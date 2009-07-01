/* gcc -std=c99 -o brightness -framework Cocoa -framework DisplayServices -F/System/Library/PrivateFrameworks brightness.m */

#import <Foundation/Foundation.h>
#include <crt_externs.h>

@interface O3Manager : NSObject
+ (void)initialize;
+ (id)engineOfClass:(NSString *)cls forDisplayID:(CGDirectDisplayID)fp12;
@end

@protocol O3EngineWireProtocol
@end

@protocol BrightnessEngineWireProtocol <O3EngineWireProtocol>
- (float)brightness;
- (BOOL)setBrightness:(float)fp8;
- (void)bumpBrightnessUp;
- (void)bumpBrightnessDown;
@end

const int kMaxDisplays = 16;

#define APP_NAME *(_NSGetProgname())

void errexit(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  fprintf(stderr, "%s: ", APP_NAME);
  vfprintf(stderr, fmt, ap);
  fprintf(stderr, "\n");
  exit(1);
}

void usage() {
  fprintf(stderr, "usage: %s [-m|-d display] [-v] <brightness>\n", APP_NAME);
  fprintf(stderr, "   or: %s -l [-v]\n", APP_NAME);
  exit(1);
}

int main(int argc, char * const argv[]) {
  if (argc == 1)
    usage();
  
  BOOL verbose = NO;
  unsigned long displayToSet = 0;
  enum { ACTION_LIST, ACTION_SET_ALL, ACTION_SET_ONE } action = ACTION_SET_ALL;
  extern char *optarg;
  extern int optind;
  int ch;

  while ( (ch = getopt(argc, argv, "lmvd:")) != -1) {
    switch (ch) {
    case 'l':
      if (action == ACTION_SET_ONE) usage();
      action = ACTION_LIST;
      break;
    case 'v':
      verbose = YES;
      break;
    case 'm':
      if (action != ACTION_SET_ALL) usage();
      action = ACTION_SET_ONE;
      displayToSet = (unsigned long)CGMainDisplayID();
      break;
    case 'd':
      if (action != ACTION_SET_ALL) usage();
      action = ACTION_SET_ONE;
      errno = 0;
      displayToSet = strtoul(optarg, NULL, 0);
      if (errno == EINVAL || errno == ERANGE)
	errexit("display must be an integer index (0) or a hexadecimal ID (0x4270a80)");
      break;
    default: usage();
    }
  }
  
  argc -= optind;
  argv += optind;

  float brightness;
  if (action == ACTION_LIST) {
    if (argc > 0) usage();
  } else {
    if (argc != 1) usage();

    errno = 0;
    brightness = strtof(argv[0], NULL);
    if (errno == ERANGE)
      usage();
    if (brightness < 0 || brightness > 1)
      errexit("brightness must be between 0 and 1");
  }

  [[NSAutoreleasePool alloc] init];
  [O3Manager initialize];

  CGDirectDisplayID display[kMaxDisplays];
  CGDisplayCount numDisplays;
  CGDisplayErr err;
  err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
  if (err != CGDisplayNoErr)
    errexit("cannot get list of displays (error %d)\n", err);

  for (CGDisplayCount i = 0; i < numDisplays; ++i) {
    CGDirectDisplayID dspy = display[i];
    CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
    if (originalMode == NULL)
      continue;

    if (action == ACTION_LIST) {
      printf("display %d: ", i);
      if (CGMainDisplayID() == dspy)
	printf("main display, ");
      printf("ID 0x%x\n", (unsigned int)dspy);
      if (verbose) {
        puts([[(NSDictionary *)originalMode description] UTF8String]);
      }
    }

    if ([[(NSDictionary *)originalMode objectForKey: @"RefreshRate"] intValue] != 0)
      continue;

    id<BrightnessEngineWireProtocol> engine =
      [O3Manager engineOfClass: @"BrightnessEngine" forDisplayID: dspy];

    switch (action) {
    case ACTION_SET_ONE:
      if ((CGDirectDisplayID)displayToSet != dspy && displayToSet != i)
	continue;
    case ACTION_SET_ALL:
      [engine setBrightness: brightness];
      if (!verbose) continue;
    case ACTION_LIST:
      printf("display %d: brightness %f\n", i, [engine brightness]);
    }
  }
  return 0;
}
