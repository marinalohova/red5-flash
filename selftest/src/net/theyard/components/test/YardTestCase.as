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
  import asunit.errors.AssertionFailedError;
  import asunit.framework.TestCase;
  import asunit.framework.TestResult;
  import asunit.framework.TestFailure;
  import asunit.framework.Assert;

  import net.theyard.components.Utils;

  import flash.events.Event;
  import flash.errors.IllegalOperationError;
  import flash.utils.*;

  /**
   * A wrapper for an asunit.framework.TestCase that attempts to
   * do the following extra things:
   * <ul>
   * <li>Attempts to print the method name on tearDown() (unfortunately we can't get it at setUp()</li>
  *  <li>Provides some methods for starting an asynchronous test and finishing one.</li>
  *  <li>Provides some means for folks to fail a test without including asunit
  *    directly </li>
  *  <li>Provides wrapper methods for event handlers that ensure if they fail that
  *    asunit correct accounts for it.</li>
  *  </ul>
  */
  public class YardTestCase extends TestCase
  {
    private var mTestCompleteCallback:Function = null;
    private var mTestTimeout:int = 0;
    private var mTestStartTime:int = 0;
    private var mNumStartingErrors:int = 0;

    /**
     * Convenience methods for failing a test
     */
    public static function fail(message:String):void
    {
      Assert.fail(message);
    }

    /**
     * A convenience method for calling assert
     */
    public static function assert(aCondition:Boolean, aMsg:String):void
    {
      if (aCondition == false)
      {
        Assert.assertTrue(aMsg, aCondition);
        //throw new Error("ASSERTION FAIL: " + aMsg);
      }
    }


    /**
     * Make a test with the given name.
     */
    public function YardTestCase(aName:String=null)
    {
      super(aName);
      // default to debugging enabled
      Utils.setDebuggingEnabled(true);
      Utils.setHtmlEnabled(false);
      mTestCompleteCallback = null;
    }

    /**
     * Called before each test is run
     */
    protected override function setUp():void
    {
      super.setUp();
      mTestCompleteCallback = null;
      Utils.ytrace("-----START-----");
      mNumStartingErrors = (getResult() as TestResult).errorCount();
    }

    /**
     * Called after each test has finished.
     */
    protected override function tearDown():void
    {
      // Let's check to see if we got an IllegalOperationError and if so
      // print out the method name to help debugging
      var result:TestResult = getResult() as TestResult;
      var numErrors:int = result.errorCount();
      // only do this if it looks like more errors were added since last
      // setUp()
      if (numErrors > mNumStartingErrors)
      {
        // OK, we got an error; let's see if the last looks like
        // a timeout problem
        var failure:TestFailure = TestFailure(result.errors()[numErrors-1]);
        if (failure.thrownException() is IllegalOperationError)
        {
          // looks like a timeout
          Utils.ytrace("Asynchronous timeout ("
              + failure.exceptionMessage()
              + ") may have occurred on: "
              + getCurrentMethod());
        }
      }
      Utils.ytrace("----- END -----: " + getCurrentMethod());
      super.tearDown();
      mTestCompleteCallback = null;
    }

    /**
     * Start an asynchronous test.
     *
     * Starts an async test that will fail in aTimeout milliseconds if
     * finishAyncTest() is not called.  We will callback aFunction when done.
     *
     * @param aTimeout The max time, in milliseconds, this tests should run for.
     * @param aFunction A callback function that will be called if this method
     *   successfully finishes.
     *
     * @see TestCase#addAync()
     * @see #finishAsyncTest()
     */
    protected function startAsyncTest(aTimeout:int,aFunction:Function=null) : void
    {
      Utils.ytrace("Starting async test (timeout=" + aTimeout + "): " + getCurrentMethod());
      assertTrue("AsyncTest already in progress", mTestCompleteCallback == null);
      mTestTimeout = aTimeout;
      mTestStartTime = getTimer();
      mTestCompleteCallback = this.addAsync(aFunction, aTimeout);
      assertTrue("AsyncTest callback is null.", mTestCompleteCallback != null);
    }

    /**
     * A method your function calls to indicate that a test has finished.
     *
     * If you don't call this method back, then asUnit will assume your test fails.
     * <p></p>
     * If you're test has failed already, you don't need to worry about calling this.
     *
     * @see #startAsyncTest()
     */
    protected function finishAsyncTest():void
    {
      if (mTestCompleteCallback != null)
      {
        // Only do this if the callback is still set; this handles cases where
        // asUnit does the tearDown already, and the finish is late

        // first check if finishAsyncTest was called within one flash
        // clock tick and the timer should have expired.  We'll error
        // for that.
        var timeNow:int = getTimer();
        var duration:int = timeNow - mTestStartTime;
        // Now this is odd, but we need to clear out the callback because
        // we'll call tearDown() during the application.  Sigh.
        var tempFunc:Function = mTestCompleteCallback;
        mTestCompleteCallback = null;
        if (duration > mTestTimeout)
        {
          // Add an error for this
          Utils.ytrace("duration ("+duration+") exceeds ("+mTestTimeout+
              "); adding error to reflect this");
          this.getResult().addError(this, new IllegalOperationError("TestCase.timeout (" + duration + "ms) exceeded on an asynchronous test method (blocking?)."));
        }
        // and this method will call tearDown()
        tempFunc.apply(this);
      } else {
        Utils.ytrace("Ignoring late finishAsyncTest");
      }
    }

    /**
     * Takes a function that you'd want called by an AS Event dispatcher, and
     * returns another function you should use instead to your Event dispatcher.
     *
     * This new function will call your function, and then correctly account for
     * any Assert failures, and call the apporpriate call back functions if needed.
     *
     * @param aFunc The event listener you want to wrap.
     */
    public function asyncEventListenerWrapper(aFunc:Function):Function
    {
      var context:YardTestCase = this;
      return function (aEvent:Event):void
      {
        try
        {
          if (context.getIsComplete() == false)
          {
            aFunc.call(context, aEvent);
          }
          else
          {
            Utils.ytrace("Event arrived after test complete: " + aEvent);
          }
        }
        catch (err:AssertionFailedError)
        {
          context.getResult().addFailure(context, err);
        }
      }
    }
  }
}
