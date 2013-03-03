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
package net.theyard.components.test
{
  import flash.utils.Timer
  import flash.events.TimerEvent;
  import flash.errors.IllegalOperationError;
  import flash.events.AsyncErrorEvent;
  import flash.events.ErrorEvent;

  import net.theyard.components.Utils;

  import asunit.framework.TestResult;

  /**
   * This test tests our customization of the Asunit TestCase.
   *
   * <p>
   * And yes, it's a little broken to test if the test framework
   * is working by using the test framework itself, but hey,
   * I don't come into your house and call your drapes tacky.
   * <p></p>
   * Actually, come to mention it, they are looking a little ratty.
   * <p></p>
   * Did you know you can easily make new curtains?  But, I digress...
   *
   * @see Nice Curtains
   */
  public class YardTestCaseTest extends YardTestCase
  {
    private var mAsyncFailExpected:Boolean = false;
    private var mTimer:Timer = null;
    private var mTimerHandler:Function = null;

    /**
     * Create the test.
     */
    public function YardTestCaseTest(aName:String=null)
    {
      super(aName);
    }

    /**
     * @see net.theyard.components.test.YardTestCase#setUp()
     */
    protected override function setUp():void
    {
      mAsyncFailExpected = false;
      mTimer = null;
      mTimerHandler = null;
      super.setUp();
    }

    /**
     * @see net.theyard.components.test.YardTestCase#tearDown()
     */
    protected override function tearDown():void
    {
      Utils.ytrace("Running tearDown: " + getCurrentMethod());
      clearTimer();
      if (mAsyncFailExpected)
      {
        // check for an async fail, and remove it from the errors
        // if it's there.
        popTopError(1);
        // clear our async flag
        mAsyncFailExpected = false;
      }
      super.tearDown();
      
    }

    private function popTopError(expectedErrors:int):void
    {
      // check for an async fail, and remove it from the errors
      // if it's there.
      var result:TestResult = (getResult() as TestResult);
      var count:int = result.errorCount();
      assertTrue(expectedErrors <= count);
      // success; we failed as expected
      Utils.ytrace("async fail test timed out as expected; clearing error");
      if (expectedErrors > 0)
      {
        result.errors().pop();
        assertTrue((getResult() as TestResult).errorCount() == count-1);
      }
    }

    private function setTimer(delay:int, handler:Function):void
    {
      var mymethod:String = getCurrentMethod();
      mTimer = new Timer(delay, 1);
      mTimerHandler = asyncEventListenerWrapper(
        function ( e:TimerEvent ):void {
          Utils.ytrace("timer for method: " + mymethod);
          onAsyncSuccessCompletion(e);
        });

      mTimer.addEventListener(TimerEvent.TIMER_COMPLETE, mTimerHandler);
      mTimer.start();
    }

    private function clearTimer():void
    {
      if (mTimer != null)
      {
        if (mTimerHandler != null)
        {
          Utils.ytrace("Removing event listener for TimerEvent.TIMER_COMPLETE on: " + getCurrentMethod());
          mTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, mTimerHandler);
          mTimerHandler = null;
        }
        mTimer.stop();
        mTimer = null;
      }
    }

    /**
     * Test that success correctly registeres with the YardTestCase
     */
    public function testSuccess():void
    {
      assertTrue("test true", true);
    }

    /**
     * Test that a failed test correctly fails.
     */
    public function testFailure():void
    {
      var failed:Boolean = false;

      try {
        Utils.ytrace("attempting test that should fail (and be caught");
        assertTrue("should fail", false);
      }
      catch (e:Error)
      {
        Utils.ytrace("got expected failure of test");
        failed = true;
      }
      if (!failed)
        fail("did not fail as expected; of course, then this is likely to be a waste of time, isn't it?");
    }

    /**
     * Test that an asynchronous test can be set up that allows us
     * to exit this function (i.e. back to the asunit main loop) but
     * still register success later.
     */
    public function testAsyncSuccess():void
    {
      startAsyncTest(1000); // set a one second timeout
      setTimer(500, onAsyncSuccessCompletion);
    }

    /**
     * Make sure that if an async test finishes successfully even before we return
     * back to Asunit that we successfully detect that success.
     *
     * <p>
     * Note that this test will cause an 'E' to be printed in the
     * running tab that Asunit reports on, but in the final report Asunit
     * will correctly know that this test didn't really fail.  To find
     * out if you actually failed you can only use the FINAL error count
     * from asunit.
     * </p>
     */
    public function testAsyncSuccessWithFinishDuringFirstTick():void
    {
      startAsyncTest(50); // set a very fast timeout
      setTimer(500, onAsyncSuccessFailure);
      finishAsyncTest();
      // this should take at least 50 ms
      for(var i:int = 0; i < 10000000; ++i)
      {
        --i;
        ++i;
      }
      popTopError(0);
    }


    /**
     * Make sure that if an async test fails even before we return
     * back to Asunit that we successfully detect that failure.
     * <p>
     * Note that this test will cause an 'E' to be printed in the
     * running tab that Asunit reports on, but in the final report Asunit
     * will correctly know that this test didn't really fail.  To find
     * out if you actually failed you can only use the FINAL error count
     * from asunit.
     * </p>
     * <p>
     * Currently this test is disabled as it causes an 'E' to be
     * printed in the AsUnit test runner.  We remove this error from the
     * final count, but still to avoid confusion...
     * </p>
     */
    public function disabled_testAsyncFailureWithFinishDuringFirstTick():void
    {
      startAsyncTest(50,
        function(args:*):*{
          Utils.ytrace("popping error so that test actually succeeds");
          popTopError(1);
        }); // set a very fast timeout
      setTimer(500, onAsyncSuccessFailure);
      // this should take at least 50 ms
      for(var i:int = 0; i < 10000000; ++i)
      {
        --i;
        ++i;
      }
      finishAsyncTest();
    }

    /**
     * Test that an asychronous test can fail in the future and we'll detect it correctly.
     *
     * <p>
     * Note that this test will cause an 'E' to be printed in the
     * running tab that Asunit reports on, but in the final report Asunit
     * will correctly know that this test didn't really fail.  To find
     * out if you actually failed you can only use the FINAL error count
     * from asunit.
     * </p>
     * <p>
     * Currently this test is disabled as it causes an 'E' to be
     * printed in the AsUnit test runner.  We remove this error from the
     * final count, but still to avoid confusion...
     * </p>
     */
    public function disabled_testAsyncFailure():void
    {
      mAsyncFailExpected = true;
      startAsyncTest(100); // set a 0.1 second timeout, so this should fail first 
      setTimer(500, onAsyncSuccessCompletion);
    }

    private function onAsyncSuccessCompletion(e:TimerEvent):void
    {
      clearTimer();
      finishAsyncTest();
    }
    private function onAsyncSuccessFailure(e:TimerEvent):void
    {
      clearTimer();
      fail("always fail here");
    }

    /**
     * Tests that we fail horribly if for some reason an exception handler isn't wrapped in a safe wrapper.
     *
     * Fail horribly means that the flash debug player will pop up an
     * exception that we didn't catch and we'll be unable to exit the player.
     */
    public function _testNonwrappedException():void
    {
      startAsyncTest(100); // set a 0.1 second timeout, so this should fail first 
      var timer:Timer = new Timer(1, 1);
      timer.addEventListener(TimerEvent.TIMER_COMPLETE,
        function(e:TimerEvent):void {
          Utils.ytrace("Throwing an error we hope will fail");
          finishAsyncTest();
          throw new IllegalOperationError("Throwing an error that is not wrapped by ASUNIT");
        });
      timer.addEventListener(ErrorEvent.ERROR,
        function(e:ErrorEvent):void {
          Utils.ytrace("caught error: " + e);
        });
      timer.start();
    }
    /**
     * Only enable this test when you want to make sure that AsUnit completely
     * handles (without us repairing) an async failure.
     */
    public function _testAsyncFailureThatIsNotRecoveredFrom():void
    {
      startAsyncTest(100);
    }

  }
}
