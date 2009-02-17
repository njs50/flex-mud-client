package com.simian.ansiTextArea
{
	public class AnsiTextMarkup
	{
		
		public var start_pos : int;		
		public var fg_colour : uint;		
		public var bg_colour : uint;		
		
		public function AnsiTextMarkup(start:int, fg_col : uint, bg_col : uint)
		{
			start_pos = start;			
			bg_colour = bg_col;
			fg_colour = fg_col;
			
		}

	}
}