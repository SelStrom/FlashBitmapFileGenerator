package parser.strategies {
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

public class TextureAtlasVisitor implements IParserVisitor {
    internal static const PADDING:int = 1;	// Add padding pixels to avoid bleeding in mipmaps.

    /** Счетчик, позволяющий задавать уникальные неповторяющиеся имена*/
    private static var _nameCounter:Number = 0;

    /** Содержит сырую информацию о всей графике*/
    private var _bitmapInfoList:Vector.<BitmapInfo>;


    public function TextureAtlasVisitor() {
        _bitmapInfoList = new <BitmapInfo>[];
    }

    // Disposes all the textures in the list.
    internal function dispose():void {
        for each(var info:BitmapInfo in _bitmapInfoList) {
            info.dispose();
        }
        _bitmapInfoList = null;
    }

    [Inline]
    public static function createBorder(bitmapData:BitmapData):void {
        var width:int = bitmapData.width;
        var height:int = bitmapData.height;

        bitmapData.copyPixels(bitmapData, new Rectangle(1, 1, width - 1, 1), new Point(1, 0));
        bitmapData.copyPixels(bitmapData, new Rectangle(width - 2, 0, 1, height - 1), new Point(width - 1, 0));
        bitmapData.copyPixels(bitmapData, new Rectangle(1, height - 2, width - 1, 1), new Point(1, height - 1));
        bitmapData.copyPixels(bitmapData, new Rectangle(1, 0, 1, height), new Point(0, 0));
    }

    /**
     * Finds an existing bitmap given the bitmapData
     * @param    bitmapData искомая картинка
     * @return  info, если искомая картинка найдена среди ранее созданных
     */
    private function findBitmapInfo(bitmapData:BitmapData):BitmapInfo {
        for each(var info:BitmapInfo in _bitmapInfoList) {
            if (bitmapData.compare(info._bitmapData) == 0) {
                return info;
            }
        }

        return null;
    }

    public function visitGraphics(displayObject:DisplayObject):BitmapInfo {
        var shapeRect:Rectangle = displayObject.getBounds(displayObject);
        var matrix:Matrix = new Matrix();
        matrix.translate((-shapeRect.left) + PADDING, (-shapeRect.top) + PADDING); //приведение координат к нулевой точке + смещение для границы
        var bitmapData:BitmapData = new BitmapData(Math.ceil(shapeRect.width) + (PADDING * 2), Math.ceil(shapeRect.height) + (PADDING * 2), true, 0xFF0000);	// Assume transparency on everything.
        bitmapData.draw(displayObject, matrix);
        createBorder(bitmapData);

        var info:BitmapInfo = findBitmapInfo(bitmapData);
        if (info != null) {
            bitmapData.dispose();
        }
        else {
            // Create a new bitmap info and add it to the list.
            info = new BitmapInfo();
            info._bitmapData = bitmapData;
            info._name = displayObject.name.slice() + 'i' + _nameCounter++;//создается уникальное имя для новой сабтекстуры
            _bitmapInfoList.push(info);//тут содержится вся сырая информации о графике
        }

        return info;
    }
}
}
