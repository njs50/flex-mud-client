package com.simian.mapper
{
	
	[RemoteClass(alias="com.simian.mapper.Map")]		
	public class Map
	{		
		
		public var oRooms : Object;
		
		[Bindable]
		public var map_name : String;
		
		[Bindable]
		public var current_layer : MapLayer;
		
		public function Map(_name:String = '')
		{
			oRooms = new Object();
			map_name = _name;				
		}



		public function getRoom(i_x:int,i_y:int,i_z:int) : Room {
			
			var x : String = i_x.toString();
			var y : String = i_y.toString();
			var z : String = i_z.toString();
			
			var yPointer : Object;
			var xPointer : Object;
			var room : Room;
			
			// find it in the z array...
			if (oRooms.hasOwnProperty(z)){
				yPointer = oRooms[z].oRooms;				
			} 
			else {				
				current_layer = new MapLayer();
				oRooms[z] = current_layer					
				current_layer.setActiveLayer();	
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
			
			var yPointer : Object;
			var xPointer : Object;			
			
			// find it in the z array...
			if (oRooms.hasOwnProperty(z)){
				yPointer = oRooms[z].oRooms;
				current_layer.addRoom(room);
			} 
			else {				
				current_layer = new MapLayer();
				oRooms[z] = current_layer
				// rabies : we shouldn't be doing this stuff here. temp for testing. layer changes/management should be done elsewhere
				current_layer.addRoom(room);						
				current_layer.setActiveLayer();	
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