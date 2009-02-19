package com.simian.mapper
{
	
	[RemoteClass(alias="com.simian.mapper.Exit")]		
	public class Exit
	{		
		public var direction : String; 		
		public var room : Room;
		public var command : String;
		
		public function Exit(_direction:String = '',_room:Room = null,command:String = '')
		{
			direction = _direction;
			room = _room;
			command = _command;
		}

	}
}