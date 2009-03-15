package com.simian.mapper
{
	
	[RemoteClass(alias="com.simian.mapper.Exit")]		
	public class Exit
	{		
		public var direction : String; 		
		public var room : Room;
		public var command : String;
		public var bLinearExit : Boolean;
		
		public function Exit(_direction:String = '',_room:Room = null,_command:String = '',_bLinearExit : Boolean = true)
		{
			direction = _direction;
			if (_room != null) room = _room;
			command = _command;
			bLinearExit = _bLinearExit;
		}

	}
}