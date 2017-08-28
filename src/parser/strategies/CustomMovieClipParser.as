package parser.strategies {
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.Dictionary;

import parser.Util;

public class CustomMovieClipParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor = new String();
    private var _externalVariables = new String();
    private var _importsHashList:Dictionary = new Dictionary();
    public var _constructor:String = new String();
    public var _variables:String = new String();
    private var _container:MovieClip;
    private var _packageName:String;

    private var _dirrectory:File = File.applicationStorageDirectory;

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():String {
        return _externalVariables;
    }

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }


    public function CustomMovieClipParser(container:MovieClip, packageName:String) {
        _container = container;
        _packageName = packageName;

        _dirrectory = _dirrectory.resolvePath(_packageName);
        if (!_dirrectory.exists) {
            _dirrectory.createDirectory();
        }
    }

    private function addToImports(line:String, includeExternal:Boolean = false):void {
        _importsHashList[line] = "";
        if (includeExternal) {
            _externalImportsHashList[line] = "";
        }
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import strom.haxe.display.MovieClip;", true);

        _externalConstructor = createConstructorData(_container);

        var fileName:String = Util.getName(_container);
        var file:File = _dirrectory.resolvePath(fileName + ".hx");
        if (file.exists) {
            trace("File " + fileName + " is exists. Abort");
            return this;
        }
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.WRITE);

        _constructor += "\n\tpublic function new() {\n";
        _constructor += "\t\tsuper();\n";
        _constructor += "\n\tthis.frameRate = 30;\n";

        addToImports("import ssmit.FrameData;");
        _constructor += "\n\tthis.frameData = new FrameData("+_container.totalFrames+");\n";
//        _constructor += "\n\tthis.frameData

        for (var frame:int = 0, size:int = _container.totalFrames; frame < size; frame++) {
            _container.gotoAndStop( frame );
//
//            _container.totalFrames
//
//            var childLength:int = _container.numChildren;
//            for( var i:int=0; i<childLength; ++i )
//            {
//
//            }

        }


//        for (var i:int = 0; i < _container.numChildren; ++i) {
//            var child:DisplayObject = _container.getChildAt(i);
//            var childParseData:IParseStrategy = FlashStageParser.parse(child).execute();
//
//            _variables += "\tpublic var " + child.name + ":" + Util.getName(child) + " = new " + Util.getName(child) + "();\n";
//            _constructor += "\n\t\tthis.addChild(this." + child.name + ");\n";
//
//            for (var line:String in childParseData.externalImportsHashList) {
//                addToImports(line);
//            }
//            _constructor += childParseData.externalConstructor;
//        }
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
        body += "class " + Util.getName(_container) + " extends MovieClip {\n";

        body += _variables;
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

    public function get type():String {
        return "";
    }
}
}
