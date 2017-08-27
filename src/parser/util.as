/**
 * Created by Andrey on 19.06.2017.
 */
package parser {
public class Util {
    //TODO @a.shatalov: empty file data vo
    public static var className:RegExp = new RegExp('(\\[class |\\[object |\\])', 'g');

    public static function getClassName(rawName:String):String {
        return rawName.replace(className, '');
    }

    public static function getName(type:Object):String {
        return type.toString().replace(className, '');
    }
}
}
