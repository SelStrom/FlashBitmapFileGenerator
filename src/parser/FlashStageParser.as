/**
 * Created by Andrey on 18.06.2017.
 */
package parser {
import fl.text.TLFTextField;

import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;

import parser.strategies.CustomMovieClipParser;
import parser.strategies.CustomSpriteParser;
import parser.strategies.GraphicsParser;
import parser.strategies.IParseStrategy;
import parser.strategies.MovieClipParser;
import parser.strategies.SpriteParser;
import parser.strategies.TLFTextParser;
import parser.strategies.TextParser;
import parser.strategies.UnknownTypeParser;

public class FlashStageParser {
    private var _outputPath:String;

    public function FlashStageParser(outputPath:String) {
        _outputPath = outputPath;

    }

    private static const VERSION:String = "3.0";

    private static var _PACKAGE_NAME:String = "generated";

    private static var _textureAtlasVisitor:TextureAtlasVisitor = null;
    private var _framerate:int = 30;

    /**
     * Растрирует мувиклипы, расположенные на главной сцене.
     * Все целевые клипы должны находиться на первом кадре. Желательно, чтобы больше ничего не было кроме них.
     * @param    stageMC
     * @param    outAtlases
     * @param    sortBitmaps по умолчанию сортирует битмапы
     * @return
     */
    public function exportFromMC(stageMC:DisplayObjectContainer, sortBitmaps:Boolean = true):void {
        Logger.trace("Start parsing");
        exportClipData(function ExportMethod():void {
            for (var i:int = 0, size:int = stageMC.numChildren; i < size; i++) {
                var mc:DisplayObject = stageMC.getChildAt(i);
                if (mc is MovieClip /*|| mc is Sprite*/) {
                    var name:String = String(mc).replace(new RegExp('(\\[class |\\[object |\\])', 'g'), '');
//                    mc.name = name;
                    createParser(DisplayObject(mc)).execute();
                    Logger.trace('Exporting complete: ' + name);
                }
            }
        }, sortBitmaps);
    }

    /**
     * Растрирует мувиклипы, расположенные в виде вектора с их определениями
     * @param    flashMC вектор с определениями мувиклипов. Задаается через new, далее шаблон вектора и массив определений.
     * @param    outAtlases
     * @param    sortBitmaps по умолчанию сортирует битмапы
     * @return
     *
     * <p>Вектор задается  "new <Class>[...]"</p>
     */
    public function exportMC(flashMC:Vector.<Class>, sortBitmaps:Boolean = true):void {
        exportClipData(function ExportMethod():void {
            for (var i:int = 0, size:int = flashMC.length; i < size; i++) {
                var name:String = String(flashMC[i]);
                name = name.replace(new RegExp('(\\[class |\\])', 'g'), '');
                createParser(DisplayObject(new flashMC[i])).execute();
                Logger.trace('Exporting complete: ' + name);
            }
        }, sortBitmaps);
    }

    private function exportClipData(exportMethod:Function, sortBitmaps:Boolean = true):void {
        _textureAtlasVisitor = new TextureAtlasVisitor();
        exportMethod();

        _textureAtlasVisitor.exportTextureAtlases(sortBitmaps, srcOutputPath, _outputPath + "assets/img/atlas/", _PACKAGE_NAME);

        _textureAtlasVisitor.dispose();
        _textureAtlasVisitor = null;
    }

    public function createParser(displayObject:DisplayObject, ignoreTotalFrames:Boolean = false):IParseStrategy {
        if (Util.getName(displayObject) == "Sprite") {
            return new SpriteParser(this, displayObject as Sprite);
        } else if (Util.getName(displayObject) == "MovieClip") {
            if (ignoreTotalFrames || (displayObject as MovieClip).totalFrames > 1) {
                return new MovieClipParser(this, displayObject as MovieClip);
            } else {
                return new SpriteParser(this, displayObject as Sprite);
            }
        }
        else if (displayObject is DisplayObjectContainer) {
            var container:DisplayObjectContainer = displayObject as DisplayObjectContainer;
            if (container is MovieClip && ( ignoreTotalFrames || (container as MovieClip).totalFrames > 1 )) {
                return new CustomMovieClipParser(this, container as MovieClip, _PACKAGE_NAME);
            } else if (container is TextField) {
                return new TextParser(container as TextField);
            } else if (container is TLFTextField) {
                return new TLFTextParser(container as TLFTextField);
            } else if (Util.getName(container) == "TCMText") {
                return new GraphicsParser(container, _textureAtlasVisitor);
            } else if (container is Sprite) {
                return new CustomSpriteParser(this, container as Sprite, _PACKAGE_NAME);
            } //else throw new Error("Unhandled child object " + displayObject.toString());
        } else if (Util.getName(displayObject) == "StaticText" ) {
            return new GraphicsParser(displayObject, _textureAtlasVisitor);
        } else if (displayObject is Shape) {
            return new GraphicsParser(displayObject, _textureAtlasVisitor);
        } else if (displayObject is Bitmap) {
            return new GraphicsParser(displayObject, _textureAtlasVisitor);
        } else if (Util.getName(displayObject) == "MorphShape") {
            return new GraphicsParser(displayObject, _textureAtlasVisitor);
        }
        return new UnknownTypeParser(displayObject);
    }

    public function get srcOutputPath():String {
        return _outputPath + "lib";
    }

    public function get framerate():int {
        return _framerate;
    }
}
}
