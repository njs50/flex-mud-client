package com.simian.window {

	import flash.events.Event;
	
	import flexlib.mdi.containers.MDIWindow;

	public class WindowEvent extends Event {
		
		// EVENT STRING DEFINITIONS
		public static const NEW_WINDOW : String = "newWindowMagic";		
		public static const CLOSE_WINDOWS : String = "closeAllWindows";
		public static const STORE_WINDOW_SETTINGS : String = "storeWindowConf";			
		public static const LOAD_WINDOW_SETTINGS : String = "loadWindowConf";
		
		// public static const RESTORE_WINDOW_STATE : String = "restoreWindowState";
				
		// TYPES OF WINDOWS WE WILL PLAY WITH
		public static const OPEN_ALIAS_WINDOW : String = 'openAliasWindow';
		public static const OPEN_TRIGGER_WINDOW : String = 'openTriggerWindow'; 
		public static const OPEN_TELNET_WINDOW : String = 'openTelnetWindow';
		public static const OPEN_TELNET_SETTINGS_WINDOW : String = 'openTelnetSettingsWindow';	
		public static const OPEN_MAPPER_WINDOW : String = 'openMapperWindow';
		
		// EVENT DATA		
		
		public var window :MDIWindow;
		
							
		public function WindowEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {		
			
			super(type,bubbles,cancelable);				
					
		}

	}
}