package com.simian.telnet
{
	import mx.collections.ArrayCollection;
	
	
	[RemoteClass(alias="com.simian.profile.Settings")]		
	[Bindable]
	public class TelnetSettings
	{
				
		
		// ansi colours in rgb format. 
		// aColoursLight = normal : black,red,green,yellow,blue,magenta,cyan,white 
		// aColoursDark = bright : black,red,green,yellow,blue,magenta,cyan,white					
		
				
	/*	// colours for telnet (standard colours. bleh!)
		public var defaultFGcolour : int  = 0x000000;		
		public var defaultBGcolour : int  = 0xc0c0c0;					
		public var acColoursLight : ArrayCollection = new ArrayCollection([0x000000,0x800000,0x008000,0x808000,0x000080,0x800080,0x008080,0xc0c0c0]);
		public var acColoursDark : ArrayCollection = new ArrayCollection([0x808080,0xff0000,0x00ff00,0xffff00,0x0000ff,0xff00ff,0x00ffff,0xffffff]);
	*/
		// colours for telnet (gooder colours ;-)		
		public var defaultFGcolour : int  = 0xffffcc;		
		public var defaultBGcolour : int  = 0x000033;					
		public var acColoursLight : ArrayCollection = new ArrayCollection([0x666666,0x800000,0x008000,0x808000,0x0000cc,0x800080,0x008080,0xcccccc]);
		public var acColoursDark : ArrayCollection = new ArrayCollection([0x999999,0xff0000,0x00ff00,0xffff00,0x0099ff,0xff00ff,0x00ffff,0xffffff]);
		
		public var maxCommands : int = 50;
		
		public var maxScrollBack : int = 1000;
		
		public function TelnetSettings()
		{

		}

	}
}