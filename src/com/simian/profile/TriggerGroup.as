package com.simian.profile
{
	
	[RemoteClass(alias="com.simian.profile.TriggerGroup")]		
	public class TriggerGroup
	{
		public var name : String;			
		
		public function TriggerGroup(_name:String = '')
		{
			this.name	= _name;
		
		}
		
		public function toString() : String {	
			if (this.name.length == 0) return '[mystery group]'; 		
			return this.name;			
		}

	}
}