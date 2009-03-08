package com.simian.telnet {
    import com.asfusion.mate.events.Dispatcher;
    
    import flash.events.*;
    import flash.net.Socket;
    import flash.utils.ByteArray;
    
    import mx.collections.ArrayCollection;

    public class Telnet{
    	
    	// public variables to be injected by MATE
    	[Bindable]
		public var aAlias : ArrayCollection = new ArrayCollection(); 
    	
    	
    	// character codes we might read from the socket
        private static const CR:int = 13; // Carriage Return (CR)
        private static const LF:int = 10; // Line Feed (LF)
        
        private static const WILL:int = 0xFB; // 251 - WILL (option code)
        private static const WONT:int = 0xFC; // 252 - WON'T (option code)
        private static const DO:int   = 0xFD; // 253 - DO (option code)
        private static const DONT:int = 0xFE; // 254 - DON'T (option code)
        private static const IAC:int  = 0xFF; // 255 - Interpret as Command (IAC)
        
        private static const ESC:int = 0x1B; //escape character
        private static const ECHO:int = 1; // toggle local echo mode?
                
        // some escape codes for colouring text
        private static const RED_TEXT : String = String.fromCharCode(ESC) + '[31m';
        private static const YELLOW_TEXT : String = String.fromCharCode(ESC) + '[33m';
        private static const RESET_TEXT : String = String.fromCharCode(ESC) + '[0m';
        
        private var serverURL:String;
        private var portNumber:int;
        private var socket:Socket;
        
        private var state:int = 0;
        private var echoMode: int = 1;
        private var openSpans: int = 0;
        
        private var commandQueue : Array = new Array(0);
        
		private var block_buffer : String = "";        
        private var blockCommand : Function = null;
        
        private var bPromptAppend : Boolean = false;
        
        private var dispatcher : Dispatcher = new Dispatcher();


                        
        public function Telnet() {
            
            // Create a new Socket object and assign event listeners.
            socket = new Socket();
            socket.addEventListener(Event.CONNECT, connectHandler);
            socket.addEventListener(Event.CLOSE, closeHandler);
            socket.addEventListener(ErrorEvent.ERROR, errorHandler);
            socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            socket.addEventListener(ProgressEvent.SOCKET_DATA, dataHandler);
            
            // connect(server,port);
                        
        }
        
        
        public function changeTitle(title:String) : void {
			var telnetEvent : TelnetEvent = new TelnetEvent(TelnetEvent.CHANGE_TITLE);
			telnetEvent.data = title;			
			dispatcher.dispatchEvent(telnetEvent);		        	
        }
        
        public function connect(server:String, port:int) : void {

            serverURL = server;
            portNumber = port;     
        	
            // Attempt to connect to remote socket server.
            try {
            	resetTerminal();
                msg("Trying to connect to " + serverURL + ":" + portNumber);
                socket.connect(serverURL, portNumber);
            } catch (error:Error) {
                /*
                    Unable to connect to remote server, display error 
                    message and close connection.
                */
                msg('error : ' +error.message);
                socket.close();
            }
        	
        }
        
        public function disconnect() : void {        	
            
            if (socket.connected) {			
				changeTitle('Disconnected, bah!');						        
            	msg("disconnected");        
				socket.close();        
            }
        }
        
        /**
         * This method is called if the socket encounters an ioError event.
         */
        public function ioErrorHandler(event:IOErrorEvent):void {

			changeTitle('Connection failed, perhaps you arn\'t trying hard enough?');			
            msg("Unable to connect: socket error");
            socket.close();
        }
        
        /**
         * This method is called by our application and is used to send data
         * to the server.
         */


      	public function sendCommand(text : String):void {
			// check aliases for this command before sending to the mud
            var ba:ByteArray = new ByteArray();

			if (socket.connected) {			
	        	ba.writeMultiByte(text + "\n", "UTF-8");
	        	writeBytesToSocket(ba);		        	
	        	if (echoMode == 1) update_msg(RED_TEXT + text + RESET_TEXT);        	
   			}
                        
        }         

      	public function sendTriggerCommand(text : String):void {
			// check aliases for this command before sending to the mud
            var ba:ByteArray = new ByteArray();

			if (socket.connected) {			
	        	ba.writeMultiByte(text + "\n", "UTF-8");
	        	writeBytesToSocket(ba);		        	
	        	if (echoMode == 1) msg( YELLOW_TEXT + text + RESET_TEXT);        	
   			}
                        
        }        
        
         
        public function writeBytesToSocket(ba:ByteArray):void {
            
            if (socket.connected) {            
	            socket.writeBytes(ba);
	            socket.flush();            
            }
        }
        
        private function connectHandler(event:Event):void {
            if (socket.connected) {
            	changeTitle('Connected to ' + serverURL + ':' + portNumber.toString());
                msg("connected...");                
            } else {
            	changeTitle('Unable to connect');
                msg("unable to connect");        
                socket.close();        
            }
        }
        
        /**
         * This method is called when the socket connection is closed by 
         * the server.
         */
        private function closeHandler(event:Event):void { 
        	changeTitle('Connection closed');       	
            msg("connection closed...");    
            socket.close();                    
        }
        
        /**
         * This method is called if the socket throws an error.
         */
        private function errorHandler(event:ErrorEvent):void {
            msg(event.text);
        }
        
        /**
         * This method is called when the socket receives data from the server.
         */
        private function dataHandler(event:ProgressEvent):void {
            var n:int = socket.bytesAvailable;
            var buffer : String;                        
            var line_buffer : String = "";
            /* start with any buffered indent from the last prompt */
            var ansi_line_buffer : String = '';
            
            // Loop through each available byte returned from the socket connection.
            while (--n >= 0) {
                // Read next available byte.
                var b:int = socket.readUnsignedByte();
                
                switch (state) {
                    case 0:
                        // If the current byte is the "Interpret as Command" code, set the state to 1.
                        if (b == IAC) {                        	
                            state = 1;
                        // if the current byte is the escape char set the state and process ansi chars etc
                        } else if (b == ECHO){
                        	if (echoMode == 0) echoMode = 1; else echoMode = 0;
                        } else if (b == ESC) {
                        	state = 3;
                        }
                        // Else, if the byte is not a carriage return, display the character using the msg() method.
                        else {
                        	
                        	var new_char : String;
                        	
                        	// if this char is a linefeed then process the line...                        	
                        	if (b == LF) { 
                        		// output the line in the buffer
                        		msg(ansi_line_buffer);   
                        		
                        		// add this line to the block buffer
                        		if (line_buffer.length > 0)	block_buffer += line_buffer + '\n';                        		                        	
                        		
                        		// reset the line buffers
                        		line_buffer = "";       
                        		ansi_line_buffer = "";                        		
                        		                 		
                        	} else {
	                        	 
	                        	// add this char to the line buffer as long as it aint a newline char 
	                        	if (b != CR){
	                        		line_buffer += String.fromCharCode(b);
	                        		ansi_line_buffer += String.fromCharCode(b);
	                        	} 
	                        	
                        	}
                        	        	
                        }
                 			
                        break;
                    case 1:
                        // If the current byte is the "DO" code, set the state to 2.
                        if (b == DO) {                        	
                            state = 2;
                        } else {                        	
                            state = 0;
                        }
                        break;
                    
                    // Blindly reject the option.
                    case 2:
                        /*
                            Write the "Interpret as Command" code, "WONT" code, 
                            and current byte to the socket and send the contents 
                            to the server by calling the flush() method.
                        */                        
                        socket.writeByte(IAC);
                        socket.writeByte(WONT);
                        socket.writeByte(b);
                        socket.flush();
                        state = 0;
                        break;
                        
                    case 3:
                    	/*  Escape char found...
                    		-- Process Ansi codes etc 
                    	*/
                    		
							/* Begin processing of extended esc code */	
							if (String.fromCharCode(b) == '[') {
								buffer = '';								
								state = 4;
								break;
							} 
							/* reset terminal command */
							else if (String.fromCharCode(b) == 'c'){
								resetTerminal();
							} 
							/* assorted other things that arn't implemented... */
							else if (String.fromCharCode(b) == 'M') msg('[Scroll Up]');
							else if (String.fromCharCode(b) == 'D') msg('[Scroll Down]');
							else if (String.fromCharCode(b) == 'H') msg('[Set Tab]');
							else if (String.fromCharCode(b) == '8') msg('[Restore Cursor & Attrs]');
							else if (String.fromCharCode(b) == '7') msg('[Save Cursor & Attrs]');
							else if (String.fromCharCode(b) == ')') msg('[Font Set G0]');
							else if (String.fromCharCode(b) == '(') msg('[Font Set G1]');							
							else msg('[unknown escape code : ' + b + ']');                    		                    	                    	     
                        	
                        	state = 0;
                        	
                    	break;
                    	
                    case 4:
                    
                    	/* we only like 0-9 and ; to be attached to our commands */
                    	if ( (b >= 48 && b <= 57) || b == 59) {
                    		buffer += String.fromCharCode(b);                   		
                    	} 
                    	/* change font color etc */
                    	else if (String.fromCharCode(b) == 'm'){                    		
                    		ansi_line_buffer += String.fromCharCode(ESC) + '[' + buffer + 'm';
                    		//ansi_line_buffer += '[ansi color : ' + buffer + 'm]';
                    		//trace( 'ansi color : ' + buffer + 'm');
                    		// ansi_line_buffer += '[ansi:' + buffer + 'm]';
                    		state = 0;
                		} else {                    
                    		// ignoring all ansi codes other than color changes!                    		
                    		//trace('[ansi:' + buffer + String.fromCharCode(b) + ']');                    	
                    		state = 0;
                    	}
                    	
                    	break;
                    
                }
                        
            }
            
            
           	// do prompt parsing stuff here (leftover stuff in the line buffer = prompt 
           	// make sure prompt is valid...
           	if (ansi_line_buffer != "") {

				// display the prompt
				msg(ansi_line_buffer);
           		
           	 	if ( 	( line_buffer.search('<') > -1 && line_buffer.search('>') > -1) || 
           	 	  		( line_buffer.search('Choice:') > -1 ) || 
           	 	  		( line_buffer.search('Password:') > -1 ) 
           	 	    ){
           			
		       		
		       		
		           	// parse the block and each line in it (minus prompt)
		           	if (block_buffer.length > 0){
		           	
		           		// parse each line in the block
		           		var aLines : Array = block_buffer.split('\n');
		           		for each (var line_text : String in aLines) {		           			
							if (parse_line.length > 0) parse_line(line_text);
		           		}		           		
		           		
		           		// parse the entire block
		           		parse_block(block_buffer);                      
		           	
		           		block_buffer = "";
		           	} 				 				 	

           			// parse the prompt (now we know it's valid)            			           			           			         		
		       		parse_prompt(line_buffer);


					bPromptAppend = false;
						
				 // this isn't a valid prompt so append the next line onto it				 
           	 	 }  else {           	 	 		           	 	
	           	 	bPromptAppend = true;
	           	 	// msg("[bad prompt]");	           	 	           	 		           	 	       	 	 
           	 	 }

           	}           	
            
        }
        


		// send new line of ansi Text Event (with data)
        public function msg(value:String): void { 
        	
        	var telnetEvent : TelnetEvent;
        	
        	// if the current line is a prompt then append output onto it.
        	if (bPromptAppend) {
				telnetEvent = new TelnetEvent(TelnetEvent.APPEND_LINE_DATA);
				bPromptAppend = false;									        	                       
        	} else {
				telnetEvent = new TelnetEvent(TelnetEvent.NEW_LINE_DATA);
        	}
        	
			telnetEvent.data = value;			
			dispatcher.dispatchEvent(telnetEvent);
        }
        
		// append current line of ansi Text Event (with data)
        public function update_msg(value:String): void { 
        	bPromptAppend = true;
        	msg(value);        	
        }


        public function resetTerminal():void {

        }         

        private function parse_prompt(prompt : String) : void {       		
        	var telnetEvent : TelnetEvent = new TelnetEvent(TelnetEvent.PARSE_PROMPT_DATA);
			telnetEvent.data = prompt;			
			dispatcher.dispatchEvent(telnetEvent);						
        }
        
        private function parse_line(line: String) : void {
        	var telnetEvent : TelnetEvent = new TelnetEvent(TelnetEvent.PARSE_LINE_DATA);
			telnetEvent.data = line;			
			dispatcher.dispatchEvent(telnetEvent);
        }
        
        private function parse_block(block: String) : void{
        	var telnetEvent : TelnetEvent = new TelnetEvent(TelnetEvent.PARSE_BLOCK_DATA);
			telnetEvent.data = block;			
			dispatcher.dispatchEvent(telnetEvent);        	        	
        }

    }
}
