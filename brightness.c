/* gcc -std=c99 -o brightness brightness.c -framework IOKit -framework ApplicationServices */

#include <stdio.h>
#include <unistd.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);
const char *APP_NAME;

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
  APP_NAME = argv[0];
  if (argc == 1)
    usage();

  int verbose = 0;
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
      verbose = 1;
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

  CGDirectDisplayID display[kMaxDisplays];
  CGDisplayCount numDisplays;
  CGDisplayErr err;
  err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
  if (err != CGDisplayNoErr)
    errexit("cannot get list of displays (error %d)\n", err);

  CFWriteStreamRef stdoutStream = NULL;
  if (verbose) {
    CFURLRef devStdout =
      CFURLCreateWithFileSystemPath(NULL, CFSTR("/dev/stdout"),
				    kCFURLPOSIXPathStyle, false);
    stdoutStream = CFWriteStreamCreateWithFile(NULL, devStdout);
    if (stdoutStream == NULL)
      errexit("cannot create CFWriteStream for /dev/stdout");
    if (!CFWriteStreamOpen(stdoutStream))
      errexit("cannot open CFWriteStream for /dev/stdout");
  }								  

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
	CFStringRef error = NULL;
	CFPropertyListWriteToStream(originalMode, stdoutStream,
				    kCFPropertyListXMLFormat_v1_0, &error);
	if (error != NULL)
	  errexit("failed to write display info (%s)",
		  CFStringGetCStringPtr(error,
					CFStringGetFastestEncoding(error)));
      }
    }

    io_service_t service = CGDisplayIOServicePort(dspy);
    switch (action) {
    case ACTION_SET_ONE:
      if ((CGDirectDisplayID)displayToSet != dspy && displayToSet != i)
	continue;
    case ACTION_SET_ALL:
      err = IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness,
				       brightness);
      if (err != kIOReturnSuccess) {
	fprintf(stderr,
		"%s: failed to set brightness of display 0x%x (error %d)\n",
		APP_NAME, (unsigned int)dspy, err);
	continue;
      }
      if (!verbose) continue;
    case ACTION_LIST:
      err = IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness,
				       &brightness);
      if (err != kIOReturnSuccess) {
	fprintf(stderr,
		"%s: failed to get brightness of display 0x%x (error %d)\n",
		APP_NAME, (unsigned int)dspy, err);
	continue;
      }
      printf("display %d: brightness %f\n", i, brightness);
    }
  }

  return 0;
}
