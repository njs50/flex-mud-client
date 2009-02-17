package com.simian.ansiTextArea
{

	import flash.display.Sprite;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.core.ScrollControlBase;
	import mx.core.ScrollPolicy;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDirection;

	public class AnsiTextArea extends ScrollControlBase
	{		

		public var defaultFGcolour : int;					
		public var defaultBGcolour : int;				
		
		public var acColoursDark : ArrayCollection;
		public var acColoursLight : ArrayCollection;
		
		
		public var maxScrollback : int = 10000;

		public var bScrollingMode : Boolean = false;			

		
		private var contentContainer : Sprite;		
		private var aAnsiRows : Array = new Array(); 		
		private var rowHeight : int = 0;		
		
		private var firstRendered : int = -1;
		private var lastRendered : int = -1;
		
		private var lastRow : AnsiTextRow;
		
		private var visibleRows : int = 0;

		 

		public function AnsiTextArea()
		{
			this.horizontalScrollPolicy = ScrollPolicy.AUTO;
			this.verticalScrollPolicy = ScrollPolicy.AUTO;
			this.liveScrolling = false;
		}
		
        override protected function createChildren():void{
            
            super.createChildren();
            
            contentContainer = new Sprite();
            addChild(contentContainer);
            contentContainer.mask = this.maskShape;

			this.addEventListener(ScrollEvent.SCROLL, onScroll);
            
            this.addEventListener(Event.RESIZE, resizeHandler);
            
        }		
        
        private function resizeHandler(event:Event) : void{
			updateVisibleRows();
			updateAndScroll();        	
        }

		private function updateVisibleRows() : void{
			if (rowHeight == 0) visibleRows = 0;
			else {
				// stinky scroll bars getting in the way when we calculate the visible area
				if (this.horizontalScrollBar) {
					visibleRows = (this.height - this.horizontalScrollBar.height) / rowHeight;
				} else visibleRows = this.height / rowHeight;
			} 			
		}
		
		private function updateAndScroll() : void{

			bScrollingMode = false;

			// update visible rows if not yet set
			if (visibleRows == 0) updateVisibleRows();

			// set scroll bar sizes
			this.setScrollBarProperties(contentContainer.width,this.width,aAnsiRows.length, visibleRows);									
			
			// set scroll bar position to be the end of the bar
			this.verticalScrollPosition = this.maxVerticalScrollPosition;
			
			// invalidate display list to force update of scroll bars
			this.invalidateDisplayList();
			
			// send scroll event to scroll to the end		
			dispatchEvent(new ScrollEvent(ScrollEvent.SCROLL,false,false,null,this.verticalScrollPosition,"vertical",firstRendered - this.verticalScrollPosition));			
			
		}
        

        private function onScroll(event:ScrollEvent):void{
            if(event.direction==ScrollEventDirection.VERTICAL){
                
                // check they arn't moving out of bounds and correct (past start)
                if (event.position < 0){
                	event.position = 0;
                	this.verticalScrollPosition = event.position;
                }  
                
                // check they arn't moving out of bounds and correct (past end)
                if (event.position >= aAnsiRows.length - visibleRows) {
                	event.position = aAnsiRows.length - visibleRows;
                	this.verticalScrollPosition = event.position;
                }
                
                // move it                
				this.contentContainer.y = -1 * event.position * rowHeight;
                
                // put something in for them to see (if it isn't already there                
				updateContent();
                
            }
            
            // regular horizontal scrolling
            else{
                this.contentContainer.x=-event.position;
                if(contentContainer.x+contentContainer.width<this.width){
                    contentContainer.x += this.width-(contentContainer.x+contentContainer.width)
                }
                if(contentContainer.x>0){
                    contentContainer.x=0;
                }
            }
            
           // trace('position: ' + event.position + ' y: ' + contentContainer.y);
        }		

		// adds display objects back to the content container depending on how close they are to the visible range
		private function updateContent() : void {
			
			// keep 5 pages behind rendered
			var new_first : int = this.verticalScrollPosition - (visibleRows * 5);			
			if (new_first < 0) new_first = 0; 
			
			// keep a page ahead rendered
			var new_last : int = this.verticalScrollPosition + (visibleRows * 2);
			
			if (new_last >= aAnsiRows.length) new_last = aAnsiRows.length - 1; 
			
			
			var i:int = 0;
			
			// remove things not needed							
			for (i = firstRendered; i <= lastRendered; i++){
				if (i != -1) {							
					if ( i < new_first || i > new_last ) {
						contentContainer.removeChild(aAnsiRows[i]);						
					//	trace('removing: ' + i );
					} 
				}				
			} 									
			
			// add things missing
			for (i = new_first; i <= new_last; i++){
				// if i isn't in the old render range add the object back				
				if ( i < firstRendered || i > lastRendered ){
				 	contentContainer.addChild(aAnsiRows[i]);
				 	// .y = rowHeight * i;				 						
					//	trace('adding: ' + i );				
				}
			} 									

			 //trace('range change: ['+ firstRendered + ',' + lastRendered +'] -> {' + new_first + ',' + new_last + '}');
			
			// update the render range			
			firstRendered = new_first;
			lastRendered = new_last;							
			 		
		}


		public function addDisplayObject(child:AnsiTextRow) : AnsiTextRow {
			
			// if this is the first row use it as a baseline for row height (font must be fixed size!)
			if (rowHeight == 0){ 
				rowHeight = child.height;					
			}
									
			child.y = rowHeight * aAnsiRows.length;			
						
			aAnsiRows.push(child);			
						
			updateAndScroll();
			
			return(child); 
			
		}
		


		private function removeRows(amount:int) : void {
			
			if (amount >= aAnsiRows.length) amount = aAnsiRows.length -1;
			
			var newRows : Array = aAnsiRows.slice(amount,aAnsiRows.length);

			var i: int								
			for (i = contentContainer.numChildren; i > 0; i--) contentContainer.removeChildAt(0);
			for (i = 0; i < amount; i++) aAnsiRows[i] = null;
						
			aAnsiRows = newRows;
			
			for (i = aAnsiRows.length -1; i >= 0 ;i--) aAnsiRows[i].y = rowHeight * i;
			
			firstRendered 	= -1;
			lastRendered 	= -1;						
			
			updateAndScroll();			
			
		}

		
		public function resetTextArea() : void {
			
			var newRow: AnsiTextRow;
			
			var i: int								
			for (i = contentContainer.numChildren; i > 0; i--) contentContainer.removeChildAt(0);
			for (i = 0; i < aAnsiRows.length; i++) aAnsiRows[i] = null;			
			aAnsiRows = new Array();
			
			firstRendered 	= -1;
			lastRendered 	= -1;

			newRow = new AnsiTextRow(defaultFGcolour,defaultBGcolour, [acColoursLight.source,acColoursDark.source]);
			newRow.text = '[Terminal Reset]';						
			addDisplayObject(newRow);						
			lastRow = newRow;	
			
		}
		
		
		// 
		public function resetScrolling() : void {
			if (bScrollingMode) updateAndScroll();
		}
		
		// send a scroll event for one page of upness
		public function pageUp() : void {			
			bScrollingMode = true;
			this.verticalScrollPosition = this.verticalScrollPosition - visibleRows
			dispatchEvent(new ScrollEvent(ScrollEvent.SCROLL,false,false,null,this.verticalScrollPosition,"vertical",firstRendered - this.verticalScrollPosition));			
		}
		
		// send a scroll event for one page of downness
		public function pageDown() : void {
			bScrollingMode = true;
			this.verticalScrollPosition = this.verticalScrollPosition + visibleRows
			dispatchEvent(new ScrollEvent(ScrollEvent.SCROLL,false,false,null,this.verticalScrollPosition,"vertical",firstRendered - this.verticalScrollPosition));			
		}
		
		public function addRow(str:String) : void {		
			
			var newRow: AnsiTextRow;
			if (lastRow) {
				newRow = new AnsiTextRow(defaultFGcolour,defaultBGcolour, [acColoursLight.source,acColoursDark.source],lastRow.fg_colour,lastRow.bg_colour);							
			} 
			else {
				newRow = new AnsiTextRow(defaultFGcolour,defaultBGcolour, [acColoursLight.source,acColoursDark.source]);				
			}
			
			newRow.text = str;						
			addDisplayObject(newRow);			
			
			lastRow = newRow;
			
			// check total length..			
			if (aAnsiRows.length > maxScrollback * 1.1){
				removeRows(maxScrollback * .1);			
			}
			
			
			
		}
		
		public function updateLastRow(str:String) : void {			
			lastRow.text += str;			
		}
		

	}
}