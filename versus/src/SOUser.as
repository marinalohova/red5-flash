/**
 * Load tester Shared Object User object
 * 
 * @author Paul Gregoire (mondain@gmail.com)
 */
package {
	
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.Timer;
	
	import mx.core.*;
	import mx.events.*;	
	
	public class SOUser {
		
	    public var sid:String;
		private var nc:NetConnection;
		public var parent:Object;
		public var path:String;
		public var so:SharedObject;
		
		private var useDirty:Boolean = false;
		
		private var updateTimer:Timer = null;
		private var updateInterval:int = 10;
		
		private var encoding:uint = ObjectEncoding.AMF3;

		/**
		 * Number of times this client has set a property on a SharedObject
		 */
		public var changesMade:int;

		/**
		 * Number of times this client has recieved a SyncEvent
		 */
		public var syncEventsRecieved:int;

		public function SOUser(_doc:Object):void {
			this.parent = _doc;
		}
		
		public function toString():String {
			return '[SOUser id='+sid+']';			
		}
	
		public function start():void {       	
			log('Start');	
			//  create the netConnection
			nc = new NetConnection();
			nc.objectEncoding = encoding;
			//  set it's client/focus to this
			nc.client = this;
			// add listeners for netstatus and security issues
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);		
			
			nc.connect(path, null);   
		}
		
		public function stop():void {
			log('Stop');
			if (updateTimer) {
				updateTimer.removeEventListener(TimerEvent.TIMER, updateSO);
				updateTimer.stop();
				updateTimer = null;
			}
			if (so) {
				so.close();
				so.removeEventListener(SyncEvent.SYNC, onSync);
				so.removeEventListener(NetStatusEvent.NET_STATUS, soStatusHandler);
				so.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				so.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				so.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			}
			if (nc.connected) {
				nc.close();		
				nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				nc.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				nc.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);					
			}
		}	
		
		public function onBWDone(... obj):void {
		}
	
		public function onBWCheck(... rest):uint {
			return 0;
		}
		
		public function onSync(event:SyncEvent):void {
			trace("onSync");
			syncEventsRecieved++;
			if (!updateTimer) {
				startUpdater(); 
			}
		}		

		private function netStatusHandler(event:NetStatusEvent):void {
			trace('Net status: '+event.info.code);
	        switch (event.info.code) {
	            case "NetConnection.Connect.Success":
					parent.soUserList.addItem(this);
					startSO();              
	                break;
	            case "NetConnection.Connect.Failed":					
	            case "NetConnection.Connect.Rejected":
					stop();
	            case "NetConnection.Connect.Closed":	                
	            	log("Failed / Rejected / Closed");
					parent.soUserList.removeItem(this);
					break;                
	        }				
		}	

		private function soStatusHandler(event:NetStatusEvent):void {
			trace('SO status: '+event.info.code);
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					startUpdater();              
					break;
				case "SharedObject.Flush.Success":
					log("SO flush success");
					break;                
				case "SharedObject.Flush.Failed":
					log("SO flush failed");
					break;
				case "SharedObject.BadPersistence":
					log("SO has already been created with different flags");
					break;
				case "SharedObject.UriMismatch":
					log("SO invalid URI");
					break;             
				case "NetConnection.Connect.Failed":
				case "NetConnection.Connect.Rejected":
				case "NetConnection.Connect.Closed":	                
					log("Failed / Rejected / Closed");
					break;                
			}				
		}			
		
		public function startSO():void {
			so = SharedObject.getRemote("loadtestSO", nc.uri, false);
			so.client = this;
			so.addEventListener(SyncEvent.SYNC, onSync);
			so.addEventListener(NetStatusEvent.NET_STATUS, soStatusHandler);
			so.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			so.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			so.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);			
			so.connect(nc);	
		}		
		
		public function startUpdater():void {
			if (updateTimer) {
				updateTimer.stop();
				updateTimer = null;
			}
			log('Creating timer');
			updateTimer = new Timer(updateInterval);
			updateTimer.addEventListener(TimerEvent.TIMER, updateSO);
			updateTimer.start();				
		}
				
		public function updateSO(... obj):void {
			var rnd:int = int(Math.random() * 100.0);
			log('Updating SO - value: ' + rnd);		
			so.setProperty("randomInteger", rnd);
			if (useDirty) {							
				so.setDirty("randomInteger");	
			}
			//so.send();
			changesMade++;
		}
				
		public function getChangesMade():int {
			return changesMade;
		}		
		       
		public function getSyncEventsReceived():int {
			return syncEventsRecieved;
		}
		       
		//called by the server
		public function setClientId(param:Object):void {
			log('Set client id called: '+param);
		}		
		
		public function setEncoding(param:int):void {
			switch(param) {
				case 0:
					encoding = ObjectEncoding.AMF0;
					break;
				default: 
					encoding = ObjectEncoding.AMF3;
			}
		}			
			
		public function setUpdateInterval(interval:int):void {
			updateInterval = int(interval);
		}	
		
		public function setUseDirtyFlag(flag:Boolean):void {
			useDirty = Boolean(flag);
		}			
			
		private function securityErrorHandler(e:SecurityErrorEvent):void {
			log('Security Error: '+e);
		}
	
		private function ioErrorHandler(e:IOErrorEvent):void {
			log('IO Error: '+e);
		}
		
		private function asyncErrorHandler(e:AsyncErrorEvent):void {
			log('Async Error: '+e);
		}		
		
		public function log(text:String):void {
			trace(this.toString() + ' ' + text);
		}		
		
	}
}