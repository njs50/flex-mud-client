package com.simian.mapper
{			
	public class PathNode
	{		
		
		public var distance : uint;
		public var room : Room;
		public var aPath : Array; 		
				
		
		public function PathNode(_distance:int,_room:Room,_aPath:Array)
		{
			this.distance 	= _distance;
			this.room 		= _room;
			this.aPath 		= _aPath;
		}

	}
}