// ActionScript file
package com.simian.ansiTextArea

 {
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;



    public class AnsiTextRow extends Sprite {
    	
	   	[Embed(source="/assets/profontwin/ProFontWindows.ttf", fontFamily="profont", advancedAntiAliasing=false, fontWeight= "normal", fontStyle = "normal", mimeType="application/x-font-truetype")]    	
	   	private var Profont:Class;    	
    	    	    	
    	private var _ansiText : String;

		private static const ESC:int = 0x1B; //escape character
		
				
		public var aColourMap : Array;
		
		
		private var defaultFGcolour : int;		
		private var defaultBGcolour : int;

		public	var bg_colour : int;
		public	var fg_colour : int;

        public function AnsiTextRow(
        		_defaultFGcolour:int = 0 , 
        		_defaultBGcolour:int = 7, 
        		_aColourMap:Array = null,
        		lastFGcolour : int = -1,
        		lastBGcolour : int = -1
        		) {

	  		// default colour map
			// ansi colours in rgb format. 
			// [0] = normal : black,red,green,yellow,blue,magenta,cyan,white 
			// [1] = bright : black,red,green,yellow,blue,magenta,cyan,white				  		
	  		
	  		if (!_aColourMap) _aColourMap = [ [0x000000,0x800000,0x008000,0x808000,0x000080,0x800080,0x008080,0xc0c0c0],
	  										  [0x808080,0xff0000,0x00ff00,0xffff00,0x0000ff,0xff00ff,0x00ffff,0xffffff] ];
	  		
			defaultFGcolour = _defaultFGcolour;
	  		defaultBGcolour	= _defaultBGcolour;		
	  		
	  		if (lastFGcolour == -1 && lastBGcolour == -1) {
				bg_colour = defaultBGcolour;
				fg_colour = defaultFGcolour;
					  			
	  		} else {
				bg_colour = lastBGcolour;
				fg_colour = lastFGcolour;	  			
	  		}
	  		
	  		aColourMap = _aColourMap;
			
			this.cacheAsBitmap = true;
			
        }

		public function colourFromCode(colNum:int, bright:int = 0) : int{
			return aColourMap[bright][colNum];
		}

		public function set text(str:String) : void {
			_ansiText = str;									
			renderText(str);			
		}
				
		
		public function get text() : String {
			return _ansiText;
		}
		
		
		private function purgeChildren() : void {

			// remove any current child display objects						
			var i:int = this.numChildren;
			while( i -- )
			{
			    this.removeChildAt( i );
			}									
			
		}
		
		private function renderText(str:String) : void {

			// buffer for individual blocks of text
			var buffer : String = '';			
			// buffer for escape sequences						
			var escape_buffer : String = '';
			// buffer for final output
			var output_buffer : String = '';
			// array of markup for this row
			var aMarkup : Array = new Array();						
			
			var new_bg_colour : int = -1;
			var new_fg_colour : int = -1;
			
			var colour_table : int = 0; 
			 
			var state : uint = 1; // 1 = read. 2 = processing escape. 
			
			var bAddMarkup : Boolean = false;

			
			// add default markup to start of markup array
			aMarkup.push( new AnsiTextMarkup(0, fg_colour, bg_colour) );
			

			// remove any children already being displayed.
			purgeChildren();
			 
			 
			// loop over each char in the new string. we are going to parse this fucker in one run 
			// if we wanted to make it even gooder we'd only add a new block on a background colour change
			// and use textFormat to change FG colours. but i'm too lazy for that atm, new colour = new block atm.
			for (var i : int = 0;i < str.length;i++) {
								
				switch (state) {
					
					case 1:
						// if it's the command character go into escape mode
						if ( str.charCodeAt(i) == ESC) state = 2; 							
						else buffer += str.charAt(i);
					
						break;
					
					case 2:
						
						// if it's the end command character it's time to do some processing					
						if (str.charCodeAt(i) == 91) break; // [ = skip it 
						else if (str.charCodeAt(i) != 109) escape_buffer += str.charAt(i);
						else {
							// Time for fun!!!														
							
							var fg_code : int = -1;
							var bg_code : int = -1;
							var col_reverse : Boolean = false;
							
							for each (var subStr : String in escape_buffer.split(';')) {
								
								var ansiCode : int = parseInt(subStr);
																
								// reset code
								if ( ansiCode == 0 ) {
									new_bg_colour = defaultBGcolour;
									new_fg_colour = defaultFGcolour;
									colour_table = 0;
								}
								
								// bight intensity
								if ( ansiCode == 1) colour_table = 1;
								
								// normal or feint intensity
								if ( ansiCode == 2 || ansiCode == 22) colour_table = 0;
								
								// underline
								//if ( ansiCode == 4)
								
								// reverse colours
								if ( ansiCode == 7) col_reverse = true;
								
								// FG color change
								if ( ansiCode <= 37 && ansiCode >= 30) fg_code = parseInt(subStr.charAt(1));
								 
								// BG color change 
								if ( ansiCode <= 47 && ansiCode >= 40) bg_code =parseInt(subStr.charAt(1));
																
							}
							
							if (fg_code != -1) new_fg_colour = colourFromCode(fg_code,colour_table);
							if (bg_code != -1) new_bg_colour = colourFromCode(bg_code,colour_table);																
							
							// if they want em reversed do the ol switcheroo							
							if (col_reverse == true) {
								
								var temp_colour : int;
								
								if (new_fg_colour != -1) temp_colour = new_fg_colour;
								else temp_colour = fg_colour;
																
								if (new_bg_colour != -1) new_fg_colour = new_bg_colour; 
								else new_fg_colour = bg_colour;
																
								new_bg_colour = temp_colour;
							}
														
							escape_buffer = "";
							bAddMarkup = true;
							state = 1;
						}
						break;
					
				}
				
				// if it's time to add this buffer to the display
				if (bAddMarkup || (i == str.length - 1)) {
					
						
					aMarkup.push( new AnsiTextMarkup(output_buffer.length, fg_colour, bg_colour) );
						
					// needs to be something in the buffer :p
					if ( buffer.length ) {
						output_buffer += buffer;
						buffer = '';
					}
					
					// update bg colour if it's changed
					if (new_bg_colour != -1) { bg_colour = new_bg_colour; new_bg_colour = -1 }					
					// update fg colour if it's changed
					if (new_fg_colour != -1) { fg_colour = new_fg_colour; new_fg_colour = -1 }
							
					bAddMarkup = false; 
					
					
				}
				
				// if this is the end of the string, add the row
				if (i == str.length - 1) { 
					var newBlock : TextField = newTF(output_buffer);
					applyMarkup(newBlock,aMarkup);
				}
				
			}
					
		}		
		

		private function applyMarkup(text:TextField, aMarkup : Array) : void {
			
			// foreground colours.
			var start_pos_fg : uint = 0;
			var start_pos_bg : uint = 0;
			var current_fg_colour : uint = aMarkup[0].fg_colour;
			var current_bg_colour : uint = aMarkup[0].bg_colour;
			
			// FYI setTextFormat formats from start pos to end pos - 1. retarded if you ask me.
						
			for each (var markup : AnsiTextMarkup in aMarkup) {								
				// if FG colour has changed then we need to colour everything before this point
				// if we have markup at the current point, then override the current markup and continue
				// this is most likely if there are multiple markups in a row
				if (markup.fg_colour != current_fg_colour && markup.start_pos > start_pos_fg) {
					fgColorChange(text, start_pos_fg, markup.start_pos, current_fg_colour);
					start_pos_fg = markup.start_pos;
					current_fg_colour = markup.fg_colour;
				} else if (markup.start_pos == start_pos_fg)current_fg_colour = markup.fg_colour; 
				
				// if BG colour has changed then we need to colour everything before this point
				if (markup.bg_colour != current_bg_colour && markup.start_pos > start_pos_bg) {
					bgColorChange(text, start_pos_bg, markup.start_pos , current_bg_colour);
					start_pos_bg = markup.start_pos;
					current_bg_colour = markup.bg_colour;
				} else if (markup.start_pos == start_pos_bg) current_bg_colour = markup.bg_colour; 
													
			}			
			// apply to whatever is left (if anything remains)
			if (start_pos_fg < text.length) fgColorChange(text, start_pos_fg, text.length, current_fg_colour);			
			if (start_pos_bg < text.length) bgColorChange(text, start_pos_bg, text.length, current_bg_colour);
			
			
		} 

		
		private function fgColorChange(text:TextField, start:int, end:int, fgCol : uint) : void {
			
			var format:TextFormat = new TextFormat();
			format.color = fgCol;			
			text.setTextFormat(format,start,end);						
			// text.appendText('[' + start.toString() + '|' + fgCol.toString() + '|' + end.toString() + ']');
		}

		private function bgColorChange(text:TextField, start:int, end:int, bgCol : uint) : void {
						
			if (bgCol != text.backgroundColor) {			
				var first:Rectangle = text.getCharBoundaries(start);
				var last:Rectangle = text.getCharBoundaries(end - 1);
				
				var background:Shape = new Shape();
				background.graphics.clear();    
	            background.graphics.beginFill(bgCol,1);
	            background.graphics.drawRect((first.x), (first.y), (last.x - first.x + last.width), first.height);            
	            background.graphics.endFill();	            
	            addChild(background);	
	            this.setChildIndex(background, 0);	            
   			}	
		}



        private function newTF(str:String): TextField {

            var tf : TextField = new TextField();
            
            tf.embedFonts = true;
            tf.background = false;                   
            tf.border = false;                                   
            tf.antiAliasType = AntiAliasType.ADVANCED;
            tf.sharpness = -100;
            tf.thickness = -100;
                        

            var format:TextFormat = new TextFormat();
            format.font = "profont";            
            format.size = 16;             
            format.leftMargin = 10;
            format.rightMargin = 10;
            format.kerning = 0;
            format.leading = 0;
            
            tf.defaultTextFormat = format;
            tf.text = str;
            
            //tf.autoSize = TextFieldAutoSize.LEFT;            
            tf.autoSize = TextFieldAutoSize.NONE;            
            tf.height = tf.textHeight; // + 2;
            tf.width = tf.textWidth + 20;
            
            addChild(tf);
            
            return tf;
            
        }
        
        
    }
}