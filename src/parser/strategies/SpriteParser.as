package parser.strategies {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.utils.Dictionary;

import parser.FlashStageParser;

import parser.FlashStageParser;

public class SpriteParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor:String = new String();
    private var _externalVariables:Dictionary = new Dictionary();
    private var _container:Sprite;
    private var _parser:FlashStageParser;

    public function get type():String {
        return "Sprite";
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

    public function SpriteParser(parser:FlashStageParser, container:Sprite) {
        _parser = parser;
        _container = container;
    }

    private function addToImports(line:String):void {
        _externalImportsHashList[line] = "";
    }

    private function addToVariables(line:String):void {
        _externalVariables[line] = "";
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.display.Sprite;");
        addToImports("import openfl.geom.Matrix;");

        addToVariables("var " + _container.name + ":" + type + " = new " + type + "();");

        _externalConstructor = "\n\t\t"+externalContext+".addChild(" + _container.name + ");\n";
        _externalConstructor += createConstructorData(_container);

        for (var i:int = 0; i < _container.numChildren; ++i) {
            var child:DisplayObject = _container.getChildAt(i);
            var childParseData:IParseStrategy = _parser.createParser(child).execute(externalContext + "." +_container.name);

            for (var line:String in childParseData.externalImportsHashList) {
                addToImports(line);
            }
            for (line in childParseData.externalVariables) {
                addToVariables(line);
            }
            _externalConstructor += childParseData.externalConstructor;
        }

        return this;
    }

    public function createConstructorData(displayObject:DisplayObject):String {
        var constructor:String = new String();
        if (displayObject.alpha != 1) {
            constructor += "\n";
            constructor += "\t\t" + displayObject.name + ".alpha = " + displayObject.alpha + ";\n";
        }
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            var matrixName:String = "mtx" + displayObject.name;
            constructor += "\n";
            constructor += "\t\tvar " + matrixName + " : Matrix = new Matrix();\n";
            constructor += "\t\t" + matrixName + ".a = " + displayObject.transform.matrix.a + ";\n";
            constructor += "\t\t" + matrixName + ".b = " + displayObject.transform.matrix.b + ";\n";
            constructor += "\t\t" + matrixName + ".c = " + displayObject.transform.matrix.c + ";\n";
            constructor += "\t\t" + matrixName + ".d = " + displayObject.transform.matrix.d + ";\n";
            constructor += "\t\t" + matrixName + ".tx = " + displayObject.transform.matrix.tx + ";\n";
            constructor += "\t\t" + matrixName + ".ty = " + displayObject.transform.matrix.ty + ";\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix = " + matrixName + ";\n";
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            constructor += "\n";
            constructor += "\t\t" + displayObject.name + ".x = " + displayObject.x + ";\n";
            constructor += "\t\t" + displayObject.name + ".y = " + displayObject.y + ";\n";
        }
        constructor += "\n\t\t" + displayObject.name + ".name = \"" + displayObject.name + "\";\n";
        return constructor;
    }
}
}
