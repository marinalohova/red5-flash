/**
 * RED5 Open Source Flash Server - http://www.osflash.org/red5
 *
 * Copyright (c) 2006-2009 by respective authors (see below). All rights reserved.
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
package org.red5.samples.echo.commands
{	
	import com.adobe.cairngorm.commands.ICommand;
	import com.adobe.cairngorm.control.CairngormEvent;
	
	import flash.net.ObjectEncoding;
	import flash.utils.getTimer;
	
	import org.red5.samples.echo.events.DisconnectEvent;
	import org.red5.samples.echo.events.EchoTestEvent;
	import org.red5.samples.echo.events.PrintTextEvent;
	import org.red5.samples.echo.events.RunTestEvent;
	import org.red5.samples.echo.model.EchoTest;
	import org.red5.samples.echo.model.ModelLocator;
	import org.red5.samples.echo.vo.EchoTestResult;
	
	/**
	 * @author Thijs Triemstra (info@collab.nl)
	 */	
	public class RunTestCommand implements ICommand 
	{		 	
	 	private var _model	: ModelLocator = ModelLocator.getInstance();
	 	
	 	/**
	 	 * @param cgEvent
	 	 */	 	
	 	public function execute(cgEvent:CairngormEvent):void
	    { 
			var event:RunTestEvent = RunTestEvent(cgEvent);

			// Create new test and listen for events
			var testObj:EchoTest = new EchoTest();
			testObj.addEventListener( EchoTestEvent.TEST_INIT, onTestInit );
			testObj.addEventListener( EchoTestEvent.TEST_ACTIVE, onTestActive );
			testObj.addEventListener( EchoTestEvent.TEST_COMPLETE, onTestComplete );
			testObj.addEventListener( EchoTestEvent.TEST_FAILED, onTestFailed );
			testObj.addEventListener( EchoTestEvent.TEST_ERROR, onTestFailed );
			testObj.addEventListener( EchoTestEvent.TEST_TIMEOUT, onTestTimeout );
			
			// Setup test and wait for result from call
			testObj.setupTest( _model.testIndex, _model.testParams.items[ _model.testIndex ] );
			
			// Call method in remote service
			if ( _model.echoService == null || _model.echoService.destination == null ) 
			{
				// NetConnection requests
				_model.nc.call( _model.httpMethod, testObj.responder, testObj.input );
			} 
			else 
			{
				// RemotingObject requests
				_model.echoService.echo( testObj.input );
			}
		}
		
		/**
		 * Add test to grid.
		 * 
		 * @param event
		 */		
		private function onTestInit( event:EchoTestEvent ):void 
		{
			var result:EchoTestResult = event.result;
			_model.testResults.addItem(result);
		}
		
		/**
		 * Updates during the test.
		 * 
		 * @param event
		 */		
		private function onTestActive( event:EchoTestEvent ):void 
		{
			var result:EchoTestResult = event.result;
			updateData(result);
		}
		
		/**
		 * @param result
		 */		
		private function updateData( result:EchoTestResult ):void
		{
			_model.testResults.setItemAt(result, _model.testResults.length-1);
		}
		
		/**
		 * Test failed, go to next test.
		 * 
		 * @param event
		 */		
		private function onTestFailed( event:EchoTestEvent ):void 
		{
			var result:EchoTestResult = event.result;
			updateData(result);
			
			_model.testsFailed++;
			_model.testIndex += 1;
			
			var disconnectEvent:DisconnectEvent = new DisconnectEvent();
			disconnectEvent.dispatch();
			
			// more tests left
			if (_model.testIndex < _model.testParams.items.length)
			{
				// continue with the next tests
				var runTestEvent : RunTestEvent = new RunTestEvent();
				runTestEvent.dispatch();
			}
		}
		
		/**
		 * Test succeeded, check if it's the last one, or continue to
		 * the next test.
		 * 
		 * @param event
		 */		
		private function onTestComplete(event:EchoTestEvent):void 
		{
			var result:EchoTestResult = event.result;
			updateData(result);
			
			var testCount: Number = _model.testParams.items.length;
			
			_model.testIndex += 1;
			
			if (_model.nc.objectEncoding == ObjectEncoding.AMF0) 
			{
				testCount = _model.testParams.AMF0COUNT;
			}
			printTestResults( testCount );
		}
		
		/**
		 * Test timed out, server is down or fatal errored.
		 * 
		 * @param event
		 */		
		private function onTestTimeout(event:EchoTestEvent):void 
		{
			var result:EchoTestResult = event.result;
			updateData(result);
			
			// stop testing
		}
		
		private function printTestResults(testCount:Number):void
		{
			var testTime:Number = (getTimer() - _model.globalTimer) / 1000;
			var printTextEvent:PrintTextEvent;
			var disconnectEvent:DisconnectEvent;
			
			if ( _model.testIndex < testCount ) 
			{
				// Still tests left, start next one.
				var runTestEvent : RunTestEvent = new RunTestEvent();
				runTestEvent.dispatch();
			} 
			else if ( _model.testsFailed == 0 ) 
			{
				// All tests were completed with success.
				printTextEvent = new PrintTextEvent("<br><b>Successfully ran " +
													_model.success + testCount + 
				           							"</font> test(s) in " + testTime +
				           							" seconds.</b><br/>");
				printTextEvent.dispatch();
				
				disconnectEvent = new DisconnectEvent();
				disconnectEvent.dispatch();
			} 
			else 
			{
				// One or more tests failed.
				printTextEvent = new PrintTextEvent("<br><b>Ran " + _model.success +
													testCount + "</font> test(s) in " + 
				           							testTime + " seconds, " + _model.failure
				           							+ _model.testsFailed + "</font> test(s) failed.</b>");
				printTextEvent.dispatch();
				
				disconnectEvent = new DisconnectEvent();
				disconnectEvent.dispatch();
			}
		}
		
	}
}
