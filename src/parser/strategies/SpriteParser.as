package parser.strategies {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.utils.Dictionary;

import parser.FlashStageParser;

public class SpriteParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor = new String();
    private var _externalVariables = new String();
    private var _container:Sprite;

    public function get type():String {
        return "Sprite";
    }

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():String {
        return _externalVariables;
    }

    public function SpriteParser(container:Sprite) {
        _container = container;
    }

    private function addToImports(line:String, includeExternal:Boolean = false):void {
        if (includeExternal) {
            _externalImportsHashList[line] = "";
        }
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.display.Sprite;", true);
        //TODO @a.shatalov: можно ли считать при externalContext != "this" не public var, а просто var
        _externalVariables = "\tpublic var " + _container.name + ":" + type + " = new " + type + "();\n";
        _externalConstructor = "\n\t\t"+externalContext+".addChild(this." + _container.name + ");\n";
        _externalConstructor += createConstructorData(_container);

        for (var i:int = 0; i < _container.numChildren; ++i) {
            var child:DisplayObject = _container.getChildAt(i);
            var childParseData:IParseStrategy = FlashStageParser.parse(child).execute(externalContext + "." +_container.name);

            for (var line:String in childParseData.externalImportsHashList) {
                addToImports(line);
            }
            _externalVariables += childParseData.externalVariables;
            _externalConstructor += childParseData.externalConstructor;
        }

        return this;
    }

    public function createConstructorData(displayObject:DisplayObject):String {
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
