//
// Stupid simple player for testing...
// @author Paul Gregoire (mondain@gmail.com)
//
// http://www.adobe.com/devnet/flash/quickstart/metadata_cue_points/
// http://crypto.hurlant.com/demo/
// http://en.wikipedia.org/wiki/Protected_Streaming
//

package {

	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.IHash;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.controls.Label;
	import mx.core.Application;
	import mx.events.VideoEvent;
	import mx.utils.SHA256;

	/**
	 * @author Paul
	 */
	[Bindable] 
	public class Main {

        private var app : Application;

		public var nc : NetConnection;
		public var ns : NetStream;
		
		public var connectorLabel : String = "Connect";    
		
		public var server : String;

		public var encoding : String = "amf3";
		
		public var location : String = "prometheus.mp4";
		
		public var playerVideo : Video; 

		public var bmd : BitmapData = null;
		
		public var canvas : Canvas;

		public var playerDisplay : Label;

        public var authMode : String = "None";

        public var user : String;

        public var passwd : String = "test";
		
		public var paused : Boolean = false;
		
		//challenge string
		public var challenge : String = null;
		
		//session id
		public var sessionId : String = null;

        public function setApplication(app:Application):void {
        	this.app = app;
        }

		public function callMethod(name:String, params:String) : void {
			log('Calling method');
			if (nc.connected) {
				var responder : Responder = new Responder(methodResponseHandler, null);
				if (params === "" || params.length < 1) {
					nc.call(name, responder);            
				} else {                
					if (params.indexOf(",") > 0) {
						var arr : Array = params.split(",");
						nc.call(name, responder, arr);
					} else {
						nc.call(name, responder, params);
					}
				}
			}
		}

		public function echo() : void {
			log('Calling method echo');
			if (nc.connected) {
				var responder : Responder = new Responder(methodResponseHandlerRequirementSet, null);
				var requirementSet : RequirementSet = new RequirementSet();
				requirementSet.children.addItem(new Requirement());
				requirementSet.children.addItem(new Requirement());
				log('Children: ' + requirementSet.children.length);
				nc.call("echo", responder, requirementSet);
			}
		}		
		
		public function methodResponseHandler(resp : Object) : void {
			log("Response: " + resp);
		}

		public function methodResponseHandlerRequirementSet(resp : RequirementSet) : void {
			log("Response: " + resp.children.length);
			log("Child 0: " + resp.children[0]);
		}

		public function onBWDone() : void {
			// have to have this for an RTMP connection
			log('onBWDone');
		}

		public function onBWCheck(... rest) : uint {
			log('onBWCheck');
			//have to return something, so returning anything :)
			return 0;
		}

		public function onError(msg : String) : void {
			log('onError: ' + msg);
		}

		public function onImageData(imageData : Object) : void {
			log('onImageData' + imageData);
			log("image track id: " + imageData.trackid);
			log("image data length: " + imageData.data.length);
    
			var ba : ByteArray = new ByteArray();
			var len : uint = imageData.data.length;
			for (var i : int = 0;i < len; i++) {
				ba.writeByte(imageData.data[i]);
			}
			//flip?     
			ba.position = 0;
    
			var imageloader : Loader = new Loader();   
			imageloader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
			imageloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			imageloader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);     
            
			canvas.rawChildren.addChild(imageloader);   
    
			imageloader.loadBytes(ba);
		}

		public function onLoaded(event : Event) : void {
			log("Image loaded: " + event);
			if (bmd === null) {
				bmd = Bitmap(event.currentTarget.content).bitmapData;           
			}
		}         

		public function onLoadError(e : Event) : void {
			log(this + ".ERROR loading " + e);
		}

		public function onLoadProgress(e : Event) : void {
			log("Load progress");
		}           

		public function onTextData(textData : Object) : void {
			log('onTextData');
			var key : String = '';
			for (key in textData) {
				log(key + ": " + textData[key]);
			}   
		}

		public function onMetaData(infoObject : Object) : void {
			log("onMetaData: " + infoObject);
    
			var key : String;
			for (key in infoObject) {
				if (key !== "covr" && key !== "seekpoints") {
					log('Meta: ' + key + ': ' + infoObject[key]);
				}
			}
    
			if (infoObject.tags != undefined && infoObject.tags.covr != undefined ) {
				log("tags: " + infoObject.tags);
				log("covr length: " + infoObject.tags.covr.length);
            
				log("Loading cover image from metadata");
    
				var ba : ByteArray = new ByteArray();
				var len : uint = infoObject.tags.covr[0].length;
				for (var i : int = 0;i < len; i++) {
					ba.writeByte(infoObject.tags.covr[0][i]);
				}
				//flip?     
				ba.position = 0;
        
				var imageloader : Loader = new Loader();   
				imageloader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
				imageloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				imageloader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);     
                
				canvas.rawChildren.addChild(imageloader);   
        
				imageloader.loadBytes(ba);
			}
            
			//duration.text = infoObject.duration;
			//frameRate.text = infoObject.framerate;
			//widthHeight.text = infoObject.width + "x" + infoObject.height;    

			if (infoObject.trackinfo) {
				log("Found track info");
				//traceObject(infoObject.trackinfo);
			}
			if (infoObject.seekpoints) {
				log("Found seekpoints");
				//traceObject(infoObject.seekpoints);

				log("Sample seekpoints: " + infoObject.seekpoints[16] + ", " + infoObject.seekpoints[24] + ", " + infoObject.seekpoints[32]);
			}
		}

		public function onCuePoint(infoObject : Object) : void {
			log('onCuePoint - name: ' + infoObject.name + ' type: ' + infoObject.type + ' time: ' + infoObject.time);
		}

		public function onPlayStatus(infoObject : Object) : void {
			log('onPlayStatus: ' + infoObject);
		}

		public function onLastSecond(infoObject : Object) : void {
			log('onLastSecond: ' + infoObject);
		}

		public function connect() : void {
			if (connectorLabel === 'Connect') {
				log('Connecting...');
				//  create the netConnection
				nc = new NetConnection();
				nc.objectEncoding = encoding == 'amf3' ? ObjectEncoding.AMF3 : ObjectEncoding.AMF0;
				//  set it's client/focus to this
				nc.client = this;
				// Acceptable values are "none", "HTTP", "CONNECT", and "best"
				// The default value is "none".
				nc.proxyType = "best";
        
				// add listeners for netstatus and security issues
				nc.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
				nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
        
				log('Auth: ' + authMode);
    
				//nc.addHeader("Credentials", false, {userid: userid, password: password});
				//nc.addHeader("Credentials", false, {userid: "'+user.text+'", password: "'+passwd.text+'"});

				if (authMode === 'None') {
					if (!user || user.length === 0) {
						nc.connect(server, null);
					} else {
						var params : Array = [];
						params[0] = user;
						params[1] = passwd;
						nc.connect(server, params);
					}
				} else if (authMode === 'Red5') {
					nc.connect(server + "?authmod=red5&user=" + user);
				} else if (authMode === 'FMS') {
					nc.connect(server + "?authmod=adobe&user=" + user);
				}
			} else if (connectorLabel === 'Disconnect') {
				log('Disconnecting...');
				if (nc.connected) {
					nc.close();
				}
			}       
		}

        public function setAuthMode(authMode : String) : void {
        	this.authMode = authMode;
        }

		public function computeSimpleSHA256(text : String) : String {
			var bytes : ByteArray = new ByteArray();
			bytes.writeUTFBytes(text);
			// ByteArray moves the cursor after each read/write, so must reset it!
			bytes.position = 0;
			var hash : String = SHA256.computeDigest(bytes);     
			return hash;
		}

		public function computeSHA256(input : String) : String {
			var hash : IHash = Crypto.getHash("sha256");
			var data : ByteArray = Hex.toArray(Hex.fromString(input));
			return Base64.encodeByteArray(hash.hash(data));
		}

		public function computeHMACSHA256(key : String, input : String) : String {
			var hmac : HMAC = Crypto.getHMAC("sha256");
			var kdata : ByteArray = Hex.toArray(Hex.fromString(key));
			var data : ByteArray = Hex.toArray(Hex.fromString(input));
			return Base64.encodeByteArray(hmac.compute(kdata, data));
		}
				
		public function onStatus(evt : NetStatusEvent) : void {
			log("NetConnection.onStatus " + evt);
			//traceObject(evt);
			var desc:String;
			if (evt.info !== '' || evt.info !== null) { 
				log("Code: " + evt.info.code);
				//log("Description: " + evt.info.description);
				//log("Application: " + evt.info.application);
				//traceObject(evt.info);
				switch (evt.info.code) {
					case "NetConnection.Connect.Success": 
						connectorLabel = "Disconnect";
						ns = new NetStream(nc);
						ns.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
						ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
						ns.client = this;
                        if (location) {                                    
    						playerVideo = new Video();
    						playerVideo.attachNetStream(ns);
    						if (location.indexOf("flv") < 0) {
    							ns.play(location);
    						} else {
    							ns.play(location, 0, -1);
    						}
    						playerDisplay.addChild(playerVideo);
    						playerVideo.width = 320;
    						playerVideo.height = 240;
							
							playerVideo.addEventListener(Event.RENDER, updateFps);
                        }                    
						//ns.play("test.flv");
						//ns.play("newfeatures.flv");
						//ns.play("BigBuckBunny.flv");
						//ns.play("city_of_ember-vp6_1080p.flv");
						//ns.play("http://www.helpexamples.com/flash/video/cuepoints.flv");
						break;
					case "NetStream.Play.StreamNotFound":
						log("Unable to locate video: " + server + '/' + location);
						break;
					case "NetConnection.Connect.Failed":
						break;
					case "NetConnection.Connect.Rejected":
						desc = evt.info.description;
						log("Description: " + desc);
						if (desc !== '') {
							log("Desc: " + desc.split('?')[1]);
							try {
								var parameters : Object = {};
								var params : Array = desc.split('?')[1].split('&');
								var length : uint = params.length;
								for (var i : uint = 0,index : int = -1;i < length; i++) {
									var kvPair : String = params[i];
									if ((index = kvPair.indexOf("=")) > 0) {
										var key : String = kvPair.substring(0, index);
										var value : String = kvPair.substring(index + 1);
										log("Key: " + key + " Value: " + value);
										parameters[key] = value;
									}
								}                            
								if (parameters["reason"] == 'needauth') {  
									log("Sending auth");
									challenge = parameters["challenge"];
									sessionId = parameters["sessionid"];
                                	// send the credentials
									app.callLater(sendCredentials);
								}
							} catch(e : Error) {
								log("Error: " + e.message);
							}
						}
						break;
					case "NetConnection.Connect.Closed":                    
						connectorLabel = 'Connect';    
						break;
					case "NetConnection.Connect.CertificateUntrustedSigner":
					   log("Certificate is not trusted");
					   if (evt.info.description) {
						   desc = evt.info.description;
						   log("Description: " + desc);
					   }
					   break;
					case "NetConnection.Connect.CertificatePrincipalMismatch":
                       log("Certificate problem");
					   if (evt.info.description) {
	                       desc = evt.info.description;
	                       log("Description: " + desc);
					   }
                       break;
                    case "NetConnection.Connect.SSLHandshakeFailed":
                       log("SSL handshake failed");
					   if (evt.info.description) {
						   desc = evt.info.description;
						   log("Description: " + desc);
					   }
                       break;
				}           
			}
		}

		public function sendCredentials() : void {
			log("Sending credentials");
			nc.connect(server + "?authmod=red5&user=" + user + "&sessionid=" + sessionId + "&response=" + computeHMACSHA256(challenge, passwd));
		}

		public function seek(position : String) : void {
			log('Seek to: ' + position);
			if (ns) {
				log("Total time: " + ns.time); //[read-only] The position of the playhead, in seconds.
				ns.seek(Number(position));
			}
            
    /*      
     var net_stream:NetStream = object.net_stream_;
     var time_fixed:Number = net_stream.time;
     time_fixed += video_streamer.flv_beginning_;
    
     var percentage:Number = 100 * (time_fixed / net_stream.totalTime);
    
            var cached_seconds = Math.floor((ns.totalTime - flv_beginning_) * (ns.bytesLoaded / ns.bytesTotal)) - 1;
    
            if (second >= flv_beginning_ && second < flv_beginning_ + cached_seconds) {
                if (Math.abs(net_stream_.time - second) > 5) {
                    ns.seek(second);
                }
            } else if (infoObject.keyframes) {
                var keyframe = getNearestKeyframe(second, infoObject.keyframes.times);
                log("seek: nearest keyframe=" + keyframe);
                second = infoObject.keyframes.times[keyframe];
                if (flv_beginning_ != second) {
                    flv_beginning_ = second;
                    var url = net_connection_.play_url + "?start=" + infoObject.keyframes.filepositions[keyframe];
                    log("play: " + url);
                    ns.play(url);
                }
            } else if (infoObject.seekpoints) {
                var keyframe = getNearestSeekpoint(second, infoObject.seekpoints);
                log("seek: nearest keyframe=" + keyframe);      
                second = infoObject.seekpoints[keyframe]["time"];
                if (flv_beginning_ != second) {
                    flv_beginning_ = second;
                    var url = net_connection_.play_url + "?start=" + infoObject.seekpoints[keyframe]["time"];
                    log("play: " + url);
                    ns.play(url);
                }
            }
    */      
		}
		
		public function pause() : void {
			if (ns) {
				if (paused) {
					log('Resume');
					ns.resume();					
					paused = false;
				} else {
					log('Pause');
					ns.pause();					
					paused = true;
				}
				//ns.togglePause()
			}
		}
        
		public function updateFps(evt:Event) : void {
			if (ns) {
				app["fps"].text = ns.currentFPS;
			}
		}		
		
		public function getNearestKeyframe(second : Number, keytimes : Array):uint {
            var index1:uint = 0;
            var index2:uint = 0;
            // Iterate through array to find keyframes before and after scrubber second
            for (var i:uint = 0;i != keytimes.length; i++) {
                if (keytimes[i] < second) {
                    index1 = i;
                } else {
                    index2 = i;
                    break;
                }
            }
            // Calculate nearest keyframe
            if(second - keytimes[index1] < keytimes[index2] - second) {
                return index1;
            } else {
                return index2;
            }
        }
        
		public function getNearestSeekpoint(second : Number, seekpoints : Array):uint {
            var index1:uint = 0;
            var index2:uint = 0;
            // Iterate through array to find keyframes before and after scrubber second
            for(var i:uint = 0;i != seekpoints.length; i++) {
                if (seekpoints[i]["time"] < second) {
                    index1 = i;
                } else {
                    index2 = i;
                    break;
                }
            }
            // Calculate nearest keyframe
            if(second - seekpoints[index1]["time"] < seekpoints[index2]["time"] - second) {
                return index1;
            } else {
                return index2;
            }
        }           
    
        public function securityErrorHandler(e : SecurityErrorEvent) : void {
            log('Security Error: ' + e);
        }
    
        public function ioErrorHandler(e : IOErrorEvent) : void {
            log('IO Error: ' + e);
        }
        
        public function asyncErrorHandler(e : AsyncErrorEvent) : void {
            log('Async Error: ' + e);
        }
        
        public function log(text : String) : void {
        	//TODO: dispatch a log event
        	if (app) {
                app["log"](text);
        	} else {
        	   trace(text);
        	}
        }
	
	}
}
