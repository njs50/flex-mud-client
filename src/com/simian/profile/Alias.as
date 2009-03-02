package com.simian.profile
{
	
	[RemoteClass(alias="com.simian.profile.Alias")]		
	public class Alias
	{
		
		public var trigger : String; 		
		public var command : String;						
		public var bEnabled : Boolean;	
		public var triggerGroup : TriggerGroup;			

		
		public function Alias(_trigger:String = '',_command:String = '', _bEnabled : Boolean = true, _group : TriggerGroup = null)
		{
			this.trigger = _trigger;
			this.command = _command;
			this.bEnabled = _bEnabled;
			this.triggerGroup = _group;
		}

		public function toString() : String {	
			if (this.trigger.length == 0) return '[mystery alias]';	
			return this.trigger;			
		}


	}
}