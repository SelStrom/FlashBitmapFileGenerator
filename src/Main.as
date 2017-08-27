package {

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.text.TextField;

import parser.FlashStageParser;

public class Main extends Sprite {
    public function Main() {
        var textField:TextField = new TextField();
        textField.text = "Hello, World";
        addChild(textField);
        //TODO @a.shatalov: implement main
        //Сформировать атлас
        //Сгенерировать классы, работащие с этим атласом
        var initClasses:Vector.<Class> = new <Class>[mcWinMainMenu, mcBlowVacuum, mcDialogBlob, mcBlowSimple,mcBorderLevelLineGreen,mcBorderLevelLineRed,
            /*mcBorderLine,*/mcBtnBlow,mcBtnBuild,mcBtnClose,/*mcBtnEnter,*/
            mcBtnLeft,/*mcBtnLeftTop,*/mcBtnRecickle,mcBtnReset,mcBtnRight,/*mcBtnRightTop,*//*mcBtnSave,*/
            mcBtnSelectLevel,mcBtnSquareRedOut,mcBtnSquareRedOver,/*mcBtnTake,mcBtnTestBuilding,*/ mcFon,/*mcElementsLayer,mcFarCastles,mcFarGlass,mcFarTrees,mcFriendsPanel,*/
            /*mcFriendsPanelItemsLayer,mcInterfaceLayer,mcLocationArea,*/
            mcLocationCastel,/*mcLocationLayer,mcLocationMap,*/mcMainScene,
            mcPlace,mcPlaceList,/*mcPlaceMask,mcRecickeIcon,*/ mcSkies,
            mcSmoke,mcSmokeJoint,mcSmokeJointBad,
            mcWinBorderConsole,mcWinLevelResult,mcWinLoadLocation,mcWinNotify,
            mcWinSelectLevel, mcWinWait];

        var dirrectory:File = File.applicationStorageDirectory;
        dirrectory = dirrectory.resolvePath("generated");
        if(dirrectory.exists) {
            dirrectory.deleteDirectory(true);
        }


        FlashStageParser.exportMC(initClasses);
//        FlashStageParser.

        dirrectory.openWithDefaultApplication();
        dirrectory.cancel();
    }
}
}
