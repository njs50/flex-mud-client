package com.simian.mapper {

	import com.asfusion.mate.events.Dispatcher;
	import com.simian.telnet.TelnetEvent;
	
	[Bindable]
	public class MapperModel {
	
		// Bindable public vars...
		public var verbose : Boolean = false;	
		public var oMap : Map;
		public var current_room : Room;
		public var lastRoom : Room;
		public var current_layer : MapLayer;		
		public var bMappingEnabled : Boolean = false;
		public var aMaps : Array;
		
		public var selected_room : Room;
				
		// private vars
		private var dispatcher : Dispatcher = new Dispatcher();
		
		private var exitingRegExp : RegExp = /You\s(\S+\s?\S*)\s(north|east|south|west|up|down)\.$/;		
		private var roomRegExp : RegExp = /([^\n]*)\n\[Exits:([^\]]*)\]\s*([^\n]*)\n([^\n]*)\n([^\n]*)/;
		
		private var current_x : int = 0;
		private var current_y : int = 0;
		private var current_z : int = 0;
				
		private var move_direction : String = '';		
				
		
		private var aPath : Array = new Array();
		private var lastPathStep : String = '';
		private var aPathBehind : Array = new Array();		
		
		
		
		
		public function MapperModel() : void {
		
			aMaps = new Array();
			
			// create a new map
			oMap = new Map('Test Map');
			
			// add the new map to the array of maps
			aMaps.push(oMap);

			// despatch a map change event
        	var mEvent : MapperEvent;       	
			mEvent = new MapperEvent(MapperEvent.CHANGE_MAP);        				
			dispatcher.dispatchEvent(mEvent);
			
		}
	
	
		public function newPath(aNewPath : Array) : void {
			this.aPath = aNewPath.reverse();
			this.lastPathStep = '';
			this.aPathBehind = new Array();
		}
		
	
		// takes a step on a path
		public function stepPath() : void {
			if (aPath.length){
				lastPathStep = aPath.pop() as String; 
				aPathBehind.push(lastPathStep);
				sendCommand(lastPathStep);
			} else if (verbose) errorMessage('stepper is out of steps to step');	
		}

		// undoes the last step
		public function undoStep() : void {			
			if (aPathBehind.length > 0) {
				lastPathStep = aPathBehind.pop(); 
				aPath.push(lastPathStep);
				if (verbose) errorMessage('undoing step');
			} else if (verbose) errorMessage('no steps to undo');								
		}	
		
		public function repeatPathStep() : void{
			if (lastPathStep != ''){ 
				sendCommand(lastPathStep);
				
			} else if (verbose) errorMessage('no step to repeat');
		}
	
	
		// start mapper
		public function mapperStart() : void {
			bMappingEnabled = true;
		}

		// stop mapper
		public function mapperStop() : void {
			bMappingEnabled = false;
		}


		public function selectRoom(room : Room) : void {
			// trace('someone clicked ::: ' + room.room_name);
			
			if (selected_room != null) {
				selected_room.bSelected = false;
				selected_room.redraw();				
			}
			
			selected_room = room;
			selected_room.bSelected = true;
			selected_room.redraw();		
			
		}
		
		
		public function moveToRoom(room : Room) : void {
			// trace('someone clicked ::: ' + room.room_name);
			
			if (selected_room != null) {
				
				var aNewPath : Array = shortestPath(current_room,selected_room);				
				
				if (shortestPath != null) {
					
					errorMessage('shortest path is ' + aNewPath.toString());
					newPath(aNewPath);
					stepPath();					
					
				} else if (verbose) errorMessage('no path to selected room available');
				
			}

		}		
		
		
		// djikstras shortest path algorithm
		public function shortestPath (startRoom : Room, endRoom : Room) : Array {
			
			var aFinal : Array = new Array();
			var aAdjacent : Array = new Array();
									
			var current_node : PathNode = new PathNode(0,startRoom,new Array()); 			
			
			while ( !nodeArrayContainsRoom(aFinal,endRoom) ) {
				
				// push the currnet_node (closest) onto the final nodes
				aFinal.push( current_node );
				
				for each (var oExit : Exit in current_node.room.room_aExits) {				
					// only add this if the room isn't already in aFinal (and it's actually an exit, not just a placeholder)				
					if ( oExit.room != null && !nodeArrayContainsRoom(aFinal,oExit.room) ){ 
						var aNewPath : Array = current_node.aPath.slice(); 
						aNewPath.push(oExit.direction);
						aAdjacent.push( new PathNode( current_node.distance + oExit.room.travel_cost, oExit.room , aNewPath ) );
					}				
				}
				
				// if there are still nodes to check continue. otherwise abandon ship
				if (aAdjacent.length > 0) {
					// sort the adjacent array so the closest thing will be last (to make for easy popping action)
					aAdjacent = aAdjacent.sortOn( "distance", Array.NUMERIC | Array.DESCENDING );				
					current_node = aAdjacent.pop();						
					// check if this is the room we are looking for!
					if (current_node.room == endRoom) return current_node.aPath;								
				} else break;			
			} 
						
			errorMessage('Target room appears unreachable from your current location');
			return null;
			
		}
		
		public function nodeArrayContainsRoom(aNode:Array, target_room: Room) : Boolean {			
			for each (var node : PathNode in aNode) {
				if ( node.room == target_room) return true; 
			} 						
			return false;			
		}
		


		// finds the users position in the event they've become desync'd or just logged in...
		public function findMe() : void {
			
			// reset the move direction
			move_direction = '';
			
			for each ( var searchMap : Map in aMaps ) {
						
				var thisRoom : Room = searchMap.find(current_room);
				
				if (thisRoom != null) {
					
					oMap = searchMap;
					
			 		// deselect the current room
			 		current_room.bCurrentroom = false;
			 		current_room.redraw();			
					
					current_room = thisRoom;
					current_layer = oMap.oRooms[current_room.room_z];
					lastRoom = current_room;
					current_x = thisRoom.room_x;
					current_y = thisRoom.room_y;
					current_z = thisRoom.room_z;
					
					// select the new current room
			 		current_room.bCurrentroom = true;
			 		current_room.redraw();
	
					// despatch a room change event to let the viewer know we have moved
			    	var mEvent : MapperEvent;       	
					mEvent = new MapperEvent(MapperEvent.CHANGE_ROOM);        				
					dispatcher.dispatchEvent(mEvent);					
					
					// our work here is done, we are found...
					return;
				
				}
			}			 
			
			
			// if we've got this far then we didn't find the room in any of the maps
			errorMessage('Your current room could not be found in the map (you might try looking around)');
			bMappingEnabled = false;
		
			
		}




		// scans a line of text for a move
		public function checkLine(text:String) : void {
			
			var oExitCheck : Object = exitingRegExp.exec(text);
			
			
			if (oExitCheck != null) {
				
				if (move_direction.length != 0){
					if (move_direction != 'Error') {
						errorMessage('Detected move ' + oExitCheck[2] + ' while we were still processing a move ' + move_direction );
						move_direction = 'Error';
					}
				} else {
					// don't want it matching 'You stand up.'
					if (oExitCheck[1].toLowerCase() != 'stand'){
						move_direction = oExitCheck[2];	
						move(move_direction);
					}
				}
				
				if (verbose) errorMessage('exited : ' + oExitCheck[2] );
			}
			
		} 
		
		

		
		// scans a block of text for room info
		public function checkBlock(text:String) : void {
						
			var oRoomCheck : Object = roomRegExp.exec(text);
			
			// if this block contains a room...
			if (oRoomCheck != null) {
			
				var expectedRoom : Room = oMap.getRoom(current_x,current_y,current_z);
				var newRoom : Room = new Room(oRoomCheck[1],oRoomCheck[2],oRoomCheck[3],oRoomCheck[4],oRoomCheck[5],current_x,current_y,current_z);
				
				// if this is a new room add it to the matrix
				// if there was a room here already make sure it's this room then switch to it...				
				if (expectedRoom == null ){ 									

					// if mapping is enabled add to the room matrix
					if (bMappingEnabled) {	
						oMap.setRoom(current_x,current_y,current_z,newRoom);
					}
					
				} else{
					if ( ! newRoom.match_room(expectedRoom) ) errorMessage('moved but not to where we expected' );
					else newRoom = expectedRoom;									
				}			
								
				// if this is the first room in the map then make it so!
				if (current_room == null) { current_room = newRoom; lastRoom = current_room; } 	
				
				// if the mapper is in an error state do nothing (but taunt the user for fun) 
				else if ( move_direction == 'Error' ) {
					errorMessage('Mapping currently suspended due to error');
				
				// if we have a pending move action then lets add this room to the map.
				} else if ( move_direction != '') {
										
					// add exits to rooms (if mapping is enabled)			
					
					if (bMappingEnabled) {		
						// add exit from last room to this room
						current_room.addExit(move_direction,newRoom);					
						// this is assuming all moves are bidirectional (no one way doors)
						newRoom.addExit(reverseDirection(move_direction),current_room);										
					}
					
					// now that we have processed the move reset move_direction;
					move_direction = '';


				
				// no move detected. maybe they are just lookin around.
				} else {
					// check the detected room vs the current room
					// to see if they've changed rooms without moving!
					if ( ! newRoom.match_room(current_room) ) errorMessage('room change detected but no move direction was noticed!' );
						 
				} 

				// if the room has changed update things here
				if ( ! newRoom.match_room(current_room) ) {
				
					// update the last/current room pointer
					lastRoom = current_room;
					current_room = newRoom;

			 		// deselect the last room (if there was one)
			 		if (lastRoom != null) {
			 			lastRoom.bCurrentroom = false;
			 			lastRoom.redraw(); 			
			 		}
	
			 		// select the new room
			 		current_room.bCurrentroom = true;
			 		current_room.redraw();

				}

								
				if (verbose) errorMessage('room detected : ' + newRoom.room_name );
			}
			
			
			
		}
		
		

		
		

		
		
		
		
		
		/********************************
		 *        UTILITY FUNCTIONS     *
		 * ******************************/
		
		
		// displays something for the user
		public function errorMessage(value:String) : void {								
        	var telnetEvent : TelnetEvent;       	
			telnetEvent = new TelnetEvent(TelnetEvent.NEW_LINE_DATA);        	
			telnetEvent.data = 'Mapper: ' + value;			
			dispatcher.dispatchEvent(telnetEvent);
		}	

		
		// sends a command to the telnet client
		public function sendCommand(value:String) : void {								
        	var telnetEvent : TelnetEvent;       	
			telnetEvent = new TelnetEvent(TelnetEvent.SEND_TRIGGER_DATA);        	
			telnetEvent.data =  value;			
			dispatcher.dispatchEvent(telnetEvent);
		}	

		
		


		private function reverseDirection(direction:String) : String {
		
			switch (direction.toLowerCase()) {
			
				case 'north':
					return 'south';
				break;

				case 'south':
					return 'north';
				break;

				case 'east':
					return 'west';
				break;

				case 'west':
					return 'east';
				break;

				case 'up':
					return 'down';
				break;

				case 'down':
					return 'up';
				break;
			
				default:  
					errorMessage('unknown directions can not be reversed!');
				break;	
				
			}			
						
			return 'unknown';
			
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





	}	
}