package com.simian.profile {

	import flash.events.Event;
	import flash.utils.ByteArray;

	public class ProfileEvent extends Event {
		
		// loading and saving profiles
		
		public static const WRITE_PROFILE_LSO : String = "writeProfileToLSOEvent";
		
		public static const SAVE_PROFILE : String = "saveProfileEvent";
		public static const LOAD_PROFILE : String = "loadProfileEvent";
		public static const LOAD_PROFILE_DATA : String = "loadProfileDataEvent";

		
		// EVENT DATA
		public var data : ByteArray;
							
		public function ProfileEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {		
			super(type,bubbles,cancelable);
		}

	}
}