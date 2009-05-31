package com.simian.telnet {

	import flash.events.Event;

	public class TelnetEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const SEND_DATA : String = "sendTelnetDataEvent";
		public static const SEND_TRIGGER_DATA : String = "sendTelnetTriggerDataEvent";
		public static const DISPATCH_DATA : String = "dispatchTelnetDataEvent";
		public static const DISPATCH_TRIGGER_DATA : String = "dispatchTelnetTriggerDataEvent";
		
		public static const NEW_LINE_DATA : String = "newTelnetDataEvent";
		public static const APPEND_LINE_DATA : String = "appendTelnetDataEvent";	

		// window events		
		public static const CHANGE_TITLE : String = "changeWindowTitleEvent";
		public static const RESET_TERMINAL : String = "resetTerminalWindowEvent";

		// triggers		
		public static const PARSE_PROMPT_DATA : String = "newPromptParseEvent";
		public static const PARSE_LINE_DATA : String = "newLineParseEvent";
		public static const PARSE_BLOCK_DATA : String = "newBlockParseEvent";
		
		// EVENT DATA
		public var data : String;	
							
		public function TelnetEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {		
			super(type,bubbles,cancelable);
		}

	}
}