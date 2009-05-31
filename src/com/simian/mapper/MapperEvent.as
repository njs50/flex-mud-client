package com.simian.mapper {

	import flash.events.Event;

	public class MapperEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const CHANGE_ROOM : String = "newMapperRoom";				
		public static const CHANGE_MAP : String = "mapperChangeMap";				
		public static const CHANGE_LAYER : String = "changeMapperLayer";		

		public static const MOUSE_OVER_ROOM : String = "mapMouseOverRoom";
		public static const MOUSE_OUT_ROOM : String = "mapMouseOutRoom";

		public static const MAPPER_SELECT_ROOM : String = "mapSelectLocation";
		public static const MAPPER_MOVE_TO_ROOM : String = "mapMoveToRoom";				
		
		// EVENT DATA				
		public var room : Room; 	
							

		public function MapperEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {								
			super(type,bubbles,cancelable);									
		}

	}
}