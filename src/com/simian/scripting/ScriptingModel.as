package com.simian.scripting {
	import com.asfusion.mate.events.Dispatcher;
	import com.simian.mapper.PathEvent;
	import com.simian.profile.Alias;
	import com.simian.profile.Trigger;
	import com.simian.telnet.TelnetEvent;
	
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	public class ScriptingModel {

		
		public var aAlias : ArrayCollection;

		private var oVariables : Object = new Object();	
	
		private var dispatcher : Dispatcher = new Dispatcher();

		// trigger vars
		public var aTrigger : ArrayCollection ;		
		public static const aParseType : Array = ['Prompt','Line','Block'];



		// function or quoted string or number or variable name 
		private static const parameterRegExp : String = '(\\w+\\(.*\\)|[\'\"].*[\'\"]|-?\\d+\\.?\\d*|\\w+)';			
		private static const evaluatorRegExp : String = '(==|!=|<|<=|>|>=)';			
		// space parameter + space + evalutator + space + parameter + space
		private static const exprRegexp : String = '^\\s*' + parameterRegExp + '\\s*' + evaluatorRegExp + '\\s*' + parameterRegExp +  '\\s*$';

		// regexp for validating a string
		private static const stringCheck : RegExp = new RegExp(/^\s*[\'\"](.*)[\"\']\s*$/); 				

		// regexp for validating a number
		private static const numberCheck : RegExp = new RegExp(/^\s*(-?\d+.?\d*)\s*$/);

		// regexp for validating a function (and extracting function name and params)
		private static const functionCheck : RegExp = new RegExp(/^\s*(\w+)\((.*)\)\s*$/);
	
	
		public function ScriptingModel() : void {
			
		}

		
		// process a single line (user import or one line of a trig / alias
		public function processCommand(command:String) : String {
			
			// see if this command is actually a function of some sort (i.e starts with a / )
			if (command.length > 0 && command.charAt(0) == '/') {				
				command = command.slice(1);				
				command = executeFunction(command);	
				command = processEmbeddedCommands(command);	
			// if this starts with a # it's a comment, ignore entire line
			} else if (command.length > 0 && command.charAt(0) == '#') {
				command = '';											
			// this is just a normal string but we need to check for embedded commands... ooOOooo	
			} else {				
				command = processEmbeddedCommands(command);
			}				
			return command;			
		}


		private function executeFunction(command:String) : String {
			
			try { 

				// run the splitter regexp on the command. 
				// validates it is a command and seperates out the parameters				
				var oCommand : Object = functionCheck.exec(command);

				if (!oCommand) throw(new Error('Invalid Command'));				
				
				// convert the parameters into an array so we can evaluate them				
				// got to do some fancy parsing due to nested functions etc
				var aParamStack : Array = splitParams(oCommand[2]);
				
				// process each param and turn it into a string 
				for (var i : int = 0; i < aParamStack.length;i++) aParamStack[i] = evalutateParam(aParamStack[i]);
												
				// gotta rejig the command if it's a reserverd work				
				if 		(oCommand[1] == 'set') oCommand[1] = 'setValue';
				else if (oCommand[1] == 'trace') oCommand[1] = 'traceValue';
				else if (oCommand[1] == 'get') oCommand[1] = 'getVarValue';
				
				// check command exists
				if (this.hasOwnProperty(oCommand[1])) {

					// go go gadget command
					command = this[oCommand[1]](aParamStack);
					
				} else {
				
					var bMatch : Boolean = false;
					
					// not a native command so check aliases
					for each (var a:Alias in aAlias) {				
						if (a.trigger == oCommand[1] ){
							bMatch = true;											
							command = a.command;
							// loop over found tokens (skip 0 as it is the command)
							// replace %1 with whatever the first parameter was etc.
							for (var j : int = 1; j <= aParamStack.length; j++){
								var regexp : RegExp = new RegExp('%' + j.toString(),'g'); 		
								if (aParamStack[j - 1].length) command = command.replace(regexp, aParamStack[j-1]);
							}
							// expand macro contents
							command = processCommand(command);
							break;					
						} 				
					}
								
					if (!bMatch) throw(new Error('Unknown Command (or alias)'));
				}
				
				
				
			} catch (error:Error) {
				
				error_handler('Error in function : "' + command + '"\n' + error.message);
				command = '';
			}
			
			return command;
			
		}

		
		private function evalutateParam(param:String) : String {
			
			// first check of this param is a string...
			var oString : Object = stringCheck.exec(param);
			
			if(oString == null) var oNumber : Object = numberCheck.exec(param);

			// if it's a string (quoted) destringerise it
			if (oString != null) param = oString[1];					
			// see if it's a number (dosn't need to be quoted)
			else if (oNumber != null)  param = oNumber[1];
			// see if it's a function (if it is execute it and put the resulting value back in here
			else if (functionCheck.test(param) == true) param = executeFunction(param);
			// it must be a variable if we got this far!
			else param = getValue(param);
			
			return param;
		}



		private function processEmbeddedCommands(command:String) : String {
			// check for embedded commands i.e hello %(fn(x,y)) -> hello + the result of the function fn(x,y)
			var aCommand : Array = splitEmbeddedCommands(command);								
			var bCommandNext : Boolean = false;								
			var part : String = '';
			
			for (var i : int = 0; i < aCommand.length; i++) {					
				part = aCommand[i];					
				if (bCommandNext == false) {
					if ( (part.charAt(part.length-1) == '%') && (part.length == 1 || part.charAt(part.length - 2) != '%') ) {
						bCommandNext = true;
						if (part.length > 1) {
							aCommand[i] = part.slice(0,part.length - 1);
						} else aCommand[i] = '';
					}						
					aCommand[i] = aCommand[i].replace('%%','%');
				} else {
					aCommand[i] = executeFunction(part);
					bCommandNext = false;						
				}															
			}				
			command = '';
			
			for (var j : int = 0; j < aCommand.length; j++) {
				command += aCommand[j];
			}			
			
			return command;
		}


		// walk through a command and split it into an array of paramaters
		// have to ignore commas nested inside brackets
		// also have to ignore commas and brackets which are inside quotes (strings) (and the other type of quote char)
		private function splitParams(params:String) : Array {			
			var aParam : Array = new Array();			
			var temp_param : String = '';			
			var nest_level : int = 0;
			var thisChar : String = '';	
			var quoteChar : String = '';		
			for (var i : int = 0; i < params.length;i++) {			
				thisChar = params.charAt(i);											
				if (thisChar == '(' && quoteChar == '') { nest_level++; temp_param += thisChar; }
				else if (thisChar == ')' && quoteChar == '') { nest_level--; temp_param += thisChar; }
				else if (thisChar == '"' || thisChar == "'")	 {
					if (quoteChar == thisChar) quoteChar = '';						
					else if (quoteChar == '') quoteChar = thisChar; 
					temp_param += thisChar;
				}	
				else if (thisChar == ',' && nest_level == 0 && quoteChar == '') { aParam.push(temp_param); temp_param = ''; } 
				else temp_param += thisChar;				
			}			
			if (temp_param.length > 0) aParam.push(temp_param);			
			return aParam;
		}
		
		// runs through a string and splits it into an array with any functions seperated out		
		private function splitEmbeddedCommands(command:String) : Array {
			var aCommand : Array = new Array();			
			var temp : String = '';
			var nest_level : int = 0;
			var quoteChar : String = '';
			var thisChar : String = '';
			var lastChar : String = '';
			var bInFucntion : Boolean = false;
			
			for (var i : int = 0; i < command.length;i++) {			
				
				thisChar = command.charAt(i);											
				
				if (thisChar == '(' && quoteChar == '') { 
					// this is the beginning of a function call
					if (nest_level == 0 && lastChar == '%'){
						bInFucntion = true;
						aCommand.push(temp);
						temp = '';						
					} else {
						temp += thisChar;	
					}					
					nest_level++; 					 
				}
				
				else if (thisChar == ')' && quoteChar == '') { 
					nest_level--; 
					if (nest_level == 0 && bInFucntion) {
						aCommand.push(temp);
						temp = '';
						bInFucntion = false;
					} else {
						temp += thisChar; 
					}
				}
				// ignore anything inside quotes if it's inside parenthese
				else if (bInFucntion && (thisChar == '"' || thisChar == "'"))	 {
					if (quoteChar == thisChar) quoteChar = '';						
					else if (quoteChar == '') quoteChar = thisChar; 
					temp += thisChar;
				}
					
				else temp += thisChar;
				
				lastChar = thisChar;				
			}			

			if(temp.length > 0) aCommand.push(temp);			
			
			return aCommand;
		}
		

		// evalutates an expression to true|false
		private function processExpression(expr:String) : Boolean{
			
			var exprSplitter : RegExp = new RegExp(exprRegexp,'');			
			var oExpr : Object = exprSplitter.exec(expr);
			
			if (oExpr != null) {
			
				oExpr[1] = evalutateParam(oExpr[1]);				
				oExpr[3] = evalutateParam(oExpr[3]);
				
				switch (oExpr[2]) {
					
					case '==':
						return oExpr[1] == oExpr[3];					
					break;
					
					case '!=':
						return oExpr[1] != oExpr[3];
					break;

					case '>':
						return Number(oExpr[1]) > Number(oExpr[3]);					
					break;

					case '>=':
						return Number(oExpr[1]) >= Number(oExpr[3]);					
					break;

					case '<':
						return Number(oExpr[1]) < Number(oExpr[3]);					
					break;

					case '<=':
						return Number(oExpr[1]) <= Number(oExpr[3]);					
					break;
					
				} 
							
			}
			
			// will only get here if expr didn't validate
			traceValue(['Error with expression : ' + expr]);
			return false;
				
		}
			


		// gets a variable from the pile, chucks an error if it hasn't been set
		private function getValue(varName:String) : String {
			if (this.oVariables.hasOwnProperty(varName)) return this.oVariables[varName];
			else {				
				traceValue(['Variable "' + varName + '" is undefined']);
				return '';
			} 	
		}




		// check aliases for a match...
		// this is very basic atm, only checking exact case sensitive matches.
		// to be replaced with a proper check at some stage (and perhaps argument expansion / parsing)
		public function checkAliases(cmd:String, cmd_type:String) : void {			
			
			// add a space betcause we want to match the command followed by either nothing or a space and more tokens
			// this way either will be matched by (start of line) + command + (space) ...
			// for example if the alias was 'l' it would be matched by 'l' or 'l a' but not by 'la'
			var test_cmd : String = cmd + ' ';
			var dataEvent : TelnetEvent;
			
			// loop through aliases and check for matches
			for each (var a:Alias in aAlias) {				
				if (test_cmd.search('^' + a.trigger + ' ') == 0){
					// match found. expand it if required
					var aTokens : Array = test_cmd.split(' ');					
					cmd = a.command;
					// loop over found tokens (skip 0 as it is the command)
					// replace %1 with whatever the first parameter was etc.
					for (var i : int = 1; i < aTokens.length; i++){
						var regexp : RegExp = new RegExp('%' + i.toString(),'g'); 		
						if (aTokens[i].length) cmd = cmd.replace(regexp, aTokens[i]);
					}	
					
					cmd = executeCodeBlock(cmd);
					
					break;				
				} 
			}			


			var aCommands : Array = cmd.split('\r')						
								
			for each (var c : String in aCommands) { 
        	
				if (cmd_type == 'trigger' || aCommands.length > 1) {
					if (c.length > 0) {
						dataEvent = new TelnetEvent(TelnetEvent.DISPATCH_TRIGGER_DATA);
						dataEvent.data = processCommand(c);
						dispatcher.dispatchEvent(dataEvent);
					}
				} 
				else {
					dataEvent = new TelnetEvent(TelnetEvent.DISPATCH_DATA);
					dataEvent.data = processCommand(c);
					dispatcher.dispatchEvent(dataEvent);
				}							
							
			}
					
		}	



		private function error_handler(message:String) : void {			
			traceValue([message]);
		}







	/* **********************************************

			* * *  Trigger Functions * * *

	   ********************************************** */

		public function checkLine(line:String) : void {									
			for each (var trig:Trigger in aTrigger) {
				if (trig.bEnabled && (trig.parse_type == 1 || trig.parse_type == 0)) {
					checkText(line, trig.trigger, trig.command);
				}
			}									
		}

		public function checkPrompt(line:String) : void {									
			for each (var trig:Trigger in aTrigger) {
				if (trig.bEnabled && trig.parse_type == 0) {
					checkText(line, trig.trigger, trig.command);
				}
			}									
		}

		public function checkBlock(line:String) : void {									
			for each (var trig:Trigger in aTrigger) {
				if (trig.bEnabled && trig.parse_type == 2) {					
					checkText(line, trig.trigger, trig.command);					
				}
			}									
		}
		
		
		private  function checkText(text:String, pattern_text:String, command : String) : void {
			
			// don't match empty triggers if anyone is mad enough to enable one ;-)
			if (pattern_text.length > 0) {			
				var regexp : RegExp = new RegExp(pattern_text,'i');			
				var oResult : Object = regexp.exec(text);
				
				// if oResult isn't null a match was found
				if (oResult) {				
					// replace any % vars in the command with the matched bit 
					for (var i : int = 0; i < oResult.length; i++){					
						var replace_regexp : RegExp = new RegExp('%' + i.toString(),'g'); 		
						command = command.replace(replace_regexp, oResult[i].toString());
					}		
					var aCommands : Array = executeCodeBlock(command).split('\r')											
					for each (var c : String in aCommands) if (c.length > 0) sendCommand(c);				
				}
			}
		}

		private function sendCommand(cmd:String) : void {			
			var telnetEvent : TelnetEvent = new TelnetEvent(TelnetEvent.SEND_TRIGGER_DATA);
			telnetEvent.data = cmd;			
			dispatcher.dispatchEvent(telnetEvent);					
		}


		private function executeCodeBlock(block:String) : String {
			
			var retCode : String = '';
						
			// split this block into smaller blocks			
			var aBlocks : Array = splitCodeBlock(block);				

			var if_regexp : RegExp = /^\s*\/if\s*(.*)$/
			var else_regexp : RegExp = /^else\s*(.*)$/
			
			// loop over each block item				
			var i : int = 0;			
			var blockItem : String
			var oIf : Object;		
			var oElse : Object;	
			while (i < aBlocks.length) {
				
				blockItem = aBlocks[i]; 				
				oIf = if_regexp.exec(blockItem);
				
				// if this is an if statement...]
				if (oIf != null) {
					
					var aPart : Array = splitIfParts(oIf[1]);
										
					// evaluate the expression..
					if (processExpression(aPart[0])) {
						
						// check to see if the command is on this same line
						if (StringUtil.trim(aPart[1]).length > 0) {
							retCode += executeCodeBlock(aPart[1]); // just incase there is a single line if statement execute this line as a block
						} else {
						// command is the next block
							retCode += executeCodeBlock(aBlocks[i+1]);
							i++; // advance us a block		
						}
						// check for else (which we will need to skip
						if (i + 1 < aBlocks.length) {
							blockItem = aBlocks[i +1];
							oElse = else_regexp.exec(blockItem);
							// if the next block is the matching else statement we will need to skip it
							if (oElse != null) {
								i++;
								// if the command is inline then we are okay. otherwise if it's the next block advance us one to skip it.
								if (StringUtil.trim(oElse[1]).length == 0) i++;
							}
						}
						
					} 
					// otherwise we need to look for the else case
					else {
						// if the true statement was in the next block skip ahead
						if (StringUtil.trim(aPart[1]).length == 0) i++;
						
						if (i+1 < aBlocks.length){ 
							blockItem = aBlocks[i+1];
							oElse = else_regexp.exec(blockItem);
							// if the next block is the matching else statement we will need to skip it
							if (oElse != null) {
								// if the command is inline
								i++;
								if (StringUtil.trim(oElse[1]).length > 0) {
									retCode += executeCodeBlock(oElse[1]);
								} else {									
									i++;
									retCode += executeCodeBlock(aBlocks[i]);									
								}
							}							
							
						}
					}
					
				
				// otherwise it's just a normal command...
				} else {
					retCode += blockItem + '\r'; 
				}				
				i++;				
			}	
				
			// error_handler('block result : ' + retCode.replace(/\r|\n/g,';'));	
									
			return retCode;			
			
		}

		// splits an if string into two parts (expression and remainder)
		private function splitIfParts(strIf : String) : Array {
			var aParts : Array = new Array();

			var temp_block : String = '';			
			var nest_level : int = 0;
			var thisChar : String = '';	
			var quoteChar : String = '';	
				
			// loop through each char in the block	
			for (var i : int = 0; i < strIf.length;i++) {			
				
				// get the next char
				thisChar = strIf.charAt(i);											
				
				// if it's the start of a new block...
				if (thisChar == '(' && quoteChar == '') { 
					 if (nest_level != 0) temp_block += thisChar;
					 nest_level++; 
				}
				
				else if (thisChar == ')' && quoteChar == '') { 				
					nest_level--;									
					if ( nest_level == 0) {
						aParts.push(StringUtil.trim(temp_block)); 
						temp_block = '';
						quoteChar = 'x'					 						
					} else temp_block += thisChar;
				
				}
				
				// quote chars
				else if (thisChar == '"' || thisChar == "'")	 {
					if (quoteChar == thisChar) quoteChar = '';						
					else if (quoteChar == '') quoteChar = thisChar; 
					temp_block += thisChar;
				}									
				
				else temp_block += thisChar;				
			}			
			
			aParts.push(StringUtil.trim(temp_block));					
			
			return aParts;
		}
	
		// turns a block of code into an array of code blocks
		private function splitCodeBlock(block:String) : Array {
			var aBlocks : Array = new Array();
			
			var temp_block : String = '';			
			var nest_level : int = 0;
			var thisChar : String = '';	
			var quoteChar : String = '';	
				
			// loop through each char in the block	
			for (var i : int = 0; i < block.length;i++) {			
				
				// get the next char
				thisChar = block.charAt(i);											
				
				// if it's the start of a new block...
				if (thisChar == '{' && quoteChar == '') { 				
					if ( nest_level == 0 ){					 
						if (StringUtil.trim(temp_block).length > 0) aBlocks.push(StringUtil.trim(temp_block)); 
						temp_block = '';					 
					} else temp_block += thisChar;				
					nest_level++;				
				}
				
				else if (thisChar == '}' && quoteChar == '') { 				
					nest_level--;				
					if ( nest_level == 0) {
						aBlocks.push(StringUtil.trim(temp_block)); 
						temp_block = '';					 						
					} else temp_block += thisChar; 
				
				}
				
				// quote chars
				else if (thisChar == '"' || thisChar == "'")	 {
					if (quoteChar == thisChar) quoteChar = '';						
					else if (quoteChar == '') quoteChar = thisChar; 
					temp_block += thisChar;
				}	
				
				// End of Line. (if we arn't in {}'s this is a whole block by itself
				else if (thisChar == '\r' && nest_level == 0 && StringUtil.trim(temp_block).length > 0 ) { aBlocks.push(StringUtil.trim(temp_block)); temp_block = ''; } 
				
				else temp_block += thisChar;				
			}			
			if ( StringUtil.trim(temp_block).length > 0) aBlocks.push(StringUtil.trim(temp_block));					

			return aBlocks;			
		}


		/* *************************************
		
			   BEGIN MAGICAL SCRIPT FUNCTIONS
		
		**************************************** */

		// sets a variable. don't forget to quote the variable name :p i.e set('x','foo')
		public function setValue(aArguments:Array) : String {
			var varName:String = aArguments[0];
			var value: String = aArguments[1];
			
			this.oVariables[varName] = value as String;			
			return '';
		}

		// traces something
		public function traceValue(aArguments:Array) : String {			
			var value:String = aArguments[0];			

        	var telnetEvent : TelnetEvent;       	
			telnetEvent = new TelnetEvent(TelnetEvent.NEW_LINE_DATA);        	
			telnetEvent.data = 'Error: ' + value;			
			dispatcher.dispatchEvent(telnetEvent);

			trace(value);			
			return '';			
		}
		
		// traces something
		public function getVarValue(aArguments:Array) : String {			
			var value:String = aArguments[0];			
			return value;							
		}
		
		
		
		// adds two numbers.
		public function add(aArguments:Array) : String {			
			var param1:String = aArguments[0];
			var param2: String = aArguments[1];

			var i : Number = Number(param1) + Number(param2);
			return i.toString();
		}

		// subtract two numbers.
		public function subtract(aArguments:Array) : String {			
			var param1:String = aArguments[0];
			var param2: String = aArguments[1];

			var i : Number = Number(param1) - Number(param2);
			return i.toString();
		}

		// multiply two numbers.
		public function multiply(aArguments:Array) : String {			
			var param1:String = aArguments[0];
			var param2: String = aArguments[1];
			var i : Number = Number(param1) * Number(param2);
			return i.toString();
		}

		// divide two numbers.
		public function divide(aArguments:Array) : String {						
			var i : Number = Number(aArguments[0]) / Number(aArguments[1]);
			return i.toString();
		}





		// evaluates an expression
		public function test(aArguments:Array) : String {			
			var expr:String = aArguments[0];
			
			var result : String = processExpression(expr).toString();			
			traceValue([result]);			
			return result;
		}



		// greater than (if p1 > p2) return p3 else ret p4
		public function gt(aArguments:Array) : String {			
			var param1:Number = Number(aArguments[0]);
			var param2: Number = Number(aArguments[1]);
			var param3: String = aArguments[2];
			var param4: String = '';			
			if (aArguments.length == 4) param4 = aArguments[3];			
			if (param1 > param2) return processCommand(param3);
			else return processCommand(param4);						
		}
	
		// less than (if p1 < p2) return p3 else ret p4
		public function lt(aArguments:Array) : String {			
			var param1:Number = Number(aArguments[0]);
			var param2: Number = Number(aArguments[1]);
			var param3: String = aArguments[2];
			var param4: String = '';			
			if (aArguments.length == 4) param4 = aArguments[3];			
			if (param1 < param2) return processCommand(param3);
			else return processCommand(param4);						
		}

		// equal to (if p1 = p2) return p3 else ret p4
		public function eq(aArguments:Array) : String {			
			var param1:String = aArguments[0];
			var param2: String = aArguments[1];
			var param3: String = aArguments[2];
			var param4: String = '';			
			if (aArguments.length == 4) param4 = aArguments[3];			
			if (param1 == param2) return processCommand(param3);
			else return processCommand(param4);						
		}
		
		
		

		// sets a path (takes a path string and turns it into an array of steps)
		public function setPath(aArguments:Array) : String {
			
			var aNewPath : Array = new Array();
			var path:String = aArguments[0];			
			var repeat : int = 1;
			var thisChar : String = '';
			
			for (var i : int = 0; i < path.length;i++) {			
				thisChar = path.charAt(i);				
				if (thisChar.search('\d') == 0) repeat = parseInt(thisChar);
				else {					
					for (var j: int = 0; j < repeat; j++) aNewPath.push(thisChar);
					repeat = 1;
				}			
			}
			
        	var pEvent : PathEvent;       	
			pEvent = new PathEvent(PathEvent.NEW_PATH);        	
			pEvent.aPath = aNewPath; 			
			dispatcher.dispatchEvent(pEvent);
			
			return '';
		}
		
		// takes a step on a path
		public function stepPath(aArguments:Array) : String {

        	var pEvent : PathEvent;       	
			pEvent = new PathEvent(PathEvent.STEP);        				 		
			dispatcher.dispatchEvent(pEvent);			
			return '';			
		}

		// undoes the last step
		public function undoStep(aArguments:Array) : String {			
        	var pEvent : PathEvent;       	
			pEvent = new PathEvent(PathEvent.UNDO_LAST_STEP);        				 		
			dispatcher.dispatchEvent(pEvent);			
			return '';			
		}

		// undoes the last step
		public function repeatStep(aArguments:Array) : String {			
        	var pEvent : PathEvent;       	
			pEvent = new PathEvent(PathEvent.REPEAT_LAST_STEP);        				 		
			dispatcher.dispatchEvent(pEvent);			
			return '';			
		}		

		// delay (x seconds, command)
		public function delay(aArguments:Array) : String {			
			var delay:Number = Number(aArguments[0]);
			var command: String = aArguments[1];
			
			setTimeout(sendCommand,delay * 1000, command);

			return '';
		}

	}
	
}