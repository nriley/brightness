brightness
==========

Command-line display brightness control for macOS.

This tool enables you to set and obtain the brightness level of all internal and certain external displays from the command line or a script.

<table><tr><th>
If you cannot control your display’s brightness from Displays System Preferences, you will not be able to do it with <tt>brightness</tt>. See <a href="https://github.com/nriley/brightness/issues/11">this issue</a> for more information and some potential other options.
</th></tr></table>

Install with Homebrew
--------------------

```brew install brightness```

Install From Source
------------------

```shell
git clone https://github.com/nriley/brightness.git
cd brightness
make
sudo make install
```

macOS Version Support
---------------------

`brightness` requires OS X/macOS 10.8 or later — but go back in the commit history and you’ll find code compatible with older (Mac) OS X versions.

Through macOS 10.12.3, `brightness` uses documented APIs.  It works on internal laptop displays.  It doesn’t work on older Apple external LCDs which connect via DVI and USB.  I don’t know if it works on newer external displays, such as Thunderbolt displays, because I don’t have any to test with.  (Feedback welcome.)

As of macOS 10.12.4 with the introduction of Night Shift, the documented APIs fail to work correctly and Apple does not provide replacement APIs.  Therefore, `brightness` uses an [undocumented method](https://github.com/nriley/brightness/issues/21) to adjust brightness.

Usage Examples
-------

Set 100% brightness: ```brightness 1```

Set 50% brightness: ```brightness 0.5```

Show current brightness: ```brightness -l```

````
% brightness
usage: brightness [-m|-d display] [-v] <brightness>
   or: brightness -l [-v]
% brightness -lv
display 0: main, active, awake, online, built-in, ID 0x4280a80
	resolution 1680 x 1050 pt (3360 x 2100 px) @ 0.0 Hz, origin (0, 0)
	physical size 286 x 179 mm
	IOKit flags 0x400003; IOKit display mode ID 0x80001002
	usable for desktop GUI, uses OpenGL acceleration
display 0: brightness 0.690430
% brightness -m 0.6
% brightness -l    
display 0: main, active, awake, online, built-in, ID 0x4280a80
display 0: brightness 0.599609
````
