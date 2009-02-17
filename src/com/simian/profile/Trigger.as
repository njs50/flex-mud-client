package com.simian.profile
{
	
	[RemoteClass(alias="com.simian.profile.Trigger")]		
	public class Trigger
	{
		public var name : String;
		public var trigger : String; 		
		public var command : String;		
		public var parse_type : int;
		public var bEnabled : Boolean;				
		
		public function Trigger(_name:String = '', _trigger:String = '',_command:String = '', _parse_type : int = 1, _bEnabled : Boolean = true)
		{
			this.name	= _name;
			this.trigger = _trigger;
			this.command = _command;
			this.parse_type = _parse_type;
			this.bEnabled = _bEnabled;
		}
		
		public function toString() : String {			
			return this.name;			
		}

	}
}