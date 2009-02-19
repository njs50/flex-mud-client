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


		public function match_room(room1:Room) : Boolean {
			if ( (room1.name != this.name) ||
				 (room1.line1 != this.line1) ||
				 (room1.line2 != this.line2) ||						 
				 (room1.line3 != this.line3) ) return false;
				 
			return true;	  
								
		}


		// adds an exit from one room to another room
		public function addExit(direction : String,to_room : Room) : void {
			
			var bExists : Boolean = false;
						
			// could check to make sure the link is to the same room
			// can't be arsed doing that just yet...			
			for each (var exit : Exit in this.aExits ) {
				if (exit.direction == direction) {													
					bExists = true;
				}
			}
			
			if (!bExists) {
				var newExit : Exit = new Exit(direction,to_room,direction);
				this.aExits.push(newExit); 
			}
			
		}

	}
}