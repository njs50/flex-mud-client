package com.simian.mapper {

	import flash.events.Event;

	public class MapperEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const CHANGE_ROOM : String = "newMapperRoom";		
		
		public static const CHANGE_MAP : String = "mapperChangeMap";
		
		
		public static const CHANGE_LAYER : String = "changeMapperLayer";
		
		// EVENT DATA				

							
		public function MapperEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {		
			
			super(type,bubbles,cancelable);				
					
		}

	}
}