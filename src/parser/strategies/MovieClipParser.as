package parser.strategies {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.display.Scene;
import flash.display.Shape;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import parser.FlashStageParser;

import parser.FlashStageParser;
import parser.TextureList;
import parser.content.FrameDataVO;

public class MovieClipParser implements IParseStrategy {
    private var _parser:FlashStageParser;
    public function MovieClipParser(parser:FlashStageParser, container:MovieClip) {
        _parser = parser;
        _container = container;
    }

    private var _container:MovieClip;
    private var _frameList:Vector.<Vector.<FrameDataVO>>;

    private var _externalImportsHashList:Dictionary = new Dictionary();

    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }

    private var _externalConstructor:String = new String();

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    private var _externalVariables:Dictionary = new Dictionary();

    public function get externalVariables():Dictionary {
        return _externalVariables;
    }

    public function get type():String {
        return "MovieClip";
    }

    private function addToVariables(line:String):void {
        _externalVariables[line] = "";
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import strom.haxe.display.MovieClip;", true);
        addToImports("import strom.FrameData;", true);
        addToImports("import strom.FrameDataVO;", true);
        addToImports("import openfl.display.FrameLabel;", true);
        addToImports("import openfl.geom.Matrix;", true);

        var name:String = _container.name;
        var frameDataName:String = "frameData" + name;
        var frameName:String = "frames" + name;
        var frameDataVOName:String = "frameDataVO" + name;

        addToVariables("var " + _container.name + ":" + type + " = new " + type + "();");
        _externalConstructor = "\n\t\t" + externalContext + ".addChild(" + name + ");\n";
        _externalConstructor += createConstructorData(_container);

        _externalConstructor += "\n\t\t" + name + ".frameRate = "+_parser.framerate+";\n";

        _externalConstructor += "\n\t\t" + frameDataName + " = new FrameData(" + _container.totalFrames + ");\n";
        _externalConstructor += "\t\tvar " + frameName + ": Array<FrameDataVO>;\n";
        _externalConstructor += "\t\tvar " + frameDataVOName + " : FrameDataVO;\n\n";

        _frameList = new Vector.<Vector.<FrameDataVO>>();
        for (var frame:int = 1; frame <= _container.totalFrames; frame++) {
            _container.gotoAndStop(frame);
            _externalConstructor += "\t\t" + frameName + " = new Array<FrameDataVO>();\n";

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

                _externalConstructor += "\n\t\t" + frameDataVOName + " = new FrameDataVO();\n";
                var objectFrameData:FrameDataVO = new FrameDataVO();
                var oldFrameData:FrameDataVO = findObjectFrameData(bitmapData);

                if (oldFrameData != null && oldFrameData.name == child.name) {
                    objectFrameData.name = oldFrameData.name;
                    objectFrameData.parser = oldFrameData.parser;

                    _externalConstructor += "\t\t" + frameDataVOName + ".addChild(" + objectFrameData.name + ");\n";
                }
                else {
                    //parse as new object
                    objectFrameData.name = child.name;
                    objectFrameData.parser = _parser.createParser(child).execute("" + frameDataVOName + "");

                    for (var line:String in objectFrameData.parser.externalImportsHashList) {
                        addToImports(line, true);
                    }
                    for (line in objectFrameData.parser.externalVariables) {
                        addToVariables(line);
                    }
                    _externalConstructor += objectFrameData.parser.externalConstructor;
                }

                objectFrameData.bitmapData = bitmapData;

                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix = new Matrix();\n";
                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.a = " + child.transform.matrix.a + ";\n";
                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.b = " + child.transform.matrix.b + ";\n";
                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.c = " + child.transform.matrix.c + ";\n";
                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.d = " + child.transform.matrix.d + ";\n";
                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.tx = " + child.transform.matrix.tx + ";\n";
                _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.ty = " + child.transform.matrix.ty + ";\n";
                if (child is Shape || child is Bitmap) {
                    var objectRect:Rectangle = child.getBounds(child);
                    if (objectRect.left != 0 || objectRect.top != 0) {
                        _externalConstructor += "\n";
                        _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.tx += " + objectRect.left + ";\n";
                        _externalConstructor += "\t\t" + frameDataVOName + ".transformationMatrix.ty += " + objectRect.top + ";\n";
                    }
                }
                _externalConstructor += "\t\t" + frameDataVOName + ".alpha = " + child.alpha + ";\n";

                _frameList[frame - 1][i] = objectFrameData;
                _externalConstructor += "\t\t" + frameName + ".push(" + frameDataVOName + ");\n";
            }

            _externalConstructor += "\n\t\t" + frameDataName + ".addFrame(" + (frame - 1) + ", " + frameName + ");\n";
        }

        _externalConstructor += "\n\t\t" + name + ".frameData = " + frameDataName + ";\n";

        var sceneCount:int = _container.scenes.length;
        for (var sceneIndex:int = 0; sceneIndex < sceneCount; ++sceneIndex) {
            var scene:Scene = _container.scenes[sceneIndex];
            for each(var label:FrameLabel in scene.labels) {
                var labelName:String = label.name;
                var labelFrame:int = label.frame;

                _externalConstructor += "\n\t\t" + name + ".addLabel(new FrameLabel(\"" + labelName + "\", " + labelFrame + "));\n";
            }
        }

        _externalConstructor += "\n\t\t" + name + ".initFrame();\n";

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

    private function addToImports(line:String, includeExternal:Boolean = false):void {
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
}
}
