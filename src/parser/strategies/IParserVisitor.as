package parser.strategies {
import flash.display.DisplayObject;

public interface IParserVisitor {
    function visitGraphics(displayObject:DisplayObject):BitmapInfo;
}
}
