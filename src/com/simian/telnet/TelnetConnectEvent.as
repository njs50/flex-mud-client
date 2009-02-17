// ActionScript file
package com.simian.telnet {

	import flash.events.Event;

	public class TelnetConnectEvent extends Event {
		
		// EVENT STRING DEFINITIONS					
		public static const CONNECT 	: String = "telnetConnectEvent";
		public static const DISCONNECT 	: String = "telnetDisconnectEvent";
		
		// EVENT DATA
		public var serverURL:String;
        public var portNumber:int;
			
		public function TelnetConnectEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {					
			super(type,bubbles,cancelable);					
		}

	}
}