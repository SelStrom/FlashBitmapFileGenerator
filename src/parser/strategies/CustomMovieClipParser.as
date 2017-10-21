package parser.strategies {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.display.Scene;
import flash.display.Shape;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import parser.FlashStageParser;

import parser.FlashStageParser;
import parser.Logger;
import parser.TextureList;
import parser.Util;
import parser.content.FrameDataVO;

public class CustomMovieClipParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor:String = new String();
    private var _externalVariables:Dictionary = new Dictionary();
    private var _importsHashList:Dictionary = new Dictionary();
    public var _constructor:String = new String();
    public var _variables:Dictionary = new Dictionary();
    private var _container:MovieClip;
    private var _packageName:String;

    private var _frameList:Vector.<Vector.<FrameDataVO>>;

    private var _directory:File;
    private var _parser:FlashStageParser;

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():Dictionary {
        return _externalVariables;
    }

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }


    public function CustomMovieClipParser(parser:FlashStageParser, container:MovieClip, packageName:String) {
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

    private function addToVariables(line:String, includeExternal:Boolean = true):void {
        if (includeExternal) {
            _externalVariables[line] = "";
        } else {
            _variables[line] = "";
        }
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import strom.haxe.display.MovieClip;", true);
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
        _constructor += "\t\tsuper();\n";
        _constructor += "\n\t\tframeRate = "+_parser.framerate+";\n";

        addToImports("import strom.FrameData;");
        addToImports("import strom.FrameDataVO;");
        addToImports("import openfl.display.FrameLabel;");
        _constructor += "\n\t\tframeData = new FrameData(" + _container.totalFrames + ");\n";
        _constructor += "\t\tvar frames : Array<FrameDataVO>;\n";
        _constructor += "\t\tvar frameDataVO : FrameDataVO;\n\n";

        _frameList = new Vector.<Vector.<FrameDataVO>>();
        for (var frame:int = 1; frame <= _container.totalFrames; frame++) {
            _container.gotoAndStop(frame);
            _constructor += "\t\tframes = new Array<FrameDataVO>();\n";

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

                _constructor += "\n\t\tframeDataVO = new FrameDataVO();\n";
                var objectFrameData:FrameDataVO = new FrameDataVO();
                var oldFrameData:FrameDataVO = findObjectFrameData(bitmapData);

                if (oldFrameData != null && oldFrameData.name == child.name) {
                    objectFrameData.name = oldFrameData.name;
                    objectFrameData.parser = oldFrameData.parser;

                    _constructor += "\t\tframeDataVO.addChild(" + objectFrameData.name + ");\n";
                }
                else {
                    //parse as new object
                    objectFrameData.name = child.name;
                    objectFrameData.parser = _parser.createParser(child).execute("frameDataVO");

                    for (var line:String in objectFrameData.parser.externalImportsHashList) {
                        addToImports(line);
                    }
                    for (line in objectFrameData.parser.externalVariables) {
                        addToVariables(line, false);
                    }
                    _constructor += objectFrameData.parser.externalConstructor;
                }

                objectFrameData.bitmapData = bitmapData;

                _constructor += "\t\tframeDataVO.transformationMatrix = new Matrix();\n";
                _constructor += "\t\tframeDataVO.transformationMatrix.a = " + child.transform.matrix.a + ";\n";
                _constructor += "\t\tframeDataVO.transformationMatrix.b = " + child.transform.matrix.b + ";\n";
                _constructor += "\t\tframeDataVO.transformationMatrix.c = " + child.transform.matrix.c + ";\n";
                _constructor += "\t\tframeDataVO.transformationMatrix.d = " + child.transform.matrix.d + ";\n";
                _constructor += "\t\tframeDataVO.transformationMatrix.tx = " + child.transform.matrix.tx + ";\n";
                _constructor += "\t\tframeDataVO.transformationMatrix.ty = " + child.transform.matrix.ty + ";\n";
                if (child is Shape || child is Bitmap) {
                    var objectRect:Rectangle = child.getBounds(child);
                    if (objectRect.left != 0 || objectRect.top != 0) {
                        _constructor += "\n";
                        _constructor += "\t\tframeDataVO.transformationMatrix.tx += " + objectRect.left + ";\n";
                        _constructor += "\t\tframeDataVO.transformationMatrix.ty += " + objectRect.top + ";\n";
                    }
                }
                _constructor += "\t\tframeDataVO.alpha = " + child.alpha + ";\n";

                _frameList[frame - 1][i] = objectFrameData;
                _constructor += "\t\tframes.push(frameDataVO);\n";
            }

            _constructor += "\n\t\tframeData.addFrame(" + (frame - 1) + ", frames);\n";
        }

        var sceneCount:int = _container.scenes.length;
        for (var sceneIndex:int = 0; sceneIndex < sceneCount; ++sceneIndex) {
            var scene:Scene = _container.scenes[sceneIndex];
            for each(var label:FrameLabel in scene.labels) {
                var labelName:String = label.name;
                var labelFrame:int = label.frame;

                _constructor += "\n\t\taddLabel(new FrameLabel(\"" + labelName + "\", " + labelFrame + "));\n";
            }
        }

        _constructor += "\t\tinitFrame();\n";
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
        body += "class " + Util.getClassName(_container) + " extends MovieClip {\n";

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

    public function get type():String {
        return Util.getClassName(_container);
    }
}
}
