Howto Build
===========

Using Flex Builder/Eclipse:

 1. Checkout this folder using Subclipse
 2. Go to Project > Properties > Flex Build Path and change the
    additional source folder path (currently defined as
    '/path/to/classes/folder') and point it to a checked out copy
    of this folder: http://red5.googlecode.com/svn/flash/trunk/classes
 3. Go to Project > Properties > Flex Build Path and click on the
    'Library Path' tab. Modify the library path folder (currently
    defined as '/path/to/lib/folder') and point it to a checked out
    copy of this folder: http://red5.googlecode.com/svn/flash/trunk/lib

Using Ant:

 1. Make sure you have a copy of this file in the folder below this one:
    http://red5.googlecode.com/svn/flash/trunk/flex.properties
 2. Modify flex.properties and point it to your Flex SDK (2 or newer)
 3. Type 'ant' to build the application
    