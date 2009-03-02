package com.simian.mapper
{
	
	[RemoteClass(alias="com.simian.mapper.Map")]		
	public class Map
	{		
		
		public var oRooms : Object;
		
		[Bindable]
		public var map_name : String;
		
		
		public function Map(_name:String = '')
		{
			oRooms = new Object();
			map_name = _name;				
		}


		public function deleteRoom(oRoom : Room) : void {
			
			// loop through any rooms this one is linked to and remove it as an exit
			for each (var exit : Exit in oRoom.room_aExits ) {
				if (exit.room != null) exit.room.removeExit('',oRoom);
			}
			
			// makes sure none of the adjacent rooms have this room as an exit
			removeExit(oRoom,oRoom.room_x+1,oRoom.room_y,oRoom.room_z);		
			removeExit(oRoom,oRoom.room_x-1,oRoom.room_y,oRoom.room_z);
			removeExit(oRoom,oRoom.room_x,oRoom.room_y+1,oRoom.room_z);
			removeExit(oRoom,oRoom.room_x,oRoom.room_y-1,oRoom.room_z);
			removeExit(oRoom,oRoom.room_x,oRoom.room_y,oRoom.room_z+1);
			removeExit(oRoom,oRoom.room_x,oRoom.room_y,oRoom.room_z-1);
			
			// find the layer
			var thisLayer : MapLayer = oRooms[oRoom.room_z];
			thisLayer.removeRoom(oRoom); 
									
			// finally kill the room
			delete thisLayer.oRooms[oRoom.room_y][oRoom.room_x];
			
		} 
		
		// if a room exists at this location run it's removeExit
		private function removeExit(oRoom : Room,x:int,y:int,z:int) : void {			
			var adjacentRoom : Room = getRoom(x,y,z);			
			if (adjacentRoom != null) adjacentRoom.removeExit('',oRoom);			
		}

		

		public function find(oRoom : Room) : Room {
			// loop through all rooms in this map and look for a match
			for each (var zLayer : Object in oRooms ) {			
				for each (var yLayer : Object in zLayer.oRooms) {					
					for each (var testRoom : Room in yLayer) {						
						if (oRoom.match_room(testRoom)) return testRoom;						
					}					
				} 				
			}			
			return null;			
		}
		

		public function getRoom(i_x:int,i_y:int,i_z:int) : Room {
			
			var x : String = i_x.toString();
			var y : String = i_y.toString();
			var z : String = i_z.toString();
			
			var yPointer : Object;
			var xPointer : Object;
			var room : Room;
			
			var current_layer : MapLayer;
			
			// find it in the z array...
			if (oRooms.hasOwnProperty(z)){
				current_layer = oRooms[z];
				yPointer = current_layer.oRooms;				
			} 
			else {				
				current_layer = new MapLayer();
				oRooms[z] = current_layer									
				yPointer = current_layer.oRooms;
			}
			
			// find it in the y array...
			if (yPointer.hasOwnProperty(y)) xPointer = yPointer[y];
			else {
				xPointer = new Object();
				yPointer[y] = xPointer;
			}

			// find it in the x array...
			if (xPointer.hasOwnProperty(x)) room = xPointer[x];
			else {
				room = null;
			}			
			
			return room;
			
		}
	
		public function setRoom(i_x:int,i_y:int,i_z:int, room: Room) : void {
			
			var x : String = i_x.toString();
			var y : String = i_y.toString();
			var z : String = i_z.toString();
			
			var current_layer : MapLayer;
			
			var yPointer : Object;
			var xPointer : Object;			
			
			// find it in the z array...
			if (oRooms.hasOwnProperty(z)){
				current_layer = oRooms[z];
				yPointer = current_layer.oRooms;
				current_layer.addRoom(room);
			} 
			else {				
				current_layer = new MapLayer();
				oRooms[z] = current_layer				
				current_layer.addRoom(room);										
				yPointer = current_layer.oRooms;
			}			
			
			// find it in the y array...
			if (yPointer.hasOwnProperty(y)) xPointer = yPointer[y];
			else {
				xPointer = new Object();
				yPointer[y] = xPointer;
			}

			// place it in the x array...
			xPointer[x] = room;
			
		}

	}
}