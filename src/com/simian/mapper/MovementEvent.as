package com.simian.mapper {

	import flash.events.Event;

	public class MovementEvent extends Event {
				
		// EVENT STRING DEFINITIONS
		public static const MOVE_DIRECTION : String = "newRoomMoveDirection";				
		public static const MOVE_LOCATION : String = "newRoomMoveLocation";
		public static const MOVE_RELATIVE_LOCATION : String = "newRoomMoveRelativeLocation";
		
		// EVENT DATA				
		public var direction : String;
		public var x : int;
		public var y : int;
		public var z : int;							

		public function MovementEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {								
			super(type,bubbles,cancelable);									
		}

	}
}