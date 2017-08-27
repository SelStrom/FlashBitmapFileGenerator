/**
 * Created by Andrey on 18.06.2017.
 */
package visitor {
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;

public interface IContentVisitor {
    function visitSprite(container:Sprite):FileDataVO;
    function visitBitmap():FileDataVO;
    function visitShape():FileDataVO;

    function visitMovieClip(container:MovieClip):FileDataVO;

    function visitTextField():FileDataVO;

    function createConstructorData(displayObject:DisplayObject):String;
}
}
