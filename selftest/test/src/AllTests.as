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
package
{
  import flash.system.Security;
  import flash.system.SecurityPanel;
  import asunit.framework.TestSuite;
  import asunit.framework.TestResult;
  import flash.events.Event;
  import flash.system.Capabilities;
  import flash.system.System;
  import flash.utils.*;
  import net.AllTests;
  import org.AllTests;

  /**
   * @private
   */
  public class AllTests extends TestSuite
  {
    public function AllTests()
    {
      // Throw this up for the entire run; this allows human operators
      // to run this once, and set the "remember" setting so that on
      // future runs the getCamera() method doesn't have to block
      Security.showSettings(SecurityPanel.PRIVACY);

      // register a complete handler that will be called by AsUnit
      // when this suite has finished
      addEventListener(Event.COMPLETE, onSuiteCompleteHandler);

      // Now, add sub-tests here.
      addTest(new net.AllTests());
      addTest(new org.AllTests());
    }

    public function onSuiteCompleteHandler(e:Event):void
    {
      // Now, even though AsUnit called that the Suite was complete,
      // it'll still do some clean-up when this function returns.
      // So, we ask Flash to call us whenever AsUnit exits
      // this set of function calls
      setTimeout(nextClockCycle, 1);
    }

    public function nextClockCycle():void
    {
      // And we get the result and figure out how to exit
      var result:TestResult = (getResult() as TestResult);
      var exitVal:int = 0;
      if(result.runCount() == 0 || // No tests ran
          !result.wasSuccessful())
      {
        exitVal = 255;
      }
      else
      {
        exitVal = 0;
      }
      // now figure out if we can actually exit
      if (Capabilities.isDebugger &&
          Capabilities.playerType == "StandAlone")
      {
        trace("setting exitVal to: " + exitVal + " and exiting the player");
        try
        {
          System.exit(exitVal);
        }
        catch (e:Error)
        {
          trace("could not exit flash player; you must set it to be trusted to allow an exit");
        }
      }
    }
  }
}
