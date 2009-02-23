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
 
		private var _map : Map; 		
		private var mapSprite : Sprite;		
		private var current_layer : Sprite;	 

		[Bindable]
		public var current_room : Room;


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
        
		
		public function set map (oMap:Map) : void {			
			_map = oMap			
			changeLayer();
		}

		public function get map () : Map {
			return _map;
		}


		public function changeLayer() : void {
			if (_map.current_layer != null) {			
				if (current_layer != null) mapSprite.removeChild(current_layer);								
				current_layer = _map.current_layer.mapSprite
				mapSprite.addChild(current_layer);	
			}
		}


		public function changeRoom() : void {			
			centerMap();			
		}


        private function resizeHandler(event:Event) : void{			
			if (current_layer != null && current_room != null) centerMap();       	
        }


        private function onScroll(event:ScrollEvent):void{
            if(event.direction==ScrollEventDirection.VERTICAL){
                
                this.mapSprite.y=-event.position;
                if(mapSprite.y+mapSprite.height<this.height){
                    mapSprite.y += this.width-(mapSprite.y+mapSprite.height)
                }
                if(mapSprite.y>0){
                    mapSprite.y=0;
                }
                
            }
            
            // regular horizontal scrolling
            else{
                this.mapSprite.x=-event.position;
                if(mapSprite.x+mapSprite.width<this.width){
                    mapSprite.x += this.width-(mapSprite.x+mapSprite.width)
                }
                if(mapSprite.x>0){
                    mapSprite.x=0;
                }
            }
                       
        }		

		
		private function resizeScrollBars() : void {
			
			var mapRect : Rectangle = mapSprite.getBounds(current_layer);
			
			// set scroll bar sizes
			// rabies : this needs a bunch of work (or maybe the scrolling code does).
			this.setScrollBarProperties(mapRect.width + (this.width / 2),this.width,mapRect.height + (this.height/2), this.height);									
			
			// potentially only 1/4 of the sprite is showing. i.e if you head all SE from exlpored land.
			
			// set scroll bar positions
			
			// this.verticalScrollPosition = 
			// this.horizontalScrollPosition =
			
			// invalidate display list to force update of scroll bars
			this.invalidateDisplayList();
			
			
		}
		
		// centers the map on the current room
		private function centerMap() : void {
			
			current_layer.x = (this.width / 2) - current_room.x;
			current_layer.y = (this.height / 2) - current_room.y ;						  
			
			resizeScrollBars();
					
		}

		


	}
}