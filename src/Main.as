package {

import flash.display.Sprite;
import flash.events.KeyboardEvent;
import flash.filesystem.File;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.ui.Keyboard;

import resourceLoader.SingleResourceLoader;

import parser.FlashStageParser;
import parser.Logger;

/**
 * Парсим графику как битмап дату
 * Для мувиклипа использовать аналог DirectMovieClip
 * В санте цель сделать через tile map только игру.
 * Гуй не трогать
 */
public class Main extends Sprite {

    private var _inputField:TextField;

    public function Main() {
        var textField:TextField = new TextField();
        textField.autoSize = TextFieldAutoSize.LEFT;
        textField.text = "Input the path to swf.";
        addChild(textField);

        _inputField = new TextField();
        _inputField.border = true;
        _inputField.type = TextFieldType.INPUT;
        _inputField.autoSize = TextFieldAutoSize.LEFT;
        _inputField.text = "type there";
        addChild(_inputField);
        _inputField.y = textField.height + 8;

        var outputLog:TextField = new TextField();
        outputLog.multiline = true;
        addChild(outputLog);
        outputLog.y = _inputField.y + 8;
        outputLog.width = stage.stageWidth;
        outputLog.height = stage.stageHeight - outputLog.y;

        Logger.output = outputLog;

        addEventListener(KeyboardEvent.KEY_UP, startParsing);

        Logger.trace("Test line");
    }

    private function startParsing(event:KeyboardEvent):void {
        if(event.charCode == Keyboard.ENTER) {
            var loader:SingleResourceLoader = new SingleResourceLoader();
            loader.onLoadComplete = onLoadComplete;
            loader.load(_inputField.text);
        }
    }

    private function onLoadComplete(loader:SingleResourceLoader):void {
//        //Сгенерировать классы, работащие с этим атласом
//        var initClasses:Vector.<Class> = new <Class>[mcWinMainMenu, mcBlowVacuum, mcDialogBlob, mcBlowSimple,mcBorderLevelLineGreen,mcBorderLevelLineRed,
//            /*mcBorderLine,*/mcBtnBlow,mcBtnBuild,mcBtnClose,/*mcBtnEnter,*/
//            mcBtnLeft,/*mcBtnLeftTop,*/mcBtnRecickle,mcBtnReset,mcBtnRight,/*mcBtnRightTop,*//*mcBtnSave,*/
//            mcBtnSelectLevel,mcBtnSquareRedOut,mcBtnSquareRedOver,/*mcBtnTake,mcBtnTestBuilding,*/ mcFon,/*mcElementsLayer,mcFarCastles,mcFarGlass,mcFarTrees,mcFriendsPanel,*/
//            mcLocationCastel, mcMainScene,
//            mcPlace,mcPlaceList, mcSkies,
//            mcSmoke,mcSmokeJoint,mcSmokeJointBad,
//            mcWinBorderConsole,mcWinLevelResult,mcWinLoadLocation,mcWinNotify,
//            mcWinSelectLevel, mcWinWait];

//        var path:String = _inputField.text;
//        if(path.substring(path.length-1) != "/") {
//            path = path + "/";
//        }

        var directory:File = new File(_inputField.text);
        while(!directory.isDirectory) {
            directory = directory.parent;
        }
        var sourceDirectory:File = directory.resolvePath("generated");
        if(sourceDirectory.exists) {
            sourceDirectory.deleteDirectory(true);
        }

        new FlashStageParser(directory.nativePath + "\\").exportFromMC(loader.content);

        directory.openWithDefaultApplication();
        directory.cancel();
    }
}
}
