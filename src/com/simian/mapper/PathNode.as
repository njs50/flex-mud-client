package com.simian.mapper
{			
	public class PathNode
	{		
		
		public var distance : uint;
		public var room : Room;
		public var path : String; 		
				
		
		public function PathNode(_distance:int,_room:Room,_path:String)
		{
			this.distance 	= _distance;
			this.room 		= _room;
			this.path 		= _path;
		}

	}
}