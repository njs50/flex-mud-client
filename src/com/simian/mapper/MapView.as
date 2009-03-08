package com.simian.mapper
{

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.core.ScrollControlBase;
	import mx.core.ScrollPolicy;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDirection;

	public class MapView extends ScrollControlBase
	{		
 
		private var map : Map; 		
		private var mapSprite : Sprite;		
		private var current_layer_sprite : Sprite;	 

		
		public var current_room : Room;

		public var last_room : Room;


		public function MapView()
		{
			this.horizontalScrollPolicy = ScrollPolicy.AUTO;
			this.verticalScrollPolicy = ScrollPolicy.AUTO;
			this.liveScrolling = false;			
		}
		
        override protected function createChildren():void{
            
            super.createChildren();
            
            mapSprite = new Sprite();
            addChild(mapSprite);    
            mapSprite.mask = this.maskShape;
                    
		 	this.addEventListener(ScrollEvent.SCROLL, onScroll);   		 	         
         	this.addEventListener(Event.RESIZE, resizeHandler);
            
        }		

		
		private function get internal_height() : int {			
			if (this.horizontalScrollBar) {
				return (this.height - this.horizontalScrollBar.height);
			} 			
			return this.height			
		}

		private function get internal_width() : int {			
			if (this.verticalScrollBar) {
				return (this.width - this.verticalScrollBar.width);
			} 			
			return this.width			
		}



		public function changeRoom() : void {		
			
			// don't do anything if we dont have at least one room
			if (current_room != null) {				
				
				var bChangeSprite : Boolean = false;

				// make sure we are still on the right map, if we've changed then update the layer
				if (map != current_room.oMap) {
					map = current_room.oMap;
					bChangeSprite = true;	
				}
				
				// if the layer has changed update the layer
				if (last_room != null) {			
					if (current_room.room_z != last_room.room_z) bChangeSprite = true;				
				} else bChangeSprite = true;
								
			
				// if it's time to change our map layer sprite...
				if (bChangeSprite) {
					if (current_layer_sprite != null) mapSprite.removeChild(current_layer_sprite);													
					current_layer_sprite = current_room.oMap.oRooms[current_room.room_z].mapSprite
					mapSprite.addChild(current_layer_sprite);						
				}

				// center the map (if required)
				centerMap();	
				
				// update the last room ref			
				last_room = current_room;
			
			}			
			
			
									
		}


        private function resizeHandler(event:Event) : void{			
			if (current_layer_sprite != null && current_room != null) centerMap();       	
        }


        private function onScroll(event:ScrollEvent):void{
        	
        	var mapRect : Rectangle = mapSprite.getBounds(this.mapSprite);
        	
        	// need to readjust position if mapRect.x and y is no longer at (0,0)
        	
            if(event.direction==ScrollEventDirection.VERTICAL){                
                this.mapSprite.y = (this.maxVerticalScrollPosition - event.position) - mapRect.height - mapRect.y;                
            }
            
            // regular horizontal scrolling
            else{
                this.mapSprite.x = (this.maxHorizontalScrollPosition - event.position) - mapRect.width - mapRect.x;
            }                       
                       
        }		

		
		private function resizeScrollBars() : void {
			
			// figure out the boundaries/position of the sprite
			var mapRect : Rectangle = mapSprite.getBounds(this.mapSprite);

			// set scroll bar sizes
			
			// so total width of the scroll bars is the width of the big sprite + one visible screen on each end.
			// this allows the map to be just off the screen. 
			this.setScrollBarProperties(mapRect.width + (this.internal_width * 2), this.internal_width , mapRect.height + (this.internal_height * 2), this.internal_height);

			// set scroll positions			
			
			this.horizontalScrollPosition 	= this.maxHorizontalScrollPosition - mapRect.width - mapRect.x - this.mapSprite.x; 			
			this.verticalScrollPosition 	= this.maxVerticalScrollPosition - mapRect.height - mapRect.y - this.mapSprite.y;			
			
			// invalidate display list to force update of scroll bars
			this.invalidateDisplayList();
			
			
		}
		
		// centers the map on the current room
		// only reposition if we have moved outside of the middle of the screen	
		private function centerMap() : void {
			
			// check that we have actually loaded a map, if not load the current one
			if (current_layer_sprite == null) changeRoom();
			
			// calc our current x and y relative to the sprites position
			var current_x : int = mapSprite.x + current_room.x;
			var current_y : int = mapSprite.y + current_room.y;
			
			// if we are outside the middle half of the screen reposition that axis		
			if(	current_x < (this.internal_width * 0.25) || current_x > (this.internal_width * 0.75) ) mapSprite.x = (this.internal_width / 2) - current_room.x;
			if(	current_y < (this.internal_height * 0.25) || current_y > (this.internal_height * 0.75) ) mapSprite.y = (this.internal_height / 2) - current_room.y ;						  
			
			resizeScrollBars();
					
		}

		


	}
}