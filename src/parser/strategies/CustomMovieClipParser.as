package parser.strategies {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import parser.FlashStageParser;
import parser.TextureList;
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

    private var _frameList:Vector.<Vector.<FrameDataVO>>;

    private function findObjectFrameData(bitmapData:BitmapData):FrameDataVO {
        for (var frame:int = _frameList.length - 1; frame >= 0; --frame) {
            for each(var frameData:FrameDataVO in _frameList[frame]) {
                if (frameData != null && (frameData.bitmapData.compare(bitmapData) == 0 )) {
                    return frameData;
                }
            }
        }

        return null;
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import strom.haxe.display.MovieClip;", true);

        _externalVariables = "\tpublic var " + _container.name + ":" + type + " = new " + type + "();\n";

        _externalConstructor = "\n\t\t"+externalContext+".addChild(this." + _container.name + ");\n";
        _externalConstructor += createConstructorData(_container);

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
        _constructor += "\n\t\tthis.frameRate = 30;\n";

        addToImports("import strom.FrameData;");
        addToImports("import strom.FrameDataVO;");
        addToImports("import haxe.ds.Array;");
        _constructor += "\n\t\tthis.frameData = new FrameData("+_container.totalFrames+");\n";
        _constructor += "\t\tvar frame : Array<FrameDataVO>;\n";
        _constructor += "\t\tvar frameDataVO : FrameDataVO;\n\n";

        _frameList = new Vector.<Vector.<FrameDataVO>>();
        for (var frame:int = 1; frame<=_container.totalFrames; frame++) {
            _container.gotoAndStop(frame);
            _constructor += "\t\tthis.frame = new Array<FrameDataVO>();\n";

            _frameList[frame - 1] = new Vector.<FrameDataVO>(_container.numChildren, true);

            var numChildren:int = _container.numChildren;
            for (var i:int = 0; i < numChildren; i++) {
                var child:DisplayObject = _container.getChildAt(i);

                //check unique frame by preview
                //create preview by frame
                var shapeRect:Rectangle = child.getBounds(child);
                var matrix:Matrix = new Matrix();
                matrix.translate((-shapeRect.left) + 1, (-shapeRect.top) + 1);
                var bitmapData:BitmapData = new BitmapData(Math.ceil(child.width) + (1 * 2), Math.ceil(child.height) + (1 * 2), true, 0x00000000);	// Assume transparency on everything.
                bitmapData.draw(child, matrix);
                TextureList.CreateBorder(bitmapData);

                _constructor += "\n\t\tthis.frameDataVO = new FrameDataVO();\n";
                var objectFrameData:FrameDataVO = new FrameDataVO();
                var oldFrameData:FrameDataVO = findObjectFrameData(bitmapData);

                if (oldFrameData != null && oldFrameData.name == child.name) {
                    objectFrameData.name = oldFrameData.name;
                    objectFrameData.parser = oldFrameData.parser;

                    _constructor += "\t\tthis.frameDataVO.addChild(this." + objectFrameData.name + ");\n";
                }
                else {
                    //parse as new object
                    objectFrameData.name = child.name;
                    objectFrameData.parser = FlashStageParser.parse(child).execute("this.frameDataVO");

                    for (var line:String in objectFrameData.parser.externalImportsHashList) {
                        addToImports(line);
                    }
                    _variables += objectFrameData.parser.externalVariables;
                    _constructor += objectFrameData.parser.externalConstructor;
                }

                objectFrameData.bitmapData = bitmapData;

                _constructor += "\t\tthis.frameDataVO.transformationMatrix = new Matrix();\n";
                _constructor += "\t\tthis.frameDataVO.transformationMatrix.a = " + child.transform.matrix.a + ";\n";
                _constructor += "\t\tthis.frameDataVO.transformationMatrix.b = " + child.transform.matrix.b + ";\n";
                _constructor += "\t\tthis.frameDataVO.transformationMatrix.c = " + child.transform.matrix.c + ";\n";
                _constructor += "\t\tthis.frameDataVO.transformationMatrix.d = " + child.transform.matrix.d + ";\n";
                _constructor += "\t\tthis.frameDataVO.transformationMatrix.tx = " + child.transform.matrix.tx + ";\n";
                _constructor += "\t\tthis.frameDataVO.transformationMatrix.ty = " + child.transform.matrix.ty + ";\n";
                if (child is Shape || child is Bitmap) {
                    var objectRect:Rectangle = child.getBounds( child );
                    if(objectRect.left != 0 || objectRect.top != 0) {
                        _constructor += "\n";
                        _constructor += "\t\tthis.frameDataVO.transformationMatrix.tx += " + objectRect.left + ";\n";
                        _constructor += "\t\tthis.frameDataVO.transformationMatrix.ty += " + objectRect.top + ";\n";
                    }
                }
                _constructor += "\t\tthis.frameDataVO.alpha = " + child.alpha + ";\n";

                _frameList[frame - 1][i] = objectFrameData;
                _constructor += "\t\tthis.frame.push(this.frameDataVO);\n";
            }

            _constructor += "\n\t\tthis.frameData.addFrame(" + (frame - 1) + ", this.frame);\n";
        }

        _constructor += "\t}\n";

        fileStream.writeUTFBytes(toString());
        fileStream.close();

        //Dispose trash data
        for (frame = _frameList.length - 1; frame >= 0; --frame) {
            for each(objectFrameData in _frameList[frame]) {
                objectFrameData.bitmapData.dispose();
                objectFrameData.bitmapData = null;
            }
        }
        // Reset the original movie clip, just in case.
        _container.gotoAndStop(1);

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
        return Util.getName(_container);
    }
}
}

import flash.display.BitmapData;
import flash.geom.Matrix;

import parser.strategies.IParseStrategy;

internal final class FrameDataVO {
    public var name:String;
    public var transformationMatrix:Matrix;
    public var alpha:Number;

    public var parser:IParseStrategy;
    public var bitmapData:BitmapData;

    public function dispose():void {
        name = null;
        transformationMatrix = null;
        bitmapData = null;
    }
}
