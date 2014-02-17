brightness
==========

Command-line display brightness control for OS X.

These tools control the hardware brightness, where available.  If you can’t use the keyboard keys or Displays System Preferences to control your brightness, `brightness` isn’t going to help you.

Two versions are included.  Both require OS X 10.6 or later — but go back in the history and you’ll find versions that work with older OS X versions.

`brightness.c` uses documented APIs.  It works on internal laptop displays.  It doesn’t work on older Apple external LCDs.  I don’t know if it works on newer displays, such as Thunderbolt displays, because I don’t have any to test with.  Unfortunately, one of the APIs used here is deprecated in OS X 10.9 with no replacement.  If you care about being able to programmatically set display brightness, [file a bug](http://bugreport.apple.com/).

`brightness.m` uses SPIs reverse-engineered from Displays System Preferences as of 2005.  It does not work as of OS X 10.9, always returning 0 brightness, but does work on OS X 10.6.  (I do not have any plans to update it nor any hardware with which to test, but contributions are welcome.)

Compilation instructions are in comments at the top of each file.

Example
-------
````
% brightness
usage: brightness [-m|-d display] [-v] <brightness>
   or: brightness -l [-v]
% brightness -lv
display 0: main, inactive, asleep, online, built-in, ID 0x4280500
	resolution 1280 x 800 pt (2560 x 1600 px) @ 0.0 Hz, origin (0, 0)
	physical size 286 x 179 mm
	IOKit flags 0x7; IOKit display mode ID 0x80001000
	pixel encoding --------RRRRRRRRGGGGGGGGBBBBBBBB
	usable for desktop GUI, uses OpenGL acceleration
display 0: brightness 0.588867
% brightness -m 0.6
% brightness -l
display 0: main, inactive, asleep, online, built-in, ID 0x4280500
display 0: brightness 0.599609
````
