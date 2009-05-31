package com.simian.telnet {

	import flash.events.Event;
	import flash.events.KeyboardEvent;

	public class TelnetKeyboardEvent extends Event {		

		// trigger mapper events from the telnet window
		public static const REMOTE_MAPPER_KEY_PRESS : String = "mapperRemoteKeypress";
		
		public var kb_event : KeyboardEvent;
							
		public function TelnetKeyboardEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {		
			super(type,bubbles,cancelable);
		}

	}
}