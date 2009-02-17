// ActionScript file
package com.simian.telnet {

	import com.simian.ansiTextArea.AnsiTextArea;
	
	import flash.events.Event;

	public class TelnetInitEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const INITIALISE 	: String = "newTelnetEvent";				
		
		// EVENT DATA
		public var textArea : AnsiTextArea;
			
		public function TelnetInitEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {					
			super(type,bubbles,cancelable);					
		}

	}
}