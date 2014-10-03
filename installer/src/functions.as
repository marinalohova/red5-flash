/**
 * Application installer main script
 *
 * @author Paul Gregoire (mondain@gmail.com)
 * @author Jay Araujo (jay@lacedinteractive.com)
 */

import flash.events.*;
import flash.media.*;
import flash.net.*;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.*;
import mx.events.*;
import mx.managers.PopUpManager;
import mx.rpc.events.ResultEvent;

private var nc:NetConnection;
private var ns:NetStream;

[Bindable]
private var hostString:String='localhost';

[Bindable]
public var clientId:String='';

[Bindable]
public var applicationList:ArrayCollection;

[Bindable]
public var selectedFilename:String=null;

private var targetJavaVersion:String="java6";

// controls on the stage

private var progressWindow:IFlexDisplayObject;

public function init():void {
    Security.allowDomain("*");

    applicationList=new ArrayCollection();
    applicationList.filterFunction=filterFunc;

    var pattern:RegExp=new RegExp("http://([^/]*)/");
    if (pattern.test(Application.application.url) == true) {
        var results:Array=pattern.exec(Application.application.url);
        hostString=results[1];
        //need to strip the port to avoid confusion
        if (hostString.indexOf(":") > 0) {
            hostString=hostString.split(":")[0];
        }
    }
    log('Host: ' + hostString);
    connect()
}

public function onBWDone(...args):void {
}

public function onBWCheck(... rest):uint {
    return 0;
}

private function netStatusHandler(event:NetStatusEvent):void {
    log('Net status: ' + event.info.code);
    switch(event.info.code) {
        case "NetConnection.Connect.Success":
            getList();
            vs.selectedIndex=1
            break;
        case "NetConnection.Connect.Failed":
        case "NetConnection.Connect.Rejected":
        	//try the war location
        	callLater(connectToWar);
        case "NetConnection.Connect.Closed":
            LabelConnecting.text='Error: ' + event.info.code
            break;
    }
}

//called by the server
public function setClientId(param:Object):void {
    log('Set client id called: ' + param);
    clientId=param as String;
    log('Setting client id: ' + clientId);
}

//called by the server in the event of a server side error
public function onAlert(alert:Object):void {
    log('Got an alert: ' + alert);
    Alert.show(String(alert), 'Alert');

    removePopUp()
}

public function onJavaVersion(version:String):void {
    log('Got the server java version: ' + version);
    //change the version string into something we can use 
    //1.6.0_10 == java6
    targetJavaVersion="java" + version.split(".")[1];
}

private function connect():void {
    log('Trying to connect');
    //  create the netConnection
    nc=new NetConnection();
    nc.objectEncoding=ObjectEncoding.AMF3;
    //  set it's client/focus to this
    nc.client=this;

    // add listeners for netstatus and security issues
    nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
    nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
    nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
    nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);

    nc.connect('rtmp://' + hostString + '/installer', null);

}

private function connectToWar():void {
    log('Trying to connect to war location');
    //  create the netConnection
    if (!nc) {
	    nc=new NetConnection();
	    nc.objectEncoding=ObjectEncoding.AMF3;
	    //  set it's client/focus to this
	    nc.client=this;
	
	    // add listeners for netstatus and security issues
	    nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
	    nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
	    nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	    nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
    }
    nc.connect('rtmp://' + hostString + '/', null);
}

public function disconnect():void {
    if (nc.connected) {
        nc.close();
    }

}

public function getList():void {
    var res:Responder=new Responder(handleAppList, null);
    nc.call("installer.getApplicationList", res);
}

//callback handler
public function handleAppList(resp:Object):void {
    //log('handle Application list ' + resp);
    try {
        var s:String=resp.body as String;
        //log('Raw string: ' + s);
        var xml:XML=new XML(s);
        //log('XML: ' + xml);
        var arr:Array=new Array();
        for each(var property:XML in xml..application) {
            log('Property: ' + property);
            var item:Item=new Item();
            item.name=String(property.@name);
            item.description=property.desc;
            item.author=property.author;
            item.filename=property.filename;
            //split the filename to get the java version
            //ex: oflaDemo-r3074-java6.war
            var tmpArr:Array=property.filename.split(".")[0].split("-");
            item.javaVersion=tmpArr[tmpArr.length - 1];

            arr.push(item);
        }
        applicationList=new ArrayCollection(arr);
        applicationList.filterFunction=filterFunc;
        applicationList.refresh();
        log('Got the application list');
        listbtn.enabled=true;
    } catch(e:Error) {
        log(e.message);
    }
}

private function rpcHandler(event:ResultEvent):void {
    var arr:Array=new Array();
    for each(var s:XML in event.result..application) {
        log(s);
        var item:Item=new Item();
        item.name=String(s.@name);
        item.description=s.desc;
        item.author=s.author;
        item.filename=s.filename;
        arr.push(item);
    }
    applicationList=new ArrayCollection(arr);
    applicationList.filterFunction=filterFunc;
    listbtn.enabled=true;
}

public function refilter():void {
    applicationList.refresh();
}

public function filterFunc(item:Object):Boolean {

    if (!ckFilter.selected)
        return true;
    if (item.javaVersion !== targetJavaVersion) {
        return false;
    } else {
        return true;
    }
}

public function handleClick(event:ListEvent):void {
    if (event.rowIndex >= 0) {
        //check the java version to make sure it matches the server
        if (grid.selectedItem.javaVersion !== targetJavaVersion) {
            Alert.show("The application version selected does not match the servers java version, please try again", "Version mismatch");
        } else {
            selectedFilename=grid.selectedItem.filename;
        }
    }
}

public function install():void {
    if (selectedFilename != null) {

        // pop up the dialog

        progressWindow=PopUpManager.createPopUp(DisplayObject(Application.application), ProgressWindow, true);
        PopUpManager.centerPopUp(progressWindow)
        ProgressWindow(progressWindow).selectedFilename=selectedFilename

        // request actual installation

        nc.call("installer.install", null, selectedFilename);
    }
}


public function uninstall():void {
// TODO
}

private function removePopUp():void {
    try {
        PopUpManager.removePopUp(progressWindow);
    } catch(err:Error) {
        trace(err);
    }
}

private function securityErrorHandler(e:SecurityErrorEvent):void {
    log('Security Error: ' + e);
    removePopUp();
}

private function ioErrorHandler(e:IOErrorEvent):void {
    log('IO Error: ' + e);
    removePopUp();
}

private function asyncErrorHandler(e:AsyncErrorEvent):void {
    log('Async Error: ' + e);
    removePopUp();
}

public function log(text:String):void {
    trace(text);
    messages.text+=text + '\n';
}

