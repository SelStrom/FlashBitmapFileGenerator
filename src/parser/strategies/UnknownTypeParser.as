package parser.strategies {
import flash.display.DisplayObject;
import flash.utils.Dictionary;

import parser.Util;

public class UnknownTypeParser implements IParseStrategy {
    public var _emptyDictionary:Dictionary = new Dictionary();
    private var _displayObject:DisplayObject;

    public function UnknownTypeParser(displayObject:DisplayObject) {
        _displayObject = displayObject;
        _emptyDictionary["---unknown type hash: " + Util.getName(displayObject)] = "";
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        return this;
    }

    public function get externalImportsHashList():Dictionary {
        return _emptyDictionary;
    }

    public function get externalConstructor():String {
        return "---unknown type for:" + Util.getName(_displayObject) + "\n";
    }

    public function get externalVariables():Dictionary {
        return _emptyDictionary;
    }

    public function get type():String {
        return "";
    }
}
}
