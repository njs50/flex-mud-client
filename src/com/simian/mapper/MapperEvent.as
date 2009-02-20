package com.simian.mapper {

	import flash.events.Event;

	public class MapperEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const NEW_ROOM : String = "newMapperRoom";		
		
		// EVENT DATA				
		public var room : Room;		
		
							
		public function MapperEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {		
			
			super(type,bubbles,cancelable);				
					
		}

	}
}