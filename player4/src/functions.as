//
// Stupid simple player for testing...
// @author Paul Gregoire (mondain@gmail.com)
//
// http://www.adobe.com/devnet/flash/quickstart/metadata_cue_points/
//
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.utils.ByteArray;

{
	
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	
	import flash.display.BitmapData
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.*;
	import mx.events.*;
	
	public var nc:NetConnection;
	public var ns:NetStream;
	public var playerVideo:Video;	
	
	public var bmd:BitmapData = null;
	
	[Bindable]
	public var hostString:String = 'localhost';
	
	[Bindable]
	public var clientId:String = '';
	
	public function init():void {
		Security.allowDomain("*");
		
		var pattern:RegExp = new RegExp("http://([^/]*)/");				
		if (pattern.test(Application.application.url) == true) {
			var results:Array = pattern.exec(Application.application.url);
			hostString = results[1];
			//need to strip the port to avoid confusion
			if (hostString.indexOf(":") > 0) {
				hostString = hostString.split(":")[0];
			}
		}
		log('Host: ' + hostString);	
	}
	
	public function onBWDone():void {
		// have to have this for an RTMP connection
		log('onBWDone');
	}
	
	public function onBWCheck(... rest):uint {
		log('onBWCheck');
		//have to return something, so returning anything :)
		return 0;
	}
	
	public function onImageData(imageData:Object):void {
		log('onImageData' + imageData);
		log("image track id: " + imageData.trackid);
		log("image data length: " + imageData.data.length);

		var ba:ByteArray = new ByteArray();
		var len:uint = imageData.data.length;
		for (var i:int=0; i<len; i++) {
			ba.writeByte(imageData.data[i]);
		}
		//flip?		
		ba.position = 0;

		var imageloader:Loader = new Loader();   
		imageloader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
		imageloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR , onLoadError);
		imageloader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);		
		
		canvas.rawChildren.addChild(imageloader);	

		imageloader.loadBytes(ba);
	}
	         
	public function onLoaded(event:Event):void {
		log("Image loaded: " + event);
		if (bmd === null) {
			bmd = Bitmap(event.currentTarget.content).bitmapData;	 		
		}
	}         
	        
	public function onLoadError(e:Event):void {
		log(this + ".ERROR loading " + e);
	}

	public function onLoadProgress(e:Event):void {
		log("Load progress");
	}	        
	           
	public function onTextData(textData:Object):void {
		log('onTextData');
		var key:String;
		for (key in textData) {
			log(key + ": " + textData[key]);
		}	
	}
	
	public function onMetaData(infoObject:Object):void {
		log("onMetaData: " + infoObject);

   		var key:String;
    	for (key in infoObject) {
    		if (key !== "covr") {
        		log('Meta: '+ key + ': ' + infoObject[key]);
      		}
    	}

		if (infoObject.tags != undefined && infoObject.tags.covr != undefined ) {
			log("tags: " + infoObject.tags);
			log("covr length: " + infoObject.tags.covr.length);
		
			log("Loading cover image from metadata");

			var ba:ByteArray = new ByteArray();
			var len:uint = infoObject.tags.covr[0].length;
			for (var i:int=0; i<len; i++) {
				ba.writeByte(infoObject.tags.covr[0][i]);
			}
			//flip?		
			ba.position = 0;
	
			var imageloader:Loader = new Loader();   
			imageloader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
			imageloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR , onLoadError);
			imageloader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);		
			
			canvas.rawChildren.addChild(imageloader);	
	
			imageloader.loadBytes(ba);
		}
		
		//duration.text = infoObject.duration;
		//frameRate.text = infoObject.framerate;
		//widthHeight.text = infoObject.width + "x" + infoObject.height;	
	}
	
	public function onCuePoint(infoObject:Object):void {
		log('onCuePoint');
	}
	
	public function connect():void {
		if (connector.label === 'Connect') {
			log('Connecting...');
			//  create the netConnection
			nc = new NetConnection();
			nc.objectEncoding = ObjectEncoding.AMF0;
			//  set it's client/focus to this
			nc.client = this;
	
			// add listeners for netstatus and security issues
			nc.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
	
		    nc.connect(server.text, null);
		} else if (connector.label === 'Disconnect') {
			log('Disconnecting...');
			if (nc.connected) {
				nc.close();
			}
		}		
	}
	
	public function onStatus(evt:NetStatusEvent):void {
		log("NetConnection.onStatus " + evt);
		if (evt.info !== '' || evt.info !== null) {	
			log("Code: " + evt.info.code);
			switch (evt.info.code) {
            case "NetConnection.Connect.Success": 
            	connector.label = "Disconnect";
				ns = new NetStream(nc);
				ns.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
				ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				ns.client = this;
								
        		playerVideo = new Video();
        		playerVideo.attachNetStream(ns);
        		ns.play(location.text);
        		playerDisplay.addChild(playerVideo);
				playerVideo.width = 320;
				playerVideo.height = 240;
				
				//ns.play("test.flv");
				//ns.play("newfeatures.flv");
				//ns.play("BigBuckBunny.flv");
				//ns.play("city_of_ember-vp6_1080p.flv");
				//ns.play("http://www.helpexamples.com/flash/video/cuepoints.flv");
				break;
            case "NetStream.Play.StreamNotFound":
                log("Unable to locate video: " + server.text + '/' + location.text);
                break;
            case "NetConnection.Connect.Failed":
                break;
            case "NetConnection.Connect.Rejected":
            	break;
            case "NetConnection.Connect.Closed":	                
				connector.label = 'Connect';	
				break;
			}			
		}
	}

	public function resize(evt:Event):void {
		var originalWidth:Number = bmd.width;
		evt.target.width = originalWidth / 2;
		var originalHeight:Number = bmd.height;
		evt.target.height = originalHeight / 2;
		log('Resize to half: ' + originalWidth + 'x' + originalHeight);
	}
	
	public function hide(evt:Event):void {
		evt.target.visible = false;
	}

	public function securityErrorHandler(e:SecurityErrorEvent):void {
		log('Security Error: '+e);
	}

	public function ioErrorHandler(e:IOErrorEvent):void {
		log('IO Error: '+e);
	}
	
	public function asyncErrorHandler(e:AsyncErrorEvent):void {
		log('Async Error: '+e);
	}
	
	public function log(text:String):void {
		var tmp:String;
		if (messages.data != null) {
			tmp = String(messages.data);
		} else {
			tmp = "";
		}
		tmp += text + '\n';
		messages.data = tmp;
		messages.verticalScrollPosition = messages.maxVerticalScrollPosition;
	}

	public function traceObject(obj:Object, indent:uint = 0):void {
	    var indentString:String = "";
	    var i:uint;
	    var prop:String;
	    var val:*;
	    for (i = 0; i < indent; i++) {
	        indentString += "\t";
	    }
	    for (prop in obj) {
	        val = obj[prop];
	        if (typeof(val) == "object") {
	            log(indentString + " " + i + ": [Object]");
	            traceObject(val, indent + 1);
	        } else {
	            log(indentString + " " + prop + ": " + val);
	        }
	    }
	} 

}
