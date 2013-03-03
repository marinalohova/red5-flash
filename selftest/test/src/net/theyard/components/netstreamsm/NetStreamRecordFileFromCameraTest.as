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
package net.theyard.components.netstreamsm
{
  import asunit.framework.Assert;

  import net.theyard.components.netconnectionsm.NetConnectionStateMachine;
  import net.theyard.components.netstreamsm.NetStreamStateMachine;
  import net.theyard.components.sm.events.StateChangeEvent;
  import net.theyard.components.test.YardTestCase;
  import net.theyard.components.netconnectionsm.NetConnectionStateMachineTestHelper;
  import net.theyard.components.sm.StateMachineTestHelper;
  import net.theyard.components.Utils;

  import flash.events.StatusEvent;
  import flash.media.Camera;
  import flash.media.Video;

  /**
   * Grabs the camera, starts publishing to a server, and then immediately stops.
   */
  public class NetStreamRecordFileFromCameraTest extends YardTestCase
  {
    private var nc:NetConnectionStateMachine;
    private var nchelper:NetConnectionStateMachineTestHelper;
    private var ns:NetStreamStateMachine;
    private var smtester:StateMachineTestHelper;
    private var listener:Function;
    private var camListener:Function;
    private var cam:Camera;

    private var vid:Video;

    /**
     * The URI the tests expect a running server on.
     * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
     */
    public static const RUNNING_SERVER_URI :String = net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;

    /**
     * The URI we'll record to.
     */
    public static const RUNNING_SERVER_RECORD_URI :String ="testrecord";

    /**
     * If the test hasn't finished in this amount of time, it fails.
     */
    public static const MILLISECONDS_ASYNC_TEST_TIMEOUT :uint = 10000; 
    public function NetStreamRecordFileFromCameraTest(aName:String=null)
    {
      super(aName);
      this.smtester = new StateMachineTestHelper();
      this.nchelper = new NetConnectionStateMachineTestHelper(this.asyncEventListenerWrapper);
    }

    /**
     * @see net.theyard.components.test.YardTestCase#setUp()
     */
    protected override function setUp() : void
    {
      super.setUp();
      nc = null;
      ns = null;
    }

    /**
     * @see net.theyard.components.test.YardTestCase#tearDown()
     */
    protected override function tearDown() : void
    {
      if (this.vid != null)
      {
        try
        {
          this.removeChild(this.vid);
        }
        catch (ex:Error)
        {
          // ignore
        }
        if (this.ns)
        {
          ns.detachFromVideo(this.vid);
        }
        this.vid = null;
      }
      if (listener != null)
      {
        ns.removeEventListener(StateChangeEvent.STATE_CHANGE, listener);
        listener = null;
      }
      if (camListener != null)
      {
        cam.removeEventListener(StatusEvent.STATUS, camListener);
        camListener = null;
      }
      super.tearDown();
    }

    /**
     * This test case tries to get the camera and then test if we can publish a file to a server from the camera.
     * <p>
     * This test first tries to get access to your Camera.  If flash can't find
     * a Camera, it just ignores the test.  If it can find a camera and it's
     * muted, we'll bring up the security dialog asking for permission.  If
     * we don't get it within the timeout we'll fail.
     * </p><p>
     * Once we get the camera, this test tries to publish the stream to the server.
     * </p><p>
     * It publishes the stream to RUNNING_SERVER_RECORD_URI
     * </p><p>
     * Once it's successfully starting publishing it just immediately stops.
     * </p><p>
     * Once it has successfully stopped publishing the test finishes.
     * </p><p>
     * Lastly if for some reason Flash can't get a camera this test is ignored,
     * but if flash gets a Muted camera it relies on the user to enable it before
     * this test runs.  For that reason, you should usually run this test
     * attended once and set the Flash security dialogs to always give it camera
     * access.  After that, it can run unattended.
     * </p>
     * @see #RUNNING_SERVER_RECORD_URI
     * @see #MILLISECONDS_ASYNC_TEST_TIMEOUT
     */
    public function testSuccessfulStreamRecord() : void
    {
      this.startAsyncTest(MILLISECONDS_ASYNC_TEST_TIMEOUT);

      // This will call the handler function each time the
      // state changes.  it is up to the handler to decide when the test
      // is done, but if it doesn't wrap it up within the Async timeout by
      // calling finishAsyncTest it will fail.

      this.nchelper.connect(this.onConnect_SuccessStreamRecord,
          RUNNING_SERVER_URI, { version : 1 });

    }

    private function onConnect_SuccessStreamRecord( nc : NetConnectionStateMachine ) : void
    {
      cam = Camera.getCamera();
      if (cam == null)
      {
        // we can't get the Camera; perhaps because we're on Linux;
        // call the test done and move on.
        Utils.ytrace("Unable to get Camera on this OS; bypassing test");
        finishAsyncTest();
        return;
      }

      this.nc = nc;
      smtester.setNextStates(NetStreamStateMachine.STATE_STARTPUBLISH);
      ns = nc.getNewNetStream();
      listener = this.asyncEventListenerWrapper(handleSuccessStreamRecordStateChanges);
      ns.addEventListener(StateChangeEvent.STATE_CHANGE, listener);
      ns.attachVideo(cam);

      // just for giggles, let's make a monitor.
      this.vid = new Video(320, 240);

      this.addChild(this.vid);
      vid.attachCamera(cam);
      if (cam.muted)
      {
        camListener = onCameraStateChange;
        cam.addEventListener(StatusEvent.STATUS, camListener);
      }
      else
      {
        ns.publish(RUNNING_SERVER_RECORD_URI, "record");
      }
    }
    private function onCameraStateChange(event : StatusEvent ) : void
    {
      var camera:Camera = Camera(event.target);
      switch (event.code)
      {
        case "Camera.Unmuted":
          // start the next part of our test.
          Utils.ytrace("Camera was  unmuted");
          ns.publish(RUNNING_SERVER_RECORD_URI, "record");
        break;
        default:
          // the user didn't allow the camera; we need to fail the test.
          Utils.ytrace("Camera was not unmuted");
          Assert.fail("Camera was not unmuted");
        break;
      }
      camera.removeEventListener(StatusEvent.STATUS, camListener);
      camListener = null;
    }
    private function handleSuccessStreamRecordStateChanges(event:StateChangeEvent) : void
    {
      var state:String = event.getState();
      smtester.checkState(state);
      switch (state)
      {
        case NetConnectionStateMachine.STATE_CONNECTED:
          break;
        case NetStreamStateMachine.STATE_STARTPUBLISH:
          smtester.setNextStates(NetStreamStateMachine.STATE_PUBLISHING);
          break;
        case NetStreamStateMachine.STATE_PUBLISHING:
          smtester.setNextStates(NetStreamStateMachine.STATE_STOPPING);
          ns.stop();
          break;
        case NetStreamStateMachine.STATE_STOPPING:
          smtester.setNextStates(NetStreamStateMachine.STATE_STOPPED);
          break;
        case NetStreamStateMachine.STATE_STOPPED:
          smtester.setNextStates(
              NetStreamStateMachine.STATE_DISCONNECTED);
          nc.close();
          break;
        case NetStreamStateMachine.STATE_DISCONNECTED:
          this.finishAsyncTest();
          break;
        default:
          // do nothing
          break;

      }
    }
  }
}
