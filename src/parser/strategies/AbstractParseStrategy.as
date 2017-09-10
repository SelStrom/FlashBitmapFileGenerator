/**
 * Created by Andrey on 07.09.2017.
 */
package parser.strategies {
import flash.display.DisplayObject;
import flash.utils.Dictionary;

public class AbstractParseStrategy implements IParseStrategy {
    protected var _externalImportsHashList:Dictionary = new Dictionary();
    protected var _externalConstructor:String = new String();
    protected var _externalVariables:Dictionary = new Dictionary();

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():Dictionary {
        return _externalVariables;
    }

    public function get type():String {
        return "unknown type";
    }

    public function AbstractParseStrategy() {
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        return null;
    }

    internal function createConstructorData(displayObject:DisplayObject):String {
        var constructor:String = new String();
        if (displayObject.alpha != 1) {
            constructor += "\n";
            constructor += "\t\tthis." + displayObject.name + ".alpha = " + displayObject.alpha + ";\n";
        }
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            constructor += "\n";
            constructor += "\t\tthis." + displayObject.name + ".transform.matrix.a = " + displayObject.transform.matrix.a + ";\n";
            constructor += "\t\tthis." + displayObject.name + ".transform.matrix.b = " + displayObject.transform.matrix.b + ";\n";
            constructor += "\t\tthis." + displayObject.name + ".transform.matrix.c = " + displayObject.transform.matrix.c + ";\n";
            constructor += "\t\tthis." + displayObject.name + ".transform.matrix.d = " + displayObject.transform.matrix.d + ";\n";
            constructor += "\t\tthis." + displayObject.name + ".transform.matrix.tx = " + displayObject.transform.matrix.tx + ";\n";
            constructor += "\t\tthis." + displayObject.name + ".transform.matrix.ty = " + displayObject.transform.matrix.ty + ";\n";
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            constructor += "\n";
            constructor += "\t\tthis." + displayObject.name + ".x = " + displayObject.x + ";\n";
            constructor += "\t\tthis." + displayObject.name + ".y = " + displayObject.y + ";\n";
        }
        return constructor;
    }
}
}
