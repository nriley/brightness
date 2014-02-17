/* clang -o brightness -framework Cocoa -framework DisplayServices -F/System/Library/PrivateFrameworks -Wl,-U,_CGDisplayModeGetPixelWidth -Wl,-U,_CGDisplayModeGetPixelHeight -mmacosx-version-min=10.6 brightness.m

   Does not compile with OS X 10.8 or newer SDK.

   For the 10.6 SDK, compile with -isysroot /path/to/MacOSX10.6.sdk.

   For the 10.7 SDK, compile with -arch i386 -isysroot /path/to/MacOSX10.7.sdk.
   (x86_64 will compile but crashes.)
*/


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

/* 10.8+ */
extern size_t CGDisplayModeGetPixelWidth(CGDisplayModeRef mode)
  __attribute__((weak_import));
extern size_t CGDisplayModeGetPixelHeight(CGDisplayModeRef mode)
  __attribute__((weak_import));

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
    CGDisplayModeRef mode = CGDisplayCopyDisplayMode(dspy);
    if (mode == NULL)
      continue;

    if (action == ACTION_LIST) {
      printf("display %d: ", i);
      if (CGDisplayIsMain(dspy))
	printf("main, ");
      printf("%sactive, %s, %sline, %s%s",
             CGDisplayIsActive(dspy) ? "" : "in",
             CGDisplayIsAsleep(dspy) ? "asleep" : "awake",
             CGDisplayIsOnline(dspy) ? "on" : "off",
             CGDisplayIsBuiltin(dspy) ? "built-in" : "external",
             CGDisplayIsStereo(dspy) ? ", stereo" : "");
      printf(", ID 0x%x\n", (unsigned int)dspy);
      if (verbose) {
        CGRect bounds = CGDisplayBounds(dspy);
        printf("\tresolution %.0f x %.0f pt",
               bounds.size.width, bounds.size.height);
        if (CGDisplayModeGetPixelWidth != NULL) {
          printf(" (%zu x %zu px)",
                 CGDisplayModeGetPixelWidth(mode),
                 CGDisplayModeGetPixelHeight(mode));
        }
        printf(" @ %.1f Hz",
               CGDisplayModeGetRefreshRate(mode));
        printf(", origin (%.0f, %.0f)\n",
               bounds.origin.x, bounds.origin.y);
        CGSize size = CGDisplayScreenSize(dspy);
        printf("\tphysical size %.0f x %.0f mm",
               size.width, size.height);
        double rotation = CGDisplayRotation(dspy);
        if (rotation)
          printf(", rotated %.0f°", rotation);
        printf("\n\tIOKit flags 0x%x",
               CGDisplayModeGetIOFlags(mode));
        printf("; IOKit display mode ID 0x%x\n",
               CGDisplayModeGetIODisplayModeID(mode));
        CFStringRef pixelEncoding = CGDisplayModeCopyPixelEncoding(mode);
        if (pixelEncoding != NULL) {
          printf("\tpixel encoding %s\n",
                 CFStringGetCStringPtr(pixelEncoding,
                                       CFStringGetFastestEncoding(pixelEncoding)));
          CFRelease(pixelEncoding);
        }
        if (CGDisplayIsInMirrorSet(dspy)) {
          CGDirectDisplayID mirrorsDisplay = CGDisplayMirrorsDisplay(dspy);
          if (mirrorsDisplay == kCGNullDirectDisplay)
            printf("\tmirrored\n");
          else
            printf("\tmirrors display ID 0x%x\n", mirrorsDisplay);
        }
        printf("\t%susable for desktop GUI%s\n",
               CGDisplayModeIsUsableForDesktopGUI(mode) ? "" : "not ",
               CGDisplayUsesOpenGLAcceleration(dspy) ?
               ", uses OpenGL acceleration" : "");
      }
    }

    float refreshRate = CGDisplayModeGetRefreshRate(mode);
    CGDisplayModeRelease(mode);
    if (refreshRate != 0)
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
