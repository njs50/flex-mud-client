package com.simian.main {
	
	import com.asfusion.mate.events.Dispatcher;
	import com.simian.profile.ProfileEvent;
	import com.simian.telnet.*;
	import com.simian.window.*;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	public class MainModel{		

		private var _telnet : Telnet;		
		
		private var _telnetWindow : TelnetWindow;
		private var _aliasWindow : AliasEditor;
		private var _triggerWindow : TriggerEditor;
		private var _settingsWindow : TelnetSettingsWindow;				
		private var _mapperWindow : MapperWindow;				
		
		private var fileReference : FileReference; 
		
		private var dispatcher : Dispatcher = new Dispatcher();
		
		[Bindable]
		public var _title : String = 'Connect Me!';				
		

		
		public function MainModel(){
			_telnet 		= new Telnet();	
		
			// windows
			_telnetWindow 	= new TelnetWindow();
			_aliasWindow 	= new AliasEditor();
			_triggerWindow 	= new TriggerEditor();
			_settingsWindow = new TelnetSettingsWindow();
			_mapperWindow	= new MapperWindow();
			
			// loading and saving profiles to local files
			fileReference 	= new FileReference();
			
		}								

		public function getAliasWindow() : AliasEditor {
			return _aliasWindow;
		}

		public function getMapperWindow() : MapperWindow {
			return _mapperWindow;
		}

		public function getTriggerWindow() : TriggerEditor {
			return _triggerWindow;
		}			

		public function getTelnetWindow() : TelnetWindow {
			return _telnetWindow;
		}

		public function getTelnetSettingsWindow() : TelnetSettingsWindow {
			return _settingsWindow;
		}		
		
		public function connect(address:String, port:int) : void{
			if (!address.length) address = ExternalInterface.call("window.location.hostname.toString");									
			_telnet.connect(address,port);
		}
		
		public function disconnect() : void{					
			_telnet.disconnect();
		}		
		
		public function changeTitle(title:String) : void {
			_title = title;
		}
		
		public function sendCommand(str:String) : void {
			_telnet.sendCommand(str);
		}		

		public function sendTriggerCommand(str:String) : void {																	
			if (str != '') _telnet.sendTriggerCommand(str);
		}
		
		public function saveProfile(serialProfile: ByteArray ) : void {
			fileReference.save(serialProfile,'telnet_profile.mud');
		}

		
		public function loadProfile() : void{
			fileReference.addEventListener(Event.SELECT, function(e:Event) : void { 
				fileReference.load();
			}); 
			
			fileReference.addEventListener(Event.COMPLETE, function(e:Event) : void { 				
				loadProfile_action( fileReference.data ); 
			});
			
			fileReference.addEventListener(Event.CANCEL, function(e:Event) : void { 				
				fileReference = new FileReference();				
			 });
			
			fileReference.browse();
		}
		
		public function loadProfile_action(data : ByteArray ) : void{			

			var mdiEvent : ProfileEvent = new ProfileEvent(ProfileEvent.LOAD_PROFILE_DATA);							
			mdiEvent.data = data;
			dispatcher.dispatchEvent(mdiEvent);	
			
			fileReference = new FileReference();				
		}		

	}
}