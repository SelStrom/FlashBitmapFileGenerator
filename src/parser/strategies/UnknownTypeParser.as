package parser.strategies {
import flash.utils.Dictionary;

public class UnknownTypeParser implements IParseStrategy {
    public var _emptyDictionarty:Dictionary = new Dictionary();
    public function UnknownTypeParser() {
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        return this;
    }

    public function get externalImportsHashList():Dictionary {
        return _emptyDictionarty;
    }

    public function get externalConstructor():String {
        return "---unknown type\n";
    }

    public function get externalVariables():String {
        return "---unknown type\n";
    }

    public function get type():String {
        return "";
    }
}
}
