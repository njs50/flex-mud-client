package com.simian.mapper
{
	
	[RemoteClass(alias="com.simian.mapper.Room")]		
	public class Room
	{
		
		public var name : String; 		
		public var line1 : String;
		public var line2 : String;
		public var line3 : String;
		public var aExits : Array;
		
		public var x : int;
		public var y : int;						
		public var z : int;
		
		public function Room(_name:String = '',_line1:String = '',_line2:String = '',_line3:String = '', _x : int = 0, _y : int = 0, _z:int = 0, _aExits:Array = null)
		{
			name = _name;
			line1 = _line1;
			line2 = _line2;
			line3 = _line3;
			x = _x;
			y = _y;
			z = _z;
			if (_aExits == null) aExits = new Array();
			else aExits = _aExits;
		}

	}
}