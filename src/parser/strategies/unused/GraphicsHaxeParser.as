package parser.strategies.unused {
import parser.content.BitmapInfo;
import parser.strategies.*;

import flash.display.DisplayObject;
import flash.utils.Dictionary;

public class GraphicsHaxeParser implements IParseStrategy {
    private var _externalImportsHashList:Dictionary = new Dictionary();
    private var _externalConstructor = new String();
    private var _externalVariables = new String();
    private var _displayObject:DisplayObject;
    private var _visitor:IParserVisitor;

    public function get type():String {
        return "Tile";
    }


    public function get externalImportsHashList():Dictionary {
        return _externalImportsHashList;
    }

    public function get externalConstructor():String {
        return _externalConstructor;
    }

    public function get externalVariables():String {
        return _externalVariables;
    }

    public function GraphicsHaxeParser(displayObject:DisplayObject, visitor:IParserVisitor) {
        this._displayObject = displayObject;
        _visitor = visitor;
    }

    private function addToImports(line:String, includeExternal:Boolean = false):void {
        if (includeExternal) {
            _externalImportsHashList[line] = "";
        }
    }

    public function execute(externalContext:String = "this"):IParseStrategy {
        addToImports("import openfl.display.Tile;", true);

        var info:BitmapInfo = _visitor.visitGraphics(_displayObject);

        _externalConstructor = "\n\t\tvar " + _displayObject.name + ": Tile = new Tile(TileNames." + info._name + ",0,0);\n";
        _externalConstructor += "//TODO add to tilemap\n";
        //TODO _externalConstructor += "\t\tTilemap.instance.addTile("+_displayObject.name+");\n";
        _externalConstructor += createConstructorData(_displayObject);

        return this;
    }

    public function createConstructorData(displayObject:DisplayObject):String {
        //TODO probably maybe trash code
        var constructor:String = new String();
        if (displayObject.alpha != 1) {
            constructor += "\n";
            constructor += "\t\t" + displayObject.name + ".alpha = " + displayObject.alpha + ";\n";
        }
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            constructor += "\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix.a = " + displayObject.transform.matrix.a + ";\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix.b = " + displayObject.transform.matrix.b + ";\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix.c = " + displayObject.transform.matrix.c + ";\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix.d = " + displayObject.transform.matrix.d + ";\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix.tx = " + displayObject.transform.matrix.tx + ";\n";
            constructor += "\t\t" + displayObject.name + ".transform.matrix.ty = " + displayObject.transform.matrix.ty + ";\n";
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            constructor += "\n";
            constructor += "\t\t" + displayObject.name + ".x = " + displayObject.x + ";\n";
            constructor += "\t\t" + displayObject.name + ".y = " + displayObject.y + ";\n";
        }
        return constructor;
    }
}
}
