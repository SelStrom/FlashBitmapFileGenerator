package parser.strategies {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.Dictionary;

import parser.FlashStageParser;
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

    private var _directory:File = File.applicationStorageDirectory;

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

    public function CustomSpriteParser(container:Sprite, packageName:String) {
        _container = container;
        _packageName = packageName;

        _directory = _directory.resolvePath(_packageName);
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

        addToVariables("var " + _container.name + ":" + type + " = new " + type + "();");

        _externalConstructor = "\n\t\t" + externalContext + ".addChild(this." + _container.name + ");\n";
        _externalConstructor += createConstructorData(_container);

        var fileName:String = Util.getClassName(_container);
        var file:File = _directory.resolvePath(fileName + ".hx");
        if (file.exists) {
            trace("File " + fileName + " is exists. Abort");
            return this;
        }
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.WRITE);

        _constructor += "\n\tpublic function new() {\n";
        _constructor += "\n\t\tsuper();\n";

        for (var i:int = 0; i < _container.numChildren; ++i) {
            var child:DisplayObject = _container.getChildAt(i);
            var childParseData:IParseStrategy = FlashStageParser.parse(child).execute();

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

        for (var line:String in _variables) {
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
