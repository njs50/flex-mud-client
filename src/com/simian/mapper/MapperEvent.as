package com.simian.mapper {

	import flash.events.Event;

	public class MapperEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const CHANGE_ROOM : String = "newMapperRoom";				
		public static const CHANGE_MAP : String = "mapperChangeMap";				
		public static const CHANGE_LAYER : String = "changeMapperLayer";		

		public static const MAPPER_START : String = "startMapperRecording";
		public static const MAPPER_STOP : String = "stopMapperRecording";
		public static const MAPPER_FIND : String = "findMapLocation";
		public static const MAPPER_SELECT_ROOM : String = "mapSelectLocation";
		
		// EVENT DATA				
		public var room : Room; 	
							

		public function MapperEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {								
			super(type,bubbles,cancelable);									
		}

	}
}