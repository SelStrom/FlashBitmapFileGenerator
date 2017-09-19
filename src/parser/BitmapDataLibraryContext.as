/**
 * Created by Andrey on 13.09.2017.
 */
package parser {
import com.adobe.images.PNGEncoder;

import flash.display.BitmapData;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import parser.content.BitmapInfo;
import parser.content.Variable;

public class BitmapDataLibraryContext {
    private var _packageName:String = "";

    protected var _importsHashList:Dictionary = new Dictionary();
    protected var _atlasVariables:Dictionary = new Dictionary();
    protected var _variables:Dictionary = new Dictionary();
    protected var _constructor:String = "";

    private var _directory:File;
    private var _atlasPath:String;
    private var _srcPath:String;

    private function addToImports(line:String):void {
        _importsHashList[line] = "";
    }

    public function addAtlasVariable(variable:Variable):void {
        _atlasVariables[variable.name] = variable;
    }

    public function addVariable(variable:Variable):void {
        _variables[variable.name] = variable;
    }

    public function BitmapDataLibraryContext(srcPath:String, atlasPath:String) {
        _atlasPath = atlasPath;
        _directory = new File(srcPath);
    }

    private function saveAtlas(fileName:String, atlasData:BitmapData):void {
        var file:File = new File(_atlasPath + fileName + ".png");
        if (file.exists) {
            Logger.trace("File " + fileName + " is exists. Abort");
            return;
        }

        var encodedData:ByteArray = PNGEncoder.encode(atlasData);

        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.UPDATE);

        fileStream.writeBytes(encodedData);
        fileStream.close();
    }

    public function execute(bitmapInfoList:Vector.<BitmapInfo>, sortBitmaps:Boolean):void {
        var fileName:String = Util.getClassName("BitmapDataLibrary");
        var file:File = _directory.resolvePath(fileName + ".hx");
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.WRITE);

        var bitmaps:Vector.<BitmapData> = TexturePacker.pack(bitmapInfoList, sortBitmaps);

        addToImports("import openfl.display.BitmapData;");
        addToImports("import openfl.geom.Rectangle;");
        addToImports("import haxe.ds.StringMap;");

        for (var i:int = 0; i < bitmaps.length; i++) {
            var bitmapData:BitmapData = bitmaps[i];
            addAtlasVariable(new Variable("bitmapData" + i.toString(), "BitmapData"));
            saveAtlas("bitmapData" + i, bitmapData);
        }
        addVariable(new Variable("bitmapDataMap", "StringMap<BitmapData>"));

        _constructor += "\n\tpublic function new() {\n";
        _constructor += "\t\tsuper();\n\n";

        for each (var line:Variable in _variables) {
            _constructor += "\t\t" + line.instaniate() + "\n";
        }
        for each (line in _atlasVariables) {
            _constructor += "\t\tthis." + line.name + " = Assets.getBitmapData(\"atlas/" + line.name + ".png\");\n";
        }

        for each(var info:BitmapInfo in bitmapInfoList) {
            _constructor += "\t\tinsertBitmapData(" +
                    "bitmapData" + info._atlasIndex + ", " +
                    "\"" + info._name + "\", " +
                    info.x + ", " +
                    info.y + ", " +
                    info.width + ", " +
                    info.height + ");\n";
        }

        _constructor += "\t}\n";

        fileStream.writeUTFBytes(toString());
        fileStream.close();
    }

    public function setPackageName(value:String):void {
        _packageName = value;
        _directory = _directory.resolvePath(_packageName);
        if (!_directory.exists) {
            _directory.createDirectory();
        }
    }

    public function toString():String {
        var body:String = new String();
        body += "package " + _packageName + ";\n";

        for (var importLine:String in _importsHashList) {
            body += importLine + "\n";
        }

        body += "\n";
        body += "class BitmapDataLibrary {\n";

        for each (var line:Variable in _variables) {
            body += "\tprivate " + line.definite() + "\n";
        }
        for each (line in _atlasVariables) {
            body += "\tprivate " + line.definite() + "\n";
        }

        body += _constructor;

        body += "\n\tpublic static function getBitmapDataByName(name:String):BitmapData {\n" +
                "\t\tif(_bitmapDataMap.exists(name)) {\n" +
                "\t\t\treturn _bitmapDataMap.get(name);\n" +
                "\t\t} else {\n" +
                "\t\t\tthrow new Error(\"Has not exists\");\n" +
                "\t\t}\n" +
                "\t}\n";

        body += "\n\tprivate function insertBitmapData(atlasName:String, textureName:String, x:Int, y:Int, width:Int, height:Int):Void {\n" +
                "\t\tvar bitmapData:BitmapData = new BitmapData(width, height, true, 0x00FFFFFF);\n" +
                "\t\tatlasName.copyPixels(bitmapData, new Rectangle(0, 0, width, height), new Point(x,y));\n" +
                "\t\tbitmapDataMap.set(textureName, bitmapData);\n" +
                "\t}\n";

        body += "}\n";

        return body;
    }
}
}
