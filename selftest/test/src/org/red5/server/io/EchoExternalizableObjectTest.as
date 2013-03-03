package org.red5.server.io
{
  import asunit.framework.Assert;
  
  import net.theyard.components.netconnectionsm.NetConnectionStateMachine;
  import net.theyard.components.sm.events.StateChangeEvent;
  import net.theyard.components.test.YardTestCase;
  import net.theyard.components.Utils;
  import flash.net.ObjectEncoding;

  /**
   * Tests if we can transmit a custom Flash object to red5 and get it back intact. 
   *
   * We test both AMF0 and AMF3 and expect the object to look the
   * same to us in both modes.
   */
  public class EchoExternalizableObjectTest extends YardTestCase
  {
      // the net connection state machine which manages the connection
      // with the server

      private var nc:NetConnectionStateMachine;
      
      // a test object to be reflected off the server
      private const testObj:ExternalizableClass = new ExternalizableClass();

      /**
       * The URI the tests expect a running server on.
       * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
       */
      
      public static const RUNNING_SERVER_URI:String = 
        net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;
      
      /**
       * Create the echo call test.
       *
       * @param name the name of the test.
       */

      public function EchoExternalizableObjectTest(name:String=null)
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
        
      /** Run the echo Object test using AMF0.
       *
       */
 
      public function disabled_testEchoObjectAmf0():void
      {
        // set encoding 

        nc.objectEncoding = ObjectEncoding.AMF0;

        // run the test
        
        startEchoExternalizableObjectTest();
      }

      /** Run the echo Object test using AMF3. */

      public function testEchoObjectAmf3():void
      {
        // set encoding 

        nc.objectEncoding = ObjectEncoding.AMF3;

        // run the test

        startEchoExternalizableObjectTest();
      }

      /** Test that a Object can be sent to the server and echoed back. */
      
      public function startEchoExternalizableObjectTest():void
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

        nc.addEventListener(StateChangeEvent.STATE_CHANGE, onConnect_EchoObject);
        
        // connect to the server

        nc.connect(RUNNING_SERVER_URI);
      }

      /** Handle the connection event. This is called when the client
       * has completed conecting to the server.
       *
       * @param state the state of the connection to the server
       */

      public function onConnect_EchoObject(state:StateChangeEvent):void
      {
        // if the client is conneced to the server, continue the test
        
        if (nc.getState() == NetConnectionStateMachine.STATE_CONNECTED)
        {
          // remove the event listener

          nc.removeEventListener(
            StateChangeEvent.STATE_CHANGE, onConnect_EchoObject);

          // call the "echoObject" method on the echo service on the
          // server passing in the onConnect_EchoObject callback and the
          // test Object
          
          nc.call(
            "echo.echoObject", onCallbackSuccess_EchoObject, null, testObj);
        }
      }
      
      /** Handle callback from the "echoObject" call on the server.
       *
       * @param result the return value from the call to "echoObject"
       */

      public function onCallbackSuccess_EchoObject(obj:Object):void
      {

        Utils.ytrace("got object: " + obj);

        var customObj:ExternalizableClass = ExternalizableClass(obj);

        assertTrue("all conversions should succeed",
          customObj.failed==0);

        nc.close();

        // signal that we have completed the asynchronous test we
        // initiated with startAsyncTest() at the start of the test

        finishAsyncTest();
      }
  }
}
