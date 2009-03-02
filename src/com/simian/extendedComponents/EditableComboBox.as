package com.simian.extendedComponents {
    
    import flash.events.Event;
    
    import mx.controls.ComboBox;
    
    public class EditableComboBox extends ComboBox {
        
        private var _inputText:String;
        
        public function EditableComboBox() {
            super();
            addEventListener("change", clear_textInput);
        }

		private function clear_textInput(e:Event) : void {
			_inputText = null;
		}
        
        override protected function textInput_changeHandler(event:Event):void {
            _inputText = this.textInput.text;            
        }
        
        public function get inputText():String {
            return _inputText;
        }
        
        
    }
}