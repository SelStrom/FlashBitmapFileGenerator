/**
 * Created by Andrey on 18.06.2017.
 */
package parser {
import fl.text.TLFTextField;

import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display3D.textures.Texture;
import flash.text.TextField;

import parser.strategies.CustomMovieClipParser;

import parser.strategies.CustomSpriteParser;
import parser.strategies.GraphicsParser;

import parser.strategies.IParseStrategy;
import parser.strategies.MovieClipParser;
import parser.strategies.SpriteParser;
import parser.strategies.TLFTextParser;
import parser.strategies.TextParser;
import parser.strategies.TextureAtlasVisitor;
import parser.strategies.UnknownTypeParser;

public class FlashStageParser {
    private static const VERSION:String = "2.0";
//    private static var _textureList:TextureList;
    private static var _objectsXML:XML;

    private static var _PACKAGE_NAME:String = "generated";

    /**
     * Растрирует мувиклипы, расположенные на главной сцене.
     * Все целевые клипы должны находиться на первом кадре. Желательно, чтобы больше ничего не было кроме них.
     * @param    stageMC
     * @param    outAtlases
     * @param    sortBitmaps по умолчанию сортирует битмапы
     * @return
     */
    public static function ExportFromMC(stageMC:DisplayObjectContainer, sortBitmaps:Boolean = true):XML {
        return ExportClipData(function ExportMethod():void {
            for (var i:int = 0, size:int = stageMC.numChildren; i < size; i++) {
                var mc:DisplayObject = stageMC.getChildAt(i);
                if (mc is MovieClip /*|| mc is Sprite*/) {
                    var name:String = String(mc).replace(new RegExp('(\\[class |\\[object |\\])', 'g'), '');
                    exportRecursive(mc, true, name); //сразу добавляет в созданный объект в _objectsXML
                    trace('Exporting complte: ' + name);
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
    public static function exportMC(flashMC:Vector.<Class>, sortBitmaps:Boolean = true):XML {
        return ExportClipData(function ExportMethod():void {
            for (var i:int = 0, size:int = flashMC.length; i < size; i++) {
                var name:String = String(flashMC[i]);
                name = name.replace(new RegExp('(\\[class |\\])', 'g'), '');
//                exportRecursive(DisplayObject(new flashMC[i]), true, name); //сразу добавляет созданный объект в _objectsXML
                parse(DisplayObject(new flashMC[i])).execute();
                trace('Exporting complte: ' + name);
            }
        }, sortBitmaps);
    }

    private static function ExportClipData(ExportMethod:Function, sortBitmaps:Boolean = true):XML {
//        _textureList = new TextureList();
        _objectsXML = <objects />;

        ExportMethod();

        var clipData:XML = <clipData />;
        clipData.@frameRate = 60;//FIXME исправить устанавливаемый фреймрейт на текущий
        clipData.@version = VERSION;
        clipData.appendChild(_objectsXML);

        //CreateTextureAtlases(clipData, sortBitmaps);
        return clipData;
    }

    public static function exportRecursive(displayObject:DisplayObject, ignoreTotalFrames:Boolean = false, forceName:String = null):* {
        throw new Error("Empty function");
//        else
//            throw new Error("Unhandled child object " + displayObject.toString());

/*
        var objectXML:XML = <object />;

        // Assign common properties.
        objectXML.@name = forceName || displayObject.name;
        if (displayObject.alpha != 1)
            objectXML.appendChild(<alpha>{ displayObject.alpha }</alpha>);
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            var transformXML:XML = <transform />;
            transformXML.@a = displayObject.transform.matrix.a;
            transformXML.@b = displayObject.transform.matrix.b;
            transformXML.@c = displayObject.transform.matrix.c;
            transformXML.@d = displayObject.transform.matrix.d;
            transformXML.@tx = displayObject.transform.matrix.tx;
            transformXML.@ty = displayObject.transform.matrix.ty;
            objectXML.appendChild(transformXML);
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            var positionXML:XML = <position />;
            positionXML.@x = displayObject.x;
            positionXML.@y = displayObject.y;
            objectXML.appendChild(positionXML);
        }

        if (displayObject is flash.display.DisplayObjectContainer) {
            var container:flash.display.DisplayObjectContainer = displayObject as flash.display.DisplayObjectContainer;

            if (container is flash.display.MovieClip && ( ignoreTotalFrames || (container as flash.display.MovieClip).totalFrames > 1 )) {
                objectXML.@type = "movie clip";

                var movieClip:MovieClip = container as flash.display.MovieClip;

                var isFlippFrames:Boolean = false;
                if (movieClip is FlippedMovieClip) isFlippFrames = true;

                var frameData:FrameData = FrameData.importFromFlashMovieClip(movieClip, exportFrameObject, isFlippFrames);

                objectXML.appendChild(frameData.exportToXML());
                objectXML.appendChild(exportSceneData(movieClip));
            }
            else if (container is fl.text.TCMText) {
                objectXML.@type = 'sprite';
                var childrenXML:XML = <children />;

                var bitmapData:BitmapData = new BitmapData(container.width, container.height, true, 0);
                bitmapData.draw(container);
                var bitmap:Bitmap = new Bitmap(bitmapData);

                var childXML:XML = exportRecursive(bitmap);
                childrenXML.appendChild(<child object={ childXML.childIndex() } name={childXML.@name.toString()}/>);

                objectXML.appendChild(childrenXML);
            }
            else if (container is TLFTextField) {
                //
                //objectXML.@type = "ignore";
                objectXML.@type = "text field";
                var tf:TLFTextField = container as TLFTextField;

                var textDataXML:XML = <data />;
                objectXML.appendChild(textDataXML);
                textDataXML.@text = tf.text;
                textDataXML.@color = tf.textColor;
                textDataXML.@font = tf.getTextFormat().font;
                textDataXML.@size = tf.getTextFormat().size;
                textDataXML.@tw = tf.width;
                textDataXML.@th = tf.height;
                textDataXML.@italic = tf.getTextFormat().italic || false;
                textDataXML.@bold = tf.getTextFormat().bold || false;
                textDataXML.@align = tf.getTextFormat().align == null ? "left" : tf.getTextFormat().align;
                //textDataXML.@align = tf.getTextFormat().align;//TODO разобраться как в некоторых случаях получать точное значение align. В общих случаях будет передано Null
                textDataXML.@autoSize = tf.autoSize;
                //TODO добавить фильтры
            }
            else {
                objectXML.@type = "sprite";

                //var childrenXML:XML = <children />;
                childrenXML = <children />;

                // Add the children to the new Starling Sprite.
                for (var i:int = 0; i < container.numChildren; ++i) {
                    var child:DisplayObject = container.getChildAt(i);
                    //var childXML:XML = exportRecursive( child );
                    childXML = exportRecursive(child);
//						childrenXML.appendChild( <child idref={ childXML.@id } /> );
                    childrenXML.appendChild(<child object={ childXML.childIndex() } name={childXML.@name.toString()}/>);//в подобных местах мы даем ссылку на используемый объект
                }

                objectXML.appendChild(childrenXML);
            }
        }
        else {
            if (displayObject is Shape || displayObject is Bitmap) {
                objectXML.@type = "image";

                var bitmapInfo:BitmapInfo = _textureList.getBitmapInfoFromDisplayObject(displayObject); //видимо сдесь создается графика

                var objectRect:Rectangle = displayObject.getBounds(displayObject);
                var imagePosX:Number = displayObject.x + objectRect.left;
                var imagePosY:Number = displayObject.y + objectRect.top;

                if (imagePosX != 0 || imagePosY != 0) {
                    if (positionXML == null) {
                        positionXML = <position />;
                        objectXML.appendChild(positionXML);
                    }
                    positionXML.@x = imagePosX;
                    positionXML.@y = imagePosY;
                }

                if (bitmapInfo._xmlList == null)
                    bitmapInfo._xmlList = new <XML>[];
                bitmapInfo._xmlList.push(objectXML);

            } //TODO обработка MorphShape
            else
                throw new Error("Unhandled child object " + displayObject.toString());
        }*/

//        _objectsXML.appendChild(objectXML);//тут удалять нельзя. Тут создается общий список всех объектов на сцене
    }

    public static function parse(displayObject:DisplayObject):IParseStrategy {
        //temp
        var ignoreTotalFrames:Boolean = false;
        //temp
        if (Util.getName(displayObject) == "Sprite") {
            return new SpriteParser(displayObject as Sprite);
        } else if (Util.getName(displayObject) == "MovieClip") {
            if(ignoreTotalFrames || (displayObject as MovieClip).totalFrames > 1) {
                return new MovieClipParser(displayObject as MovieClip);
            } else {
                return new SpriteParser(displayObject as Sprite);
            }
        }

        else if (displayObject is DisplayObjectContainer) {
            var container:DisplayObjectContainer = displayObject as DisplayObjectContainer;
            if (container is MovieClip && ( ignoreTotalFrames || (container as MovieClip).totalFrames > 1 )) {
                return new CustomMovieClipParser(container as MovieClip, _PACKAGE_NAME);
            } else if (container is TextField) {
                return new TextParser(container as TextField);
            } else if (container is TLFTextField) {
                return new TLFTextParser(container as TLFTextField);
            } else if (Util.getName(container) == "TCMText") {
                return new GraphicsParser(container, _texureAtlasVisitor);
            } else if (container is Sprite) {
                return new CustomSpriteParser(container as Sprite, _PACKAGE_NAME);
            } //else throw new Error("Unhandled child object " + displayObject.toString());
        } else if (displayObject is Shape) {
            return new GraphicsParser(displayObject, _texureAtlasVisitor);
        } else if (displayObject is Bitmap) {
            return new GraphicsParser(displayObject, _texureAtlasVisitor);
        } //TODO обработка MorphShape
        return new UnknownTypeParser(displayObject);
    }

    public static function createAtlas():void {
        //TODO @a.shatalov: реализовать создание атласа
        //данные брать через метод  _texureAtlasVisitor
    }

    private static var _texureAtlasVisitor:TextureAtlasVisitor = new TextureAtlasVisitor();
}
}
