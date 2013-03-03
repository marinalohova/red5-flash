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
  import net.theyard.components.netconnectionsm.NetConnectionStateMachine;
  import net.theyard.components.netstreamsm.NetStreamStateMachine;
  import net.theyard.components.sm.events.StateChangeEvent;
  import net.theyard.components.test.YardTestCase;
  import net.theyard.components.netconnectionsm.NetConnectionStateMachineTestHelper;
  import net.theyard.components.sm.StateMachineTestHelper;
  import net.theyard.components.Utils;

  import flash.media.Video;

  /**
   * Tests if we can play back a recorded file off of an RTMP server using the NetStreamStateMachine.
   * 
   * @see NetStreamStateMachine
   */
  public class NetStreamPlaybackRecordedFileTest extends YardTestCase
  {
    private var nc:NetConnectionStateMachine;
    private var nchelper:NetConnectionStateMachineTestHelper;
    private var ns:NetStreamStateMachine;
    private var smtester:StateMachineTestHelper;
    private var listener:Function;

    private var vid:Video;

    /**
     * The URI the tests expect a running server on.
     * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
     */
    public static const RUNNING_SERVER_URI :String = net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;

    /**
     * The name of the recorded file we attempt to play.
     */
    public static const RUNNING_SERVER_RECORDED_URI :String ="testvid.flv";

    /**
     * Create the test.
     */
    public function NetStreamPlaybackRecordedFileTest(aName:String=null)
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
        ns.removeEventListener(StateChangeEvent.STATE_CHANGE,
            listener);
        listener = null;
      }
      super.tearDown();
    }

    /**
     * Attempt to play the RUNNING_SERVER_RECORDED_URI file.
     *
     * If successful, this test will temporarily overlay the flash screen
     * with a video file playing back the file.  When the file successfully
     * finishes, the video file will be removed.
     *
     * @see #RUNNING_SERVER_RECORDED_URI
     */
    public function testSuccessfulStreamPlay() : void
    {
      Utils.ytrace("Make sure " + RUNNING_SERVER_RECORDED_URI + " is accessible on the Red5 server");

      // This timer needs to run for at least as long as the
      // video plays.
      this.startAsyncTest(30000);

      // This will call the handler function each time the
      // state changes.  it is up to the handler to decide when the test
      // is done, but if it doesn't wrap it up within the Async timeout by
      // calling finishAsyncTest it will fail.
      this.nchelper.connect(this.onConnect_SuccessStreamPlay,
          RUNNING_SERVER_URI, { version : 1 });

    }

    private function onConnect_SuccessStreamPlay(
        nc : NetConnectionStateMachine ) : void
    {
      this.nc = nc;
      ns = nc.getNewNetStream();
      listener = this.asyncEventListenerWrapper(this.handleSuccessStreamPlayStateChanges);
      ns.addEventListener(StateChangeEvent.STATE_CHANGE,
          listener);

      // just for giggles, let's make a monitor.
      this.vid = new Video(320, 240);

      this.addChild(this.vid);
      ns.attachToVideo(this.vid);

      smtester.setNextStates(NetStreamStateMachine.STATE_STARTPLAY);
      ns.play(RUNNING_SERVER_RECORDED_URI, 0); // the 0 should make it look for a recorded file.

    }

    private function handleSuccessStreamPlayStateChanges(
        event:StateChangeEvent) : void
    {
      var state:String = event.getState();
      smtester.checkState(state);
      switch (state)
      {
        case NetStreamStateMachine.STATE_STARTPLAY:
          smtester.setNextStates(NetStreamStateMachine.STATE_PLAYING);
          break;
        case NetStreamStateMachine.STATE_PLAYING:
          smtester.setNextStates(NetStreamStateMachine.STATE_STOPPED);
          // now, just wait for the file to finish playing.
          break;
        case NetStreamStateMachine.STATE_STOPPED:
          smtester.setNextStates(NetStreamStateMachine.STATE_DISCONNECTED);
          ns.detachFromVideo(this.vid);
          this.removeChild(this.vid);
          this.vid = null;
          // close the net connection, which should result
          // in a stream disconnected
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
