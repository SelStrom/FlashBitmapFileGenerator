/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 */
package parser.content {
import flash.display.BitmapData;

//	import starling.display.Image;

public final class BitmapInfo {
    internal static const PADDING:int = 1;

    public var _bitmapData:BitmapData;
    public var _name:String;
    public var _imageList:*//Vector.<Image>;
    public var _xmlList:Vector.<XML>;

    public var _atlasX:int;
    public var _atlasY:int;
    public var _atlasIndex:int;

    public function get x():int {
        return _atlasX + PADDING;
    }

    public function get y():int {
        return _atlasY + PADDING;
    }

    public function get width():int {
        return _bitmapData.width - PADDING * 2;
    }

    public function get height():int {
        return _bitmapData.height - PADDING * 2;
    }

    public function dispose():void {
        _bitmapData.dispose();
        _bitmapData = null;
        _name = null;
        _imageList = null;	// WARNING: Do not dispose Images. They are still in use.
        _xmlList = null;
    }
}
}