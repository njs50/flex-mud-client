package com.simian.profile
{
	
	import flexlib.mdi.containers.MDIWindow;
	
	import mx.core.Application;
	
	[RemoteClass(alias="com.simian.profile.MDIWindowSettings")]	
	public class MDIWindowSettings
	{
		
		public var name : String;
		public var x : int;
		public var y : int; 		
		public var width : uint;
		public var height : uint;
		
		
								
		
		public function MDIWindowSettings( ) : void {
			
		}
		
		
		public function getSettings(window:MDIWindow ) : void {			
			this.name = window.name;
			this.x = window.x;
			this.y = window.y;
			this.width = window.width;
			this.height = window.height;								
		}


		// apply stored settings to a window but check that it remains within the application bounds		
		public function applySettings(window:MDIWindow) : void {
			// magic width
			window.width = this.width;				
			if (window.width > Application.application.width) window.width = Application.application.width; 
			
			// magic height
			window.height = this.height;
			if (window.height > Application.application.height) window.height = Application.application.height;
			
			// x pos
			window.x = this.x;
			if (window.x + window.width > Application.application.width) window.x = Application.application.width - window.width;
			
			// y pos
			window.y = this.y;
			if (window.y + window.height > Application.application.height) window.y = Application.application.height - window.height;						
								
		}


	}
}