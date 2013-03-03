This application is based off The Yard's self-test application.

http://theyard.googlecode.com/

It fires up AsUnit and runs through the unit tests than can be found
in the test/src directory

To build:
ant compile-tests

To run:
First, from your red5 tree, do:
ant run-tests-server

Once that's running, do:
ant run-tests
or bring up build/red5-selftest.swf in a flash player

To generate documentation run:
ant doc

Here's the original text from the README:

These libraries contain the following:

- net.theyard.components.test.TestYardCase:
    An abstraction of the asunit.framework.TestCase object that does some extra things

- A series of tests for the theyard-flashutils library
  In particular, tests for the NetConnectionStateMachine and the NetStreamStateMachine

All tests assume the following:
 - You must give the application permission to access your camera; it will
   throw up the Flash security dialog that asks for this; give it permission
   and check the box to have flash remember it in the future.
 - You must be running a media server accessible at http://localhost/.  If
   you want to change that, see net.theyard.components.tests.DefaultFixtures.as
 - You must be running an application accessible at http://localhost/selftest
 - You must have a FLV file hosted on that server at http://localhost/selftest/testvid.flv
 - You must ensure your server allows publishing of live streams

Once that's done, the tests should run successfully.  Turns out the Red5
java server trunk has two build targets that are set up for this application:

1) ant run-tests-systemtest: starts up a red5 test server, and uses this swf file
  to do an end-to-end system test.
2) ant run-tests-server: starts up a red5 test server that has a web-application 
  installed at rtmp://HOSTNAME/selftest/ that will provide all the files
  and APIs that this selftest assumes.

