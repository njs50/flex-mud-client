package com.simian.profile {		
	
	import com.asfusion.mate.events.Dispatcher;
	import com.simian.telnet.TelnetSettings;
	import com.simian.window.WindowEvent;
	
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	
	import flexlib.mdi.containers.MDIWindow;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
		
	public class UserModel {

		// array of aliases						
		private var _aAlias : ArrayCollection;
		private var _aTrigger : ArrayCollection;
		private var _aWindowSettings	: Array;		
		private var _telnetSettings : TelnetSettings
		
		// local shared object data
		private var localData : SharedObject;
		
		private static const PROFILE_VERSION : String = "0.000005i";
		
		private var dispatcher : Dispatcher = new Dispatcher();

		
		// constructor (load data from shared objects here if they exist (init them if they don't)...)
		public function UserModel(){			
								
			_aAlias 	= new ArrayCollection();	
			_aTrigger 	= new ArrayCollection();				
				
			localData = SharedObject.getLocal('telnetData');
			
			// check the loaded profiles version is the same as this one
			if ( !( (localData.data.hasOwnProperty('profileVersion')) && (localData.data.profileVersion == PROFILE_VERSION) ) ){			   	
			   	localData.clear();
			   	trace('-- local profile cleared (failed version check)');			   	
			}
			
			// if the flash cookie is new lets initialise all the stuff we plan to store in it
			if (localData.size == 0) {
				localData.data.aAlias 			= new Array();
				localData.data.aTrigger 		= new Array();
				localData.data.aWindowSettings 	= new Array();
				localData.data.profileVersion 	= PROFILE_VERSION;
				localData.data.telnetSettings	= new TelnetSettings(); 				
			}
			
			_aAlias.source 		= localData.data.aAlias;			
			_aTrigger.source 	= localData.data.aTrigger;			
			_aWindowSettings 	= localData.data.aWindowSettings;
			_telnetSettings		= localData.data.telnetSettings;	
														
		}
		
		
		
		
		
		
		
		/* PUBLIC PROPERTIES - accessed via getters n setters and stored in a local flash cookie */
		
		[Bindable]		
		public function set aAlias(ac:ArrayCollection) : void {
			this._aAlias = ac;
			localData.data.aAlias = ac.source;
			writeProfile();			
		}
		
		public function get aAlias() : ArrayCollection {
			return this._aAlias
		}
		
		
		[Bindable]		
		public function set aTrigger(ac:ArrayCollection) : void {
			this._aTrigger = ac;
			localData.data.aTrigger = ac.source;
			writeProfile();			
		}
		
		public function get aTrigger() : ArrayCollection {
			return this._aTrigger
		}
		


		[Bindable]		
		public function set aWindowSettings(a:Array) : void {
			this._aWindowSettings = a;
			localData.data.aWindowSettings = a;
			writeProfile();			
		}
		
		public function get aWindowSettings() : Array {
			return this._aWindowSettings;
		}

		[Bindable]		
		public function set telnetSettings(ts:TelnetSettings) : void {
			this._telnetSettings = ts;
			localData.data.telnetSettings = ts;
			writeProfile();			
		}
		
		public function get telnetSettings() : TelnetSettings {
			return this._telnetSettings;
		}




		/* User profile public functions */



		
		
		
		
		public function storeWindowSettings(window:MDIWindow) : void {		
			var winSettings : MDIWindowSettings = new MDIWindowSettings();
			var index : int  = findSettingsIndex(window);			
			winSettings.getSettings(window);						
			if (index >= 0){
				aWindowSettings[index] = winSettings;				
			} else {
				aWindowSettings.push(winSettings);				
			}						
			writeProfile();
		}

	
		public function  restoreWindowSettings(window:MDIWindow) : void {			
		 	var windex : int  = findSettingsIndex(window);			
			if (windex >= 0){ 
				var ws : MDIWindowSettings = aWindowSettings[windex] as MDIWindowSettings;
				ws.applySettings(window);
			}
		}

		
		private function findSettingsIndex(window:MDIWindow) : int {									
			for (var i:int = 0; i < aWindowSettings.length; i++) {								
				if (window.name == aWindowSettings[i].name) return i;												
			}						
			return -1;
		}

		// write to the local shared object now (may prompt user to allow more storage)
		private function writeProfile() : void {						
			localData.flush();
		}
		
		
		


		public function toByteArray() : ByteArray {				
			var out : ByteArray = new ByteArray();
			out.writeObject(this);					
			return out;	
		}
		
		
		public function fromByteArray(baIn : ByteArray) : void {
			
			var configObj : Object = baIn.readObject();

        	// send event to close all windows
			var mdiEvent : WindowEvent = new WindowEvent(WindowEvent.CLOSE_WINDOWS);							
			dispatcher.dispatchEvent(mdiEvent);	  
						
        	if (configObj.hasOwnProperty('aWindowSettings') && configObj.aWindowSettings)
        		aWindowSettings = importArray(configObj.aWindowSettings,MDIWindowSettings);
        	
        	if (configObj.hasOwnProperty('aAlias') && configObj.aAlias)
        		aAlias 	= new ArrayCollection(importArray(configObj.aAlias.source,Alias));
        	
        	if (configObj.hasOwnProperty('aTrigger') && configObj.aTrigger)
        		aTrigger = new ArrayCollection(importArray(configObj.aTrigger.source,Trigger));
        	
        	if (configObj.hasOwnProperty('telnetSettings') && configObj.telnetSettings) {
        		telnetSettings = importObject(configObj.telnetSettings, TelnetSettings) as TelnetSettings;
        	}						

        	// send event to restore main telnet window (to loaded state)
			mdiEvent = new WindowEvent(WindowEvent.OPEN_TELNET_WINDOW);							
			dispatcher.dispatchEvent(mdiEvent);
			
		}
		

		
		
		// takes a generic object and a class definition and populates a new instance of that class 
		// with any properties that are in the generic object.
		// this is in case extra props are added so that old objects can be imported (new props will go to their default value) 
		public function importObject(oIn:Object,classIn:Class) : Object {			
			var oOut: Object = new classIn();
			var classDef : Object = ObjectUtil.getClassInfo(oOut);			
			for each (var propName : QName in classDef.properties){
				if (oIn.hasOwnProperty(propName.localName)) {
					oOut[propName.localName] = oIn[propName.localName];
				}					 
			}						
			return oOut;			
		}

		
		// imports an array or array collection into an array of the correct type
		// have to handle arrays of length 1 in the XML which don't show up as being an array at all		
		public function importArray(aIn:Array,classDef:Class) : Array {			
			var aOut : Array = new Array();	
			for each (var obj:Object in aIn) {				
				aOut.push(importObject(obj,classDef));				
			}						
			return aOut;
		}


	}
}