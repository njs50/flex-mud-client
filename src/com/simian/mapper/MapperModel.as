package com.simian.mapper {

	import com.asfusion.mate.events.Dispatcher;
	import com.simian.telnet.TelnetEvent;
	
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	[Bindable]
	public class MapperModel {
	
		// Bindable public vars...
		public var oMap : Map = new Map('temporary map');
		public var current_room : Room;
				
		public var dictMapLayerSprites : Dictionary = new Dictionary();		
		public var dictRoomSprites : Dictionary = new Dictionary();
		
		public var verbose : Boolean = false;	
		
		public var lastRoom : Room;
		
		public var bMappingEnabled : Boolean = false;
		public var bAutoMove : Boolean = false;
		public var aMaps : Array;
		
		public var selected_room : Room;
				
		// private vars
		private var dispatcher : Dispatcher = new Dispatcher();
		
		private var exitingRegExp : RegExp = /You\s(\S+\s?\S*)\s(north|east|south|west|up|down)\.$/;		
		private var roomRegExp : RegExp = /([^\n]*)\n\[Exits:([^\]]*)\]\s*([^\n]*)\n([^\n]*)\n([^\n]*)/g;
	
	
		// vars for room detection
		private var current_x : int = 0;
		private var current_y : int = 0;
		private var current_z : int = 0;				
		private var move_direction : String = '';
		private var aQueuedMoves : Array = new Array();		
	
				
		// vars for path handling	
		private var aPath : Array = new Array();
		private var lastPathStep : String = '';
		private var aPathBehind : Array = new Array();		
		
		
		
		
		public function MapperModel() : void {
		
			aMaps = new Array();			
			
		}
	
	
	
		public function getLayerSprite(layer : MapLayer) : Sprite {
			
			if (layer != null) {
			
				var layerSprite : Sprite = dictMapLayerSprites[layer];
				
				// if this layer doesn't have a sprite setup yet do it!
				if (layerSprite == null){
					
					layerSprite = new Sprite();			
					for each (var yLayer : Object in layer.oRooms) {				
						for each (var oRoom : Room in yLayer) {					
							var thisSprite : Sprite = oRoom.getSprite(); 
							dictRoomSprites[oRoom] = thisSprite;
							layerSprite.addChild(thisSprite);							 					
						}  
					}																				
					dictMapLayerSprites[layer] = layerSprite;
				}			
				
				return layerSprite;
			} 
			
			return null;
			
		}
		
		
		public function addRoom(i_x:int,i_y:int,i_z:int, room: Room) : void {
			
			oMap.setRoom(i_x,i_y,i_z,room);
			
			var thisLayer : MapLayer = oMap.oRooms[i_z];			
			var layerSprite : Sprite = getLayerSprite(thisLayer);
			var thisSprite : Sprite = room.getSprite(); 
			
			dictRoomSprites[room] = thisSprite;
			layerSprite.addChild(thisSprite);
			
		}
		
		public function removeRoom(oRoom:Room) : void {
			
			var thisLayer : MapLayer = oMap.oRooms[oRoom.room_z];			
			var layerSprite : Sprite = getLayerSprite(thisLayer);			
			var thisSprite : Sprite = dictRoomSprites[oRoom];
			
			// remove the sprite from dict and sprite
			layerSprite.removeChild(thisSprite);
			dictRoomSprites[oRoom] = null;

			// loop through any rooms this one is linked to and remove it as an exit
			for each (var exit : Exit in oRoom.room_aExits ) {
				if (exit.room != null) removeExitFromRoom(oRoom,exit.room.room_x,exit.room.room_y,exit.room.room_z);
			}
			
			// also make sure none of the adjacent rooms have this room as an exit (one way)
			removeExitFromRoom(oRoom,oRoom.room_x+1,oRoom.room_y,oRoom.room_z);		
			removeExitFromRoom(oRoom,oRoom.room_x-1,oRoom.room_y,oRoom.room_z);
			removeExitFromRoom(oRoom,oRoom.room_x,oRoom.room_y+1,oRoom.room_z);
			removeExitFromRoom(oRoom,oRoom.room_x,oRoom.room_y-1,oRoom.room_z);
			removeExitFromRoom(oRoom,oRoom.room_x,oRoom.room_y,oRoom.room_z+1);
			removeExitFromRoom(oRoom,oRoom.room_x,oRoom.room_y,oRoom.room_z-1);					
		
			// finally kill the room
			delete thisLayer.oRooms[oRoom.room_y][oRoom.room_x];						
			
		}
		
		// if a room exists at this location run it's removeExit
		private function removeExitFromRoom(oRoom : Room,x:int,y:int,z:int) : void {						
			var adjacentRoom : Room = oMap.getRoom(x,y,z);			
			var bChange : Boolean = false;						
			if (adjacentRoom != null) {
				var aNewExits : Array = new Array();				
				for each (var exit : Exit in adjacentRoom.room_aExits ) {
					if ( exit.room == oRoom ) {
						exit.room = null;
						aNewExits.push(exit);
						bChange = true;
					} else {
						aNewExits.push(exit);
					}
				}				
				if (bChange) {						
					adjacentRoom.room_aExits = aNewExits;
					redrawRoom(adjacentRoom);
				}				
			} 			
		}		

		
		
		public function redrawRoom(room:Room) : void {
			if (room != null) dictRoomSprites[room] = room.getSprite(dictRoomSprites[room],(room == selected_room),(room == current_room));			
		}
		
	
	  	public function newMap(mapname:String) : void {
	  		// make sure they've entered a name for this new map
	  		
	  		if (aMaps == null) aMaps = new Array();
	  		
	  		if (aMaps.length == 0 ) {

				// create a new map
				oMap = new Map(mapname);
				
				// add the new map to the array of maps
				aMaps.push(oMap);
	  			
	  		} else {
	  		
				// create a new map
				var oNewMap : Map = new Map(mapname);
					
				// add the new map to the array of maps
				aMaps.push(oNewMap);  
				
				var oldLinkRoom : Room = current_room;
				var newLinkRoom : Room = new Room(oNewMap,current_room.room_name,'',current_room.room_line1,current_room.room_line2,current_room.room_line3,0,0,0);
	
				if (oldLinkRoom.aLinkedRooms == null) oldLinkRoom.aLinkedRooms = new Array();
	
				// add the parent (and it's linked rooms) as a link to this room						
				newLinkRoom.aLinkedRooms = oldLinkRoom.aLinkedRooms.slice();
				newLinkRoom.aLinkedRooms.push(oldLinkRoom);			
				// add this room to the parents list of linked rooms
				oldLinkRoom.aLinkedRooms.push(newLinkRoom);
				// add this room to any other rooms linked to the parent
				for each (var oRoom : Room in oldLinkRoom.aLinkedRooms) oRoom.aLinkedRooms.push(newLinkRoom);  						
				
				// add exit stubs for any exits on the parent room			
				for each (var oExit : Exit in oldLinkRoom.room_aExits) newLinkRoom.room_aExits.push(new Exit(oExit.direction));
									
				// change model details (back to defaults!)
				oMap = oNewMap;				
				current_x = 0;
				current_y = 0;			
				current_z = 0;
				move_direction = '';
				aQueuedMoves = new Array();
				lastRoom = null;

				// add room to map
				addRoom(0,0,0,newLinkRoom);
				
				setCurrentRoom(newLinkRoom);
				
	  		}
	  	}  		
	
	
		public function setCurrentRoom(room:Room) : void {
			if (current_room != null) {
				lastRoom = current_room;
				dictRoomSprites[lastRoom] = lastRoom.getSprite(dictRoomSprites[lastRoom],(lastRoom == selected_room),false);
			}
			current_room = room;
			dictRoomSprites[current_room] = current_room.getSprite(dictRoomSprites[current_room],(current_room == selected_room),true);
		}
	
		public function newPath(aNewPath : Array) : void {
			if (aNewPath != null && aNewPath.length > 0) {
				this.aPath = aNewPath.reverse();
				this.lastPathStep = '';
				this.aPathBehind = new Array();
			}
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
				dictRoomSprites[selected_room] = selected_room.getSprite(dictRoomSprites[selected_room],false,(selected_room == current_room));				
			}
			
			selected_room = room;
			
			dictRoomSprites[selected_room] = selected_room.getSprite(dictRoomSprites[selected_room],true,(selected_room == current_room));			
			
		}
		
		
		public function moveToRoom(room : Room) : void {
			// trace('someone clicked ::: ' + room.room_name);
			
			if (selected_room != null) {
				
				var aNewPath : Array = shortestPath(current_room,selected_room);				
				
				if (shortestPath != null) {

					newPath(aNewPath);					
					if (bAutoMove) stepPath();					
					
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
			aQueuedMoves = new Array();
			
			for each ( var searchMap : Map in aMaps ) {
						
				var thisRoom : Room = searchMap.find(current_room);
				
				if (thisRoom != null) {
					
					oMap = searchMap;
					
					setCurrentRoom(thisRoom);															
					lastRoom = current_room;
					
					current_x = thisRoom.room_x;
					current_y = thisRoom.room_y;
					current_z = thisRoom.room_z;										
						
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
				
				if (move_direction != 'Error') {
					// don't want it matching 'You stand up.' or 'You wake up.'	
					if (oExitCheck[1].toLowerCase() != 'stand' && oExitCheck[1].toLowerCase() != 'wake'){
						if (move_direction.length != 0){
							aQueuedMoves.push(oExitCheck[2]);	
						} else {
							move_direction = oExitCheck[2];	
							move(move_direction);
						}
					} 
					
					if (verbose) errorMessage('exited : ' + oExitCheck[2] );
				
					if (bAutoMove && aPath.length > 0) stepPath();						
				}
					
			}
			
		} 
		
		public function nextMoveDirection(direction:String) : void {			
			move_direction = direction;
			move(direction);
			if (verbose) errorMessage('expecting move : ' + move_direction );			
		}
		
		public function nextMoveLocation(_x : int, _y : int, _z : int) : void {			
			move_direction = 'teleport';
			current_x = _x;
			current_y = _y;
			current_z = _z;			
			if (verbose) errorMessage('teleporting : ' + move_direction + ' (' + current_x + ',' + current_y + ',' + current_z + ')' );
		}

		public function nextMoveRelativeLocation(_x : int, _y : int, _z : int) : void {			
			move_direction = 'teleport';
			current_x += _x;
			current_y += _y;
			current_z += _z;			
			if (verbose) errorMessage('teleporting : ' + move_direction + ' (' + current_x + ',' + current_y + ',' + current_z + ')' );
		}		

		
		// scans a block of text for room info
		public function checkBlock(text:String) : void {
						
			var oRoomCheck : Object;  
			
			// if this block contains a room...
			while (oRoomCheck = roomRegExp.exec(text)) {
				
				var expectedRoom : Room = oMap.getRoom(current_x,current_y,current_z);
				var newRoom : Room = new Room(oMap,oRoomCheck[1],oRoomCheck[2],oRoomCheck[3],oRoomCheck[4],oRoomCheck[5],current_x,current_y,current_z);
				
				// if this is a new room add it to the matrix
				// if there was a room here already make sure it's this room then switch to it...				
				if (expectedRoom == null ){ 									

					// if mapping is enabled add to the room matrix
					if (bMappingEnabled) {	
						addRoom(current_x,current_y,current_z,newRoom);
					}
					
				} else{
					if ( ! newRoom.match_room(expectedRoom) ){
						errorMessage('moved but not to where we expected' );
						move_direction = 'Error'
					} else newRoom = expectedRoom;									
				}			
								
				// if this is the first room in the map then make it so!
				if (current_room == null) { current_room = newRoom; lastRoom = current_room; } 	
				
				// if the mapper is in an error state do nothing (but taunt the user for fun) 
				else if ( move_direction == 'Error' ) {
					errorMessage('Mapping currently suspended due to error');
					// attempt to recover from the error if we are not mapping
										
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
					// if another move is already queued (as there can potentially be multiple moves in the same block)
					// process the next move too
					if (aQueuedMoves.length > 0 && move_direction != 'Error') {												
						move_direction = aQueuedMoves[0];
						move(move_direction);	
						aQueuedMoves = aQueuedMoves.slice(1);
					} else move_direction = '';


				
				// no move detected. maybe they are just lookin around.
				} else {
					// check the detected room vs the current room
					// to see if they've changed rooms without moving!
					if ( ! newRoom.match_room(current_room) ){
						errorMessage('room change detected but no move direction was noticed!' );						
					} 
						 
				} 

				// if the room has changed update things here
				if ( ! newRoom.match_room(current_room) ) {								
					setCurrentRoom(newRoom);				
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