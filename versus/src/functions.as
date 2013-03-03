/**
 * Main script
 * 
 * @author Paul Gregoire (mondain@gmail.com)
 */
	
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.*;
	import mx.events.*;

	[Bindable]
	private var hostString:String = '192.168.1.2';

	[Bindable]	
	public var soUserList:ArrayCollection = new ArrayCollection();	
	
	private static var timer:Timer = null;

	private static var totalTime:int = 0;
	private static var startTime:int;

	public function init():void {
		//Security.allowDomain("*");		
		var pattern:RegExp = new RegExp("http://([^/]*)/");				
		if (pattern.test(FlexGlobals.topLevelApplication.url) == true) {
			var results:Array = pattern.exec(FlexGlobals.topLevelApplication.url);
			hostString = results[1];
			//need to strip the port to avoid confusion
			if (hostString.indexOf(":") > 0) {
				hostString = hostString.split(":")[0];
			}
		}
	}

	//called by the server in the event of a server side error
	public function setAlert(alert:Object):void {
		log('Got an alert: '+alert);
		Alert.show(String(alert), 'Server Error');
	}	
	        
    public function startTest():void {
    	log('Start test');		
    	var delay:int = 0.1;
    	//convert to seconds
    	delay = (delay * 1000);
    	//create the timer only once
    	if (timer == null) {
	    	timer = new Timer(delay);
		    timer.addEventListener("timer", timerHandler);
    	}
		timer.start();
		startTime = getTimer();
		var maxSOUsers:int = int(targetUsers.text);
		for (var i:int = 0; i < maxSOUsers; i += 1) {
			//start a new view
			log('Creating a new SO user');
			var souser:SOUser = new SOUser(this);
			souser.sid = String(i);
			souser.setEncoding(useAMF3 ? (useAMF3.selected === true ? 3 : 0) : 0);
			// dirty doesnt need to be forced for a primative type
			souser.setUseDirtyFlag(false);
			souser.setUpdateInterval(int(updateInterval.text));
			souser.path = givenPath.text;
			souser.start();
		}
    }
    
    public function stopTest():void { 
		var currentTime:int = getTimer();
		totalTime = (currentTime - startTime) * 0.001;		
		if (timer) {      	
    		timer.stop();
    		timer = null;
    	}		
		log('Stopping after ' + totalTime + 's');
		testTime.text = String(totalTime);
		//go thru so user list
		var souser:SOUser;
		for (var i:int = 0; i < soUserList.length; i += 1) {
			souser = soUserList.getItemAt(i) as SOUser;
			souser.stop();
		}
		soUserList.removeAll();		
    }    
    
	public function timerHandler(event:TimerEvent):void {
		//trace("Timer fired");
		var maxSync:int = int(targetSync.text);	
		var syncCount:int = 0;
		var changes:int = 0;
		for each (var souser:SOUser in soUserList) {
			syncCount += souser.syncEventsRecieved;
			changes += souser.changesMade;
			if (syncCount >= maxSync) {
				log("Sync count reached");
				stopTest();
			}				
		}	
		totalSyncEvents.text = String(syncCount);
		totalChanges.text = String(changes);
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
		var tmp:String = String(messages.data);
		tmp += text + '\n';
		messages.data = tmp;
	}
	