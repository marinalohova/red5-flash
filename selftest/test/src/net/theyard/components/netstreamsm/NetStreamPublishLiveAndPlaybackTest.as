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
  import flash.events.TimerEvent;
  import flash.media.Camera;
  import flash.media.Video;
  import flash.utils.Timer;

  /**
   * Tests if we can publish a live stream and play it back off of an RTMP server using the NetStreamStateMachine.
   * 
   * @see NetStreamStateMachine
   */
  public class NetStreamPublishLiveAndPlaybackTest extends YardTestCase
  {
    private var nc:NetConnectionStateMachine;
    private var nchelper:NetConnectionStateMachineTestHelper;
    private var playNs:NetStreamStateMachine;
    private var playNsListener:Function;
    private var pubNs:NetStreamStateMachine
    private var pubNsListener:Function;
    private var cam:Camera;
    private var camListener:Function;

    // playback state machine helper
    private var playSm:StateMachineTestHelper;

    private var numPlays:uint;

    // publish state machine helper
    private var pubSm:StateMachineTestHelper

    private var vid:Video;

    /**
     * The URI the tests expect a running server on.
     * @see net.theyard.components.test.DefaultFixtures#RUNNING_SERVER_URI
     */
    public static const RUNNING_SERVER_URI :String = net.theyard.components.test.DefaultFixtures.RUNNING_SERVER_URI;

    /**
     * The URI we'll publish to and playback from.
     */
    public static const RUNNING_SERVER_PUBLISH_URI :String ="testlive";

    /**
     * How long we publish a live stream for.
     */
    public static const MILLISECONDS_TO_PUBLISH : uint = 10000;

    /**
     * How much time we spend playing back the life stream before we stop.
     */
    public static const MILLISECONDS_TO_PLAY_AT_ONE_TIME : uint = 2000;

    /**
     * How many times we stop and start playback of the published live stream
     */
    public static const MAX_TIMES_TO_RESTART_PLAYING :uint = 2;

    /**
     * If the test hasn't finished in this amount of time, it fails.
     */
    public static const MILLISECONDS_ASYNC_TEST_TIMEOUT :uint = 30000; 

    /**
     * Create the test
     */
    public function NetStreamPublishLiveAndPlaybackTest(aName:String=null)
    {
      super(aName);
      this.playSm = new StateMachineTestHelper();
      this.pubSm = new StateMachineTestHelper();
      this.nchelper = new NetConnectionStateMachineTestHelper(this.asyncEventListenerWrapper);
      this.numPlays = 0;
    }

    /**
     * @see net.theyard.components.test.YardTestCase#setUp()
     */
    protected override function setUp() : void
    {
      super.setUp();
      this.nc = null;
      this.pubNs = null;
      this.pubNsListener = null;
      this.playNs = null;
      this.playNsListener = null;
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
        if (this.playNs)
        {
          this.playNs.detachFromVideo(this.vid);
        }
        this.vid = null;
      }
      if (camListener != null)
      {
        cam.removeEventListener(StatusEvent.STATUS, camListener);
        camListener = null;
      }
      if (this.pubNsListener != null)
      {
        this.pubNs.removeEventListener(StateChangeEvent.STATE_CHANGE, this.pubNsListener);
        this.pubNsListener = null;
      }
      if (this.playNsListener != null)
      {
        this.playNs.removeEventListener(StateChangeEvent.STATE_CHANGE, this.playNsListener);
        this.playNsListener = null;
      }
      this.pubNs = null;
      this.playNs = null;
      if (this.nc)
      {
        this.nc.close();
      }
      this.nc = null;
      super.tearDown();
    }

    /**
     * This test case publishes a stream, and then plays it back and stops playback.
     *
     * <p>
     * It publishes the stream to RUNNING_SERVER_PUBLISH_URI
     * </p><p>
     * It then starts playback (opening a window on the flash player to show
     * the video) of that live stream.  It will start and stop the playback
     * of that stream up to MAX_TIMES_TO_RESTART_PLAYING.
     * </p><p>
     * This means if you're watching the test you'll see the feed from your
     * camera for a few seconds, then it will stop and restart a few seconds
     * later.
     * </p><p>
     * Lastly if for some reason Flash can't get a camera this test is ignored,
     * but if flash gets a Muted camera it relies on the user to enable it before
     * this test runs.  For that reason, you should usually run this test
     * attended once and set the Flash security dialogs to always give it camera
     * access.  After that, it can run unattended.
     * </p>
     * @see #RUNNING_SERVER_PUBLISH_URI
     * @see #MAX_TIMES_TO_RESTART_PLAYING
     * @see #MILLISECONDS_TO_PLAY_AT_ONE_TIME
     * @see #MILLISECONDS_TO_PUBLISH
     * @see #MILLISECONDS_ASYNC_TEST_TIMEOUT
     */
    public function testPublishAndPlayback() : void
    {
      this.startAsyncTest(MILLISECONDS_ASYNC_TEST_TIMEOUT);

      // This will call the handler function each time the
      // state changes.  it is up to the handler to decide when the test
      // is done, but if it doesn't wrap it up within the Async timeout by
      // calling finishAsyncTest it will fail.

      this.nchelper.connect(this.onConnect_Success,
          RUNNING_SERVER_URI, { version : 1 });

    }

    private function onConnect_Success( nc : NetConnectionStateMachine ) : void
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
      this.pubSm.setNextStates(NetStreamStateMachine.STATE_STARTPUBLISH);
      this.pubNs = nc.getNewNetStream();
      this.pubNsListener = this.asyncEventListenerWrapper(this.publishOnStateChange);

      this.pubNs.addEventListener(StateChangeEvent.STATE_CHANGE, this.pubNsListener);

      this.pubNs.attachVideo(cam);

      if (cam.muted)
      {
        camListener = this.asyncEventListenerWrapper(this.onCameraStateChange);
        cam.addEventListener(StatusEvent.STATUS, this.camListener);
      }
      else
      {
        this.pubNs.publish(RUNNING_SERVER_PUBLISH_URI, "live");
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
          this.pubNs.publish(RUNNING_SERVER_PUBLISH_URI, "live");
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
    private function publishOnStateChange(event : StateChangeEvent) : void
    {
      var state :String = event.getState();
      pubSm.checkState(state);
      switch (state)
      {
        case NetStreamStateMachine.STATE_STARTPUBLISH:
          pubSm.setNextStates(NetStreamStateMachine.STATE_PUBLISHING);
          break;
        case NetStreamStateMachine.STATE_PUBLISHING:
          // Start our playback.
          this.startPlayStream();
          // and set a timer to stop publishing in 10 seconds.
          var t :
            Timer = new Timer(MILLISECONDS_TO_PUBLISH, 1);

          t.addEventListener(TimerEvent.TIMER_COMPLETE,
              this.asyncEventListenerWrapper(
                function () : void { this.pubNs.stop(); }));
          t.start();
          pubSm.setNextStates(
              NetStreamStateMachine.STATE_STOPPING,
              NetStreamStateMachine.STATE_STOPPED,
              NetStreamStateMachine.STATE_DISCONNECTED
              );
          break;
        case NetStreamStateMachine.STATE_STOPPED:
          // now done, next is disconnect.
          this.pubNs.removeEventListener(StateChangeEvent.STATE_CHANGE,
              this.pubNsListener);
          this.pubNsListener = null;
          break;
        default:
          // ignore
          break;
      }
    }

    private function startPlayStream( ) : void
    {
      this.playNs = nc.getNewNetStream();
      this.playNsListener = this.asyncEventListenerWrapper(this.playOnStateChange);

      this.playNs.addEventListener(StateChangeEvent.STATE_CHANGE,
          this.playNsListener);

      // just for giggles, let's make a monitor.
      this.vid = new Video(320, 240);

      this.addChild(this.vid);
      this.playNs.attachToVideo(this.vid);
      this.doPlay();
    }
    private function doPlay() : void
    {
      this.playSm.setNextStates(NetStreamStateMachine.STATE_STARTPLAY);
      this.playNs.play(RUNNING_SERVER_PUBLISH_URI);
      this.numPlays = this.numPlays + 1;
    }

    private function playOnStateChange(event : StateChangeEvent) : void
    {
      var state :String = event.getState();
      playSm.checkState(state);
      var t :Timer;
      switch (state)
      {
        case NetStreamStateMachine.STATE_STARTPLAY:
          playSm.setNextStates(NetStreamStateMachine.STATE_PLAYING);
          break;

        case NetStreamStateMachine.STATE_PLAYING:
          // the stream should stop recording / publishing automatically
          // which means we should go straight to stopped.
          playSm.setNextStates(NetStreamStateMachine.STATE_STOPPING);
          // do a bunch of starts and stops every 5 seconds quickly.
          Utils.ytrace("PPPPPPPPPPPPPPPPPPPPPPP: " + numPlays + " : " + MAX_TIMES_TO_RESTART_PLAYING);
          if (this.numPlays <= MAX_TIMES_TO_RESTART_PLAYING)
          {
            t = new Timer(MILLISECONDS_TO_PLAY_AT_ONE_TIME, 1);
            t.addEventListener(TimerEvent.TIMER_COMPLETE,
                function (e:TimerEvent):void
                {
                Utils.ytrace("timer hit; stopping playback");
                playNs.stop();
                }
                );
            t.start();
          }
          break;
        case NetStreamStateMachine.STATE_STOPPING:
          playSm.setNextStates(NetStreamStateMachine.STATE_STOPPED);
          break;
        case NetStreamStateMachine.STATE_STOPPED:
          // Awesome.  Now, the test is done.
          Utils.ytrace("SSSSSSSSSSSSSSSSSSSSSSS: " + numPlays + " : " + MAX_TIMES_TO_RESTART_PLAYING);

          if (this.numPlays < MAX_TIMES_TO_RESTART_PLAYING)
          {
            t = new Timer(MILLISECONDS_TO_PLAY_AT_ONE_TIME, 1);
            t.addEventListener(TimerEvent.TIMER_COMPLETE,
                function (e:TimerEvent):void
                {
                Utils.ytrace("timer hit; starting playback");
                doPlay();
                }
                );
            t.start();
          }
          else
          {
            playSm.setNextStates(NetStreamStateMachine.STATE_DISCONNECTED);
            playNs.removeEventListener(StateChangeEvent.STATE_CHANGE,
                playNsListener);
            this.playNsListener = null;
            pubNs.removeEventListener(StateChangeEvent.STATE_CHANGE,
                pubNsListener);
            this.pubNsListener = null;
            this.finishAsyncTest();
          }
          break;
        default:
          // ignore
          break;
      }
    }
  }
}
