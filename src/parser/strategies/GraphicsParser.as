package parser.strategies {
import flash.display.DisplayObject;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import parser.content.BitmapInfo;

public class GraphicsParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor:String = new String();
    private var _externalVariables:Dictionary = new Dictionary();
    private var _displayObject:DisplayObject;
    private var _visitor:IParserVisitor;

    public function get type():String {
        return "Bitmap";
    }

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():Dictionary {
        return _externalVariables;
    }

    public function GraphicsParser(displayObject:DisplayObject, visitor:IParserVisitor) {
        this._displayObject = displayObject;
        _visitor = visitor;
    }

    private function addToImports(line:String, includeExternal:Boolean = false):void {
        if (includeExternal) {
            _externalImportsHashList[line] = "";
        }
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.display.Bitmap;", true);
//        addToImports("import BitmapDataLibrary;", true);

        var info:BitmapInfo = _visitor.visitGraphics(_displayObject);

        _externalConstructor = "\n\t\tvar " + _displayObject.name + ": Bitmap = new Bitmap(BitmapDataLibrary.getBitmapDataByName(\"" + info._name + "\"));\n";
        _externalConstructor += "\t\t" + externalContext + ".addChild(" + _displayObject.name + ");\n";
        _externalConstructor += createConstructorData(_displayObject);

        return this;
    }

    public function createConstructorData(displayObject:DisplayObject):String {
        var name:String = displayObject.name;
        
        var constructor:String = new String();
        if (displayObject.alpha != 1) {
            constructor += "\n";
            constructor += "\t\tthis." + name + ".alpha = " + displayObject.alpha + ";\n";
        }
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            constructor += "\n";
            constructor += "\t\tthis." + name + ".transform.matrix.a = " + displayObject.transform.matrix.a + ";\n";
            constructor += "\t\tthis." + name + ".transform.matrix.b = " + displayObject.transform.matrix.b + ";\n";
            constructor += "\t\tthis." + name + ".transform.matrix.c = " + displayObject.transform.matrix.c + ";\n";
            constructor += "\t\tthis." + name + ".transform.matrix.d = " + displayObject.transform.matrix.d + ";\n";
            constructor += "\t\tthis." + name + ".transform.matrix.tx = " + displayObject.transform.matrix.tx + ";\n";
            constructor += "\t\tthis." + name + ".transform.matrix.ty = " + displayObject.transform.matrix.ty + ";\n";
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            constructor += "\n";
            constructor += "\t\tthis." + name + ".x = " + displayObject.x + ";\n";
            constructor += "\t\tthis." + name + ".y = " + displayObject.y + ";\n";
        }

        var objectRect:Rectangle = displayObject.getBounds( displayObject );
        if( objectRect.left != 0 || objectRect.top != 0 )
        {
            constructor += "\n";
            constructor += "\t\tthis." + name + ".transform.matrix.tx += " + objectRect.left + ";\n";
            constructor += "\t\tthis." + name + ".transform.matrix.ty += " + objectRect.top + ";\n";
        }

        return constructor;
    }
}
}
