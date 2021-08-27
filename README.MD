UTX-Viewer 3.3.1 build 31 (beta)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
(c) 2000-2002, Jesco Topp (& Andy Ford)


THIS PROGRAM IS PROVIDED UNDER THE GNU/GPL.


1. COMMENTS BY THE AUTHOR
2. IMPORTANT NOTES
2. VERSION HISTORY
3. CONTACT/INFO


1. COMMENTS BY THE AUTHOR
~~~~~~~~~~~~~~~~~~~~~~~~~

a) for v3.3.1 (written in June 2002):

This it is. The probably last release of UTX-Viewer in its current
form. Maybe something new will come for UT2k3, but I, frankly, don't
know. Maybe some plans for Linux, I don't know.

UTX-Viewer is a OpenSource project. The initial copyright might belong
to me, but everybody can - and is encouraged - to work on it and enhance
it. You may re-distribute any modifications on your own or send them to
me to have them added to the official tree.

Use your power.

b) for v3.0 (written in mid-2001):

Version 3 of the UTX-Viewer has been rewritten from scratch, 
at least most parts of it. While the old version might be good 
in terms of design and usability, the underlying code-base is 
ugly and not very well designed.
My goal with this rewrite was to fix these issues and make it 
easier to implement future features. Professional programmers 
might still consider my coding style to be of poor quality, but 
I'm still learning.

For those, who are interested in numbers (like me): In total this 
program consists of almost 4000 lines of code, spread across 20 files.
It's the work of almost three months.

Unfortunately, I haven't been able to implement all the features I had 
in my mind for the v3 release. The following things will follow in later 
releases:

  - support for writing packages (even adding to already existing ones)
  - OpenGL support for *every* preview and not only the details dialog


1b. COMMENTS BY THE AUTHOR (for v3.3.0)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is a beta release. Especially the new OpenGL renderer (Preferences/Rendering) 
is in an early state. The reason for this release is the leave of myself from the 
team and my search for a proficient succedessor.


2. IMPORTANT NOTES
~~~~~~~~~~~~~~~~~~

a) supported games

As this is a total rewrite, there may be some issues with packages 
from other Unreal-Engine games other than U1, UT and DeusEx. Mail me 
at jesco@planetunreal.com and I'll fix these issues asap.

Also, 'Clive Barker's Undying' seems to cause some trouble. I have to
further investigate those packages.

b) very very large packages

You may encounter some problems loading *very* large packages (like 
Botpack.u & Co.), which also contain masses of scripts, models and 
geometry. The application will produce an error-box like 'Oversized 
header tables...' along with a number of entries in these tables. If 
you get such an error when trying to preview an ordinary texture package, 
drop me a line along with a copy of the logfile and I'll increase the size 
of the internal tables asap.

c) OpenGL

The OpenGL interface should work even with cards that do not support OpenGL
in hardware. Full software emulation is used then.

Oh, but don't try and increase the maximum texture size to more than 512*512, 
even if your video-card supports it. This doesn't do anything as the largest 
textures in UT are 512*512 ;-)

The renderer for the main window doesn't support scrolling yet.

d) unsupported textures

All those fance scripted, wet, fire, wave and ice textures are not supported. 
And I doubt they ever will (there are just too few of them).
S3TC compressed texture aren't supported either, although this will change in 
a future release.

e) resolutions lower than 1024*768

If you encounter problems using the viewer at resolutions lower than 1024*768, then
try the compatibility mode. In this mode, some control are left away or repositioned
and resized. This ensure that you can use all of the viewer's features.



3. VERSION HISTORY
~~~~~~~~~~~~~~~~~~
3.3.1 (build 31) beta:
- added xml-code for XP's new gui-styles [eGo]

3.3.0 (build 30) beta:
- some minor code-cleanup
- new OpenGL renderer for main-window [in progress]; user can choose
  which renderer to use
- rewritten file handling (fixes a nasty error under XP when opening the first package)
- filename of active package is displayed in the title bar
- added shortcuts for most used menu-items
- started catalogue printing


