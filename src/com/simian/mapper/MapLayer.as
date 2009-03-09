package com.simian.mapper
{
	import com.asfusion.mate.events.Dispatcher;
	
	import flash.display.Sprite;	
	
	[RemoteClass(alias="com.simian.mapper.MapLayer")]		
	public class MapLayer
	{		
		// room arrays (x/y) for this layer		
		public var oRooms : Object;
						
		private var dispatcher : Dispatcher = new Dispatcher();
		
		
		public function MapLayer()
		{
			oRooms = new Object();			
		}


	}
}