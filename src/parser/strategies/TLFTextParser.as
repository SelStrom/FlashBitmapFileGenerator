/**
 * Created by Andrey on 07.09.2017.
 */
package parser.strategies {
import fl.text.TLFTextField;

public class TLFTextParser extends AbstractParseStrategy {
    private var _container:TLFTextField;

    public override function get type():String {
        return "TextField";
    }

    public function TLFTextParser(container:TLFTextField) {
        _container = container;
    }

    private function addToImports(line:String):void {
        _externalImportsHashList[line] = "";
    }

    private function addToVariables(line:String):void {
        _externalVariables[line] = "";
    }

    public override function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.text.TextField;");
        addToImports("import openfl.text.TextFormat;");

        var name:String = _container.name;
        addToVariables("var " + name + ":TextField = new TextField();");

        _externalConstructor = "\t\t" + externalContext + ".addChild(" + name + ");\n";
        _externalConstructor += createConstructorData(_container);

        createTextData(name);

        return this;
    }

    private function createTextData(name:String):void {
        _externalConstructor += "\t\tthis." + name + ".text = \"" + _container.text + "\";\n";
        _externalConstructor += "\t\tthis." + name + ".textColor = 0x" + _container.textColor + ";\n";
        _externalConstructor += "\t\tthis." + name + ".autoSize = \"" + _container.autoSize + "\";\n";
        _externalConstructor += "\t\tthis." + name + ".width = " + _container.width + ";\n";
        _externalConstructor += "\t\tthis." + name + ".height = " + _container.height + ";\n";

        var textFormat:String = name + "TextFormat";

        _externalConstructor += "\n\t\tvar " + textFormat + ":TextFormat = new TextFormat();\n";
        _externalConstructor += "\t\tthis." + textFormat + ".font = \"" + _container.getTextFormat().font + "\";\n";
        _externalConstructor += "\t\tthis." + textFormat + ".size = " + _container.getTextFormat().size + ";\n";
        _externalConstructor += "\t\tthis." + textFormat + ".italic = " + _container.getTextFormat().italic + ";\n";
        _externalConstructor += "\t\tthis." + textFormat + ".bold = " + _container.getTextFormat().bold + ";\n";
    }

}
}
