/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 */
package parser.strategies {
import flash.display.BitmapData;

//	import starling.display.Image;

public final class BitmapInfo {
    public var _bitmapData:BitmapData;
    public var _name:String;
    public var _imageList:*//Vector.<Image>;
    public var _xmlList:Vector.<XML>;

    public var _atlasX:int;
    public var _atlasY:int;
    public var _atlasIndex:int;

    public function dispose():void {
        _bitmapData.dispose();
        _bitmapData = null;
        _name = null;
        _imageList = null;	// WARNING: Do not dispose Images. They are still in use.
        _xmlList = null;
    }
}
}