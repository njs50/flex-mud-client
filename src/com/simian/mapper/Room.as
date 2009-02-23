package com.simian.mapper
{
	import flash.display.Shape;	
	
	
	[RemoteClass(alias="com.simian.mapper.Room")]		
	public class Room extends Shape
	{
		
		// size of sprite 
		private static const sprite_area : int = 29;
		private static const join_size : int = 5;
		
		public var room_name : String; 		
		public var room_line1 : String;
		public var room_line2 : String;
		public var room_line3 : String;
		public var room_aExits : Array;
				
		public var room_x : int;
		public var room_y : int;						
		public var room_z : int;
				
		public var bSelected : Boolean = false;
		
		public function Room(_name:String = '',_line1:String = '',_line2:String = '',_line3:String = '', _x : int = 0, _y : int = 0, _z:int = 0, _aExits:Array = null)
		{
			room_name = _name;
			room_line1 = _line1;
			room_line2 = _line2;
			room_line3 = _line3;
			room_x = _x;
			room_y = _y;
			room_z = _z;
			if (room_aExits == null) room_aExits = new Array();
			else room_aExits = _aExits;
			
			// draw us a sprite
			redraw();
			
		}


		



		public function redraw() : void	{

			var midpoint : int = (sprite_area + 1) / 2;
			var length: int = sprite_area - (join_size * 2);
			
			// clear the sprite...			
			this.graphics.clear();
			
			this.scaleX = 1;
			this.scaleY = 1;
			
			
			// change border colour if this is selected
			if (this.bSelected){				
				this.graphics.lineStyle(1,0xff0000);				
			}else {				
				this.graphics.lineStyle(1,0x000000);				
			}						

			// add in the room box	
			this.graphics.beginFill(0x00ff00);			
			this.graphics.drawRect(join_size,join_size,length,length);			
			this.graphics.endFill();
			
			this.graphics.lineStyle(1,0x000000);

			// draw in any exits
			for each (var exit : Exit in this.room_aExits ) {

				switch (exit.direction) {
				
					case 'north':
						this.graphics.moveTo(midpoint,join_size);
						this.graphics.lineTo(midpoint,0);
					break;
	
					case 'south':
						this.graphics.moveTo(midpoint,sprite_area - join_size);
						this.graphics.lineTo(midpoint,sprite_area);						
					break;
	
					case 'east':
						this.graphics.moveTo(sprite_area - join_size,midpoint);
						this.graphics.lineTo(sprite_area,midpoint);						
					break;
	
					case 'west':
						this.graphics.moveTo(join_size,midpoint);
						this.graphics.lineTo(0,midpoint);												
					break;
	
					case 'up':
						
					break;
	
					case 'down':
						
					break;
				
				}


				
	
			}
			


			// position the room in the map...			
			this.x = this.room_x * sprite_area;
			this.y = this.room_y * sprite_area * -1;
		
		}



		public function match_room(room1:Room) : Boolean {
			if ( (room1.room_name != this.room_name) ||
				 (room1.room_line1 != this.room_line1) ||
				 (room1.room_line2 != this.room_line2) ||						 
				 (room1.room_line3 != this.room_line3) ) return false;
				 
			return true;	  
								
		}


		// adds an exit from one room to another room
		public function addExit(direction : String,to_room : Room) : void {
			
			var bExists : Boolean = false;
						
			// could check to make sure the link is to the same room
			// can't be arsed doing that just yet...			
			for each (var exit : Exit in this.room_aExits ) {
				if (exit.direction == direction) {													
					bExists = true;
				}
			}
			
			if (!bExists) {
				var newExit : Exit = new Exit(direction,to_room,direction);
				this.room_aExits.push(newExit); 				
				// update the sprite.
				redraw();				
			}
			
		}

	}
}