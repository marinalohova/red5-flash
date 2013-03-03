package org.red5.server.io
{
  import asunit.framework.Assert;
  
  import net.theyard.components.netconnectionsm.NetConnectionStateMachine;
  import net.theyard.components.sm.events.StateChangeEvent;
  import net.theyard.components.test.YardTestCase;
  import flash.net.ObjectEncoding;

  /**
   * Tests if we can transmit a string to red5 and get it back intact. 
   */
  
  public class EchoStringTest extends YardTestCase
  {
      // the net connection state machine which manages the connection
      // with the server

      private var nc:NetConnectionStateMachine;

      // a test string to be reflected off the server

      private const testString:String = "this is a test string";
      
      /**
       * The URI the tests expect a running server on.
       * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
       */
      
      public static const RUNNING_SERVER_URI :String = 
        net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;
      
      /**
       * Create the echo string call test.
       *
       * @param name the name of the test.
       */

      public function EchoStringTest(name:String=null)
      {
        super(name);

        // create the net connection state machine

        nc = new NetConnectionStateMachine();
        
      }

      /**
       * @see net.theyard.components.test.YardTestCase#setUp()
       */

      protected override function setUp():void
      {
        super.setUp();
      }
      
      /**
       * @see net.theyard.components.test.YardTestCase#tearDown()
       */

      protected override function tearDown():void
      {
        super.tearDown();
      }

      /** Run the echo string test using AMF0. */

      public function testEchoStringAmf0():void
      {
        // set encoding 

        nc.objectEncoding = ObjectEncoding.AMF0;

        // run the test

        startEchoStringTest();
      }

      /** Run the echo string test using AMF3. */

      public function testEchoStringAmf3():void
      {
        // set encoding 

        nc.objectEncoding = ObjectEncoding.AMF3;

        // run the test

        startEchoStringTest();
      }

      /** Test that a string can be sent to the server and echoed back. */
      
      public function startEchoStringTest():void
      {
        // indicate that this is an asynchronous test and all action
        // associated with this test should complete within the allotted
        // time (10000 milliseconds in this case).  farther down in the
        // test code finishAsyncTest() is called to signal successfull
        // test completion. if finishAsyncTest() is NOT called within
        // the allotted time the test will fail.

        startAsyncTest(10000);

        // add a listener to the net connection state machine to detects
        // when it has reached the connected state and then can continue
        // with this test

        nc.addEventListener(StateChangeEvent.STATE_CHANGE, onConnect_EchoString);
        
        // connect to the server

        nc.connect(RUNNING_SERVER_URI);
      }

      /** Handle the connection event. This is called when the client
       * has completed conecting to the server.
       *
       * @param state the state of the connection to the server
       */

      public function onConnect_EchoString(state:StateChangeEvent):void
      {
        // if the client is conneced to the server, continue the test
        
        if (nc.getState() == NetConnectionStateMachine.STATE_CONNECTED)
        {
          // remove the event listener

          nc.removeEventListener(
            StateChangeEvent.STATE_CHANGE, onConnect_EchoString);

          // call the "echoString" method on the echo service on the
          // server passing in the onConnect_EchoString callback and the
          // test string
          
          nc.call(
            "echo.echoString", onCallbackSuccess_EchoString, null, testString);
        }
      }
      
      /** Handle callback from the "echoString" call on the server.
       *
       * @param result the return value from the call to "echoString"
       */

      public function onCallbackSuccess_EchoString(resultString:String):void
      {
        // test that the result from the "echoString" call

        assertTrue(testString + " != " + resultString, testString == resultString);

        // close the connection to the server

        nc.close();

        // signal that we have completed the asynchronous test we
        // initiated with startAsyncTest() at the start of the test

        finishAsyncTest();
      }
  }
}
