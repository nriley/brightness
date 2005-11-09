/* gcc -o brightness -framework Cocoa -framework DisplayServices -F/System/Library/PrivateFrameworks brightness.m */

#import <Foundation/Foundation.h>

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

int main(int argc, const char *argv[])
{
  CGDirectDisplayID display[kMaxDisplays];
  CGDisplayCount numDisplays;
  CGDisplayCount i;
  CGDisplayErr err;
  
  [[NSAutoreleasePool alloc] init];
  [O3Manager initialize];

  err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
  if (err != CGDisplayNoErr) {
      NSLog(@"Cannot get displays (%d)", err);
      exit(1);
  }
  printf("%d displays found", (int)numDisplays);
  for ( i = 0; i < numDisplays; ++i ) {
      CGDirectDisplayID dspy = display[i];
      CFDictionaryRef originalMode;

      originalMode = CGDisplayCurrentMode(dspy);
      if (originalMode == NULL)
	continue;

      NSLog(@"Display 0x%x: %@", (unsigned int)dspy, originalMode);

      if ([[(NSDictionary *)originalMode objectForKey: @"RefreshRate"] intValue] == 0) {
	id<BrightnessEngineWireProtocol> engine =
	  [O3Manager engineOfClass: @"BrightnessEngine" forDisplayID: dspy];
	NSLog(@"Engine: %@", engine);
	NSLog(@"Brightness was %f", [engine brightness]);
	if (argc == 2) {
	  float newBrightness = [[NSString stringWithCString: argv[1]] floatValue];
	  if (newBrightness < 0. || newBrightness > 1.) {
	    NSLog(@"Brightness should be between 0 and 1");
	    exit(1);
	  }
	  [engine setBrightness: newBrightness];
	  NSLog(@"Brightness is now %f", [engine brightness]);
	}
      }
    }
  exit(0);
}
