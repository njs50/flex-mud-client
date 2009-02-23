package com.simian.mapper
{
	import com.asfusion.mate.events.Dispatcher;
	
	import flash.display.Sprite;	
	
	[RemoteClass(alias="com.simian.mapper.MapLayer")]		
	public class MapLayer
	{		
		// room arrays (x/y) for this layer		
		public var oRooms : Object;
		
		// sprite representing this layer of the map
		[Bindable]
		public var mapSprite : Sprite;
		
		private var dispatcher : Dispatcher = new Dispatcher();
		
		
		public function MapLayer()
		{
			oRooms = new Object();
			mapSprite = new Sprite();
		}

		
		
		public function addRoom(oRoom:Room) : void {			
			// add this room if it isn't already there... 		
	 		if (! mapSprite.contains(oRoom) ) mapSprite.addChild(oRoom);			
		}

		
		public function setActiveLayer(): void {
			// broadcast that we have changed layers        	
        	var mEvent : MapperEvent;       	
			mEvent = new MapperEvent(MapperEvent.CHANGE_LAYER);        			
			dispatcher.dispatchEvent(mEvent);
								
		}


	}
}