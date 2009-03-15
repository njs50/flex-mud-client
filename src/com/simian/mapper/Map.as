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


		

		public function find(oRoom : Room) : Room {
			// loop through all rooms in this map and look for a match
			if (oRoom != null) {
				for each (var zLayer : Object in oRooms ) {			
					for each (var yLayer : Object in zLayer.oRooms) {					
						for each (var testRoom : Room in yLayer) {						
							if (oRoom != testRoom && oRoom.match_room(testRoom)) return testRoom;						
						}					
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

			// place it in the x array...
			xPointer[x] = room;
			
		}

	}
}