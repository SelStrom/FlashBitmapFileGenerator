package parser.strategies {
import flash.display.DisplayObject;

import parser.content.BitmapInfo;

public interface IParserVisitor {
    function visitGraphics(displayObject:DisplayObject):BitmapInfo;
}
}
