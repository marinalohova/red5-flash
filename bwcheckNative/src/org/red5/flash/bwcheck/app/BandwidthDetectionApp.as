package org.red5.flash.bwcheck.app
{
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;
	
	import mx.controls.TextArea;
	import mx.core.Application;
	
	import org.red5.flash.bwcheck.ClientServerBandwidth;
	import org.red5.flash.bwcheck.ServerClientBandwidth;
	import org.red5.flash.bwcheck.events.BandwidthDetectEvent;
	
	public class BandwidthDetectionApp extends Application
	{
		private var _serverURL:String = "localhost";
		private var _serverApplication:String = "";
		private var _clientServerService:String = "";
		private var _serverClientService:String = "";
		
		private var nc:NetConnection;
		public var txtLog:TextArea;
		
		public function BandwidthDetectionApp()
		{
			
		}
		
		public function set serverURL(url:String):void
		{
			_serverURL = url;
		}
		
		public function set serverApplication(app:String):void
		{
			_serverApplication = app;
		}
		
		public function set clientServerService(service:String):void
		{
			_clientServerService = service;
		}
		
		public function set serverClientService(service:String):void
		{
			_serverClientService = service;
		}
		
		public function connect():void
		{
			nc = new NetConnection();
			nc.objectEncoding = flash.net.ObjectEncoding.AMF0;
			nc.client = this;
			nc.addEventListener(NetStatusEvent.NET_STATUS, onStatus);	
			nc.connect("rtmp://" + _serverURL + "/" + _serverApplication);
		}
		
		
		private function onStatus(event:NetStatusEvent):void
		{
			switch (event.info.code)
			{
				case "NetConnection.Connect.Success":
					txtLog.data += "\n" + event.info.code;
					txtLog.data += "\n Detecting Server Client Bandwidth \n\n";
					ServerClient();
				break;	
			}
			
		}
		
		public function ClientServer():void
		{
			var clientServer:ClientServerBandwidth  = new ClientServerBandwidth();
			//connect();
			clientServer.connection = nc;
			clientServer.service = _clientServerService;
			clientServer.addEventListener(BandwidthDetectEvent.DETECT_COMPLETE,onClientServerComplete);
			clientServer.addEventListener(BandwidthDetectEvent.DETECT_STATUS,onClientServerStatus);
			clientServer.addEventListener(BandwidthDetectEvent.DETECT_FAILED,onDetectFailed);
			clientServer.start();
		}
		
		public function ServerClient():void
		{
			var serverClient:ServerClientBandwidth = new ServerClientBandwidth();
			//connect();
			serverClient.connection = nc;
			serverClient.service = _serverClientService;
			serverClient.addEventListener(BandwidthDetectEvent.DETECT_COMPLETE,onServerClientComplete);
			serverClient.addEventListener(BandwidthDetectEvent.DETECT_STATUS,onServerClientStatus);
			serverClient.addEventListener(BandwidthDetectEvent.DETECT_FAILED,onDetectFailed);
			
			serverClient.start();
		}
		
		public function onDetectFailed(event:BandwidthDetectEvent):void
		{
			txtLog.data += "\n Detection failed with error: " + event.info.application + " " + event.info.description;
		}
		
		public function onClientServerComplete(event:BandwidthDetectEvent):void
		{			
			txtLog.data += "\n\n kbitUp = " + event.info.kbitUp + ", deltaUp= " + event.info.deltaUp + ", deltaTime = " + event.info.deltaTime + ", latency = " + event.info.latency + " KBytes " + event.info.KBytes;
			txtLog.data += "\n\n Client to Server Bandwidth Detection Complete";
		}
		
		public function onClientServerStatus(event:BandwidthDetectEvent):void
		{
			if (event.info) {
				txtLog.data += "\n count: "+event.info.count+ " sent: "+event.info.sent+" timePassed: "+event.info.timePassed+" latency: "+event.info.latency+" overhead:  "+event.info.overhead+" packet interval: " + event.info.pakInterval + " cumLatency: " + event.info.cumLatency;
			}
		}
		
		public function onServerClientComplete(event:BandwidthDetectEvent):void
		{
			txtLog.data += "\n\n kbit Down: " + event.info.kbitDown + " Delta Down: " + event.info.deltaDown + " Delta Time: " + event.info.deltaTime + " Latency: " + event.info.latency;
			txtLog.data += "\n\n Server Client Bandwidth Detect Complete";
			txtLog.data += "\n\n Detecting Client Server Bandwidth\n\n";
			ClientServer();
		}
		
		public function onServerClientStatus(event:BandwidthDetectEvent):void
		{	
			if (event.info) {
				txtLog.data += "\n count: "+event.info.count+ " sent: "+event.info.sent+" timePassed: "+event.info.timePassed+" latency: "+event.info.latency+" cumLatency: " + event.info.cumLatency;
			}
		}

	}
}
