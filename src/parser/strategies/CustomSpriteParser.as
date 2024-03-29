package parser.strategies {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.Dictionary;

import parser.FlashStageParser;

import parser.FlashStageParser;
import parser.Logger;
import parser.Util;

public class CustomSpriteParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor:String = new String();
    private var _externalVariables:Dictionary = new Dictionary();
    private var _importsHashList:Dictionary = new Dictionary();
    public var _constructor:String = new String();
    public var _variables:Dictionary = new Dictionary();
    private var _container:Sprite;
    private var _packageName:String;

    private var _directory:File;
    private var _parser:FlashStageParser;

    public function get type():String {
        return Util.getClassName(_container);
    }

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():Dictionary {
        return _externalVariables;
    }

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }

    public function CustomSpriteParser(parser:FlashStageParser, container:Sprite, packageName:String) {
        _parser = parser;
        _container = container;
        _packageName = packageName;

        _directory = new File(_parser.srcOutputPath).resolvePath(_packageName);
        if (!_directory.exists) {
            _directory.createDirectory();
        }
    }

    private function addToImports(line:String, includeExternal:Boolean = false):void {
        _importsHashList[line] = "";
        if (includeExternal) {
            _externalImportsHashList[line] = "";
        }
    }

    private function addToVariables(line:String, includeExternal:Boolean = true):void {
        if (includeExternal) {
            _externalVariables[line] = "";
        } else {
            _variables[line] = "";
        }
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.display.Sprite;", true);
        addToImports("import openfl.geom.Matrix;", true);

        addToVariables("var " + _container.name + ":" + type + " = new " + type + "();");

        _externalConstructor = "\n\t\t" + externalContext + ".addChild(" + _container.name + ");\n";
        _externalConstructor += createConstructorData(_container);

        var fileName:String = Util.getClassName(_container);
        var file:File = _directory.resolvePath(fileName + ".hx");
        if (file.exists) {
            Logger.trace("File " + fileName + " is exists. Abort");
            return this;
        }
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.WRITE);

        _constructor += "\n\tpublic function new() {\n";
        _constructor += "\n\t\tsuper();\n";

        for (var i:int = 0; i < _container.numChildren; ++i) {
            var child:DisplayObject = _container.getChildAt(i);
            var childParseData:IParseStrategy = _parser.createParser(child).execute();

            for (var line:String in childParseData.externalImportsHashList) {
                addToImports(line);
            }
            for (line in childParseData.externalVariables) {
                addToVariables(line, false);
            }
            _constructor += childParseData.externalConstructor;
        }
        _constructor += "\t}\n";

        fileStream.writeUTFBytes(toString());
        fileStream.close();
        return this;
    }

    public function toString():String {
        var body:String = new String();
        body += "package " + _packageName + ";\n";

        for (var line:String in _importsHashList) {
            body += line + "\n";
        }

        body += "\n";
        body += "class " + Util.getClassName(_container) + " extends Sprite {\n";

        for (line in _variables) {
            body += "\tpublic " + line + "\n";
        }
        body += _constructor;

        body += "}\n";

        return body;
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
