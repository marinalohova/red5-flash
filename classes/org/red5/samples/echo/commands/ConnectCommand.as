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
	
	import mx.rpc.remoting.RemoteObject;
	
	import org.red5.samples.echo.events.ConnectEvent;
	import org.red5.samples.echo.events.PrintTextEvent;
	import org.red5.samples.echo.events.StartTestsEvent;
	import org.red5.samples.echo.model.ModelLocator;
	
	/**
	 * @author Thijs Triemstra (info@collab.nl)
	 */	
	public class ConnectCommand implements ICommand 
	{	
		private var _model 		: ModelLocator = ModelLocator.getInstance();
		private var _url		: String;
		private var _protocol	: String;
		private var _encoding	: uint;
		
	 	/**
	 	 * @param cgEvent
	 	 */	 	
	 	public function execute(cgEvent:CairngormEvent):void
	    { 
	    	var flushStatus		: String = null;
	    	var startTestsEvent	: StartTestsEvent = new StartTestsEvent();
			var event			: ConnectEvent = ConnectEvent(cgEvent);
			
			if (_model.nc.connected)
			{
				_model.nc.close();
			}
			
			_protocol = event.protocol;
			_encoding = event.encoding;
			_model.nc.objectEncoding = _encoding;
			
			if (_protocol == "http")
			{
			    // Remoting...
				_url = _model.httpServer;
				_model.local_so.data.httpUri = _url;
			}
			else
			{
				// RTMP...
				_url = _model.rtmpServer;
				_model.local_so.data.rtmpUri = _url;
			}
            
            _model.statusText = "Connecting through <b>" + _protocol.toUpperCase() + "</b> using <b>AMF" 
                         		+ _encoding  + "</b> encoding...";
            try
            {
                flushStatus = _model.local_so.flush();
            } 
            catch ( error:Error ) 
            {
            	var printTextEvent:PrintTextEvent = new PrintTextEvent("<br/><b>" + _model.failure +
            										"Local SharedObject error: </font></b>" +
            										error.getStackTrace() + "<br/>");
				printTextEvent.dispatch();
            }
            
			if (_protocol == "remoteObject") 
			{
				// Setup a RemoteObject
            	_model.echoService = new RemoteObject("Red5Echo");
            	_model.echoService.source = "EchoService";
            	
            	// echoService.addEventListener( ResultEvent.RESULT, onRem );
            	
				if (_model.user.userid.length > 0)
				{
					// test credentials feature
					_model.echoService.setCredentials(_model.user.userid, _model.user.password);
					_model.statusText += " ( using setCredentials )";
				}
				_model.statusText += "...";
				
				startTestsEvent.dispatch();
				// ignore rest of setup logic
				return;
			}
			else if (_protocol == "sharedObject")
			{
				
			}
			
			if (_model.user.userid.length > 0)
			{
				// test credentials feature
				_model.nc.addHeader("Credentials", false, Object(_model.user));
				_model.statusText += " ( using setCredentials )";
			}

			_model.statusText += "...";
			if (_model.echoService != null)
			{
				// http_txt.text
				_model.echoService.destination = null;
			}
			// connect to server if a url is given
			if (_url != '')
			{
				_model.nc.connect(_url);
				//			
				if ( _protocol == "http" )
				{
					// Don't wait for a successfull connection for AMF0/AMF3 remoting tests.
					startTestsEvent.dispatch();
				}
				
				_model.connecting = true;
			}
			else
			{
				printTextEvent = new PrintTextEvent("\n<b>Host should not be empty</b>");
				printTextEvent.dispatch();
			}
			trace(_url);
		}
		
	}
}
