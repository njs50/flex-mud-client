package com.simian.profile {		
	
	import com.asfusion.mate.events.Dispatcher;
	import com.simian.mapper.Map;
	import com.simian.telnet.TelnetSettings;
	import com.simian.window.WindowEvent;
	
	import flash.net.SharedObject;
	import flash.net.getClassByAlias;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	import flexlib.mdi.containers.MDIWindow;
	
	import mx.collections.ArrayCollection;
	
		
	public class UserModel {

		// array of aliases						
		private var _aAlias : ArrayCollection;
		private var _aTrigger : ArrayCollection;
		private var _aTriggerGroup : ArrayCollection;
		private var _aWindowSettings	: Array;		
		private var _telnetSettings : TelnetSettings
				
		private var _aMaps : Array;
		
		// local shared object data
		private var localData : SharedObject;
		
		private static const PROFILE_VERSION : String = "0.000006m";
		
		private var dispatcher : Dispatcher = new Dispatcher();

		
		// constructor (load data from shared objects here if they exist (init them if they don't)...)
		public function UserModel(){			
			
			_aAlias 	= new ArrayCollection();	
			_aTrigger 	= new ArrayCollection();				
			_aTriggerGroup 	= new ArrayCollection();
				
			localData = SharedObject.getLocal('telnetData');
			
			// check the loaded profiles version is the same as this one
			if ( !( (localData.data.hasOwnProperty('profileVersion')) && (localData.data.profileVersion == PROFILE_VERSION) ) ){			   	
			   	localData.clear();
			   	trace('-- local profile cleared (failed version check)');			   	
			}
			
			// if the flash cookie is new lets initialise all the stuff we plan to store in it
			if (localData.size == 0) {
				localData.data.aAlias 			= new Array();
				localData.data.aMaps 			= new Array();				
				localData.data.aTrigger 		= new Array();
				localData.data.aTriggerGroup	= new Array();				
				localData.data.aWindowSettings 	= new Array();
				localData.data.profileVersion 	= PROFILE_VERSION;
				localData.data.telnetSettings	= new TelnetSettings(); 				
			}
			
			aMaps				= localData.data.aMaps;
			_aAlias.source 			= localData.data.aAlias;			
			_aTrigger.source 		= localData.data.aTrigger;
			_aTriggerGroup.source 	= localData.data.aTriggerGroup;			
			_aWindowSettings 		= localData.data.aWindowSettings;
			_telnetSettings			= localData.data.telnetSettings;	
		
			// remove any redundant trigger groups
			removeEmptyGroups();
														
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
		public function set aTriggerGroup(ac:ArrayCollection) : void {
			this._aTriggerGroup = ac;
			localData.data.aTriggerGroup = ac.source;
			writeProfile();			
		}
		
		public function get aTriggerGroup() : ArrayCollection {
  			if (this._aTriggerGroup.length == 0 || !this._aTriggerGroup.getItemAt(0).hasOwnProperty('data') ) {	  			
  				this._aTriggerGroup.addItemAt({name:"No Group", data:null},0);
  			}
			return this._aTriggerGroup;
		}
		
		[Bindable]		
		public function set aMaps(a:Array) : void {
			this._aMaps = a;
			localData.data.aMaps = a;
			writeProfile();			
		}
		
		public function get aMaps() : Array {
			return this._aMaps;
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

			// this dictionary will be used to match old objects pointers to new ones 
			// as we are going to recreate all objects (in case of schema evolution).			
			var objectLookup : Dictionary = new Dictionary();
			// we are going to queue up the import of any embedded objects to prevent
			// infinite loops of badness when a child obj is linked to a parent
			var aDelayedImportQueue : Array = new Array();

        	// send event to close all windows
			var mdiEvent : WindowEvent = new WindowEvent(WindowEvent.CLOSE_WINDOWS);							
			dispatcher.dispatchEvent(mdiEvent);	  

        	if (configObj.hasOwnProperty('aTriggerGroup') && configObj.aTriggerGroup) {      
        		// if (configObj.aTriggerGroup.length > 0 && configObj.aTriggerGroup.getItemAt(0).hasOwnProperty('data') ) 
        		configObj.aTriggerGroup.removeItemAt(0);  		        		     		
        		this.aTriggerGroup.source = importArray(configObj.aTriggerGroup.source,TriggerGroup,objectLookup,aDelayedImportQueue);        		        		        		
        	}

        	if (configObj.hasOwnProperty('aMaps') && configObj.aMaps)
        		aMaps = importArray(configObj.aMaps,Map,objectLookup,aDelayedImportQueue);        	
						
        	if (configObj.hasOwnProperty('aWindowSettings') && configObj.aWindowSettings)
        		aWindowSettings = importArray(configObj.aWindowSettings,MDIWindowSettings,objectLookup,aDelayedImportQueue);
        	
        	if (configObj.hasOwnProperty('aAlias') && configObj.aAlias)
        		aAlias 	= new ArrayCollection(importArray(configObj.aAlias.source,Alias,objectLookup,aDelayedImportQueue));
        	
        	if (configObj.hasOwnProperty('aTrigger') && configObj.aTrigger)
        		aTrigger = new ArrayCollection(importArray(configObj.aTrigger.source,Trigger,objectLookup,aDelayedImportQueue));
        	
        	
        	if (configObj.hasOwnProperty('telnetSettings') && configObj.telnetSettings) {
        		telnetSettings = importObject(configObj.telnetSettings, TelnetSettings,objectLookup,aDelayedImportQueue) as TelnetSettings;
        	}						

			// process any delayed imports
			while (aDelayedImportQueue.length) {
				var thisImport : DelayedImport = aDelayedImportQueue.pop();								
				thisImport.destObj[thisImport.destProp] = importObject(thisImport.oIn,thisImport.oInClass,objectLookup,aDelayedImportQueue);
			}					

			// remove any redundant trigger groups
			removeEmptyGroups();
			
			// clear the object lookup object now we are done
			objectLookup = null;
			aDelayedImportQueue = null;

        	// send event to restore main telnet window (to loaded state)
			mdiEvent = new WindowEvent(WindowEvent.OPEN_TELNET_WINDOW);							
			dispatcher.dispatchEvent(mdiEvent);
			
		}
		

		
		
		// takes a generic object and a class definition and populates a new instance of that class 
		// with any properties that are in the generic object.
		// this is in case extra props are added so that old objects can be imported (new props will go to their default value) 
		public function importObject(oIn:Object,classIn:Class,objectLookup:Dictionary,aDelayedImportQueue:Array) : Object {			
			
			// check to see if this object already exists in the dictionary.
			var oOut: Object = objectLookup[oIn];
			
			var typeRegexp : RegExp = /com\.simian\.([^:]*)::(\w+)/;			
			
			// otherwise create it!
			if (oOut == null) {			
				
				oOut = new classIn();
				
				// could replace with these...
				// var className:String = flash.utils.getQualifiedClassName( yourObject );
				// var objectClass:Class = flash.utils.getDefinitionByName( className ) as Class;
				
				var classInfo:XML = describeType(oOut); 
				
				
				for each (var v:XML in (classInfo..variable,classInfo..accessor)) {
					
					var propName : String = v.@name; 
					var propType : String = v.@type;
					
					if (oIn.hasOwnProperty(propName)) {
						
						var thisProp : * = oIn[propName];
						
						// must be at least this long to be com.simian.x::x
						// not going to be any primitive type i can think of bigger than this length
						// currently only support embedded com.simian objects
						// i'm sure theres a better way to do this...
						if (propType.length > 14) {														
							if (thisProp != null){
								// check dictionary for this class (if it's not a simian type then just process as a primitive)
								var bSimian : Boolean = false;
								var c : Class = objectLookup[propType];
								// otherwise figure it out from the object (this is going to die horribly if it isn't com.simian...)
								if (c == null) {
									var oType : Object = typeRegexp.exec(propType);
									if (oType != null){
										bSimian = true;
										c = getClassByAlias('com.simian.' + oType[1] + '.' + oType[2]);
										objectLookup[propType] = c;
									}	
								}
								
								if (bSimian) {
								
									oOut[propName] = objectLookup[thisProp];
									
									if (oOut[propName] == null && thisProp != null) {											
										aDelayedImportQueue.push(new DelayedImport(oOut,propName,thisProp,c));
									}
									
								} else oOut[propName] = thisProp;
								
							}
							
						} else {
							oOut[propName] = thisProp;	
						}
												
						
					}					 
				}										
				objectLookup[oIn] = oOut;
			}			
			return oOut;			
		}

		
		// imports an array or array collection into an array of the correct type
		// have to handle arrays of length 1 in the XML which don't show up as being an array at all		
		public function importArray(aIn:Array,classDef:Class,objectLookup:Dictionary,aDelayedImportQueue:Array) : Array {			
			var aOut : Array = new Array();	
			for each (var obj:Object in aIn) {				
				aOut.push(importObject(obj,classDef,objectLookup,aDelayedImportQueue));				
			}						
			return aOut;
		}

  		private  function removeEmptyGroups() : void {
  			
  			// loop through all the groups (apart from the first which is null (ungrouped) )
  			for (var i : int = aTriggerGroup.length -1; i > 0; i--) {
  				
  				var thisGroup : TriggerGroup = aTriggerGroup[i];  				
  				var bDelete : Boolean = true;
  				
  				// check all the triggers to see if any are in this here group
  				for each (var trig : Trigger in aTrigger.source){ if ( trig.triggerGroup == thisGroup ) bDelete = false; } 
  				for each (var alias : Alias in aAlias.source){ if ( alias.triggerGroup == thisGroup ) bDelete = false; }
  				
  				// delete the unlucky ones
  				if (bDelete) aTriggerGroup.removeItemAt(i);
  				
  			}
  			
  		}		



	}
}

	

class DelayedImport {

	public var destObj : *;
	public var destProp : String;
	public var oIn : *;
	public var oInClass : Class;

	function DelayedImport(_destObj : *, _destProp : String, _oIn : *, _oInClass : Class) {
		this.destObj = _destObj;
		this.destProp = _destProp;
		this.oIn = _oIn;
		this.oInClass = _oInClass;
	}
	
}	
	
