package com.simian.mapper
{
	import com.asfusion.mate.events.Dispatcher;
	import com.simian.profile.ProfileEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;	
	
	
	[RemoteClass(alias="com.simian.mapper.Room")]			
	public class Room 
	{
		
		// size of sprite 
		private static const sprite_area : int = 29;
		private static const join_size : int = 5;
		
		// the map this room belongs to
		
		// instances of this room in other maps;
		public var aLinkedRooms : Array;
				
		public var room_name : String; 				
		public var room_line1 : String;
		public var room_line2 : String;
		public var room_line3 : String;
		
		public var room_notes : String;
		
		public var room_aExits : Array;
				
		public var room_x : int;
		public var room_y : int;						
		public var room_z : int;
		
		public var room_colour : uint;
		
		public var travel_cost : int = 1;
		
		public var bookmark_label : String = '';		
						
		private var dispatcher : Dispatcher = new Dispatcher();
		
		public function Room(_name:String = '',exits_string:String = '',_line1:String = '',_line2:String = '',_line3:String = '', _x : int = 0, _y : int = 0, _z:int = 0, bookmark:String = '')
		{

			// set default properties.
			room_name = _name;
			room_line1 = _line1;
			room_line2 = _line2;
			room_line3 = _line3;
			room_x = _x;
			room_y = _y;
			room_z = _z;
			
			bookmark_label = bookmark;
			
			// set us up the exits
			room_aExits = new Array();			
			
			// parse any exits out of the optinal exit string (these are untested exits)
			var exitsRegexp : RegExp = /(north|east|south|west|up|down)/ig;			
			var oExits : Object;
			
			while (oExits = exitsRegexp.exec(exits_string)) {
				addExit(oExits[1],null);
			}			
			
		}

		public function mouseOverHandler(event:Event) : void {			
			// broadcast that the user has selected this room        	
        	var mEvent : MapperEvent;       	
			mEvent = new MapperEvent(MapperEvent.MOUSE_OVER_ROOM);        			
			mEvent.room = this;
			dispatcher.dispatchEvent(mEvent);							
		}


		public function clickHandler(event:Event) : void {

			// broadcast that the user has selected this room        
        	var mEvent : MapperEvent;       	
			mEvent = new MapperEvent(MapperEvent.MAPPER_SELECT_ROOM);        			
			mEvent.room = this;
			dispatcher.dispatchEvent(mEvent);			
			
		}

		public function doubleclickHandler(event:Event) : void {

			// broadcast that the user has selected this room        	
        	var mEvent : MapperEvent;       	
			mEvent = new MapperEvent(MapperEvent.MAPPER_MOVE_TO_ROOM);        			
			mEvent.room = this;
			dispatcher.dispatchEvent(mEvent);			
			
		}




		public function getSprite(recycleSprite : Sprite = null, bSelected:Boolean = false, bCurrentroom : Boolean = false) : Sprite {
			
			var thisSprite : Sprite			
								
			if (recycleSprite == null) {
				thisSprite = new Sprite();	
				
				// set mouse event settings
				thisSprite.doubleClickEnabled = true;
				thisSprite.mouseChildren = false;
				
				// add an event handler for if someone clicks on us
				thisSprite.addEventListener(MouseEvent.CLICK,clickHandler);
				thisSprite.addEventListener(MouseEvent.DOUBLE_CLICK,doubleclickHandler);
				thisSprite.addEventListener(MouseEvent.MOUSE_OVER,mouseOverHandler);				
								
			} else {
				thisSprite = recycleSprite;
				thisSprite.graphics.clear();
			}
			
			
			
			var midpoint : int = (sprite_area + 1) / 2;
			var length: int = sprite_area - (join_size * 2);			
			
			thisSprite.scaleX = 1;
			thisSprite.scaleY = 1;
			
			
			// change border colour if this is selected
			if (bCurrentroom){				
				thisSprite.graphics.lineStyle(1,0xff0000);				
			}else {				
				thisSprite.graphics.lineStyle(1,0x000000);				
			}						

			// add in the room box	
			if (this.aLinkedRooms != null && this.aLinkedRooms.length > 0) this.room_colour = 0xffccff;
			else if (!this.room_colour) this.room_colour = 0xffffcc;				
									
			thisSprite.graphics.beginFill(this.room_colour);		
					
			thisSprite.graphics.drawRect(join_size,join_size,length,length);			
			thisSprite.graphics.endFill();
			
			// draw a box round it if it's selected
			if (bSelected) {
				thisSprite.graphics.lineStyle(1,0x0000ff);
				thisSprite.graphics.drawRect(join_size - 1,join_size - 1,length + 2,length + 2);									
			}
			
			
			

			// draw in any exits
			for each (var exit : Exit in this.room_aExits ) {
				
				var join_gap : int = 0;
				var startPoint : int;
			
				if ( !exit.bLinearExit) thisSprite.graphics.lineStyle(1,0x00ff00);
				else thisSprite.graphics.lineStyle(1,0x000000); 
				
				// if this exit hasn't been linked to a room yet leave a gap
				if (exit.room == null) join_gap = 2;
				
				switch (exit.direction) {
				
					case 'north':
						thisSprite.graphics.moveTo(midpoint,join_size);
						thisSprite.graphics.lineTo(midpoint,0 + join_gap);
					break;
	
					case 'west':
						thisSprite.graphics.moveTo(join_size,midpoint);
						thisSprite.graphics.lineTo(0 + join_gap,midpoint);												
					break;
	
					case 'south':
						thisSprite.graphics.moveTo(midpoint,sprite_area - join_size);
						thisSprite.graphics.lineTo(midpoint,sprite_area - join_gap);						
					break;
	
					case 'east':
						thisSprite.graphics.moveTo(sprite_area - join_size,midpoint);
						thisSprite.graphics.lineTo(sprite_area - join_gap,midpoint);						
					break;
	
					case 'up':
						startPoint = join_size + 5;
						if (exit.room != null) thisSprite.graphics.beginFill(0x000000);
						thisSprite.graphics.moveTo(startPoint,startPoint - 3);
						thisSprite.graphics.lineTo(startPoint + 3, startPoint + 1);
						thisSprite.graphics.lineTo(startPoint - 3, startPoint + 1);
						thisSprite.graphics.lineTo(startPoint, startPoint - 3);
						if (exit.room != null) thisSprite.graphics.endFill();
					break;
	
					case 'down':
						startPoint = sprite_area - join_size - 5;
						if (exit.room != null) thisSprite.graphics.beginFill(0x000000);
						thisSprite.graphics.moveTo(startPoint,startPoint + 3);
						thisSprite.graphics.lineTo(startPoint + 3, startPoint - 1);
						thisSprite.graphics.lineTo(startPoint - 3, startPoint - 1);
						thisSprite.graphics.lineTo(startPoint, startPoint + 3);	
						if (exit.room != null) thisSprite.graphics.endFill();					
					break;
				
				}
	
			}
			
			// position the room in the map...			
			thisSprite.x = this.room_x * sprite_area;
			thisSprite.y = this.room_y * sprite_area * -1;						
			
			return thisSprite;
			
		}
	


		public function match_room(room1:Room) : Boolean {
			if ( (room1.room_name != this.room_name) ||
				 (room1.room_line1 != this.room_line1) ||
				 (room1.room_line2 != this.room_line2) ||						 
				 (room1.room_line3 != this.room_line3) ) return false;
				 
			return true;	  
								
		}


		// adds an exit from one room to another room
		public function addExit(direction : String,to_room : Room,_command:String = '', _bLinearExit : Boolean = true) : void {
			
			var bExists : Boolean = false;
			
			if (_command == '') _command = direction;
						
			// could check to make sure the link is to the same room
			// can't be arsed doing that just yet...			
			for each (var exit : Exit in this.room_aExits ) {
				if (exit.direction == direction) {													
					if (exit.room != to_room && to_room != null) {
						exit.room = to_room;
						exit.command = _command;
						exit.bLinearExit = _bLinearExit;
					} 
					bExists = true;
				}
			}
			
			if (!bExists) {				
				var newExit : Exit = new Exit(direction,to_room,_command, _bLinearExit);
				this.room_aExits.push(newExit); 
				// save changes to the map
				dispatcher.dispatchEvent( new ProfileEvent(ProfileEvent.WRITE_PROFILE_LSO) );																
			}
			
		}
		
		
		// returns the exit info for a given direction
		public function findExit(direction : String) : Exit {
			for each (var exit : Exit in this.room_aExits ) {
				if (exit.direction == direction) return exit;																	
			}			
			return null;
		}
		

	}
}