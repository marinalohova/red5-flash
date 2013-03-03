package org.red5.server.io
{
  import asunit.framework.Assert;
  
  import net.theyard.components.netconnectionsm.NetConnectionStateMachine;
  import net.theyard.components.sm.events.StateChangeEvent;
  import net.theyard.components.test.YardTestCase;
  import net.theyard.components.Utils;
  import flash.net.ObjectEncoding;
  import flash.xml.XMLDocument;

  /**
   * Tests if we can transmit a array to red5 and get it back intact. 
   *
   * We test both AMF0 and AMF3 and expect the array to look the
   * same to us in both modes.
   */
  public class EchoXMLTest extends YardTestCase
  {
      // the net connection state machine which manages the connection
      // with the server

      private var nc:NetConnectionStateMachine;
      
      // a test array to be reflected off the server
      
      private const testXML:XML =
      <employees>
          <employee ssn="123-123-1234">
              <name first="John" last="Doe"/>
              <address>
                  <street>11 Main St.</street>
                  <city>San Francisco</city>
                  <state>CA</state>
                  <zip>98765</zip>
              </address>
          </employee>
          <employee ssn="789-789-7890">
              <name first="Mary" last="Roe"/>
              <address>
                  <street>99 Broad St.</street>
                  <city>Newton</city>
                  <state>MA</state>
                  <zip>01234</zip>
              </address>
          </employee>
      </employees>;

      private const testXMLDocument:XMLDocument=
        new XMLDocument(testXML.toXMLString());
      
      /**
       * The URI the tests expect a running server on.
       * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
       */
      
      public static const RUNNING_SERVER_URI:String = 
        net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;
      
      /**
       * Create the echo array call test.
       *
       * @param name the name of the test.
       */

      public function EchoXMLTest(name:String=null)
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
        
      /** Test that a XML string can be sent to the server and echoed back
          under AMF3. */

      public function disabled_testEchoXMLAmf0():void
      {
        // set encoding 

        nc.objectEncoding = ObjectEncoding.AMF0;

        startTestEchoXML();
      }

      public function testEchoXMLAmf3():void
      {
        // set encoding 

        nc.objectEncoding = ObjectEncoding.AMF3;

        startTestEchoXML();
      }

      public function startTestEchoXML():void
      {

        // run the test

        // Make sure we have valid xml
        assertTrue("XML data is empty: "+testXML, testXML != null);

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

        nc.addEventListener(StateChangeEvent.STATE_CHANGE, onConnect_EchoXML);
        
        // connect to the server

        nc.connect(RUNNING_SERVER_URI);
      }

      /** Handle the connection event. This is called when the client
       * has completed conecting to the server.
       *
       * @param state the state of the connection to the server
       */

      public function onConnect_EchoXML(state:StateChangeEvent):void
      {
        // if the client is conneced to the server, continue the test
        
        if (nc.getState() == NetConnectionStateMachine.STATE_CONNECTED)
        {
          // remove the event listener

          nc.removeEventListener(
            StateChangeEvent.STATE_CHANGE, onConnect_EchoXML);

          // call the "echoXML" method on the echo service on the
          // server passing in the onConnect_EchoXML callback and the
          // test array
          
          if (nc.objectEncoding == ObjectEncoding.AMF0)
          {
            nc.call(
                "echo.echoXML", onCallbackSuccess_EchoXML, null, testXMLDocument);
          } else {
            nc.call(
                "echo.echoXML", onCallbackSuccess_EchoXML, null, testXML);
          }
        }
      }
      
      /** Handle callback from the "echoXML" call on the server.
       *
       * @param result the return value from the call to "echoXML"
       */

      public function onCallbackSuccess_EchoXML(result:Object):void
      {
        Utils.ytrace("Got result: " + result);
        if (nc.objectEncoding == ObjectEncoding.AMF0)
        {
          var resultXMLDoc:XMLDocument = new XMLDocument(result as String);
          Utils.ytrace("Got xml doc: " + resultXMLDoc.toString());
          assertTrue("xml is different",
            resultXMLDoc.toString() == testXMLDocument.toString());

        } else {
          var resultXML:XML = XML(result);
          Utils.ytrace("Got xml: " + resultXML);
          var resultZip:String = testXML.employee.(@ssn=="789-789-7890").address.zip;
          Utils.ytrace("Got zip: " + resultZip);

          assertTrue("missing Mary Roe's zip: " + resultZip,
              resultZip == "01234");
        }

        // close the connection to the server

        nc.close();

        // signal that we have completed the asynchronous test we
        // initiated with startAsyncTest() at the start of the test

        finishAsyncTest();
      }
  }
}
