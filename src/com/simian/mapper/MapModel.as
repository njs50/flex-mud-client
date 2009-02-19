package com.simian.mapper {
	import com.asfusion.mate.events.Dispatcher;
	import com.simian.telnet.TelnetEvent;
	

	
	public class MapModel {
	
		public var verbose : Boolean = true;
	
		private var dispatcher : Dispatcher = new Dispatcher();
				
		private var exitingRegExp : RegExp = /You (\w+) (north|east|south|west|up|down)\.$/		
		private var roomRegExp : RegExp = /([^\n]*)\n\[Exits:([^\]]*)\]\s*([^\n]*)\n([^\n]*)\n([^\n]*)/;
		
		private var currentRoom : Room;
		
		private var current_x : int = 0;
		private var current_y : int = 0;
		private var current_z : int = 0;
				
		private var move_direction : String = '';		
		
		private var lastRoom : Room;
		
		private var _rooms : Object = new Object();
		
		
		public function MapModel() : void {
			
		}
	
	
		public function getRoom(i_x:int,i_y:int,i_z:int) : Room {
			
			var x : String = i_x.toString();
			var y : String = i_y.toString();
			var z : String = i_z.toString();
			
			var yPointer : Object;
			var zPointer : Object;
			var room : Room;
			
			// find it in the x array...
			if (_rooms.hasOwnProperty(x)) yPointer = _rooms[x];
			else {
				yPointer = new Object();
				_rooms[x] = yPointer;
			}
			
			// find it in the y array...
			if (yPointer.hasOwnProperty(y)) zPointer = yPointer[y];
			else {
				zPointer = new Object();
				yPointer[y] = zPointer;
			}

			// find it in the z array...
			if (zPointer.hasOwnProperty(z)) room = zPointer[z];
			else {
				room = null;
			}			
			
			return new Room();
			
		}
	
		public function setRoom(i_x:int,i_y:int,i_z:int, room: Room) : void {
			
			var x : String = i_x.toString();
			var y : String = i_y.toString();
			var z : String = i_z.toString();
			
			var yPointer : Object;
			var zPointer : Object;
			
			
			// find it in the x array...
			if (_rooms.hasOwnProperty(x)) yPointer = _rooms[x];
			else {
				yPointer = new Object();
				_rooms[x] = yPointer;
			}
			
			// find it in the y array...
			if (yPointer.hasOwnProperty(y)) zPointer = yPointer[y];
			else {
				zPointer = new Object();
				yPointer[y] = zPointer;
			}

			// place it in the z array...
			zPointer[z] = room;
			
		}


		
		public function checkLine(text:String) : void {
			
			var oExitCheck : Object = exitingRegExp.exec(text);
			
			if (oExitCheck != null) {
				
				if (move_direction.length != 0){
					if (move_direction != 'Error') {
						errorMessage('Detected move ' + oExitCheck[2] + ' while we were still processing a move ' + move_direction );
						move_direction = 'Error';
					}
				} else {
					move_direction = oExitCheck[2];	
					move(move_direction);
				}
				
				if (verbose) errorMessage('exited : ' + oExitCheck[2] );
			}
			
		} 
		
		
		private function move(direction:String) : void {
		
			switch (direction) {
			
				case 'north':
					current_y++;
				break;

				case 'south':
					current_y--;
				break;

				case 'east':
					current_x++;
				break;

				case 'west':
					current_x--;
				break;

				case 'up':
					current_z++;
				break;

				case 'down':
					current_z--;
				break;
			
				default:  
					errorMessage('moved in unknown direction!');
				break;	
			}			
			
			if (verbose) errorMessage('new location : (' + current_x + ',' + current_y + ',' + current_z + ')' );
			
		}		
		
		
		public function checkBlock(text:String) : void {
						
			var oRoomCheck : Object = roomRegExp.exec(text);
			
			// if this block contains a room...
			if (oRoomCheck != null) {
			
				var newRoom : Room = new Room(oRoomCheck[1],oRoomCheck[3],oRoomCheck[4],oRoomCheck[5],current_x,current_y,current_z);				
			
				// if this is the first room in the map then make it so!
				if (currentRoom == null) { currentRoom = newRoom; lastRoom = currentRoom };	
				
				// if the mapper is in an error state do nothing (but taunt the user for fun) 
				if ( move_direction == 'Error' ) {
					errorMessage('Mapping currently suspended due to error');
				
				// if we have a pending move action then lets add this room to the map.
				} else if ( move_direction != '') {
					
					// it's a move indeed!
					lastRoom = currentRoom;					
										
					setRoom(current_x,current_y,current_z,newRoom);
					
					
					// now that we have processed the move reset move_direction;
					move_direction = '';
				
				// no move detected. maybe they are just lookin around.
				} else {
					// check the detected room vs the current room
					if ( (newRoom.name != currentRoom.name) ||
						 (newRoom.line1 != currentRoom.line1) ||
						 (newRoom.line2 != currentRoom.line2) ||						 
						 (newRoom.line3 != currentRoom.line3) ) {
						 	
						 	// ruh roh, they've changed rooms without moving!
						 	errorMessage('room change detected but no move direction was noticed!' );
						 	
						 }
				} 
								
				if (verbose) errorMessage('room detected : ' + newRoom.name );
			}
			
			
			
		}
		
		
		
		// displays something for the user
		public function errorMessage(value:String) : void {								
        	var telnetEvent : TelnetEvent;       	
			telnetEvent = new TelnetEvent(TelnetEvent.NEW_LINE_DATA);        	
			telnetEvent.data = 'Mapper: ' + value;			
			dispatcher.dispatchEvent(telnetEvent);
		}	

	}
	
}