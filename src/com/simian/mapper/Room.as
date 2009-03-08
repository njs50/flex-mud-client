package com.simian.mapper
{
	import com.asfusion.mate.events.Dispatcher;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;	
	
	
	[RemoteClass(alias="com.simian.mapper.Room")]			
	public class Room extends Sprite
	{
		
		// size of sprite 
		private static const sprite_area : int = 29;
		private static const join_size : int = 5;
		
		// the map this room belongs to
		public var oMap : Map;
		
		// instances of this room in other maps;
		public var aLinkedRooms : Array;
				
		public var room_name : String; 				
		public var room_line1 : String;
		public var room_line2 : String;
		public var room_line3 : String;
		public var room_aExits : Array;
				
		public var room_x : int;
		public var room_y : int;						
		public var room_z : int;
		
		public var travel_cost : int = 1;
				
		public var bCurrentroom : Boolean = false;		
		public var bSelected : Boolean = false;
		
		private var dispatcher : Dispatcher = new Dispatcher();
		
		public function Room(_map:Map, _name:String = '',exits_string:String = '',_line1:String = '',_line2:String = '',_line3:String = '', _x : int = 0, _y : int = 0, _z:int = 0, _aExits:Array = null)
		{

			// set default properties.
			this.doubleClickEnabled = true;
			this.mouseChildren = false;

			oMap = _map;			
			
			room_name = _name;
			room_line1 = _line1;
			room_line2 = _line2;
			room_line3 = _line3;
			room_x = _x;
			room_y = _y;
			room_z = _z;
			
			// set us up the exits
			if (room_aExits == null) room_aExits = new Array();
			else room_aExits = _aExits;
			
			// parse any exits out of the optinal exit string (these are untested exits)
			var exitsRegexp : RegExp = /(north|east|south|west|up|down)/ig;			
			var oExits : Object;
			
			while (oExits = exitsRegexp.exec(exits_string)) {
				addExit(oExits[1],null);
			}
			
			// add an event handler for if someone clicks on us
			addEventListener(MouseEvent.CLICK,clickHandler);
			addEventListener(MouseEvent.DOUBLE_CLICK,doubleclickHandler);
			addEventListener(MouseEvent.MOUSE_OVER,mouseOverHandler);
			
			
			// draw us a sprite
			redraw();
			
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


		public function redraw() : void	{

			var midpoint : int = (sprite_area + 1) / 2;
			var length: int = sprite_area - (join_size * 2);
			
			// clear the sprite...			
			this.graphics.clear();
			
			this.scaleX = 1;
			this.scaleY = 1;
			
			
			// change border colour if this is selected
			if (this.bCurrentroom){				
				this.graphics.lineStyle(1,0xff0000);				
			}else {				
				this.graphics.lineStyle(1,0x000000);				
			}						

			// add in the room box	
			this.graphics.beginFill(0x00ff00);			
			this.graphics.drawRect(join_size,join_size,length,length);			
			this.graphics.endFill();
			
			// draw a box round it if it's selected
			if (this.bSelected) {
				this.graphics.lineStyle(1,0x0000ff);
				this.graphics.drawRect(join_size - 1,join_size - 1,length + 2,length + 2);									
			}
			
			
			this.graphics.lineStyle(1,0x000000);

			// draw in any exits
			for each (var exit : Exit in this.room_aExits ) {
				
				var join_gap : int = 0;
				var startPoint : int;
				
				// if this exit hasn't been linked to a room yet leave a gap
				if (exit.room == null) join_gap = 2;
				
				switch (exit.direction) {
				
					case 'north':
						this.graphics.moveTo(midpoint,join_size);
						this.graphics.lineTo(midpoint,0 + join_gap);
					break;
	
					case 'west':
						this.graphics.moveTo(join_size,midpoint);
						this.graphics.lineTo(0 + join_gap,midpoint);												
					break;
	
					case 'south':
						this.graphics.moveTo(midpoint,sprite_area - join_size);
						this.graphics.lineTo(midpoint,sprite_area - join_gap);						
					break;
	
					case 'east':
						this.graphics.moveTo(sprite_area - join_size,midpoint);
						this.graphics.lineTo(sprite_area - join_gap,midpoint);						
					break;
	
					case 'up':
						startPoint = join_size + 5;
						if (exit.room != null) this.graphics.beginFill(0x000000);
						this.graphics.moveTo(startPoint,startPoint - 3);
						this.graphics.lineTo(startPoint + 3, startPoint + 1);
						this.graphics.lineTo(startPoint - 3, startPoint + 1);
						this.graphics.lineTo(startPoint, startPoint - 3);
						if (exit.room != null) this.graphics.endFill();
					break;
	
					case 'down':
						startPoint = sprite_area - join_size - 5;
						if (exit.room != null) this.graphics.beginFill(0x000000);
						this.graphics.moveTo(startPoint,startPoint + 3);
						this.graphics.lineTo(startPoint + 3, startPoint - 1);
						this.graphics.lineTo(startPoint - 3, startPoint - 1);
						this.graphics.lineTo(startPoint, startPoint + 3);	
						if (exit.room != null) this.graphics.endFill();					
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
					if (exit.room != to_room && to_room != null) exit.room = to_room;
					bExists = true;
				}
			}
			
			if (!bExists) {
				var newExit : Exit = new Exit(direction,to_room,direction);
				this.room_aExits.push(newExit); 				
				// update the sprite (if this isn't being called from the contructor i.e untested exit)
				if (to_room != null) redraw();
			}
			
		}
		
		// sets the exit back to being a stub. 
		public function removeExit(direction : String = '', to_room : Room = null) : void {
			
			var aNewExits : Array = new Array();
			
			for each (var exit : Exit in this.room_aExits ) {
				if (direction != '' && exit.direction == direction) {	
					exit.room = null;
					aNewExits.push(exit);
				} else if ( to_room != null && exit.room == to_room ) {
					exit.room = null;
					aNewExits.push(exit);
				} else {
					aNewExits.push(exit);
				}
			}
						
			this.room_aExits = aNewExits;
			this.redraw();

		}
		

	}
}