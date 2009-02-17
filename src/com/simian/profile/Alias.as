package com.simian.profile
{
	
	[RemoteClass(alias="com.simian.profile.Alias")]		
	public class Alias
	{
		
		public var trigger : String; 		
		public var command : String;						
		
		public function Alias(_trigger:String = '',_command:String = '')
		{
			trigger = _trigger;
			command = _command;
		}

	}
}