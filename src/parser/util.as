/**
 * Created by Andrey on 19.06.2017.
 */
package parser {
public class Util {
    //TODO @a.shatalov: empty file data vo
    public static var className:RegExp = new RegExp('(\\[class |\\[object |\\])', 'g');

    public static function getName(type:Object):String {
        return type.toString().replace(className, '');
    }

    public static function getClassName(type:Object):String {
        var name:String = getName(type);
        return name.charAt(0).toUpperCase() + name.substr(1);
    }
}
}