3.2.0 (build 28):
- Package list has been replaced by a TreeView;
  - new search option; generates a new treenode with all 
    results
  - mass extraction currently disabled
- Added support for groups in 'Package Export' dialog
- Fixed size limit for packages (Oversized-Headers Error)
- 10-15% performance increase in texture extraction (plus 
  another 30% when using Windows NT/2000/XP)
- Splashscreen is now displayed for two secs at startup
- Removed noisy palettes in packages with S3TC textures; 
  although, only the non-compressed mipmaps are displayed
- Error in logging fixed 

3.1 (build 24):
- Added compatibility mode for ppl using 800*600
- Added Browse functions for all folder names, so no more 
  typing them in
- Added support for up to 4 'Favorite' folders. These can be 
  accessed quickly via the new Favorites menu 
- UTX files are no longer locked if you try and view them 
  while you are using them in UnrealED 
- Fixed display scrolling beyond first/last texture 
- Added a Track Bar to zoom in/out instead of buttons
- Added marker for currently selected texture 
- Added dialog for full-size texture preview like in v22 
- Added check for package-signature. Invalid files are now 
  handled correctly
- Added count of textures in current package in package-info 
  dialog 

3.0 (build 20):
- completely rewritten from scratch
- new gui (no list for internal packages anymore, 
           but 60% more previews are displayed at once)
- mass extraction of complete packages
- new dialog for information on packages and their contents
- support to preview packages from folders different than 
  the current texture folder
- advanced logging to ease bug-fixing

2.2:
- OpenGL-support
- Full support for AnimatedTextures (via OpenGL),
  placed in the "Texture Details"-Tab
- More detailed infos on textures
- enhanced support for other Unreal Technology Games
  (no need for changing registry entries anymore)

2.0: 
- added a direct-package-writer, meaning that
  you can create texture-packages directly
  from within the app
- added support for other Unreal Technology Games
  (Unreal1, DeusEx, RuneDemo)
- optimized user-interface

1.0: 
- enhanced user-interface (search-option, help-text)
- lots of bug-fixes

0.9b: 
- TiledPreview is working again
- Full-Size preview of textures
- much cleaner code & interfaces
- bug-fixes (i.e. colour-bug)

0.9: 
- completely re-written
- added a direct-package-reader, meaning that
  you don't need to pre-export the textures as
  the app can read the textures directly from
  within their packages.
  Scripted textures aren't supported at the
  moment, same applies to FireTextures and
  compressed textures. Animated textures are
  supported indirectly by previewing every keyframe
  like a single texture.
- profile-support is broken in this version
- TiledPreview is broken in this version
- UTX-Viewer is .ZIP again (the filename of
  the .exe has changed, too, it's now
  UTPackage.exe);

0.7: 
- added 'TiledPreview'; helps you to check if a 
  texture is seamless or not
- added support for profiles; displays only those
  texture-packages which are in a specific profile,
  helps you to ensure that everybody has the packages
  to run your map
- removed 'options.exe'; the app now detects if its
  started for the first time and displays a nice
  preference-dialog
- slightly tweaked 1-click conversion
- bug-fixing

0.6c: 
- re-designed User-Interface
- added HTML-Preview
- added 1-click conversion

0.6b: 
- fixed bugs where space in folder/filenames would 
  cause ucc.exe to quit with an error
- fixed "Update of Package List"; you don't need to
  specify the UTX-Viewer folder before the first start
- Optimized size
- UTX-Viewer is now UMOD

0.6: 
- first release


4. CONTACT/INFO
~~~~~~~~~~~~~~~
a) 

Jesco Topp

Tasks: - initial idea
       - lead-coder

E-Mail: <jesco@users.sourceforge.net>                
Web: http://utx-viewer.sourceforge.net

b) 

Andy 'Fordy' Ford

Tasks: - coder
       - artwork
       - beta-tester

E-Mail: <Fordy@planetunreal.com>
Web: http://www.planetunreal.com/fordy/

c)

Jan 'eGo' Urbansky

Tasks: - freelance work (v3.3.1 is his work)

Web: http://www.unrealediting.de
Web: http://www.ego-creations.de