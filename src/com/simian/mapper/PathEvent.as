package com.simian.mapper {

	import flash.events.Event;

	public class PathEvent extends Event {
				
		// EVENT STRING DEFINITIONS
		public static const NEW_PATH : String = "newMapperPath";				
		public static const STEP : String = "MapperPathAdvance";
		public static const REPEAT_LAST_STEP : String = "MapperRepeatLastStep";				
		public static const UNDO_LAST_STEP : String = "MapperUndoLastStep";		
		
		// EVENT DATA				
		public var aPath : Array; 								

		public function PathEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {								
			super(type,bubbles,cancelable);									
		}

	}
}