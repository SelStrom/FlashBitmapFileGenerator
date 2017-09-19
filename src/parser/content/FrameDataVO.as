package parser.content {
import parser.strategies.*;

import flash.display.BitmapData;
import flash.geom.Matrix;

public final class FrameDataVO {
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
}
