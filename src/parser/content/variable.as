/**
 * Created by Andrey on 13.09.2017.
 */
package parser.content {
public class Variable {
    public var name:String;
    public var type:String;

    public function Variable(name:String, type:String) {
        this.name = name;
        this.type = type;
    }

    public function definite():String {
        return "var " + name + " : " + type + ";";
    }

    public function instaniate():String {
        return name + " = new " + type + "();";
    }
}
}
