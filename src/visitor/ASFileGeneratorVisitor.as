/**
 * Created by Andrey on 18.06.2017.
 */
package visitor {
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import parser.FlashStageParser;
import parser.Util;

public class ASFileGeneratorVisitor implements IContentVisitor {
    private var _dirrectory:File = File.applicationStorageDirectory;

    private var _sourcePath:File = null;
    private var _packageName:String = null;

    public function ASFileGeneratorVisitor(packageName:String) {
        _packageName = packageName;
        _dirrectory = _dirrectory.resolvePath(_packageName);
        if(_dirrectory.exists) {
            _dirrectory.deleteDirectory(true);
        }
        if (!_dirrectory.exists) {
            _dirrectory.createDirectory();
        }
    }

    public function visitSprite(container:Sprite):FileDataVO {
        var fileName:String = Util.getName(container);
        var file:File = _dirrectory.resolvePath(fileName + ".as");
        var fileData:FileDataVO = new FileDataVO();
        if (file.exists) {
            return fileData;
        }

        fileData.constructor = createConstructorData(container);
        //TODO @a.shatalov: вынести импорты в переменную
        var body:String = new String();
        body += "package " + _packageName + " {\n";
        body += "import flash.display.Sprite;\n";
        body += "\n";
        body += "public class " + Util.getName(container) + " extends Sprite {\n";

        var constructor:String = new String();
        var variables:String = new String();

        constructor += "\n\tpublic function " + Util.getName(container) + "() {\n";

        for (var i:int = 0; i < container.numChildren; ++i) {
            var child:DisplayObject = container.getChildAt(i);

            //TODO @a.shatalov: add unknown types to import
            
            variables += "\tpublic var " + child.name + ":" + Util.getName(child) + " = new " + Util.getName(child) + "();\n";

            constructor += "\n\t\tthis.addChild(this." + child.name + ");\n";

            var childFileData:FileDataVO = FlashStageParser.exportRecursive(child);
            constructor += childFileData.constructor;
            //imports += childFileData.imports; <-- для импортов нужен словарь, где ключ - импорт. Тогда можно будет кидать туда все без проверок
        }
        constructor += "\t}\n";

        body += variables;
        body += constructor;

        body += "}\n}\n";

        var fileStream : FileStream = new FileStream();
        fileStream.open(file, FileMode.WRITE);
        fileStream.writeUTFBytes(body);
        fileStream.close();

        file.save(body);
        return fileData;
    }

    public function visitBitmap():FileDataVO {
        return new FileDataVO();
    }

    public function visitShape():FileDataVO {
        return new FileDataVO();
    }

    public function visitMovieClip(container:MovieClip):FileDataVO {
        return visitSprite(container as Sprite);
    }

    public function visitTextField():FileDataVO {
        return new FileDataVO();
    }

    public function saveFile(fileName:String, data:String):void {
        var file:File = _dirrectory.resolvePath(fileName + ".as");
        if (file.exists) {
            var error:String = 'Error: file "' + fileName + '" already exists!';
            throw new Error(error);
        }
        else {
            file.save(data);
        }
    }

    public function createConstructorData(displayObject:DisplayObject):String {
        var constructor:String = new String();
        if (displayObject.alpha != 1) {
            constructor += "\n";
            constructor += "\t\tthis."+displayObject.name+".alpha = " + displayObject.alpha + ";\n";
        }
        if (displayObject.transform.matrix.a != 1
                || displayObject.transform.matrix.b != 0
                || displayObject.transform.matrix.c != 0
                || displayObject.transform.matrix.d != 1) {
            constructor += "\n";
            constructor += "\t\tthis."+displayObject.name+".transform.matrix.a = " + displayObject.transform.matrix.a + ";\n";
            constructor += "\t\tthis."+displayObject.name+".transform.matrix.b = " + displayObject.transform.matrix.b + ";\n";
            constructor += "\t\tthis."+displayObject.name+".transform.matrix.c = " + displayObject.transform.matrix.c + ";\n";
            constructor += "\t\tthis."+displayObject.name+".transform.matrix.d = " + displayObject.transform.matrix.d + ";\n";
            constructor += "\t\tthis."+displayObject.name+".transform.matrix.tx = " + displayObject.transform.matrix.tx + ";\n";
            constructor += "\t\tthis."+displayObject.name+".transform.matrix.ty = " + displayObject.transform.matrix.ty + ";\n";
        }
        else if (displayObject.x != 0 || displayObject.y != 0) {
            constructor += "\n";
            constructor += "\t\tthis."+displayObject.name+".x = " + displayObject.x + ";\n";
            constructor += "\t\tthis."+displayObject.name+".y = " + displayObject.y + ";\n";
        }
        return constructor;
    }
}
}
