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

    private function addToImports(line:String):void {
        _externalImportsHashList[line] = "";
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.display.Bitmap;");
        addToImports("import openfl.geom.Matrix;");
//        addToImports("import BitmapDataLibrary;");

        var info:BitmapInfo = _visitor.visitGraphics(_displayObject);

        _externalConstructor = "\n\t\tvar " + _displayObject.name + ": Bitmap = new Bitmap(BitmapDataLibrary.getInstance().getBitmapDataByName(\"" + info._name + "\"));\n";
        _externalConstructor += "\t\t" + externalContext + ".addChild(" + _displayObject.name + ");\n";
        _externalConstructor += createConstructorData(_displayObject);

        return this;
    }

    public function createConstructorData(displayObject:DisplayObject):String {
        var name:String = displayObject.name;
        var matrixName:String = "mtx" + displayObject.name;

        var constructor:String = new String();
        constructor += "\n\t\tvar " + matrixName + " : Matrix = new Matrix();\n";

        if (displayObject.alpha != 1) {
            constructor += "\n";
            constructor += "\t\t" + name + ".alpha = " + displayObject.alpha + ";\n";
        }
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            constructor += "\n";
            constructor += "\t\t" + matrixName + ".a = " + displayObject.transform.matrix.a + ";\n";
            constructor += "\t\t" + matrixName + ".b = " + displayObject.transform.matrix.b + ";\n";
            constructor += "\t\t" + matrixName + ".c = " + displayObject.transform.matrix.c + ";\n";
            constructor += "\t\t" + matrixName + ".d = " + displayObject.transform.matrix.d + ";\n";
            constructor += "\t\t" + matrixName + ".tx = " + displayObject.transform.matrix.tx + ";\n";
            constructor += "\t\t" + matrixName + ".ty = " + displayObject.transform.matrix.ty + ";\n";
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            constructor += "\n";
            constructor += "\t\t" + name + ".x = " + displayObject.x + ";\n";
            constructor += "\t\t" + name + ".y = " + displayObject.y + ";\n";
        }

        var objectRect:Rectangle = displayObject.getBounds( displayObject );
        if( objectRect.left != 0 || objectRect.top != 0 )
        {
            constructor += "\n";
            constructor += "\t\t" + matrixName + ".tx += " + objectRect.left + ";\n";
            constructor += "\t\t" + matrixName + ".ty += " + objectRect.top + ";\n";
        }
        constructor += "\t\t" + displayObject.name + ".transform.matrix = " + matrixName + ";\n";
        constructor += "\n\t\t" + displayObject.name + ".name = \"" + displayObject.name + "\";\n";
        return constructor;
    }
}
}
