/*
 * The Yard Utilties - http://www.theyard.net/
 * 
 * Copyright (c) 2008 by Vlideshow, Inc..  All Rights Resrved.
 * 
 * This library is free software; you can redistribute it and/or modify it under the 
 * terms of the GNU Lesser General Public License as published by the Free Software 
 * Foundation; either version 2.1 of the License, or (at your option) any later 
 * version. 
 * 
 * This library is distributed in the hope that it will be useful, but WITHOUT ANY 
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along 
 * with this library; if not, write to the Free Software Foundation, Inc., 
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
 */
package net.theyard.components.netconnectionsm
{
  import net.theyard.components.netconnectionsm.NetConnectionStateMachine;
  import net.theyard.components.sm.events.StateChangeEvent;
  import net.theyard.components.test.YardTestCase;
  import net.theyard.components.sm.StateMachineTestHelper;
  import net.theyard.components.Utils;

  import flash.events.TimerEvent;
  import flash.utils.Timer;

  /**
   * These tests test the NetConnectionStateMachine
   *
   * @see NetConnectionStateMachine
   */
  public class NetConnectionStateMachineTest extends YardTestCase
  {
    /**
     * The URI that these tests try to connect to.
     * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
     */
    public static const RUNNING_SERVER_URI :String = net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;

    private var ncsm :NetConnectionStateMachine;
    private var smtester :StateMachineTestHelper;

    /**
     * Create a test
     */
    public function NetConnectionStateMachineTest(aName:String=null)
    {
      super(aName);
      this.smtester = new StateMachineTestHelper();
      Utils.setDebuggingEnabled(true);
      Utils.ytrace("Starting a test");
    }

    /**
     * Called before each test is run.
     */
    protected override function setUp():void
    {
      super.setUp();
      this.ncsm = new NetConnectionStateMachine();
    }

    /**
     * Called after each test is run.
     */
    protected override function tearDown():void
    {
      this.ncsm=null;
      this.smtester.setNextStates({});
      super.tearDown();
    }

    /**
     * Test that a null URI raises an immediate exception.
     */
    public function testNullUriAssert():void
    {
      var gotException:Boolean = false;
      try
      {
        this.ncsm.connect(null);
      }
      catch (ex:Error)
      {
        gotException = true;
      }
      assertTrue("Did not get expected exception", gotException);
    }

    /**
     * Test that we successfully connect to a running server.  Note
     * this function assumes a server is running on the RUNNING_SERVER_URI
     *
     * @see #RUNNING_SERVER_URI
     */
    public function testSuccessfulConnection():void
    {
      Utils.ytrace(
          "This test will fail unless a server is running here: "
          + RUNNING_SERVER_URI);

      // We need to set up a handler for when the connect finishes.
      this.smtester.setNextStates(NetConnectionStateMachine.STATE_CONNECTING);

      this.startAsyncTest(15000);

      // This will call the handler function each time the
      // state changes.  it is up to the handler to decide when the test
      // is done, but if it doesn't wrap it up within the Async timeout by
      // calling finishAsyncTest it will fail.

      this.ncsm.addEventListener(
          StateChangeEvent.STATE_CHANGE,
          asyncEventListenerWrapper(this.handleStateChange));
      // And finally, try connecting to some garbage URL.
      this.ncsm.connect(RUNNING_SERVER_URI, {version:1});
    }

    private function handleStateChange(event:StateChangeEvent) : void
    {
      var state:String = event.getState();
      switch (state)
      {
        case NetConnectionStateMachine.STATE_CONNECTING:
          Utils.ytrace("Got CONNECTING; now waiting for CONNECTED");
          smtester.checkStateAndSetNextStates(
              event.getState(), NetConnectionStateMachine.STATE_CONNECTED);
          break;
        case NetConnectionStateMachine.STATE_CONNECTED:
          Utils.ytrace("Got CONNECTED; now closing and waiting for DISCONNECTING");
          smtester.checkStateAndSetNextStates(
              state, NetConnectionStateMachine.STATE_DISCONNECTING);
          ncsm.close();
          break;
        case NetConnectionStateMachine.STATE_DISCONNECTING:
          Utils.ytrace("Got DISCONNECTING; now waiting for DISCONNECTED");
          smtester.checkStateAndSetNextStates(state, NetConnectionStateMachine.STATE_DISCONNECTED);
          break;
        case NetConnectionStateMachine.STATE_DISCONNECTED:
          Utils.ytrace("Got DISCONNECTED; finished test");
          smtester.checkStateAndSetNextStates(state, {});
          this.finishAsyncTest();
          break;
        default:
          // this should never happen.
          smtester.checkState(state);
          break;
      }
    }

    /**
     * Test that we fail to connect to invalid URI.
     *
     * <p>
     * This test is currently disabled.
     * </p>
     * <p>
     * Note: This test takes 60 seconds to pass, so only enable
     * it when you have the time.
     * </p>
     */
    public function disabled_testInvalidURI():void
    {
      // We need to set up a handler for when the connect finishes.
      smtester.setNextStates(NetConnectionStateMachine.STATE_CONNECTING);

      this.startAsyncTest(60000);

      this.ncsm.addEventListener(
          StateChangeEvent.STATE_CHANGE,
          asyncEventListenerWrapper(this.handleInvalidUri));
      // And finally, try connecting to some garbage URL.
      this.ncsm.connect("rtmp://invalid.website/invalidapp");
    }

    private function handleInvalidUri(event:StateChangeEvent) : void
    {
      var state:String = event.getState();
      switch (state)
      {
        case NetConnectionStateMachine.STATE_CONNECTING:
          smtester.checkStateAndSetNextStates(
              state, NetConnectionStateMachine.STATE_DISCONNECTED);
          break;
        case NetConnectionStateMachine.STATE_DISCONNECTED:
          smtester.checkStateAndSetNextStates(state, {});
          this.finishAsyncTest();
          break;
        default:
          smtester.checkState(state);
          break;
      }
    }

    private var LOADTEST_NUM_SIMULTANEOUS_CONNECTIONS : int = 100;
    // give up to one second per connection
    private var LOADTEST_TIMEOUT_PER_CONNECTION : int = 1000;
    private var mLoadTest_ConnectionsMade : int = 0;
    private var mLoadTest_DisconnectionsMade : int = 0;
    private var mLoadTest_Listener : Function = null;


    /**
     * Does a mini-load test by firing up a bunch of connections and then disconnecting.
     *
     * Currently this test will open up 100 simulatanous connections and then
     * disconnect them.  It will fail if this process either (a) doesn't open
     * every connection or (b) takes longer than 1 second.
     */
    public function testLoadTest() : void
    {
      Utils.ytrace("Starting NCSM Load Test with " + LOADTEST_NUM_SIMULTANEOUS_CONNECTIONS + " connections");
      mLoadTest_Listener = asyncEventListenerWrapper(this.handleLoadTest);
      // Give us 2 seconds to start up all the tests
      var ncs:Array = new Array();
      var i:int=0;
      var nc : NetConnectionStateMachine = null;
      for(i = 0; i < LOADTEST_NUM_SIMULTANEOUS_CONNECTIONS; i++)
      {
        nc = new NetConnectionStateMachine();
        nc.addEventListener(
            StateChangeEvent.STATE_CHANGE,
            mLoadTest_Listener);
        ncs.push(nc);
      }
      // now that they are all created, start the async part of this test
      this.startAsyncTest(2000 + LOADTEST_TIMEOUT_PER_CONNECTION*LOADTEST_NUM_SIMULTANEOUS_CONNECTIONS);
      for(i = 0; i < LOADTEST_NUM_SIMULTANEOUS_CONNECTIONS; i++)
      {
        nc = NetConnectionStateMachine(ncs.pop());
        Utils.ytrace("Attempting connection to: " + RUNNING_SERVER_URI);
        nc.connect(RUNNING_SERVER_URI, {version:1});
      }
    }
    private function handleLoadTest(event:StateChangeEvent) : void
    {
      var state:String = event.getState();
      var nc:NetConnectionStateMachine = NetConnectionStateMachine(event.target);
      switch(state)
      {
        case NetConnectionStateMachine.STATE_CONNECTED:
          ++mLoadTest_ConnectionsMade;
          Utils.ytrace("CONNECTED: " + mLoadTest_ConnectionsMade);
          var t : Timer = new Timer(100, 1);
          t.addEventListener(TimerEvent.TIMER_COMPLETE,
            asyncEventListenerWrapper(
              function() : void { nc.close(); }));
          t.start();
          break;
        case NetConnectionStateMachine.STATE_DISCONNECTED:
          ++mLoadTest_DisconnectionsMade;
          Utils.ytrace("DISCONNECTED: " + mLoadTest_DisconnectionsMade);
          nc.removeEventListener(StateChangeEvent.STATE_CHANGE, mLoadTest_Listener);
          if (mLoadTest_DisconnectionsMade == LOADTEST_NUM_SIMULTANEOUS_CONNECTIONS)
          {
            assertEquals("not enough connections", mLoadTest_ConnectionsMade, mLoadTest_DisconnectionsMade);
            this.finishAsyncTest();
          }
          break;
        default:
          // ignore;
          Utils.ytrace("Ignoring transition event for: " + nc);
          break;
      }
    }
  }
}
