/**
 * Created by Andrey on 16.09.2017.
 */
package parser {
import flash.text.TextField;

public class Logger {
    public static var output:TextField;

    public static function trace(... rest):void {
        output.text += "\n" + rest.join(" ");
        output.scrollV = output.maxScrollV;
    }
}
}
